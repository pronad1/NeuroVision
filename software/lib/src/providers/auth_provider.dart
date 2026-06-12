// lib/src/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class NVAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  NVUser? _nvUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  NVUser? get nvUser => _nvUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _nvUser != null;
  bool get isLoading => _status == AuthStatus.loading;

  NVAuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _nvUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final nvUser = await _authService.getCurrentNVUser();
      if (nvUser != null) {
        _nvUser = nvUser;
        _status = AuthStatus.authenticated;
      } else {
        _nvUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _nvUser = null;
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.login(email, password);

    if (error != null) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = error;
      notifyListeners();
    }
    // Auth listener will handle success case

    return error;
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String role,
    required String name,
    String? institution,
    String? specialization,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.signUp(
      email: email,
      password: password,
      role: role,
      name: name,
      institution: institution,
      specialization: specialization,
    );

    _status = AuthStatus.unauthenticated;
    if (error != null) _errorMessage = error;
    notifyListeners();

    return error;
  }

  Future<String?> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.signInWithGoogle();

    if (error != null) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = error;
      notifyListeners();
    }

    return error;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _nvUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
