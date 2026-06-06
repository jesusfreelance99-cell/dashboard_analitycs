import '../models/user_model.dart';

/// Cache en-memoria de usuarios. Misma API que la versión SQLite,
/// pero funciona en todas las plataformas incluyendo Flutter web.
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();

  factory LocalDbService() => _instance;
  LocalDbService._internal();

  final List<UserModel> _users = [];

  Future<void> upsertUser(UserModel user) async {
    _users.removeWhere((u) => u.id == user.id);
    _users.add(user);
  }

  Future<void> upsertUsers(List<UserModel> users) async {
    _users.clear();
    _users.addAll(users);
  }

  Future<List<UserModel>> getAllUsers() async => List.of(_users);

  Future<List<UserModel>> getActiveUsers() async =>
      _users.where((u) => u.status).toList();

  Future<UserModel?> getUserByEmail(String email) async =>
      _users.where((u) => u.email == email).firstOrNull;

  Future<List<UserModel>> searchUsersByName(String query) async {
    final q = query.toLowerCase();
    return _users
        .where(
          (u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .take(50)
        .toList();
  }

  Future<List<UserModel>> getUsersPaginated(int page, int pageSize) async {
    final offset = (page - 1) * pageSize;
    return _users.skip(offset).take(pageSize).toList();
  }

  Future<int> getUsersCount() async => _users.length;

  Future<List<String>> getActiveFcmTokens() async => _users
      .where((u) => u.status && u.fcmToken.isNotEmpty)
      .map((u) => u.fcmToken)
      .toList();

  Future<String?> getUserFcmToken(String userId) async =>
      _users.where((u) => u.id == userId).firstOrNull?.fcmToken;

  Future<void> clearDatabase() async => _users.clear();

  Future<void> close() async {}
}
