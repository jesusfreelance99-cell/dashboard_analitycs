import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';

class RevenueCatMetrics {
  const RevenueCatMetrics({
    required this.currency,
    required this.status,
    required this.source,
    required this.updatedAtLabel,
    required this.overview,
    required this.ranges,
  });

  final String currency;
  final String status;
  final String source;
  final String updatedAtLabel;
  final RevenueCatOverviewMetrics overview;
  final Map<DateRange, RevenueCatRangeMetrics> ranges;

  factory RevenueCatMetrics.fromMap(Map<String, dynamic> map) {
    final rangeMap = (map['ranges'] as Map<String, dynamic>? ?? const {});

    return RevenueCatMetrics(
      currency: map['currency'] as String? ?? 'USD',
      status: map['status'] as String? ?? 'idle',
      source: map['source'] as String? ?? 'RevenueCat',
      updatedAtLabel: map['updated_at_label'] as String? ?? '',
      overview: RevenueCatOverviewMetrics.fromMap(
        map['overview'] as Map<String, dynamic>? ?? const {},
      ),
      ranges: {
        DateRange.d7: RevenueCatRangeMetrics.fromMap(
          rangeMap['d7'] as Map<String, dynamic>? ?? const {},
        ),
        DateRange.d30: RevenueCatRangeMetrics.fromMap(
          rangeMap['d30'] as Map<String, dynamic>? ?? const {},
        ),
        DateRange.d90: RevenueCatRangeMetrics.fromMap(
          rangeMap['d90'] as Map<String, dynamic>? ?? const {},
        ),
        DateRange.all: RevenueCatRangeMetrics.fromMap(
          rangeMap['all'] as Map<String, dynamic>? ?? const {},
        ),
      },
    );
  }

  RevenueCatRangeMetrics range(DateRange dateRange) {
    return ranges[dateRange] ?? const RevenueCatRangeMetrics();
  }
}

class RevenueCatOverviewMetrics {
  const RevenueCatOverviewMetrics({
    this.mrr = 0,
    this.computedMrr = 0,
    this.activeTrials = 0,
    this.activeSubscriptions = 0,
    this.monthlySubscriptions = 0,
    this.annualSubscriptions = 0,
    this.revenue28d = 0,
    this.newCustomers28d = 0,
    this.activeCustomers28d = 0,
    this.subRetentionP1 = 0,
    this.subRetentionP3 = 0,
    this.subRetentionP6 = 0,
    this.cancelledSubscriptions = 0,
    this.churnRateFirestore = 0,
    this.annualTrialSubscriptions = 0,
    this.annualCancelledSubscriptions = 0,
    this.monthlyCancelledSubscriptions = 0,
  });

  final double mrr;
  final double computedMrr;
  final int activeTrials;
  final int activeSubscriptions;
  final int monthlySubscriptions;
  final int annualSubscriptions;
  final double revenue28d;
  final int newCustomers28d;
  final int activeCustomers28d;
  final double subRetentionP1;
  final double subRetentionP3;
  final double subRetentionP6;
  final int cancelledSubscriptions;
  final double churnRateFirestore;
  final int annualTrialSubscriptions;
  final int annualCancelledSubscriptions;
  final int monthlyCancelledSubscriptions;

  factory RevenueCatOverviewMetrics.fromMap(Map<String, dynamic> map) {
    return RevenueCatOverviewMetrics(
      mrr: (map['mrr'] as num?)?.toDouble() ?? 0,
      computedMrr: (map['computed_mrr'] as num?)?.toDouble() ?? 0,
      activeTrials: (map['active_trials'] as num?)?.toInt() ?? 0,
      activeSubscriptions: (map['active_subscriptions'] as num?)?.toInt() ?? 0,
      monthlySubscriptions: (map['monthly_subscriptions'] as num?)?.toInt() ?? 0,
      annualSubscriptions: (map['annual_subscriptions'] as num?)?.toInt() ?? 0,
      revenue28d: (map['revenue_28d'] as num?)?.toDouble() ?? 0,
      newCustomers28d: (map['new_customers_28d'] as num?)?.toInt() ?? 0,
      activeCustomers28d: (map['active_customers_28d'] as num?)?.toInt() ?? 0,
      subRetentionP1: (map['sub_retention_p1'] as num?)?.toDouble() ?? 0,
      subRetentionP3: (map['sub_retention_p3'] as num?)?.toDouble() ?? 0,
      subRetentionP6: (map['sub_retention_p6'] as num?)?.toDouble() ?? 0,
      cancelledSubscriptions: (map['cancelled_subscriptions'] as num?)?.toInt() ?? 0,
      churnRateFirestore: (map['churn_rate_firestore'] as num?)?.toDouble() ?? 0,
      annualTrialSubscriptions: (map['annual_trial_subscriptions'] as num?)?.toInt() ?? 0,
      annualCancelledSubscriptions: (map['annual_cancelled_subscriptions'] as num?)?.toInt() ?? 0,
      monthlyCancelledSubscriptions: (map['monthly_cancelled_subscriptions'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasMrrBreakdown => monthlySubscriptions > 0 || annualSubscriptions > 0;

  String subRetentionLabel(double rate) {
    if (rate <= 0) return '—';
    return '${(rate * 100).toStringAsFixed(1)}%';
  }

  String get subRetentionP1Label => subRetentionLabel(subRetentionP1);
  String get subRetentionP3Label => subRetentionLabel(subRetentionP3);
  String get subRetentionP6Label => subRetentionLabel(subRetentionP6);
  String get cancelledLabel => cancelledSubscriptions > 0 ? '$cancelledSubscriptions' : '0';
  String get churnRateLabel => churnRateFirestore > 0
      ? '${churnRateFirestore.toStringAsFixed(1)}%'
      : '0%';

  String get mrrLabel => RevenueCatRangeMetrics.formatCurrency(mrr);
  String get computedMrrLabel => RevenueCatRangeMetrics.formatCurrency(computedMrr);
  String get activeTrialsLabel =>
      RevenueCatRangeMetrics.formatInteger(activeTrials);
  String get activeSubscriptionsLabel =>
      RevenueCatRangeMetrics.formatInteger(activeSubscriptions);
  String get revenue28dLabel =>
      RevenueCatRangeMetrics.formatCurrency(revenue28d);
  String get newCustomers28dLabel =>
      RevenueCatRangeMetrics.formatInteger(newCustomers28d);
  String get activeCustomers28dLabel =>
      RevenueCatRangeMetrics.formatInteger(activeCustomers28d);
}

class RevenueCatDailyPoint {
  final String date;
  final double revenue;

  const RevenueCatDailyPoint({required this.date, required this.revenue});

  factory RevenueCatDailyPoint.fromMap(Map<String, dynamic> m) {
    return RevenueCatDailyPoint(
      date: m['date'] as String? ?? '',
      revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueCatRangeMetrics {
  const RevenueCatRangeMetrics({
    this.mrr = 0,
    this.revenue = 0,
    this.activeSubscriptions = 0,
    this.activeTrials = 0,
    this.churn = 0,
    this.cancelledSubscriptions = 0,
    this.newCustomers = 0,
    this.activeCustomers = 0,
    this.revenueBars = const [42, 68, 88, 124, 98],
    this.timeSeries = const [],
    this.periodLabel = '',
  });

  final double mrr;
  final double revenue;
  final int activeSubscriptions;
  final int activeTrials;
  final double churn;
  final int cancelledSubscriptions;
  final int newCustomers;
  final int activeCustomers;
  final List<double> revenueBars;
  final List<RevenueCatDailyPoint> timeSeries;
  final String periodLabel;

  factory RevenueCatRangeMetrics.fromMap(Map<String, dynamic> map) {
    final rawBars = (map['revenue_bars'] as List<dynamic>? ?? const [])
        .map((item) => (item as num?)?.toDouble() ?? 0)
        .toList();

    final rawSeries = map['revenue_time_series'] as List<dynamic>? ?? const [];

    return RevenueCatRangeMetrics(
      mrr: (map['mrr'] as num?)?.toDouble() ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0,
      activeSubscriptions: (map['active_subscriptions'] as num?)?.toInt() ?? 0,
      activeTrials: (map['active_trials'] as num?)?.toInt() ?? 0,
      churn: (map['churn'] as num?)?.toDouble() ?? 0,
      cancelledSubscriptions: (map['cancelled_subscriptions'] as num?)?.toInt() ?? 0,
      newCustomers: (map['new_customers'] as num?)?.toInt() ?? 0,
      activeCustomers: (map['active_customers'] as num?)?.toInt() ?? 0,
      revenueBars: rawBars.isEmpty ? const [42, 68, 88, 124, 98] : rawBars,
      timeSeries: rawSeries
          .whereType<Map<String, dynamic>>()
          .map(RevenueCatDailyPoint.fromMap)
          .toList(),
      periodLabel: map['period_label'] as String? ?? '',
    );
  }

  String get mrrLabel => formatCurrency(mrr);
  String get revenueLabel => formatCurrency(revenue);
  String get activeSubscriptionsLabel => formatInteger(activeSubscriptions);
  String get activeTrialsLabel => formatInteger(activeTrials);
  String get newCustomersLabel => formatInteger(newCustomers);
  String get activeCustomersLabel => formatInteger(activeCustomers);
  String get cancelledSubscriptionsLabel =>
      cancelledSubscriptions > 0 ? cancelledSubscriptions.toString() : '—';

  String get churnLabel {
    final percent = churn <= 1 ? churn * 100 : churn;
    if (percent <= 0) return '—';
    return '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%';
  }

  static String formatCurrency(double value) {
    if (value <= 0) return '—';
    final rounded = value >= 100
        ? value.round().toString()
        : value.toStringAsFixed(0);
    return '\$$rounded';
  }

  static String formatInteger(int value) {
    if (value <= 0) return '0';
    return value.toString();
  }
}
