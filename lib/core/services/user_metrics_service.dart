import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';

class UserMetricsService {
  static final _local = LocalDbService();
  static final _db = FirebaseFirestore.instance;

  static Future<UserCounts>? _future;

  static Future<UserCounts> get future => _future ??= _load();

  static void refresh() => _future = null;

  static Future<UserCounts> _load() async {
    final users = await _local.getAllUsers();
    if (users.isNotEmpty) return UserCounts.fromUsers(users);
    return _loadFromFirestore();
  }

  static Future<int> _countQuery(Query query) async {
    try {
      return (await query.count().get()).count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<UserCounts> _loadFromFirestore() async {
    // Cada query es independiente — si una falla, las demás siguen
    final total = await _countQuery(_db.collection('users'));

    final active = await _countQuery(
      _db.collection('users').where('user_info.status', isEqualTo: true),
    );

    // plan_user es subcollección → collectionGroup para contar todos los activos
    // Fallback: contar directamente desde user_info.plan
    int pro = await _countQuery(
      _db.collectionGroup('plan_user').where('status', isEqualTo: 'active'),
    );
    if (pro == 0) {
      pro = await _countQuery(
        _db.collection('users').where('user_info.plan', isEqualTo: 'pro'),
      );
    }

    return UserCounts(
      total: total,
      active: active,
      pro: pro,
      free: total - pro,
      newToday: 0,
    );
  }
}
