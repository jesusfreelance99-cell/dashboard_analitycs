import 'package:flutter/material.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  // ── Form values ────────────────────────────────────────────────
  String _email = '';
  String _password = '';
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // ── Validation errors ──────────────────────────────────────────
  String? _emailError;
  String? _passwordError;

  // ── Status ─────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.idle;

  // ── Getters ────────────────────────────────────────────────────
  String get email => _email;
  String get password => _password;
  bool get rememberMe => _rememberMe;
  bool get obscurePassword => _obscurePassword;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.loading;

  // ── Regex ──────────────────────────────────────────────────────
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  // ── Setters ────────────────────────────────────────────────────
  void setEmail(String value) {
    _email = value;
    if (_emailError != null) {
      _emailError = null;
      notifyListeners();
    }
  }

  void setPassword(String value) {
    _password = value;
    if (_passwordError != null) {
      _passwordError = null;
      notifyListeners();
    }
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Validate email on blur if not empty
  void validateEmailOnBlur() {
    if (_email.isEmpty) return;
    _validateEmail();
    notifyListeners();
  }

  // ── Validation ─────────────────────────────────────────────────
  bool _validateEmail() {
    if (_email.trim().isEmpty) {
      _emailError = 'Ingresa tu correo';
      return false;
    }
    if (!_emailRegex.hasMatch(_email.trim())) {
      _emailError = 'Ingresa un correo válido';
      return false;
    }
    _emailError = null;
    return true;
  }

  bool _validatePassword() {
    if (_password.isEmpty) {
      _passwordError = 'Ingresa tu contraseña';
      return false;
    }
    _passwordError = null;
    return true;
  }

  bool validateAll() {
    final okEmail = _validateEmail();
    final okPassword = _validatePassword();
    notifyListeners();
    return okEmail && okPassword;
  }

  // ── Auth actions ───────────────────────────────────────────────

  /// Simulate login — returns true when navigation should happen
  Future<bool> login() async {
    if (!validateAll()) return false;

    _status = AuthStatus.loading;
    notifyListeners();

    // Simulated network delay (replace with real auth call)
    await Future.delayed(const Duration(milliseconds: 780));

    _status = AuthStatus.success;
    notifyListeners();
    return true;
  }

  /// Google login — no validation needed
  Future<bool> loginWithGoogle() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    _status = AuthStatus.success;
    notifyListeners();
    return true;
  }

  void resetStatus() {
    _status = AuthStatus.idle;
    notifyListeners();
  }

  void clearErrors() {
    _emailError = null;
    _passwordError = null;
    notifyListeners();
  }
}
