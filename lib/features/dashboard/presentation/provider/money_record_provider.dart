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
  DocumentSnapshot? _lastVisible;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 15;

  List<MoneyRecord> get transactions => _records;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  String get _userBoxName => 'transactions_${_auth.currentUser?.uid ?? 'guest'}';

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
    _lastVisible = null;
    _hasMore = true;
    notifyListeners();
    await fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    if (_auth.currentUser == null) return;

    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    
    // Reset paging on initial fetch
    _lastVisible = null;
    _hasMore = true;

    // 1. Initial Load from Hive (all cached) for UI responsiveness
    _records = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    // 2. Fetch first page from Firestore
    try {
      final query = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastVisible = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;

        final remoteRecords = snapshot.docs.map((doc) => _mapDocToRecord(doc)).toList();

        // For initial fetch, we sync local cache
        await box.clear();
        await box.addAll(remoteRecords);
        _records = remoteRecords;
        notifyListeners();
      } else {
        _hasMore = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }
  }

  Future<void> fetchMoreTransactions() async {
    if (_auth.currentUser == null || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final query = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .startAfterDocument(_lastVisible!)
          .limit(_pageSize);

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastVisible = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;

        final newRecords = snapshot.docs.map((doc) => _mapDocToRecord(doc)).toList();
        _records.addAll(newRecords);
        
        // Update local cache too
        final box = await Hive.openBox<MoneyRecord>(_userBoxName);
        await box.addAll(newRecords);
        
        notifyListeners();
      } else {
        _hasMore = false;
        notifyListeners();
      }
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
    await box.add(tx);
    
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
    await box.deleteAt(index);
    _records.removeAt(index);
    notifyListeners();
  }
}
