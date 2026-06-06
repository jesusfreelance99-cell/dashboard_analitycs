import 'package:flutter/material.dart';

class LoginScreenProvider extends ChangeNotifier {
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _isLoading;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<void> login() async {
    _isLoading = true;
    notifyListeners();
    // TODO: conectar con auth service
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
