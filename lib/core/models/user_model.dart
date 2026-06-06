class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String fcmToken;
  final bool status;
  final String role;
  final String createdAt;
  final String syncedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.fcmToken,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.syncedAt,
  });

  // Convertir desde JSON de Firestore
  factory UserModel.fromFirestore(String docId, Map<String, dynamic> data) {
    final userInfo = data['user_info'] ?? {};

    return UserModel(
      id: docId,
      fullName: userInfo['full_name'] ?? '',
      email: userInfo['email'] ?? '',
      fcmToken: userInfo['fcm_token'] ?? '',
      status: userInfo['status'] ?? false,
      role: userInfo['role'] ?? 'customer',
      createdAt: userInfo['created_at'] ?? '',
      syncedAt: DateTime.now().toIso8601String(),
    );
  }

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'fcm_token': fcmToken,
      'status': status ? 1 : 0,
      'role': role,
      'created_at': createdAt,
      'synced_at': syncedAt,
    };
  }

  // Convertir desde Map de SQLite
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      fcmToken: map['fcm_token'] ?? '',
      status: (map['status'] ?? 0) == 1,
      role: map['role'] ?? 'customer',
      createdAt: map['created_at'] ?? '',
      syncedAt: map['synced_at'] ?? '',
    );
  }

  @override
  String toString() => 'UserModel(id: $id, fullName: $fullName, email: $email)';
}
