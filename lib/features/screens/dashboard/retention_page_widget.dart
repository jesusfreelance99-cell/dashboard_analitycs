import 'dart:math' as math;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:dashboard_analitycs/core/models/retention_metrics_model.dart';
import 'package:dashboard_analitycs/core/services/retention_metrics_service.dart';
import 'package:dashboard_analitycs/core/widgets/app_shimmer.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/empty_tables_component.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/shared_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class RetentionPage extends StatefulWidget {
  const RetentionPage({super.key});

  @override
  State<RetentionPage> createState() => _RetentionPageState();
}

class _RetentionPageState extends State<RetentionPage> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _autoRefreshIfStale();
  }

  Future<void> _autoRefreshIfStale() async {
    try {
      if (await RetentionMetricsService.needsRefresh()) {
        await RetentionMetricsService.requestRefresh(source: 'auto');
      }
    } catch (_) {}
  }

  Future<void> _manualRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await RetentionMetricsService.requestRefresh(source: 'manual');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RetentionMetrics?>(
      stream: RetentionMetricsService.stream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _RetentionShimmer(
            refreshing: _refreshing,
            onRefresh: _manualRefresh,
          );
        }

        final metrics = snap.data;

        if (metrics == null || metrics.status == 'idle') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, null),
              const SizedBox(height: 60),
              const EmptyTablesComponent(
                title: 'Sin datos de retención',
                description: 'Presiona ⟳ para sincronizar.',
              ),
            ],
          );
        }

        if (metrics.status == 'loading') {
          return _RetentionShimmer(
            refreshing: _refreshing,
            onRefresh: _manualRefresh,
          );
        }

        final hasData =
            metrics.newVsReturning.isNotEmpty ||
            metrics.retentionCurve.isNotEmpty ||
            metrics.engagementSeries.isNotEmpty ||
            metrics.ltvCurve.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, metrics),
            const SizedBox(height: 24),
            if (metrics.newVsReturning.isNotEmpty ||
                metrics.retentionCurve.isNotEmpty) ...[
              _SummaryCards(
                data: metrics.newVsReturning,
                retentionCurve: metrics.retentionCurve,
              ),
              const SizedBox(height: 20),
            ],
            if (metrics.newVsReturning.isNotEmpty) ...[
              Panel(
                child: _NewVsReturningSection(data: metrics.newVsReturning),
              ),
              const SizedBox(height: 20),
            ],
            if (metrics.retentionCurve.isNotEmpty) ...[
              Panel(child: _RetentionCurveChart(data: metrics.retentionCurve)),
              const SizedBox(height: 20),
            ],
            if (metrics.engagementSeries.isNotEmpty) ...[
              Panel(child: _EngagementChart(data: metrics.engagementSeries)),
              const SizedBox(height: 20),
            ],
            if (metrics.ltvCurve.isNotEmpty) ...[
              Panel(child: _LtvChart(data: metrics.ltvCurve)),
              const SizedBox(height: 20),
            ],
            if (!hasData) ...[
              const SizedBox(height: 40),
              const EmptyTablesComponent(
                title: 'Sin datos aún',
                description:
                    'Los datos aparecerán tras la primera sincronización.',
              ),
            ],
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, RetentionMetrics? metrics) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Retención',
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
// SUMMARY CARDS — top row of 3
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.data, required this.retentionCurve});
  final List<NewVsReturningPoint> data;
  final List<RetentionCurvePoint> retentionCurve;

  double? _delta(List<int> values) {
    if (values.length < 4) return null;
    final half = values.length ~/ 2;
    final first = values.sublist(0, half).fold(0, (s, v) => s + v).toDouble();
    final second = values.sublist(half).fold(0, (s, v) => s + v).toDouble();
    if (first <= 0) return null;
    return (second - first) / first;
  }

  double _rateAt(int day) {
    if (retentionCurve.isEmpty) return 0;
    for (int i = 0; i < retentionCurve.length - 1; i++) {
      if (retentionCurve[i].day <= day && day <= retentionCurve[i + 1].day) {
        final t =
            (day - retentionCurve[i].day) /
            (retentionCurve[i + 1].day - retentionCurve[i].day);
        return retentionCurve[i].rate +
            t * (retentionCurve[i + 1].rate - retentionCurve[i].rate);
      }
    }
    return day <= retentionCurve.first.day
        ? retentionCurve.first.rate
        : retentionCurve.last.rate;
  }

  @override
  Widget build(BuildContext context) {
    final totalNew = data.fold(0, (s, p) => s + p.newUsers);
    final totalReturning = data.fold(0, (s, p) => s + p.returningUsers);
    final newSpark = data.map((p) => p.newUsers).toList();
    final retSpark = data.map((p) => p.returningUsers).toList();
    final d1 = _rateAt(1);
    final d7 = _rateAt(7);
    final d30 = _rateAt(30);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final cols = constraints.maxWidth >= 700 ? 3 : 1;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;

        final cards = <Widget>[
          _MetricCard(
            label: 'Usuarios nuevos',
            value: _fmtInt(totalNew),
            icon: Icons.person_add_outlined,
            color: AppColors.chartBlue,
            delta: _delta(newSpark),
            sparkline: newSpark,
          ),
          _MetricCard(
            label: 'Recurrentes',
            value: _fmtInt(totalReturning),
            icon: Icons.repeat_rounded,
            color: AppColors.chartGreen,
            delta: _delta(retSpark),
            sparkline: retSpark,
          ),
          _RetentionRateCard(d1: d1, d7: d7, d30: d30),
        ];

        if (cols == 1) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i < cards.length - 1) const SizedBox(height: gap),
              ],
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                SizedBox(width: w, child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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

class _RetentionRateCard extends StatelessWidget {
  const _RetentionRateCard({
    required this.d1,
    required this.d7,
    required this.d30,
  });
  final double d1;
  final double d7;
  final double d30;

  @override
  Widget build(BuildContext context) {
    final hasData = d1 > 0 || d7 > 0 || d30 > 0;

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
                  color: AppColors.chartAmber.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.loop_rounded,
                  size: 18,
                  color: AppColors.chartAmber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '% Retención',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.dc.ink2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hasData ? '${(d1 * 100).toStringAsFixed(1)}%' : '—',
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
          if (hasData)
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RateLabel(label: 'D1', pct: d1, color: AppColors.chartAmber),
                  const SizedBox(width: 20),
                  _RateLabel(label: 'D7', pct: d7, color: AppColors.chartBlue),
                  const SizedBox(width: 20),
                  _RateLabel(
                    label: 'D30',
                    pct: d30,
                    color: AppColors.chartGreen,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  'Sin datos de cohorte',
                  style: TextStyle(fontSize: 13, color: context.dc.ink3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RateLabel extends StatelessWidget {
  const _RateLabel({
    required this.label,
    required this.pct,
    required this.color,
  });
  final String label;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.dc.ink3)),
        const SizedBox(height: 2),
        Text(
          '${(pct * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW VS RETURNING — with filter chips
// ─────────────────────────────────────────────────────────────────────────────

enum _UserFilter { all, newOnly, returningOnly }

enum _DayRange { d7, d30 }

class _NewVsReturningSection extends StatefulWidget {
  const _NewVsReturningSection({required this.data});
  final List<NewVsReturningPoint> data;

  @override
  State<_NewVsReturningSection> createState() => _NewVsReturningSectionState();
}

class _NewVsReturningSectionState extends State<_NewVsReturningSection> {
  _UserFilter _userFilter = _UserFilter.all;
  _DayRange _dayRange = _DayRange.d30;

  List<NewVsReturningPoint> get _filtered {
    final days = _dayRange == _DayRange.d7 ? 7 : 30;
    final src = widget.data;
    return src.length > days ? src.sublist(src.length - days) : src;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    if (filtered.isEmpty) return const SizedBox.shrink();

    final maxNew = filtered.map((p) => p.newUsers).fold(0, math.max);
    final maxRet = filtered.map((p) => p.returningUsers).fold(0, math.max);
    final maxVal = math.max(maxNew, maxRet).toDouble();
    if (maxVal <= 0) return const SizedBox.shrink();

    final showNew =
        _userFilter == _UserFilter.all || _userFilter == _UserFilter.newOnly;
    final showRet =
        _userFilter == _UserFilter.all ||
        _userFilter == _UserFilter.returningOnly;

    final spotsNew = <FlSpot>[];
    final spotsRet = <FlSpot>[];
    for (int i = 0; i < filtered.length; i++) {
      spotsNew.add(FlSpot(i.toDouble(), filtered[i].newUsers.toDouble()));
      spotsRet.add(FlSpot(i.toDouble(), filtered[i].returningUsers.toDouble()));
    }

    final step = math.max(1, (filtered.length / 6).ceil());
    final dateLabels = <int, String>{};
    for (int i = 0; i < filtered.length; i += step) {
      final raw = filtered[i].date;
      if (raw.length >= 8) {
        dateLabels[i] = '${raw.substring(6, 8)}/${raw.substring(4, 6)}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Nuevos vs Recurrentes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.dc.ink,
                ),
              ),
            ),
            if (showNew)
              _LegendDot(color: AppColors.chartBlue, label: 'Nuevos'),
            if (showNew && showRet) const SizedBox(width: 14),
            if (showRet)
              _LegendDot(color: AppColors.chartGreen, label: 'Recurrentes'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _ChipBtn(
              label: 'Todos',
              selected: _userFilter == _UserFilter.all,
              onTap: () => setState(() => _userFilter = _UserFilter.all),
            ),
            const SizedBox(width: 8),
            _ChipBtn(
              label: 'Nuevos',
              selected: _userFilter == _UserFilter.newOnly,
              activeColor: AppColors.chartBlue,
              onTap: () => setState(() => _userFilter = _UserFilter.newOnly),
            ),
            const SizedBox(width: 8),
            _ChipBtn(
              label: 'Recurrentes',
              selected: _userFilter == _UserFilter.returningOnly,
              activeColor: AppColors.chartGreen,
              onTap: () =>
                  setState(() => _userFilter = _UserFilter.returningOnly),
            ),
            const Spacer(),
            _ChipBtn(
              label: '7d',
              selected: _dayRange == _DayRange.d7,
              onTap: () => setState(() => _dayRange = _DayRange.d7),
            ),
            const SizedBox(width: 8),
            _ChipBtn(
              label: '30d',
              selected: _dayRange == _DayRange.d30,
              onTap: () => setState(() => _dayRange = _DayRange.d30),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.dc.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (v, _) => Text(
                      _fmtInt(v.toInt()),
                      style: TextStyle(fontSize: 11, color: context.dc.ink3),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final label = dateLabels[v.toInt()];
                      if (label == null) return const SizedBox.shrink();
                      return Text(
                        label,
                        style: TextStyle(fontSize: 11, color: context.dc.ink3),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.dc.elevated,
                  getTooltipItems: (spots) => spots.map((s) {
                    final label = s.barIndex == 0 && showNew
                        ? 'Nuevos: ${_fmtInt(s.y.toInt())}'
                        : 'Recurrentes: ${_fmtInt(s.y.toInt())}';
                    return LineTooltipItem(
                      label,
                      TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: s.bar.color,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                if (showNew) _line(spotsNew, AppColors.chartBlue),
                if (showRet) _line(spotsRet, AppColors.chartGreen),
              ],
              minY: 0,
              maxY: maxVal * 1.15,
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    isCurved: true,
    curveSmoothness: 0.3,
    color: color,
    barWidth: 2.5,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(50), color.withAlpha(0)],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RETENTION CURVE (prominent)
// ─────────────────────────────────────────────────────────────────────────────

class _RetentionCurveChart extends StatelessWidget {
  const _RetentionCurveChart({required this.data});
  final List<RetentionCurvePoint> data;

  double _rateAt(int day) {
    if (data.isEmpty) return 0;
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i].day <= day && day <= data[i + 1].day) {
        final t = (day - data[i].day) / (data[i + 1].day - data[i].day);
        return data[i].rate + t * (data[i + 1].rate - data[i].rate);
      }
    }
    return day <= data.first.day ? data.first.rate : data.last.rate;
  }

  @override
  Widget build(BuildContext context) {
    final spots = data
        .map((p) => FlSpot(p.day.toDouble(), p.rate * 100))
        .toList();
    final d1 = (_rateAt(1) * 100).toStringAsFixed(1);
    final d7 = (_rateAt(7) * 100).toStringAsFixed(1);
    final d30 = (_rateAt(30) * 100).toStringAsFixed(1);
    final maxDay = data.isEmpty ? 42 : data.last.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
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
            const SizedBox(height: 2),
            Text(
              'Porcentaje de usuarios que regresan tras la primera sesión',
              style: TextStyle(fontSize: 13, color: context.dc.ink3),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatChip(
              color: AppColors.chartAmber,
              label: 'Día 1',
              value: '$d1%',
            ),
            const SizedBox(width: 16),
            _StatChip(
              color: AppColors.chartBlue,
              label: 'Día 7',
              value: '$d7%',
            ),
            const SizedBox(width: 16),
            _StatChip(
              color: AppColors.chartGreen,
              label: 'Día 30',
              value: '$d30%',
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.dc.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}%',
                      style: TextStyle(fontSize: 11, color: context.dc.ink3),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: (maxDay / 6).ceilToDouble(),
                    getTitlesWidget: (v, _) {
                      final day = v.toInt();
                      if (day == 0) return const SizedBox.shrink();
                      return Text(
                        'Día $day',
                        style: TextStyle(fontSize: 10, color: context.dc.ink3),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.dc.elevated,
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          'Día ${s.x.toInt()}: ${s.y.toStringAsFixed(1)}%',
                          TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.chartBlue,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.chartBlue,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.chartBlue.withAlpha(60),
                        AppColors.chartBlue.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ],
              minY: 0,
              maxY: 105,
              minX: 0,
              maxX: maxDay.toDouble(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENGAGEMENT CHART
// ─────────────────────────────────────────────────────────────────────────────

class _EngagementChart extends StatelessWidget {
  const _EngagementChart({required this.data});
  final List<EngagementPoint> data;

  String _fmtSec(double sec) {
    if (sec <= 0) return '0s';
    final total = sec.round();
    final m = total ~/ 60;
    final s = total % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final maxSec = data.map((p) => p.avgSessionSec).fold(0.0, math.max);
    if (maxSec <= 0) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].avgSessionSec));
    }

    final recent = data.length >= 7 ? data.sublist(data.length - 7) : data;
    final avgRecent = recent.isEmpty
        ? 0.0
        : recent.map((p) => p.avgSessionSec).reduce((a, b) => a + b) /
              recent.length;

    final step = math.max(1, (data.length / 6).ceil());
    final dateLabels = <int, String>{};
    for (int i = 0; i < data.length; i += step) {
      final raw = data[i].date;
      if (raw.length >= 8) {
        dateLabels[i] = '${raw.substring(6, 8)}/${raw.substring(4, 6)}';
      }
    }

    final yInterval = _niceInterval(maxSec, 4);
    final chartMax = yInterval * 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interacción de los usuarios',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.dc.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Duración media de sesión — últimos 42 días',
          style: TextStyle(fontSize: 13, color: context.dc.ink3),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatChip(
              color: AppColors.chartPurple,
              label: 'Promedio reciente',
              value: _fmtSec(avgRecent),
            ),
            const SizedBox(width: 16),
            _StatChip(
              color: AppColors.chartAmber,
              label: 'Máximo',
              value: _fmtSec(maxSec),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.dc.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: yInterval,
                    getTitlesWidget: (v, _) => Text(
                      _fmtSec(v),
                      style: TextStyle(fontSize: 10, color: context.dc.ink3),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final label = dateLabels[v.toInt()];
                      if (label == null) return const SizedBox.shrink();
                      return Text(
                        label,
                        style: TextStyle(fontSize: 11, color: context.dc.ink3),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.dc.elevated,
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          _fmtSec(s.y),
                          TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.chartPurple,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.chartPurple,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.chartPurple.withAlpha(60),
                        AppColors.chartPurple.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ],
              minY: 0,
              maxY: chartMax,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LTV CHART
// ─────────────────────────────────────────────────────────────────────────────

class _LtvChart extends StatelessWidget {
  const _LtvChart({required this.data});
  final List<LtvPoint> data;

  @override
  Widget build(BuildContext context) {
    final maxVal = data
        .map((p) => p.avgRevenue)
        .fold(0.0, (a, b) => a > b ? a : b);
    if (maxVal <= 0) return const SizedBox.shrink();

    final spots = data
        .map((p) => FlSpot(p.day.toDouble(), p.avgRevenue))
        .toList();
    final maxDay = data.isEmpty ? 120 : data.last.day;
    final latest = data.last.avgRevenue;
    final yInterval = _niceInterval(maxVal, 4);
    final chartMax = yInterval * 5;

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
                    'Valor medio 120 días',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.dc.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ingresos acumulados promedio por usuario (cohorte)',
                    style: TextStyle(fontSize: 13, color: context.dc.ink3),
                  ),
                ],
              ),
            ),
            _StatChip(
              color: AppColors.chartAmber,
              label: 'LTV día ${data.last.day}',
              value: '\$${latest.toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.dc.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: yInterval,
                    getTitlesWidget: (v, _) => Text(
                      '\$${v.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: context.dc.ink3),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: (maxDay / 5).ceilToDouble(),
                    getTitlesWidget: (v, _) {
                      final day = v.toInt();
                      if (day == 0) return const SizedBox.shrink();
                      return Text(
                        'Día $day',
                        style: TextStyle(fontSize: 10, color: context.dc.ink3),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => context.dc.elevated,
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          'Día ${s.x.toInt()}\n\$${s.y.toStringAsFixed(2)}',
                          TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.chartAmber,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: AppColors.chartAmber,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.chartAmber.withAlpha(60),
                        AppColors.chartAmber.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ],
              minY: 0,
              maxY: chartMax,
              minX: 0,
              maxX: maxDay.toDouble(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? context.dc.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : context.dc.elevated,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: color.withAlpha(80), width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : context.dc.ink2,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final String value;

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
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: context.dc.ink3)),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.dc.ink,
              ),
            ),
          ],
        ),
      ],
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
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: context.dc.ink2)),
      ],
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({required this.data, required this.color});
  final List<int> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 0 : data.reduce(math.max);
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
    final pct = (delta.abs() * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isUp ? '↑' : '↓'} $pct%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _RefreshBtn extends StatelessWidget {
  const _RefreshBtn({required this.refreshing, required this.onTap});
  final bool refreshing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: refreshing ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.dc.elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: refreshing
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.dc.ink3,
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

class _RetentionShimmer extends StatelessWidget {
  const _RetentionShimmer({required this.refreshing, required this.onRefresh});
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(width: 160, height: 32, radius: 8),
                    const SizedBox(height: 8),
                    AppSkeletonBox(width: 200, height: 14, radius: 6),
                  ],
                ),
              ),
              AppSkeletonBox(width: 40, height: 40, radius: 20),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: context.dc.surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonBox(width: 36, height: 36, radius: 12),
                        const SizedBox(height: 14),
                        AppSkeletonBox(width: 80, height: 40, radius: 8),
                        const SizedBox(height: 12),
                        AppSkeletonBox(
                          width: double.infinity,
                          height: 44,
                          radius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 14),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: context.dc.surface,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(width: 220, height: 18, radius: 6),
                const SizedBox(height: 20),
                AppSkeletonBox(width: double.infinity, height: 200, radius: 12),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: context.dc.surface,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(width: 200, height: 18, radius: 6),
                const SizedBox(height: 20),
                AppSkeletonBox(width: double.infinity, height: 220, radius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _fmtInt(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

double _niceInterval(double maxVal, int targetTicks) {
  if (maxVal <= 0) return 10;
  final raw = maxVal / targetTicks;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  final normalized = raw / magnitude;
  final nice = normalized < 1.5
      ? 1.0
      : normalized < 3.5
      ? 2.0
      : normalized < 7.5
      ? 5.0
      : 10.0;
  return nice * magnitude;
}
