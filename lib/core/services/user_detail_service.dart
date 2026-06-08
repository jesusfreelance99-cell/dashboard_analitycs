import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/models/user_detail_model.dart';
import 'package:dashboard_analitycs/core/models/user_model.dart';

class UserDetailService {
  static final _db = FirebaseFirestore.instance;

  static Future<UserDetail> fetch(UserModel user) async {
    final uid = user.id;

    // Fire all requests concurrently
    final mainFuture = _db.collection('users').doc(uid).get();
    final planFuture = _db
        .collection('users')
        .doc(uid)
        .collection('plan_user')
        .limit(1)
        .get();
    final subsFuture = _db
        .collection('users')
        .doc(uid)
        .collection('my_platforms_suscriptions')
        .get();
    final budgetsFuture = _db
        .collection('users')
        .doc(uid)
        .collection('my_budgets')
        .get();
    final expFuture = _db
        .collection('users')
        .doc(uid)
        .collection('expenses_or_income')
        .orderBy('created_at', descending: true)
        .limit(15)
        .get();

    // Await all — individual failures are caught below
    final mainDoc = await mainFuture;
    final data = mainDoc.data() ?? {};

    // device_info
    final di = _asMap(data['device_info']);
    // permissions
    final pm = _asMap(data['permissions']);
    // user_info
    final ui = _asMap(data['user_info']);
    // address
    final addr = _asMap(data['address']);

    // plan_user
    UserPlanDetail? plan;
    try {
      final planSnap = await planFuture;
      if (planSnap.docs.isNotEmpty) {
        plan = UserPlanDetail.fromMap(planSnap.docs.first.data());
      }
    } catch (_) {}

    // subscriptions
    List<PlatformSubscription> subs = [];
    try {
      final subsSnap = await subsFuture;
      subs = subsSnap.docs
          .map((d) => PlatformSubscription.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {}

    // budgets
    List<BudgetEntry> budgets = [];
    try {
      final budgetsSnap = await budgetsFuture;
      budgets = budgetsSnap.docs
          .map((d) => BudgetEntry.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {}

    // expenses
    List<ExpenseEntry> expenses = [];
    try {
      final expSnap = await expFuture;
      expenses = expSnap.docs
          .map((d) => ExpenseEntry.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {}

    return UserDetail(
      id: uid,
      fullName: ui['full_name'] as String? ?? user.fullName,
      email: ui['email'] as String? ?? user.email,
      plan: ui['plan'] as String? ?? user.plan,
      status: ui['status'] == true,
      country: addr['country'] as String? ?? user.country,
      city: addr['city'] as String? ?? user.city,
      createdAt: ui['created_at'] as String? ?? user.createdAt,
      deviceBranch: di['branch'] as String? ?? '',
      deviceModel: di['model'] as String? ?? '',
      deviceVersion: di['version'] as String? ?? '',
      appVersion: di['version_app'] as String? ?? '',
      language: di['language'] as String? ?? '',
      permCamera: pm['camera'] == true,
      permLocation: pm['location'] == true,
      permNotifications: pm['notifications'] == true,
      permVoice: pm['voice'] == true,
      typeRegister: ui['type_register'] as String? ?? '',
      typeCurrency: ui['type_currency'] as String? ?? '',
      updatedAt: _parseTs(ui['updated_at']),
      planUser: plan,
      subscriptions: subs,
      budgets: budgets,
      recentExpenses: expenses,
    );
  }

  static Map<String, dynamic> _asMap(dynamic val) =>
      val is Map ? val as Map<String, dynamic> : <String, dynamic>{};

  static DateTime? _parseTs(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
    return null;
  }
}
