import 'dart:math' as math;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:dashboard_analitycs/core/models/features_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/revenuecat_metrics_model.dart';
import 'package:dashboard_analitycs/core/services/features_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/revenuecat_metrics_service.dart';
import 'package:dashboard_analitycs/core/widgets/app_shimmer.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/empty_tables_component.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/shared_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key, required this.range});
  final DateRange range;

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _autoRefreshIfStale();
  }

  Future<void> _autoRefreshIfStale() async {
    try {
      if (await FeaturesMetricsService.needsRefresh()) {
        await FeaturesMetricsService.requestRefresh(source: 'auto');
      }
    } catch (_) {}
  }

  Future<void> _manualRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await FeaturesMetricsService.requestRefresh(source: 'manual');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeaturesMetrics?>(
      stream: FeaturesMetricsService.stream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _FeaturesShimmer();
        }
        final metrics = snap.data;

        if (metrics == null || metrics.status == 'idle') {
          return Column(
            children: [
              _buildHeader(context, null),
              const SizedBox(height: 60),
              const EmptyTablesComponent(
                title: 'Sin datos de features',
                description: 'Presiona ⟳ para sincronizar.',
              ),
            ],
          );
        }

        if (metrics.status == 'loading') {
          return const _FeaturesShimmer();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, metrics),
            const SizedBox(height: 24),
            // 1 — Métricas principales con sparklines
            _StatsGrid(metrics: metrics),
            // 2 — Trend + comparativa semanal
            if (metrics.timeSeries.hasData) ...[
              const SizedBox(height: 20),
              _TrendSection(timeSeries: metrics.timeSeries),
              const SizedBox(height: 20),
              StreamBuilder<RevenueCatMetrics?>(
                stream: RevenueCatMetricsService.stream(),
                builder: (context, rcSnap) {
                  final rcSeries =
                      rcSnap.data?.range(DateRange.d30).timeSeries ??
                      const <RevenueCatDailyPoint>[];
                  return _WeeklyComparisonSection(
                    timeSeries: metrics.timeSeries,
                    rcRevenueSeries: rcSeries,
                  );
                },
              ),
            ],
            // 3 — Comportamiento
            const SizedBox(height: 20),
            Panel(child: _BehaviorSection(metrics: metrics)),
            // 4 — Adopción: donut + lista
            const SizedBox(height: 20),
            _AdoptionRow(metrics: metrics),
            // 5 — Curva de retención global
            if (metrics.retentionCurve.isNotEmpty) ...[
              const SizedBox(height: 20),
              Panel(
                child: _RetentionCurveSection(curve: metrics.retentionCurve),
              ),
            ],
            // 6 — Retención por feature
            if (metrics.retention.isNotEmpty) ...[
              const SizedBox(height: 20),
              Panel(child: _RetentionSection(retention: metrics.retention)),
            ],
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, FeaturesMetrics? metrics) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uso de features',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: context.dc.ink,
                ),
              ),
              if (metrics?.updatedAtLabel.isNotEmpty == true)
                Text(
                  'Actualizado ${metrics!.updatedAtLabel}',
                  style: TextStyle(fontSize: 14, color: context.dc.ink3),
                ),
            ],
          ),
        ),
        _RefreshBtn(refreshing: _refreshing, onTap: _manualRefresh),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS GRID — 4 cards simétricas con sparklines
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatefulWidget {
  const _StatsGrid({required this.metrics});
  final FeaturesMetrics metrics;

  @override
  State<_StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<_StatsGrid> {
  DateRange _range = DateRange.d7;

  String _label(DateRange r) => switch (r) {
    DateRange.all => 'Hoy',
    DateRange.d7 => '7 días',
    DateRange.d30 => '30 días',
    DateRange.d90 => '90 días',
  };

  double? _delta(int current, int base, int days, int baseDays) {
    if (base <= 0) return null;
    final bl = base * days / baseDays;
    if (bl <= 0) return null;
    return (current - bl) / bl;
  }

  @override
  Widget build(BuildContext context) {
    final sm = widget.metrics.session(_range) ?? const SessionMetrics();
    final sm30 =
        widget.metrics.session(DateRange.d30) ?? const SessionMetrics();
    final sm90 =
        widget.metrics.session(DateRange.d90) ?? const SessionMetrics();
    final ts = widget.metrics.timeSeries;

    final days = switch (_range) {
      DateRange.all => 1,
      DateRange.d7 => 7,
      DateRange.d30 => 30,
      DateRange.d90 => 90,
    };
    final baseM = (_range == DateRange.d30 || _range == DateRange.d90)
        ? sm90
        : sm30;
    final baseD = (_range == DateRange.d30 || _range == DateRange.d90)
        ? 90
        : 30;
    final usersDlt = _delta(sm.activeUsers, baseM.activeUsers, days, baseD);
    final sessDlt = _delta(sm.sessions, baseM.sessions, days, baseD);

    final sparkDays = ts.activeUsers.isEmpty
        ? 0
        : days.clamp(1, ts.activeUsers.length);
    final usersSpark = ts.activeUsers.isNotEmpty && sparkDays > 0
        ? ts.activeUsers.sublist(math.max(0, ts.activeUsers.length - sparkDays))
        : <int>[];
    final sessSpark = ts.sessions.isNotEmpty && sparkDays > 0
        ? ts.sessions.sublist(math.max(0, ts.sessions.length - sparkDays))
        : <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period selector
        Row(
          children: [
            for (final r in DateRange.values) ...[
              _PeriodChip(
                label: _label(r),
                selected: _range == r,
                onTap: () => setState(() => _range = r),
              ),
              if (r != DateRange.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final cols = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
            final cards = [
              _StatCard(
                label: 'Usuarios activos',
                value: _fmtNum(sm.activeUsers),
                icon: Icons.people_outline_rounded,
                color: AppColors.chartBlue,
                delta: usersDlt,
                sparkline: usersSpark,
              ),
              _StatCard(
                label: 'Sesiones totales',
                value: _fmtNum(sm.sessions),
                icon: Icons.bar_chart_rounded,
                color: AppColors.chartPurple,
                delta: sessDlt,
                sparkline: sessSpark,
              ),
              _StatCard(
                label: 'Sesiones por usuario',
                value: sm.sessions > 0
                    ? sm.sessionsPerUser.toStringAsFixed(1)
                    : '—',
                icon: Icons.repeat_rounded,
                color: AppColors.chartAmber,
              ),
              _StatCard(
                label: 'Duración media sesión',
                value: sm.avgDurationFormatted,
                icon: Icons.timer_outlined,
                color: AppColors.chartGreen,
              ),
            ];
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final c in cards) SizedBox(width: w, child: c)],
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delta,
    this.sparkline = const [],
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? delta;
  final List<int> sparkline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: context.dc.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.dc.ink2,
                  ),
                ),
              ),
              if (delta != null && delta!.abs() >= 0.01)
                _DeltaBadge(delta: delta!),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
                height: 0.95,
                color: context.dc.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: sparkline.length > 2
                ? _MiniSparkline(data: sparkline, color: color)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({required this.data, required this.color});
  final List<int> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = data.reduce(math.max);
    if (maxVal <= 0) return const SizedBox.shrink();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxVal * 1.4,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withAlpha(40), color.withAlpha(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final isUp = delta > 0;
    final color = isUp ? AppColors.chartGreen : AppColors.chartRed;
    final icon = isUp
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final pct = '${isUp ? '+' : ''}${(delta * 100).toStringAsFixed(0)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            pct,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TREND CHART — 30 días con dos líneas
// ─────────────────────────────────────────────────────────────────────────────

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.timeSeries});
  final FeaturesTimeSeries timeSeries;

  @override
  Widget build(BuildContext context) {
    final maxVal = timeSeries.maxValue;
    final maxY = (maxVal * 1.3).ceilToDouble().clamp(4.0, double.infinity);
    final interval = (maxY / 4).ceilToDouble();
    final n = timeSeries.dates.length;
    final labelInt = n <= 10 ? 1.0 : (n / 5).floor().toDouble();

    final usersSpots = timeSeries.activeUsers
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
    final sessionSpots = timeSeries.sessions
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividad',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.dc.ink,
                      ),
                    ),
                    Text(
                      'Últimos 30 días',
                      style: TextStyle(fontSize: 13, color: context.dc.ink3),
                    ),
                  ],
                ),
              ),
              _LegendDot(color: AppColors.pink, label: 'Usuarios'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.chartBlue, label: 'Sesiones'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: context.dc.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: interval,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          _fmtNum(v.toInt()),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.dc.ink3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: labelInt,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= timeSeries.dates.length) {
                          return const SizedBox.shrink();
                        }
                        final d = timeSeries.dates[idx];
                        if (d.length < 8) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${d.substring(6)}/${d.substring(4, 6)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.dc.ink3,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: usersSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.pink,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.pink.withAlpha(45),
                          AppColors.pink.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: sessionSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.chartBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 3],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => context.dc.elevated,
                    getTooltipItems: (spots) => spots.map((s) {
                      final isUsers = s.barIndex == 0;
                      final color = isUsers
                          ? AppColors.pink
                          : AppColors.chartBlue;
                      return LineTooltipItem(
                        '${isUsers ? 'Usuarios' : 'Sesiones'}: ${s.y.toInt()}',
                        TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: context.dc.ink3)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY COMPARISON — Esta semana vs La semana pasada
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyComparisonSection extends StatelessWidget {
  const _WeeklyComparisonSection({
    required this.timeSeries,
    this.rcRevenueSeries = const [],
  });
  final FeaturesTimeSeries timeSeries;
  final List<RevenueCatDailyPoint> rcRevenueSeries;

  List<double> _thisWeek(List<num> data) => data.length >= 7
      ? data.sublist(data.length - 7).map((e) => e.toDouble()).toList()
      : data.map((e) => e.toDouble()).toList();

  List<double> _lastWeek(List<num> data) => data.length >= 14
      ? data
            .sublist(data.length - 14, data.length - 7)
            .map((e) => e.toDouble())
            .toList()
      : <double>[];

  double? _delta(num current, num prev) {
    if (prev <= 0) return null;
    return (current - prev) / prev;
  }

  @override
  Widget build(BuildContext context) {
    if (timeSeries.dates.length < 2) return const SizedBox.shrink();

    final usersThis = _thisWeek(timeSeries.activeUsers);
    final usersLast = _lastWeek(timeSeries.activeUsers);
    final sessThis = _thisWeek(timeSeries.sessions);
    final sessLast = _lastWeek(timeSeries.sessions);

    final rcRevs = rcRevenueSeries.map((p) => p.revenue).toList();
    final revThis = rcRevs.isNotEmpty ? _thisWeek(rcRevs) : <double>[];
    final revLast = rcRevs.isNotEmpty ? _lastWeek(rcRevs) : <double>[];

    final currentUsers = timeSeries.activeUsers.isNotEmpty
        ? timeSeries.activeUsers.last
        : 0;
    final prevUsers = timeSeries.activeUsers.length >= 8
        ? timeSeries.activeUsers[timeSeries.activeUsers.length - 8]
        : 0;
    final currentSess = timeSeries.sessions.isNotEmpty
        ? timeSeries.sessions.last
        : 0;
    final prevSess = timeSeries.sessions.length >= 8
        ? timeSeries.sessions[timeSeries.sessions.length - 8]
        : 0;
    final currentRev = rcRevs.isNotEmpty ? rcRevs.last : 0.0;
    final prevRev = rcRevs.length >= 8 ? rcRevs[rcRevs.length - 8] : 0.0;
    final hasRevenue = rcRevs.any((r) => r > 0);

    final panels = [
      _CompPanel(
        title: 'Usuarios activos',
        subtitle: 'por día',
        valueStr: _fmtNum(currentUsers),
        delta: _delta(currentUsers, prevUsers),
        thisWeek: usersThis,
        lastWeek: usersLast,
        color: AppColors.chartBlue,
      ),
      _CompPanel(
        title: 'Sesiones',
        subtitle: 'por día',
        valueStr: _fmtNum(currentSess),
        delta: _delta(currentSess, prevSess),
        thisWeek: sessThis,
        lastWeek: sessLast,
        color: AppColors.chartPurple,
      ),
      if (hasRevenue)
        _CompPanel(
          title: 'Ingresos',
          subtitle: 'del día',
          valueStr: '\$${currentRev.toStringAsFixed(2)}',
          delta: _delta(currentRev, prevRev),
          thisWeek: revThis,
          lastWeek: revLast,
          color: AppColors.chartGreen,
        ),
    ];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estadísticas semanales',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.dc.ink,
                      ),
                    ),
                    Text(
                      'Esta semana vs la semana pasada',
                      style: TextStyle(fontSize: 13, color: context.dc.ink3),
                    ),
                  ],
                ),
              ),
              // Leyenda
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 18, height: 2, color: AppColors.pink),
                  const SizedBox(width: 5),
                  Text(
                    'Esta semana',
                    style: TextStyle(fontSize: 11, color: context.dc.ink3),
                  ),
                  const SizedBox(width: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 3; i++) ...[
                        Container(width: 4, height: 2, color: context.dc.ink3),
                        if (i < 2) const SizedBox(width: 2),
                      ],
                    ],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Semana pasada',
                    style: TextStyle(fontSize: 11, color: context.dc.ink3),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= (hasRevenue ? 700 : 500);
              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < panels.length; i++) ...[
                        Expanded(child: panels[i]),
                        if (i < panels.length - 1)
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            color: context.dc.divider,
                          ),
                      ],
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < panels.length; i++) ...[
                    panels[i],
                    if (i < panels.length - 1) ...[
                      const SizedBox(height: 20),
                      Container(height: 1, color: context.dc.divider),
                      const SizedBox(height: 20),
                    ],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompPanel extends StatelessWidget {
  const _CompPanel({
    required this.title,
    required this.subtitle,
    required this.valueStr,
    required this.delta,
    required this.thisWeek,
    required this.lastWeek,
    required this.color,
  });
  final String title;
  final String subtitle;
  final String valueStr;
  final double? delta;
  final List<double> thisWeek;
  final List<double> lastWeek;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (thisWeek.isEmpty) return const SizedBox.shrink();

    final thisSpots = thisWeek
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final lastSpots = lastWeek
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final allVals = [...thisWeek, ...lastWeek];
    final maxAll = allVals.fold(0.0, (m, v) => math.max(m, v));
    final maxY = (maxAll * 1.35).clamp(2.0, double.infinity);
    final interval = (maxY / 3).ceilToDouble().clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: context.dc.ink3),
            children: [
              TextSpan(
                text: title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.dc.ink2,
                ),
              ),
              TextSpan(text: ' $subtitle'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              valueStr,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
                height: 1,
                color: context.dc.ink,
              ),
            ),
            const SizedBox(width: 8),
            if (delta != null && delta!.abs() >= 0.001)
              _DeltaBadge(delta: delta!),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.dc.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: interval,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        _fmtNum(v.toInt()),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 10, color: context.dc.ink3),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                      final idx = v.toInt();
                      if (idx < 0 || idx >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          days[idx],
                          style: TextStyle(
                            fontSize: 11,
                            color: context.dc.ink3,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: thisSpots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: color,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, _) => spot.x == thisSpots.last.x,
                    getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: context.dc.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [color.withAlpha(28), color.withAlpha(0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                if (lastSpots.isNotEmpty)
                  LineChartBarData(
                    spots: lastSpots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: context.dc.ink3,
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.x == lastSpots.last.x,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: context.dc.ink3,
                            strokeWidth: 1.5,
                            strokeColor: context.dc.surface,
                          ),
                    ),
                    dashArray: [5, 3],
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
              lineTouchData: const LineTouchData(enabled: false),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BEHAVIOR — bloques de comportamiento
// ─────────────────────────────────────────────────────────────────────────────

class _BehaviorSection extends StatelessWidget {
  const _BehaviorSection({required this.metrics});
  final FeaturesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final sm7 = metrics.session(DateRange.d7) ?? const SessionMetrics();
    final feat7 = metrics.featureList(DateRange.d7);
    final feat1 = metrics.featureList(DateRange.all);

    final totalEvents = feat7.fold(0, (acc, e) => acc + e.count);
    final featPerSession = sm7.sessions > 0
        ? (totalEvents / sm7.sessions).toStringAsFixed(1)
        : '—';
    final topD1 = feat1.isNotEmpty ? feat1.first.displayName : '—';
    final topD7 = feat7.isNotEmpty ? feat7.first.displayName : '—';
    final topRetention = metrics.retention.isNotEmpty
        ? metrics.retention.reduce(
            (a, b) => a.retentionScore > b.retentionScore ? a : b,
          )
        : null;
    final topRetainName = topRetention != null
        ? FeatureEventRow(
            name: topRetention.name,
            count: 0,
            uniqueUsers: 0,
            perSession: 0,
          ).displayName
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comportamiento',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.dc.ink,
          ),
        ),
        Text(
          'GA4 · últimos 7 días',
          style: TextStyle(fontSize: 13, color: context.dc.ink3),
        ),
        const SizedBox(height: 20),
        // ── 3 stat cards ────────────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final cols = constraints.maxWidth >= 600 ? 3 : 1;
            final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
            final cards = [
              _BehaviorCard(
                icon: Icons.touch_app_outlined,
                color: AppColors.chartPurple,
                value: featPerSession,
                label: 'Features por sesión',
                insight: topD7,
                insightLabel: 'feature líder',
              ),
              _BehaviorCard(
                icon: Icons.hourglass_bottom_rounded,
                color: AppColors.chartAmber,
                value: sm7.avgDurationFormatted,
                label: 'Duración media',
                insight: sm7.engagementRatePct,
                insightLabel: 'engagement rate',
              ),
              _BehaviorCard(
                icon: Icons.bolt_rounded,
                color: AppColors.chartGreen,
                value: sm7.engagementRatePct,
                label: 'Tasa engagement',
                insight: topD1,
                insightLabel: 'más usada hoy',
              ),
            ];
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final c in cards) SizedBox(width: w, child: c)],
            );
          },
        ),
        const SizedBox(height: 14),
        // ── Insight strip ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: context.dc.elevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;
              final items = [
                _InsightChip(
                  icon: Icons.star_rounded,
                  color: AppColors.chartAmber,
                  label: 'Hoy',
                  value: topD1,
                ),
                _InsightChip(
                  icon: Icons.trending_up_rounded,
                  color: AppColors.chartBlue,
                  label: '7 días',
                  value: topD7,
                ),
                _InsightChip(
                  icon: Icons.loop_rounded,
                  color: AppColors.chartGreen,
                  label: 'Retención',
                  value: topRetainName,
                ),
              ];
              if (isWide) {
                return Row(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      Expanded(child: items[i]),
                      if (i < items.length - 1)
                        Container(
                          width: 1,
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: context.dc.divider,
                        ),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i < items.length - 1) ...[
                      const SizedBox(height: 10),
                      Container(height: 1, color: context.dc.divider),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BehaviorCard extends StatelessWidget {
  const _BehaviorCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.insight,
    required this.insightLabel,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String insight;
  final String insightLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                height: 1,
                color: context.dc.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: color.withAlpha(30)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.dc.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                insightLabel,
                style: TextStyle(fontSize: 10, color: context.dc.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.dc.ink3,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.dc.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADOPTION ROW — Donut (izq) + Events list (der)
// ─────────────────────────────────────────────────────────────────────────────

class _AdoptionRow extends StatefulWidget {
  const _AdoptionRow({required this.metrics});
  final FeaturesMetrics metrics;

  @override
  State<_AdoptionRow> createState() => _AdoptionRowState();
}

class _AdoptionRowState extends State<_AdoptionRow> {
  DateRange _range = DateRange.d7;

  @override
  Widget build(BuildContext context) {
    final allEvents = widget.metrics.featureList(_range);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final donut = _CategoryDonutPanel(
          events: allEvents,
          range: _range,
          onRangeChanged: (r) => setState(() => _range = r),
        );
        final list = _TopEventsPanel(
          events: allEvents,
          range: _range,
          onRangeChanged: (r) => setState(() => _range = r),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: constraints.maxWidth * 0.42, child: donut),
              const SizedBox(width: 16),
              Expanded(child: list),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [donut, const SizedBox(height: 16), list],
        );
      },
    );
  }
}

// ─ Donut panel ─
class _CategoryDonutPanel extends StatelessWidget {
  const _CategoryDonutPanel({
    required this.events,
    required this.range,
    required this.onRangeChanged,
  });
  final List<FeatureEventRow> events;
  final DateRange range;
  final ValueChanged<DateRange> onRangeChanged;

  String _catName(FeatureCategory c) => switch (c) {
    FeatureCategory.financial => 'Finanzas',
    FeatureCategory.budget => 'Presupuesto',
    FeatureCategory.voice => 'Voz',
    FeatureCategory.widget => 'Widget',
    FeatureCategory.subscription => 'Suscripción',
    FeatureCategory.conversion => 'Conversión',
    FeatureCategory.auth => 'Auth',
    FeatureCategory.onboarding => 'Onboarding',
    FeatureCategory.notification => 'Notificaciones',
    FeatureCategory.other => 'Otros',
  };

  @override
  Widget build(BuildContext context) {
    final totals = <FeatureCategory, int>{};
    for (final e in events) {
      totals[e.category] = (totals[e.category] ?? 0) + e.count;
    }
    final total = totals.values.fold(0, (a, b) => a + b);
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Por categoría',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.dc.ink,
                      ),
                    ),
                  ],
                ),
              ),
              _RangeDropdown(value: range, onChanged: onRangeChanged),
            ],
          ),
          const SizedBox(height: 20),
          if (total == 0)
            const SizedBox(
              height: 160,
              child: EmptyTablesComponent(title: 'Sin datos', description: ''),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sections: sorted.map((entry) {
                        final pct = entry.value / total * 100;
                        final color = _colorForCat(entry.key);
                        return PieChartSectionData(
                          value: pct,
                          color: color,
                          title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
                          radius: 52,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: 38,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(enabled: false),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    children: sorted.take(7).map((entry) {
                      final pct = total > 0 ? entry.value / total * 100 : 0.0;
                      final color = _colorForCat(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _catName(entry.key),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: context.dc.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (total > 0)
            Text(
              '${_fmtNum(total)} eventos totales',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.dc.ink3,
              ),
            ),
        ],
      ),
    );
  }
}

// ─ Events list panel ─
class _TopEventsPanel extends StatefulWidget {
  const _TopEventsPanel({
    required this.events,
    required this.range,
    required this.onRangeChanged,
  });
  final List<FeatureEventRow> events;
  final DateRange range;
  final ValueChanged<DateRange> onRangeChanged;

  @override
  State<_TopEventsPanel> createState() => _TopEventsPanelState();
}

class _TopEventsPanelState extends State<_TopEventsPanel> {
  FeatureCategory? _cat;
  int _page = 0;
  static const _pageSize = 5;

  String _catName(FeatureCategory? c) => switch (c) {
    null => 'Todos',
    FeatureCategory.financial => 'Finanzas',
    FeatureCategory.budget => 'Presupuesto',
    FeatureCategory.voice => 'Voz',
    FeatureCategory.widget => 'Widget',
    FeatureCategory.subscription => 'Suscripción',
    FeatureCategory.conversion => 'Conversión',
    FeatureCategory.auth => 'Auth',
    FeatureCategory.onboarding => 'Onboarding',
    FeatureCategory.notification => 'Notificaciones',
    FeatureCategory.other => 'Otros',
  };

  @override
  Widget build(BuildContext context) {
    final filtered = _cat == null
        ? widget.events
        : widget.events.where((e) => e.category == _cat).toList();
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final safePage = _page.clamp(0, totalPages - 1);
    final pageItems = filtered
        .skip(safePage * _pageSize)
        .take(_pageSize)
        .toList();
    final maxCount = filtered.isEmpty
        ? 1
        : filtered.fold(0, (m, e) => math.max(m, e.count));
    final presentCats = widget.events.map((e) => e.category).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Eventos más usados',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.dc.ink,
                  ),
                ),
              ),
              _RangeDropdown(
                value: widget.range,
                onChanged: widget.onRangeChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CatChip(
                  label: 'Todos',
                  color: context.dc.ink2,
                  selected: _cat == null,
                  onTap: () => setState(() {
                    _cat = null;
                    _page = 0;
                  }),
                ),
                for (final cat in presentCats) ...[
                  const SizedBox(width: 6),
                  _CatChip(
                    label: _catName(cat),
                    color: _colorForCat(cat),
                    selected: _cat == cat,
                    onTap: () => setState(() {
                      _cat = _cat == cat ? null : cat;
                      _page = 0;
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (pageItems.isEmpty)
            const SizedBox(
              height: 100,
              child: EmptyTablesComponent(title: 'Sin datos', description: ''),
            )
          else
            for (int i = 0; i < pageItems.length; i++)
              _EventListRow(
                rank: safePage * _pageSize + i + 1,
                event: pageItems[i],
                maxCount: maxCount,
              ),
          if (totalPages > 1) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageBtn(
                  icon: Icons.chevron_left_rounded,
                  enabled: safePage > 0,
                  onTap: () => setState(() => _page = safePage - 1),
                ),
                const SizedBox(width: 14),
                Text(
                  '${safePage + 1} / $totalPages',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.dc.ink2,
                  ),
                ),
                const SizedBox(width: 14),
                _PageBtn(
                  icon: Icons.chevron_right_rounded,
                  enabled: safePage < totalPages - 1,
                  onTap: () => setState(() => _page = safePage + 1),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? context.dc.elevated : context.dc.progressBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? context.dc.ink2 : context.dc.ink3,
        ),
      ),
    );
  }
}

class _EventListRow extends StatelessWidget {
  const _EventListRow({
    required this.rank,
    required this.event,
    required this.maxCount,
  });
  final int rank;
  final FeatureEventRow event;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final color = _colorForCat(event.category);
    final fraction = maxCount > 0 ? event.count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.dc.ink3,
              ),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.dc.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 5,
                    color: context.dc.progressBg,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction.clamp(0.01, 1.0),
                      child: Container(color: color.withAlpha(200)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtNum(event.count),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.dc.ink,
                ),
              ),
              Text(
                '${event.uniqueUsers} usr',
                style: TextStyle(fontSize: 11, color: context.dc.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RETENTION CURVE — cohort line chart (global user retention)
// ─────────────────────────────────────────────────────────────────────────────

class _RetentionCurveSection extends StatelessWidget {
  const _RetentionCurveSection({required this.curve});
  final List<RetentionPoint> curve;

  double _rateAt(int day) {
    for (final p in curve) {
      if (p.day == day) return p.rate;
    }
    // interpolate closest
    RetentionPoint? prev, next;
    for (final p in curve) {
      if (p.day <= day) prev = p;
      if (p.day >= day && next == null) next = p;
    }
    if (prev == null) return next?.rate ?? 0;
    if (next == null || next.day == prev.day) return prev.rate;
    final t = (day - prev.day) / (next.day - prev.day);
    return prev.rate + (next.rate - prev.rate) * t;
  }

  @override
  Widget build(BuildContext context) {
    if (curve.isEmpty) return const SizedBox.shrink();

    final maxDay = curve.last.day;
    final d1Rate = _rateAt(1);
    final d7Rate = _rateAt(7);
    final d30Rate = _rateAt(math.min(30, maxDay));

    final spots = curve
        .map((p) => FlSpot(p.day.toDouble(), (p.rate * 100)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Retención de usuarios',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.dc.ink,
                    ),
                  ),
                  Text(
                    'Últimos $maxDay días · % que regresa en el día N',
                    style: TextStyle(fontSize: 12, color: context.dc.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // ── Summary chips ─────────────────────────────────────────────────────
        Row(
          children: [
            _CurveChip(
              label: 'Día 1',
              rate: d1Rate,
              color: AppColors.chartAmber,
            ),
            const SizedBox(width: 10),
            _CurveChip(
              label: 'Día 7',
              rate: d7Rate,
              color: AppColors.chartBlue,
            ),
            const SizedBox(width: 10),
            _CurveChip(
              label: 'Día 30',
              rate: d30Rate,
              color: AppColors.chartGreen,
            ),
          ],
        ),
        const SizedBox(height: 22),
        // ── Chart ─────────────────────────────────────────────────────────────
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxDay.toDouble(),
              minY: 0,
              maxY: 100,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.dc.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: 20,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${v.toInt()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: context.dc.ink3),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: (maxDay / 6).ceilToDouble().clamp(1, 999),
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Día ${v.toInt()}',
                        style: TextStyle(fontSize: 10, color: context.dc.ink3),
                      ),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.chartBlue,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.chartBlue.withAlpha(50),
                        AppColors.chartBlue.withAlpha(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.dc.elevated,
                  getTooltipItems: (spots) => spots.map((s) {
                    return LineTooltipItem(
                      'Día ${s.x.toInt()}\n',
                      TextStyle(fontSize: 11, color: context.dc.ink3),
                      children: [
                        TextSpan(
                          text: '${s.y.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.chartBlue,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurveChip extends StatelessWidget {
  const _CurveChip({
    required this.label,
    required this.rate,
    required this.color,
  });
  final String label;
  final double rate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = '${(rate * 100).toStringAsFixed(1)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.dc.ink3,
                ),
              ),
              Text(
                pct,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RETENTION — horizontal comparative bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _RetentionSection extends StatelessWidget {
  const _RetentionSection({required this.retention});
  final List<FeatureRetentionRow> retention;

  @override
  Widget build(BuildContext context) {
    final sorted = [...retention]
      ..sort((a, b) => b.retentionScore.compareTo(a.retentionScore));
    final maxD1 = sorted.fold(0, (m, r) => math.max(m, r.d1Users));
    final maxD7 = sorted.fold(0, (m, r) => math.max(m, r.d7Users));
    final maxD30 = sorted.fold(0, (m, r) => math.max(m, r.d30Users));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Retención por feature',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.dc.ink,
                    ),
                  ),
                  Text(
                    'Usuarios únicos que repiten · D1 / D7 / D30',
                    style: TextStyle(fontSize: 12, color: context.dc.ink3),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RetDot(color: AppColors.chartAmber, label: 'D1'),
                const SizedBox(width: 14),
                _RetDot(color: AppColors.chartBlue, label: 'D7'),
                const SizedBox(width: 14),
                _RetDot(color: AppColors.chartGreen, label: 'D30'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Column headers
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            children: [
              const Expanded(flex: 5, child: SizedBox.shrink()),
              const SizedBox(width: 12),
              Expanded(
                flex: 11,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'D1 · 1 día',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.chartAmber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'D7 · 7 días',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.chartBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'D30 · 30 días',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.chartGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 56),
            ],
          ),
        ),
        for (int i = 0; i < sorted.length; i++) ...[
          _RetentionRow(
            row: sorted[i],
            maxD1: maxD1,
            maxD7: maxD7,
            maxD30: maxD30,
          ),
          if (i < sorted.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(height: 1, color: context.dc.divider),
            ),
        ],
      ],
    );
  }
}

class _RetDot extends StatelessWidget {
  const _RetDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.dc.ink2,
          ),
        ),
      ],
    );
  }
}

class _RetentionRow extends StatelessWidget {
  const _RetentionRow({
    required this.row,
    required this.maxD1,
    required this.maxD7,
    required this.maxD30,
  });
  final FeatureRetentionRow row;
  final int maxD1;
  final int maxD7;
  final int maxD30;

  @override
  Widget build(BuildContext context) {
    final name = FeatureEventRow(
      name: row.name,
      count: 0,
      uniqueUsers: 0,
      perSession: 0,
    ).displayName;
    final catColor = _colorForCat(
      FeatureEventRow(
        name: row.name,
        count: 0,
        uniqueUsers: 0,
        perSession: 0,
      ).category,
    );
    final score = row.retentionScore;
    final scoreColor = score >= 0.5
        ? AppColors.chartGreen
        : score >= 0.25
        ? AppColors.chartAmber
        : AppColors.chartRed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.dc.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 11,
          child: Row(
            children: [
              Expanded(
                child: _HBar(
                  value: row.d1Users,
                  max: maxD1,
                  color: AppColors.chartAmber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HBar(
                  value: row.d7Users,
                  max: maxD7,
                  color: AppColors.chartBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HBar(
                  value: row.d30Users,
                  max: maxD30,
                  color: AppColors.chartGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 44,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${(score * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: scoreColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HBar extends StatelessWidget {
  const _HBar({required this.value, required this.max, required this.color});
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final frac = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.dc.ink,
              ),
            ),
            const Spacer(),
            if (max > 0 && value > 0)
              Text(
                '${(frac * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 10, color: context.dc.ink3),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(
              height: 7,
              decoration: BoxDecoration(
                color: context.dc.progressBg,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (frac > 0)
              FractionallySizedBox(
                widthFactor: frac,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _RangeDropdown extends StatelessWidget {
  const _RangeDropdown({required this.value, required this.onChanged});
  final DateRange value;
  final ValueChanged<DateRange> onChanged;

  String _label(DateRange r) => switch (r) {
    DateRange.all => 'Hoy',
    DateRange.d7 => '7 días',
    DateRange.d30 => '30 días',
    DateRange.d90 => '90 días',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<DateRange>(
        value: value,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: context.dc.ink3,
        ),
        dropdownColor: context.dc.elevated,
        borderRadius: BorderRadius.circular(14),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.dc.ink,
        ),
        items: DateRange.values
            .map((r) => DropdownMenuItem(value: r, child: Text(_label(r))))
            .toList(),
        onChanged: (r) {
          if (r != null) onChanged(r);
        },
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(26) : context.dc.elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : context.dc.ink3,
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink : context.dc.elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : context.dc.ink3,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _RefreshBtn extends StatelessWidget {
  const _RefreshBtn({required this.refreshing, required this.onTap});
  final bool refreshing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.dc.elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: refreshing
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.pink,
                ),
              )
            : Icon(Icons.refresh_rounded, size: 20, color: context.dc.ink2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesShimmer extends StatelessWidget {
  const _FeaturesShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          AppSkeletonBox(width: 240, height: 34, radius: 10),
          const SizedBox(height: 8),
          AppSkeletonBox(width: 160, height: 14, radius: 6),
          const SizedBox(height: 24),
          // Period chips
          Row(
            children: [
              for (int i = 0; i < 4; i++) ...[
                AppSkeletonBox(width: 68, height: 34, radius: 20),
                if (i < 3) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // 4 stat cards
          LayoutBuilder(
            builder: (_, constraints) {
              final w = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    AppSkeletonBox(width: w, height: 138, radius: 28),
                    if (i < 3) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Trend chart
          AppSkeletonBox(width: double.infinity, height: 270, radius: 32),
          const SizedBox(height: 20),
          // Weekly comparison
          AppSkeletonBox(width: double.infinity, height: 220, radius: 32),
          const SizedBox(height: 20),
          // Behavior: panel with 3 cards + strip
          AppSkeletonBox(width: double.infinity, height: 220, radius: 32),
          const SizedBox(height: 20),
          // Adoption: donut + events list
          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 720;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(
                      width: constraints.maxWidth * 0.42,
                      height: 320,
                      radius: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppSkeletonBox(
                        width: double.infinity,
                        height: 320,
                        radius: 32,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  AppSkeletonBox(
                    width: double.infinity,
                    height: 240,
                    radius: 32,
                  ),
                  const SizedBox(height: 16),
                  AppSkeletonBox(
                    width: double.infinity,
                    height: 320,
                    radius: 32,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Retention chart
          AppSkeletonBox(width: double.infinity, height: 380, radius: 32),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Color _colorForCat(FeatureCategory cat) => switch (cat) {
  FeatureCategory.financial => AppColors.chartGreen,
  FeatureCategory.budget => AppColors.chartOlive,
  FeatureCategory.voice => AppColors.chartPurple,
  FeatureCategory.widget => AppColors.chartBlue,
  FeatureCategory.subscription => AppColors.chartAmber,
  FeatureCategory.conversion => AppColors.pink,
  FeatureCategory.auth => AppColors.chartRed,
  FeatureCategory.onboarding => AppColors.chartPink,
  FeatureCategory.notification => AppColors.ink3,
  FeatureCategory.other => AppColors.ink3,
};

String _fmtNum(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final s = n.toString();
    return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
  }
  return '${(n / 1000000).toStringAsFixed(1)}M';
}
