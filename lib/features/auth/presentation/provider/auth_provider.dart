import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:money_tracker/general/models/user.dart';

class AuthProvider with ChangeNotifier {
  static const String userBoxName = 'user_profile';
  AppUser? _currentUser;
  bool _isAuthenticated = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    final box = await Hive.openBox<AppUser>(userBoxName);
    if (_auth.currentUser != null) {
      if (box.isNotEmpty) {
        _currentUser = box.getAt(0);
      } else {
        _currentUser = AppUser(
          id: _auth.currentUser!.uid,
          name: _auth.currentUser!.displayName ?? 'User',
          phoneNumber: '',
          initialBalance: 0.0,
          joinedDate: DateTime.now(),
        );
      }
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required Function(String error) onError,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName);
        await _onLoginSuccess(fullName, email);
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      onError(e.message ?? 'Unknown error occurred');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onError(e.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required Function(String error) onError,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _onLoginSuccess(userCredential.user!.displayName ?? 'User', email);
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      onError(e.message ?? 'Login failed');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onError(e.toString());
    }
  }

  Future<void> _onLoginSuccess(String name, String email) async {
    final user = AppUser(
      id: _auth.currentUser!.uid,
      name: name,
      phoneNumber: email,
      initialBalance: 0.0,
      joinedDate: DateTime.now(),
    );

    // 1. Sync to local Hive
    final box = await Hive.openBox<AppUser>(userBoxName);
    await box.clear();
    await box.add(user);

    // 2. Sync to Firestore (New functionality)
    try {
      await _firestore.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.phoneNumber,
        'joinedDate': user.joinedDate,
        'lastLogin': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore Sync Error: $e');
    }

    _currentUser = user;
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(fullName);
        
        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': fullName,
        });

        // Update local Hive
        final box = await Hive.openBox<AppUser>(userBoxName);
        if (box.isNotEmpty) {
          final localUser = box.getAt(0);
          if (localUser != null) {
            final updatedUser = AppUser(
              id: localUser.id,
              name: fullName,
              phoneNumber: localUser.phoneNumber,
              initialBalance: localUser.initialBalance,
              joinedDate: localUser.joinedDate,
            );
            await box.putAt(0, updatedUser);
            _currentUser = updatedUser;
          }
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateEmail({
    required String newEmail,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
        
        // Update Firestore (email field)
        await _firestore.collection('users').doc(user.uid).update({
          'email': newEmail,
        });

        // Update local Hive
        final box = await Hive.openBox<AppUser>(userBoxName);
        if (box.isNotEmpty) {
          final localUser = box.getAt(0);
          if (localUser != null) {
            final updatedUser = AppUser(
              id: localUser.id,
              name: localUser.name,
              phoneNumber: newEmail,
              initialBalance: localUser.initialBalance,
              joinedDate: localUser.joinedDate,
            );
            await box.putAt(0, updatedUser);
            _currentUser = updatedUser;
          }
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    final box = await Hive.openBox<AppUser>(userBoxName);
    await box.clear();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
