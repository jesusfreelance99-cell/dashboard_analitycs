class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String fcmToken;
  final bool status;
  final String role;
  final String plan;
  final String createdAt;
  final String syncedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.fcmToken,
    required this.status,
    required this.role,
    required this.plan,
    required this.createdAt,
    required this.syncedAt,
  });

  factory UserModel.fromFirestore(String docId, Map<String, dynamic> data) {
    final userInfo = data['user_info'] ?? {};
    return UserModel(
      id: docId,
      fullName: userInfo['full_name'] ?? '',
      email: userInfo['email'] ?? '',
      fcmToken: userInfo['fcm_token'] ?? '',
      status: userInfo['status'] ?? false,
      role: userInfo['role'] ?? 'customer',
      plan: userInfo['plan'] ?? '',
      createdAt: userInfo['created_at'] ?? '',
      syncedAt: DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'fcm_token': fcmToken,
      'status': status ? 1 : 0,
      'role': role,
      'plan': plan,
      'created_at': createdAt,
      'synced_at': syncedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      fcmToken: map['fcm_token'] ?? '',
      status: (map['status'] ?? 0) == 1,
      role: map['role'] ?? 'customer',
      plan: map['plan'] ?? '',
      createdAt: map['created_at'] ?? '',
      syncedAt: map['synced_at'] ?? '',
    );
  }

  @override
  String toString() => 'UserModel(id: $id, fullName: $fullName, email: $email)';
}

class UserCounts {
  final int total;
  final int pro;
  final int free;
  final int active;
  final int newToday;

  const UserCounts({
    required this.total,
    required this.pro,
    required this.free,
    required this.active,
    required this.newToday,
  });

  static const empty = UserCounts(
    total: 0,
    pro: 0,
    free: 0,
    active: 0,
    newToday: 0,
  );

  factory UserCounts.fromUsers(List<UserModel> users) {
    final now = DateTime.now();
    final pro = users.where((u) => u.plan == 'pro').length;
    final newToday = users.where((u) {
      final d = DateTime.tryParse(u.createdAt);
      return d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).length;
    return UserCounts(
      total: users.length,
      active: users.where((u) => u.status).length,
      pro: pro,
      free: users.length - pro,
      newToday: newToday,
    );
  }

  int get _safeTotal => total > 0 ? total : 1;
  double get proProportion => (pro / _safeTotal).clamp(0.0, 1.0);
  String get proPercent => '${(pro / _safeTotal * 100).toStringAsFixed(1)}%';
  String get freePercent => '${(free / _safeTotal * 100).toStringAsFixed(1)}%';
  String get activePercent => '${(active / _safeTotal * 100).toStringAsFixed(1)}%';
}
