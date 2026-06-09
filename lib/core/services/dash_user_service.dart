import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashUserData {
  final String nombre;
  final String email;
  final String rol;

  const DashUserData({
    required this.nombre,
    required this.email,
    required this.rol,
  });

  String get firstName => nombre.split(' ').first;
  String get initials {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }
}

class DashUserService {
  static Future<DashUserData?>? _future;

  static Future<DashUserData?> get() => _future ??= _fetch();

  static void refresh() => _future = null;

  static Future<DashUserData?> _fetch() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) return null;
      final snap = await FirebaseFirestore.instance
          .collection('users_dashboard')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first.data();
      return DashUserData(
        nombre: d['nombre'] as String? ?? email.split('@').first,
        email: d['email'] as String? ?? email,
        rol: d['rol'] as String? ?? '',
      );
    } catch (_) {
      final fallback = FirebaseAuth.instance.currentUser;
      if (fallback == null) return null;
      return DashUserData(
        nombre: fallback.displayName ?? fallback.email?.split('@').first ?? 'Admin',
        email: fallback.email ?? '',
        rol: '',
      );
    }
  }
}
