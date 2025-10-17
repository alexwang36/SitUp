import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  bool isLoading = false;
  String? errorMessage;

  AuthViewModel(this._authService);

  Stream<User?> get userStream => _authService.userChanges;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
      errorMessage = null;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.register(email, password);
      errorMessage = null;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async => _authService.signOut();

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
