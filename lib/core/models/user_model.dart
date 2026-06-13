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
  final String country;
  final String city;

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
    this.country = '',
    this.city = '',
  });

  factory UserModel.fromFirestore(String docId, Map<String, dynamic> data) {
    final userInfo = data['user_info'];
    final ui =
        userInfo is Map ? userInfo as Map<String, dynamic> : <String, dynamic>{};
    final address = data['address'];
    final addr =
        address is Map ? address as Map<String, dynamic> : <String, dynamic>{};
    final deviceInfo = data['device_info'];
    final di = deviceInfo is Map
        ? deviceInfo as Map<String, dynamic>
        : <String, dynamic>{};

    String country = (addr['country'] as String? ?? '').trim();

    if (country.isEmpty) {
      // Fallback 1: locale (ej. "es_CO" → "CO" → "Colombia")
      final locale = (di['language'] as String? ?? '').trim();
      if (locale.contains('_')) {
        final isoCode = locale.split('_').last.toUpperCase();
        country = _isoToCountry[isoCode] ?? '';
      }
    }

    if (country.isEmpty) {
      // Fallback 2: currency (ej. "COP" → "Colombia")
      final currency = (ui['type_currency'] as String? ?? '').toUpperCase();
      country = _currencyToCountry[currency] ?? '';
    }

    return UserModel(
      id: docId,
      fullName: ui['full_name'] as String? ?? '',
      email: ui['email'] as String? ?? '',
      fcmToken: ui['fcm_token'] as String? ?? '',
      status: ui['status'] == true,
      role: ui['role'] as String? ?? 'customer',
      plan: ui['plan'] as String? ?? '',
      createdAt: ui['created_at'] as String? ?? '',
      syncedAt: DateTime.now().toIso8601String(),
      country: country,
      city: addr['city'] as String? ?? '',
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
      'country': country,
      'city': city,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fcmToken: map['fcm_token'] as String? ?? '',
      status: (map['status'] ?? 0) == 1,
      role: map['role'] as String? ?? 'customer',
      plan: map['plan'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      syncedAt: map['synced_at'] as String? ?? '',
      country: map['country'] as String? ?? '',
      city: map['city'] as String? ?? '',
    );
  }

  // ISO code → country name
  static const Map<String, String> _isoToCountry = {
    'CO': 'Colombia',   'MX': 'México',         'US': 'Estados Unidos',
    'ES': 'España',     'AR': 'Argentina',       'VE': 'Venezuela',
    'PE': 'Perú',       'CL': 'Chile',           'EC': 'Ecuador',
    'BR': 'Brasil',     'PA': 'Panamá',          'GT': 'Guatemala',
    'CR': 'Costa Rica', 'DO': 'Rep. Dominicana', 'BO': 'Bolivia',
    'HN': 'Honduras',   'NI': 'Nicaragua',       'SV': 'El Salvador',
    'PY': 'Paraguay',   'UY': 'Uruguay',         'CU': 'Cuba',
    'PR': 'Puerto Rico','CA': 'Canadá',          'PT': 'Portugal',
    'FR': 'Francia',    'DE': 'Alemania',        'GB': 'Reino Unido',
    'IT': 'Italia',     'IE': 'Irlanda',         'NL': 'Holanda',
    'BE': 'Bélgica',    'CH': 'Suiza',           'SE': 'Suecia',
    'NO': 'Noruega',    'AU': 'Australia',       'JP': 'Japón',
    'CN': 'China',      'KR': 'Corea del Sur',   'IN': 'India',
  };

  // Currency code → country name (solo monedas no ambiguas)
  static const Map<String, String> _currencyToCountry = {
    'COP': 'Colombia',          'MXN': 'México',
    'ARS': 'Argentina',         'PEN': 'Perú',
    'CLP': 'Chile',             'BRL': 'Brasil',
    'CRC': 'Costa Rica',        'GTQ': 'Guatemala',
    'HNL': 'Honduras',          'NIO': 'Nicaragua',
    'DOP': 'Rep. Dominicana',   'BOB': 'Bolivia',
    'PYG': 'Paraguay',          'UYU': 'Uruguay',
    'VES': 'Venezuela',         'CUP': 'Cuba',
    'CAD': 'Canadá',            'GBP': 'Reino Unido',
    'AUD': 'Australia',         'JPY': 'Japón',
    'KRW': 'Corea del Sur',     'CNY': 'China',
    'SEK': 'Suecia',            'NOK': 'Noruega',
    'CHF': 'Suiza',             'INR': 'India',
    // USD y EUR son ambiguos — no se usan como fallback
  };

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
