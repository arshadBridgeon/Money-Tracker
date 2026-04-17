import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_tracker/general/models/transaction.dart';

class MoneyRecordProvider with ChangeNotifier {
  List<MoneyRecord> _records = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Pagination State
  int _incomeDisplayLimit = 10;
  int _expenseDisplayLimit = 10;
  DocumentSnapshot? _lastIncomeVisible;
  DocumentSnapshot? _lastExpenseVisible;
  bool _hasMoreIncome = true;
  bool _hasMoreExpense = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 10;

  List<MoneyRecord> get transactions => _records;

  // Getters for filtered transactions with display limits
  List<MoneyRecord> getFilteredTransactions(bool isIncome) {
    final filtered = _records.where((tx) => tx.isIncome == isIncome).toList();
    final limit = isIncome ? _incomeDisplayLimit : _expenseDisplayLimit;
    return filtered.take(limit).toList();
  }

  bool hasMore(bool isIncome) {
    final filteredLocalCount = _records.where((tx) => tx.isIncome == isIncome).length;
    final limit = isIncome ? _incomeDisplayLimit : _expenseDisplayLimit;
    final hasMoreRemote = isIncome ? _hasMoreIncome : _hasMoreExpense;
    
    // We have more if the limit hasn't reached the total local count 
    // OR if Firestore says there are more remote records.
    return limit < filteredLocalCount || hasMoreRemote;
  }

  bool get isLoadingMore => _isLoadingMore;

  String get _userBoxName =>
      'transactions_${_auth.currentUser?.uid ?? 'guest'}';

  double get totalBalance {
    double total = 0.0;
    for (var tx in _records) {
      if (tx.isIncome) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  double get totalIncome {
    double total = 0.0;
    for (var tx in _records) {
      if (tx.isIncome) {
        total += tx.amount;
      }
    }
    return total;
  }

  double get totalExpense {
    double total = 0.0;
    for (var tx in _records) {
      if (!tx.isIncome) {
        total += tx.amount;
      }
    }
    return total;
  }

  Future<void> refreshForNewUser() async {
    _records = [];
    _incomeDisplayLimit = 10;
    _expenseDisplayLimit = 10;
    _lastIncomeVisible = null;
    _lastExpenseVisible = null;
    _hasMoreIncome = true;
    _hasMoreExpense = true;
    notifyListeners();
    await fetchTransactions();
  }
  
  Future<void> fetchTransactions() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    
    // Load cached records into memory but keep display limits low
    _updateRecordsFromBox(box);
    _incomeDisplayLimit = 10;
    _expenseDisplayLimit = 10;
    notifyListeners();

    // Fetch initial pages from Firestore to sync latest (background)
    await _fetchInitialPage(true);
    await _fetchInitialPage(false);
  }

  Future<void> _fetchInitialPage(bool isIncome) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('isIncome', isEqualTo: isIncome)
          .orderBy('date', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();
      
      if (isIncome) {
        _lastIncomeVisible = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMoreIncome = snapshot.docs.length == _pageSize;
      } else {
        _lastExpenseVisible = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMoreExpense = snapshot.docs.length == _pageSize;
      }

      final box = await Hive.openBox<MoneyRecord>(_userBoxName);
      for (var doc in snapshot.docs) {
        final record = _mapDocToRecord(doc);
        await box.put(record.id, record);
      }
      _updateRecordsFromBox(box);
      notifyListeners();
    } catch (e) {
      debugPrint('Initial fetch error ($isIncome): $e');
    }
  }

  Future<void> fetchMoreTransactions(bool isIncome) async {
    if (_isLoadingMore) return;

    final filteredLocal = _records.where((tx) => tx.isIncome == isIncome).toList();
    int currentLimit = isIncome ? _incomeDisplayLimit : _expenseDisplayLimit;

    // 1. Try to expand local view first
    if (currentLimit < filteredLocal.length) {
      if (isIncome) _incomeDisplayLimit += 10;
      else _expenseDisplayLimit += 10;
      notifyListeners();
      return;
    }

    // 2. If local exhausted, fetch from Firestore
    final user = _auth.currentUser;
    final lastVisible = isIncome ? _lastIncomeVisible : _lastExpenseVisible;
    final hasMoreFlag = isIncome ? _hasMoreIncome : _hasMoreExpense;

    if (user == null || !hasMoreFlag || lastVisible == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('isIncome', isEqualTo: isIncome)
          .orderBy('date', descending: true)
          .startAfterDocument(lastVisible)
          .limit(_pageSize);

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        if (isIncome) {
          _lastIncomeVisible = snapshot.docs.last;
          _hasMoreIncome = snapshot.docs.length == _pageSize;
          _incomeDisplayLimit += snapshot.docs.length;
        } else {
          _lastExpenseVisible = snapshot.docs.last;
          _hasMoreExpense = snapshot.docs.length == _pageSize;
          _expenseDisplayLimit += snapshot.docs.length;
        }

        final box = await Hive.openBox<MoneyRecord>(_userBoxName);
        for (var doc in snapshot.docs) {
          final record = _mapDocToRecord(doc);
          await box.put(record.id, record);
        }
        _updateRecordsFromBox(box);
      } else {
        if (isIncome) _hasMoreIncome = false;
        else _hasMoreExpense = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch more error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  MoneyRecord _mapDocToRecord(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoneyRecord(
      id: doc.id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      isIncome: data['isIncome'] as bool,
    );
  }

  Future<void> addTransaction(MoneyRecord tx) async {
    if (_auth.currentUser == null) return;

    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    await box.put(tx.id, tx);

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('transactions')
          .doc(tx.id)
          .set({
            'title': tx.title,
            'amount': tx.amount,
            'date': tx.date,
            'isIncome': tx.isIncome,
          });
    } catch (e) {
      debugPrint('Firestore sync error: $e');
    }

    // Instead of refetching all, just prepend or re-init pager
    _records.insert(0, tx);
    notifyListeners();
  }

  Future<void> deleteTransaction(int index) async {
    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    final txToDelete = _records[index];

    if (_auth.currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('transactions')
            .doc(txToDelete.id)
            .delete();
      } catch (e) {
        debugPrint('Firestore delete error: $e');
      }
    }

    // Deleting from local for UI
    await box.delete(txToDelete.id);
    _updateRecordsFromBox(box);
    notifyListeners();
  }

  Future<void> updateTransaction(MoneyRecord updatedRecord) async {
    if (_auth.currentUser == null) return;

    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    await box.put(updatedRecord.id, updatedRecord);

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('transactions')
          .doc(updatedRecord.id)
          .update({
        'title': updatedRecord.title,
        'amount': updatedRecord.amount,
        'date': updatedRecord.date,
        'isIncome': updatedRecord.isIncome,
      });
    } catch (e) {
      debugPrint('Firestore update error: $e');
    }

    _updateRecordsFromBox(box);
    notifyListeners();
  }

  void _updateRecordsFromBox(Box<MoneyRecord> box) {
    final allItems = box.values.toList();
    final Map<String, MoneyRecord> uniqueItems = {};

    for (var item in allItems) {
      uniqueItems[item.id] = item;
    }

    _records = uniqueItems.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> clearLocalCache() async {
    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    await box.clear();
    _records = [];
    _incomeDisplayLimit = 10;
    _expenseDisplayLimit = 10;
    _lastIncomeVisible = null;
    _lastExpenseVisible = null;
    _hasMoreIncome = true;
    _hasMoreExpense = true;
    notifyListeners();
  }
}
