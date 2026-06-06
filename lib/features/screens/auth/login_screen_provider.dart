import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/user_sync_service.dart';

class LoginScreenProvider extends ChangeNotifier {
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sign in with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Verify user role in Firestore based on email
      final userEmail = emailController.text.trim();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users_dashboard')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // No matching user document found
        await FirebaseAuth.instance.signOut();
        _errorMessage = 'Usuario no encontrado en la base de datos.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userData = querySnapshot.docs.first.data();
      if (userData['rol'] != 'admin') {
        // User does not have admin role
        await FirebaseAuth.instance.signOut();
        _errorMessage = 'Acceso denegado: se requiere rol de administrador.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Sincronizar usuarios desde Firebase a SQLite
      print('🔵 Sincronizando usuarios...');
      try {
        await UserSyncService().syncAllUsers();
        print('✅ Usuarios sincronizados correctamente');
      } catch (e) {
        print('⚠️ Error sincronizando usuarios: $e');
      }

      // All checks passed
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseErrorCode(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _mapFirebaseErrorCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Este usuario ha sido deshabilitado.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Credenciales incorrectas. Verifica tu correo y contraseña.';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión a internet.';
      default:
        return 'Error al iniciar sesión: $code';
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📱 Iniciando Google Sign-In desde provider...');
      final result = await GoogleAuthService.signInWithGoogle();

      if (result == null) {
        print('⚠️ Usuario canceló');
        _isLoading = false;
        notifyListeners();
        return false; // Usuario canceló
      }

      print('✅ Google Sign-In completado exitosamente');

      // Sincronizar usuarios desde Firebase a SQLite
      print('🔵 Sincronizando usuarios...');
      try {
        await UserSyncService().syncAllUsers();
        print('✅ Usuarios sincronizados correctamente');
      } catch (e) {
        print('⚠️ Error sincronizando usuarios: $e');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final errorMsg = _cleanErrorMessage(e.toString());
      _errorMessage = errorMsg;
      print('❌ Error en Google Sign-In: $errorMsg');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _cleanErrorMessage(String error) {
    // Extrae el mensaje de error limpio
    if (error.contains('Usuario no registrado')) {
      return 'Usuario no registrado en el sistema. Contacta al administrador.';
    } else if (error.contains('Acceso denegado')) {
      return error.split(':').skip(1).join(':').trim();
    } else if (error.contains('No se pudo obtener las credenciales')) {
      return 'OAuth no está configurado. Verifica Google Cloud Console.';
    } else if (error.contains('Exception:')) {
      return error.replaceFirst('Exception: ', '');
    }
    return error.length > 100 ? error.substring(0, 100) + '...' : error;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
