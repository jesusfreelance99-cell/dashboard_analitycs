import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL AGGREGATE
// ─────────────────────────────────────────────────────────────────────────────

class UserDetail {
  final String id;
  final String fullName;
  final String email;
  final String plan;
  final bool status;
  final String country;
  final String city;
  final String createdAt;

  // device_info
  final String deviceBranch;
  final String deviceModel;
  final String deviceVersion;
  final String appVersion;
  final String language;

  // permissions
  final bool permCamera;
  final bool permLocation;
  final bool permNotifications;
  final bool permVoice;

  // user_info extras
  final String typeRegister;
  final String typeCurrency;
  final DateTime? updatedAt;

  // subcollections
  final UserPlanDetail? planUser;
  final List<PlatformSubscription> subscriptions;
  final List<BudgetEntry> budgets;
  final List<ExpenseEntry> recentExpenses;

  const UserDetail({
    required this.id,
    required this.fullName,
    required this.email,
    required this.plan,
    required this.status,
    required this.country,
    required this.city,
    required this.createdAt,
    this.deviceBranch = '',
    this.deviceModel = '',
    this.deviceVersion = '',
    this.appVersion = '',
    this.language = '',
    this.permCamera = false,
    this.permLocation = false,
    this.permNotifications = false,
    this.permVoice = false,
    this.typeRegister = '',
    this.typeCurrency = '',
    this.updatedAt,
    this.planUser,
    this.subscriptions = const [],
    this.budgets = const [],
    this.recentExpenses = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN
// ─────────────────────────────────────────────────────────────────────────────

class UserPlanDetail {
  final String planName;
  final String status;
  final String typePlan;
  final DateTime? startDate;
  final DateTime? endDate;
  final String subscriptionId;
  final DateTime? createdAt;

  const UserPlanDetail({
    required this.planName,
    required this.status,
    required this.typePlan,
    this.startDate,
    this.endDate,
    required this.subscriptionId,
    this.createdAt,
  });

  factory UserPlanDetail.fromMap(Map<String, dynamic> data) {
    return UserPlanDetail(
      planName: data['plan_name'] as String? ?? '',
      status: data['status'] as String? ?? '',
      typePlan: data['type_plan'] as String? ?? '',
      startDate: _parseDate(data['start_date']),
      endDate: _parseDate(data['end_date']),
      subscriptionId: data['suscription_id'] as String? ?? '',
      createdAt: _parseDate(data['created_at']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLATFORM SUBSCRIPTIONS
// ─────────────────────────────────────────────────────────────────────────────

class PlatformSubscription {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double price;
  final String typeCurrency;
  final String frequency;
  final String categorieName;
  final DateTime? nextPaymentDate;
  final bool status;

  const PlatformSubscription({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.price,
    required this.typeCurrency,
    required this.frequency,
    required this.categorieName,
    this.nextPaymentDate,
    required this.status,
  });

  factory PlatformSubscription.fromMap(String docId, Map<String, dynamic> data) {
    return PlatformSubscription(
      id: docId,
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      typeCurrency: data['type_currency'] as String? ?? '',
      frequency: data['frecuency'] as String? ?? '',
      categorieName: data['categorie_name'] as String? ?? '',
      nextPaymentDate: _parseDate(data['next_payment_date']),
      status: data['status'] == true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDGETS
// ─────────────────────────────────────────────────────────────────────────────

class BudgetEntry {
  final String id;
  final String nameCategory;
  final double valueBudget;
  final String colorHex;

  const BudgetEntry({
    required this.id,
    required this.nameCategory,
    required this.valueBudget,
    required this.colorHex,
  });

  factory BudgetEntry.fromMap(String docId, Map<String, dynamic> data) {
    return BudgetEntry(
      id: docId,
      nameCategory: data['name_category'] as String? ?? '',
      valueBudget: (data['value_budget'] as num?)?.toDouble() ?? 0,
      colorHex: data['color_budget'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPENSES / INCOME
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseEntry {
  final String id;
  final String description;
  final String categorieName;
  final String emoji;
  final double price;
  final String type;
  final String typeCurrency;
  final String source;
  final DateTime? dateExpenses;

  const ExpenseEntry({
    required this.id,
    required this.description,
    required this.categorieName,
    required this.emoji,
    required this.price,
    required this.type,
    required this.typeCurrency,
    required this.source,
    this.dateExpenses,
  });

  bool get isExpense => type == 'expense';

  factory ExpenseEntry.fromMap(String docId, Map<String, dynamic> data) {
    return ExpenseEntry(
      id: docId,
      description: data['description'] as String? ?? '',
      categorieName: data['categorie_name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      type: data['type'] as String? ?? 'expense',
      typeCurrency: data['type_currency'] as String? ?? '',
      source: data['source'] as String? ?? '',
      dateExpenses: _parseDate(data['date_expenses']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────────────────────────────────────────

DateTime? _parseDate(dynamic val) {
  if (val == null) return null;
  if (val is Timestamp) return val.toDate();
  if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
  return null;
}
