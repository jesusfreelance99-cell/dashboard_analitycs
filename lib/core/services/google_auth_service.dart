import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static final _firebaseAuth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Inicia sesión con Google
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('🔵 Iniciando Google Sign-In...');

      // Obtener cuenta de Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('🟡 Usuario canceló Google Sign-In');
        return null; // Usuario canceló
      }

      print('✅ Usuario de Google obtenido: ${googleUser.email}');

      // Obtener credenciales
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('No se pudo obtener las credenciales de autenticación de Google');
      }

      print('✅ Credenciales de Google obtenidas');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autenticar con Firebase
      print('🔵 Autenticando con Firebase...');
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('No se pudo obtener el usuario de Firebase');
      }

      print('✅ Usuario autenticado en Firebase: ${user.email}');

      // Verificar si el usuario existe en Firestore y tiene rol admin
      print('🔵 Verificando rol en Firestore...');
      final userDoc = await _firestore.collection('users_dashboard').doc(user.uid).get();

      if (!userDoc.exists) {
        print('❌ Usuario no existe en Firestore');
        // Usuario no existe en Firestore, logout
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        throw Exception('Usuario no registrado en el sistema. Contacta con el administrador.');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['rol'] ?? 'user';

      print('✅ Usuario encontrado en Firestore con rol: $userRole');

      if (userRole != 'admin') {
        print('❌ Usuario no tiene rol admin');
        // Usuario no tiene rol admin
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        throw Exception('Acceso denegado: se requiere rol de administrador. Tu rol es: $userRole');
      }

      print('✅ Acceso permitido. Login exitoso.');

      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'userData': userData,
      };
    } catch (e) {
      print('❌ Error en Google Sign-In: $e');
      rethrow;
    }
  }

  /// Cierra sesión — siempre completa aunque Google SignIn falle en web
  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google Sign-In puede fallar en web sin sesión activa — ignoramos
    }
  }

  /// Obtiene el usuario actual
  static User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Stream de cambios de autenticación
  static Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}
