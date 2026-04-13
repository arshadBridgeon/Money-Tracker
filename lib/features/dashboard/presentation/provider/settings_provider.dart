import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _currency = 'INR';
  bool _biometricEnabled = false;
  String? _appPin;
  bool _remindersEnabled = true;

  String get currency => _currency;
  bool get biometricEnabled => _biometricEnabled;
  bool get hasPin => _appPin != null;
  bool get remindersEnabled => _remindersEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'INR';
    _biometricEnabled = prefs.getBool('biometric') ?? false;
    _appPin = prefs.getString('app_pin');
    _remindersEnabled = prefs.getBool('reminders') ?? true;
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', value);
    notifyListeners();
  }

  Future<void> toggleBiometric(bool value) async {
    _biometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric', value);
    notifyListeners();
  }

  Future<void> setPin(String? value) async {
    _appPin = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('app_pin');
    } else {
      await prefs.setString('app_pin', value);
    }
    notifyListeners();
  }

  Future<void> toggleReminders(bool value) async {
    _remindersEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders', value);
    notifyListeners();
  }
}
