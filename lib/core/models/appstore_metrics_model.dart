class AppStoreMetrics {
  final double rating;
  final int totalReviews;
  final int downloadsLastMonth;
  final int redownloads;
  final String periodLabel;
  final int? impressions;
  final double? conversion;
  final String status; // 'partial' | 'complete'

  const AppStoreMetrics({
    required this.rating,
    required this.totalReviews,
    required this.downloadsLastMonth,
    required this.redownloads,
    required this.periodLabel,
    this.impressions,
    this.conversion,
    this.status = 'partial',
  });

  factory AppStoreMetrics.fromMap(Map<String, dynamic> m) {
    return AppStoreMetrics(
      rating: (m['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (m['total_reviews'] as num?)?.toInt() ?? 0,
      downloadsLastMonth: (m['downloads_last_month'] as num?)?.toInt() ?? 0,
      redownloads: (m['redownloads'] as num?)?.toInt() ?? 0,
      periodLabel: m['downloads_period_label'] as String? ?? '',
      impressions: (m['impressions'] as num?)?.toInt(),
      conversion: (m['conversion'] as num?)?.toDouble(),
      status: m['status'] as String? ?? 'partial',
    );
  }

  String get ratingStr => rating > 0 ? rating.toStringAsFixed(1) : '—';
  String get downloadsStr => downloadsLastMonth > 0 ? _fmt(downloadsLastMonth) : '—';
  String get redownloadsStr => redownloads > 0 ? _fmt(redownloads) : '—';
  String get impressionsStr => (impressions != null && impressions! > 0) ? _fmt(impressions!) : '—';
  String get conversionStr => (conversion != null && conversion! > 0) ? '${conversion!.toStringAsFixed(1)}%' : '—';

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
