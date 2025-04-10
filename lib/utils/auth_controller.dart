import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController with ChangeNotifier {
  bool _isAuthenticated = false;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  AuthController() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _checkAuthStatus();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AuthController: $e');
      _isAuthenticated = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _checkAuthStatus() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final hasPin = _prefs!.getString('user_pin') != null;

    // If there's no PIN set, we don't enforce authentication yet
    if (!hasPin) {
      _isAuthenticated = true;
      notifyListeners();
      return;
    }

    // Always require authentication when the app is started/reopened
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> login() async {
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    notifyListeners();
  }

  // Method to check if PIN exists (for first-time users)
  Future<bool> hasPinSet() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!.getString('user_pin') != null;
  }

  Future<bool> resetPin(String currentPin) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final savedPin = _prefs!.getString('user_pin') ?? '';

    if (savedPin == currentPin) {
      await _prefs!.remove('user_pin');
      return true;
    }

    return false;
  }
  
  // Method to update PIN
  Future<bool> updatePin(String currentPin, String newPin) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final savedPin = _prefs!.getString('user_pin') ?? '';

    if (savedPin == currentPin) {
      await _prefs!.setString('user_pin', newPin);
      return true;
    }

    return false;
  }
}
