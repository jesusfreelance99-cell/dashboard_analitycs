import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  static Database? _database;

  factory LocalDbService() {
    return _instance;
  }

  LocalDbService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'trevo_dashboard.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users_cache (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        fcm_token TEXT NOT NULL,
        status INTEGER NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT,
        synced_at TEXT NOT NULL
      )
    ''');

    // Índices para búsquedas rápidas
    await db.execute('CREATE INDEX idx_email ON users_cache(email)');
    await db.execute('CREATE INDEX idx_full_name ON users_cache(full_name)');
    await db.execute('CREATE INDEX idx_status ON users_cache(status)');
  }

  // Insertar o actualizar usuario
  Future<void> upsertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users_cache',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insertar múltiples usuarios (para sincronización masiva)
  Future<void> upsertUsers(List<UserModel> users) async {
    final db = await database;
    final batch = db.batch();

    for (final user in users) {
      batch.insert(
        'users_cache',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // Obtener todos los usuarios
  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users_cache');
    return [for (final map in maps) UserModel.fromMap(map)];
  }

  // Obtener usuarios activos (status = true)
  Future<List<UserModel>> getActiveUsers() async {
    final db = await database;
    final maps = await db.query(
      'users_cache',
      where: 'status = ?',
      whereArgs: [1],
    );
    return [for (final map in maps) UserModel.fromMap(map)];
  }

  // Buscar usuario por email
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users_cache',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  // Buscar usuarios por nombre (parcial)
  Future<List<UserModel>> searchUsersByName(String query) async {
    final db = await database;
    final maps = await db.query(
      'users_cache',
      where: 'full_name LIKE ?',
      whereArgs: ['%$query%'],
      limit: 50,
    );
    return [for (final map in maps) UserModel.fromMap(map)];
  }

  // Obtener usuarios con paginación
  Future<List<UserModel>> getUsersPaginated(int page, int pageSize) async {
    final db = await database;
    final offset = (page - 1) * pageSize;
    final maps = await db.query(
      'users_cache',
      offset: offset,
      limit: pageSize,
      orderBy: 'created_at DESC',
    );
    return [for (final map in maps) UserModel.fromMap(map)];
  }

  // Obtener total de usuarios
  Future<int> getUsersCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users_cache');
    return (result.first['count'] as int?) ?? 0;
  }

  // Obtener FCM tokens de usuarios activos (para envío masivo)
  Future<List<String>> getActiveFcmTokens() async {
    final db = await database;
    final maps = await db.query(
      'users_cache',
      columns: ['fcm_token'],
      where: 'status = ? AND fcm_token != ?',
      whereArgs: [1, ''],
    );
    return [for (final map in maps) map['fcm_token'] as String];
  }

  // Obtener FCM token de un usuario específico
  Future<String?> getUserFcmToken(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users_cache',
      columns: ['fcm_token'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['fcm_token'] as String?;
  }

  // Limpiar base de datos
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users_cache');
  }

  // Cerrar base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
