import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';

class UserSyncService {
  static final UserSyncService _instance = UserSyncService._internal();
  final _firestore = FirebaseFirestore.instance;
  final _localDb = LocalDbService();

  factory UserSyncService() {
    return _instance;
  }

  UserSyncService._internal();

  /// Sincronizar todos los usuarios desde Firestore a SQLite
  Future<void> syncAllUsers() async {
    try {
      log('🔵 Iniciando sincronización de usuarios...');

      final usersSnapshot = await _firestore
          .collection('users')
          .limit(10000) // Limite de seguridad
          .get();

      final users = <UserModel>[];

      for (final doc in usersSnapshot.docs) {
        try {
          final user = UserModel.fromFirestore(doc.id, doc.data());
          users.add(user);
        } catch (e) {
          log('❌ Error procesando usuario ${doc.id}: $e');
        }
      }

      if (users.isNotEmpty) {
        await _localDb.upsertUsers(users);
        log('✅ Sincronizados ${users.length} usuarios');
      } else {
        log('⚠️ No se encontraron usuarios');
      }
    } catch (e) {
      log('❌ Error en sincronización: $e');
      rethrow;
    }
  }

  /// Sincronizar solo usuarios activos
  Future<void> syncActiveUsers() async {
    try {
      log('🔵 Sincronizando usuarios activos...');

      final usersSnapshot = await _firestore
          .collection('users')
          .where('user_info.status', isEqualTo: true)
          .limit(10000)
          .get();

      final users = <UserModel>[];

      for (final doc in usersSnapshot.docs) {
        try {
          final user = UserModel.fromFirestore(doc.id, doc.data());
          users.add(user);
        } catch (e) {
          log('❌ Error procesando usuario ${doc.id}: $e');
        }
      }

      if (users.isNotEmpty) {
        await _localDb.upsertUsers(users);
        log('✅ Sincronizados ${users.length} usuarios activos');
      }
    } catch (e) {
      log('❌ Error sincronizando usuarios activos: $e');
      rethrow;
    }
  }

  /// Obtener un usuario específico por ID desde Firestore
  Future<UserModel?> getUserFromFirestore(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) return null;

      return UserModel.fromFirestore(docSnapshot.id, docSnapshot.data() ?? {});
    } catch (e) {
      log('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  /// Obtener todos los usuarios desde base de datos local
  Future<List<UserModel>> getAllUsersLocal() async {
    return await _localDb.getAllUsers();
  }

  /// Obtener usuarios activos desde base de datos local
  Future<List<UserModel>> getActiveUsersLocal() async {
    return await _localDb.getActiveUsers();
  }

  /// Buscar usuario por email en base de datos local
  Future<UserModel?> getUserByEmailLocal(String email) async {
    return await _localDb.getUserByEmail(email);
  }

  /// Buscar usuarios por nombre en base de datos local
  Future<List<UserModel>> searchUsersLocal(String query) async {
    if (query.isEmpty) return [];
    return await _localDb.searchUsersByName(query);
  }

  /// Obtener tokens FCM de todos los usuarios activos
  Future<List<String>> getActiveFcmTokens() async {
    return await _localDb.getActiveFcmTokens();
  }

  /// Obtener FCM token de un usuario específico
  Future<String?> getUserFcmToken(String userId) async {
    return await _localDb.getUserFcmToken(userId);
  }

  /// Obtener usuarios con paginación
  Future<List<UserModel>> getUsersPaginated(int page, int pageSize) async {
    return await _localDb.getUsersPaginated(page, pageSize);
  }

  /// Obtener total de usuarios
  Future<int> getUsersCount() async {
    return await _localDb.getUsersCount();
  }

  /// Limpiar caché local
  Future<void> clearLocalCache() async {
    await _localDb.clearDatabase();
  }
}
