import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_tracker/models/transaction.dart';

class MoneyRecordProvider with ChangeNotifier {
  List<MoneyRecord> _records = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<MoneyRecord> get transactions => _records;

  // Box name is unique for each user to avoid data mixing
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

  // Clear local records and fetch from Firestore when user changes
  Future<void> refreshForNewUser() async {
    _records = [];
    notifyListeners();
    await fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    if (_auth.currentUser == null) return;

    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    
    // 1. Load from local first for speed
    _records = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    // 2. Fetch from Firestore to get remote data
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();
      
      final remoteRecords = snapshot.docs.map((doc) {
        final data = doc.data();
        return MoneyRecord(
          id: doc.id,
          title: data['title'] as String,
          amount: (data['amount'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          isIncome: data['isIncome'] as bool,
        );
      }).toList();

      // Update local storage with remote data
      await box.clear();
      await box.addAll(remoteRecords);
      _records = remoteRecords;
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }
  }

  Future<void> addTransaction(MoneyRecord tx) async {
    if (_auth.currentUser == null) return;
    
    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    await box.add(tx);
    
    // Sync to Firestore
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
    
    await fetchTransactions();
  }

  Future<void> deleteTransaction(int index) async {
    final box = await Hive.openBox<MoneyRecord>(_userBoxName);
    final txToDelete = box.getAt(index);
    
    if (txToDelete != null && _auth.currentUser != null) {
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

    await box.deleteAt(index);
    await fetchTransactions();
  }
}
