import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:money_tracker/general/models/bill_reminder.dart';

class ReminderProvider with ChangeNotifier {
  static const String _boxName = 'bill_reminders';
  List<BillReminder> _reminders = [];
  bool _isLoading = false;

  List<BillReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;

  int get overdueCount => _reminders.where((r) => !r.isPaid && r.dueDate.isBefore(DateTime.now())).length;
  List<BillReminder> get overdueReminders => _reminders.where((r) => !r.isPaid && r.dueDate.isBefore(DateTime.now())).toList();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load from local Cache
        final box = await Hive.openBox<BillReminder>('${_boxName}_${user.uid}');
        _reminders = box.values.toList();
        _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        notifyListeners();

        // Sync from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .get();
            
        final remoteReminders = snapshot.docs.map((doc) => BillReminder.fromJson(doc.data())).toList();
        
        // Sync local with remote (Simple overwrite for now)
        await box.clear();
        await box.addAll(remoteReminders);
        
        _reminders = remoteReminders;
        _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      }
    } catch (e) {
      debugPrint('Reminder Sync Error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addReminder({
    required String title,
    required double amount,
    required DateTime dueDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final id = const Uuid().v4();
    final reminder = BillReminder(
      id: id,
      title: title,
      amount: amount,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .doc(id)
        .set(reminder.toJson());

    // Save locally
    final box = await Hive.openBox<BillReminder>('${_boxName}_${user.uid}');
    await box.add(reminder);

    _reminders.add(reminder);
    _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    notifyListeners();
  }

  Future<void> markAsPaid(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index].isPaid = !_reminders[index].isPaid;
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(id)
          .update({'isPaid': _reminders[index].isPaid});

      // Update locally
      final box = await Hive.openBox<BillReminder>('${_boxName}_${user.uid}');
      final localIndex = box.values.toList().indexWhere((r) => r.id == id);
      if (localIndex != -1) {
        final reminder = box.getAt(localIndex);
        if (reminder != null) {
          reminder.isPaid = _reminders[index].isPaid;
          await reminder.save();
        }
      }
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Delete Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .doc(id)
        .delete();

    // Delete local
    final box = await Hive.openBox<BillReminder>('${_boxName}_${user.uid}');
    final localIndex = box.values.toList().indexWhere((r) => r.id == id);
    if (localIndex != -1) {
      await box.deleteAt(localIndex);
    }

    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
