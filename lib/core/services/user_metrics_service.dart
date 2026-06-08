import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';

class UserMetricsService {
  static final _local = LocalDbService();
  static final _db = FirebaseFirestore.instance;

  static Future<UserCounts>? _future;

  // Cached future — se comparte entre rebuilds; se invalida con refresh()
  static Future<UserCounts> get future => _future ??= _load();

  static void refresh() => _future = null;

  static Future<UserCounts> _load() async {
    final users = await _local.getAllUsers();
    if (users.isNotEmpty) return UserCounts.fromUsers(users);
    return _loadFromFirestore();
  }

  static Future<UserCounts> _loadFromFirestore() async {
    try {
      final results = await Future.wait([
        _db.collection('users').count().get(),
        _db
            .collection('users')
            .where('user_info.status', isEqualTo: true)
            .count()
            .get(),
        _db
            .collection('plan_user')
            .where('status', isEqualTo: 'active')
            .count()
            .get(),
      ]);

      final total = results[0].count ?? 0;
      final active = results[1].count ?? 0;
      final pro = results[2].count ?? 0;

      return UserCounts(
        total: total,
        active: active,
        pro: pro,
        free: total - pro,
        newToday: 0,
      );
    } catch (_) {
      return UserCounts.empty;
    }
  }
}
