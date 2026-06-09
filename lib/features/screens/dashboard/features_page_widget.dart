import 'dart:math' as math;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:dashboard_analitycs/core/models/features_metrics_model.dart';
import 'package:dashboard_analitycs/core/services/features_metrics_service.dart';
import 'package:dashboard_analitycs/core/widgets/app_shimmer.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/empty_tables_component.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/shared_widgets.dart';
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
                description: 'Presiona el botón ⟳ para sincronizar.',
              ),
            ],
          );
        }

        if (metrics.status == 'loading') {
          return Column(
            children: [
              _buildHeader(context, metrics),
              const SizedBox(height: 60),
              const Center(child: CircularProgressIndicator(color: AppColors.pink)),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, metrics),
            const SizedBox(height: 20),
            _SessionCards(metrics: metrics),
            const SizedBox(height: 18),
            Panel(
              child: _ComportamientoSection(metrics: metrics),
            ),
            const SizedBox(height: 18),
            Panel(
              child: _AdoptionSection(metrics: metrics),
            ),
            const SizedBox(height: 18),
            if (metrics.retention.isNotEmpty)
              Panel(
                child: _RetentionSection(retention: metrics.retention),
              ),
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
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: context.dc.ink,
                ),
              ),
              if (metrics?.updatedAtLabel.isNotEmpty == true)
                Text(
                  'Actualizado: ${metrics!.updatedAtLabel}',
                  style: TextStyle(fontSize: 12, color: context.dc.ink3),
                ),
            ],
          ),
        ),
        _FeaturesRefreshButton(refreshing: _refreshing, onTap: _manualRefresh),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SESSION CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _SessionCards extends StatefulWidget {
  const _SessionCards({required this.metrics});
  final FeaturesMetrics metrics;

  @override
  State<_SessionCards> createState() => _SessionCardsState();
}

class _SessionCardsState extends State<_SessionCards> {
  DateRange _range = DateRange.d7;

  @override
  Widget build(BuildContext context) {
    final sm = widget.metrics.session(_range) ?? const SessionMetrics();

    String rangeLabel(DateRange r) => switch (r) {
      DateRange.all => 'Hoy',
      DateRange.d7  => '7 días',
      DateRange.d30 => '30 días',
      DateRange.d90 => '90 días',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final r in DateRange.values) ...[
              _PeriodChip(
                label: rangeLabel(r),
                selected: _range == r,
                onTap: () => setState(() => _range = r),
              ),
              if (r != DateRange.values.last) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          const gap = 14.0;
          final cols = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 2 : 1;
          final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
          final cards = [
            _StatCard(
              label: 'Usuarios activos',
              value: _fmtNum(sm.activeUsers),
              icon: Icons.people_outline_rounded,
              color: AppColors.chartBlue,
            ),
            _StatCard(
              label: 'Sesiones totales',
              value: _fmtNum(sm.sessions),
              icon: Icons.bar_chart_rounded,
              color: AppColors.chartPurple,
            ),
            _StatCard(
              label: 'Sesiones / usuario',
              value: sm.sessions > 0 ? sm.sessionsPerUser.toStringAsFixed(1) : '—',
              icon: Icons.repeat_rounded,
              color: AppColors.chartAmber,
            ),
            _StatCard(
              label: 'Tiempo medio sesión',
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
        }),
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.dc.ink2, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1,
              color: context.dc.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPORTAMIENTO
// ─────────────────────────────────────────────────────────────────────────────

class _ComportamientoSection extends StatelessWidget {
  const _ComportamientoSection({required this.metrics});
  final FeaturesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final sm7    = metrics.session(DateRange.d7) ?? const SessionMetrics();
    final feat7  = metrics.featureList(DateRange.d7);
    final feat1  = metrics.featureList(DateRange.all);

    // Features promedio por sesión (d7)
    final totalEvents = feat7.fold(0, (acc, e) => acc + e.count);
    final featPerSession = sm7.sessions > 0
        ? (totalEvents / sm7.sessions).toStringAsFixed(1)
        : '—';

    final topD1 = feat1.isNotEmpty ? feat1.first.displayName : '—';
    final topD7 = feat7.isNotEmpty ? feat7.first.displayName : '—';

    // Feature que más retiene (mayor retention_score)
    final topRetention = metrics.retention.isNotEmpty
        ? metrics.retention.reduce((a, b) => a.retentionScore > b.retentionScore ? a : b)
        : null;
    final topRetainName = topRetention != null
        ? FeatureEventRow(name: topRetention.name, count: 0, uniqueUsers: 0, perSession: 0).displayName
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelHeader(title: 'Comportamiento', trailing: 'GA4 · últimos 7 días'),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final stats = [
            _BehaviorStat(
              value: featPerSession,
              label: 'features / sesión',
              icon: Icons.touch_app_outlined,
              color: AppColors.chartPurple,
            ),
            _BehaviorStat(
              value: sm7.avgDurationFormatted,
              label: 'tiempo medio sesión',
              icon: Icons.hourglass_empty_rounded,
              color: AppColors.chartAmber,
            ),
            _BehaviorStat(
              value: sm7.engagementRatePct,
              label: 'tasa de engagement',
              icon: Icons.bolt_outlined,
              color: AppColors.chartGreen,
            ),
          ];

          return isWide
              ? Row(
                  children: [
                    for (int i = 0; i < stats.length; i++) ...[
                      Expanded(child: stats[i]),
                      if (i < stats.length - 1)
                        Container(width: 1, height: 60, color: context.dc.divider, margin: const EdgeInsets.symmetric(horizontal: 20)),
                    ],
                  ],
                )
              : Column(
                  children: [for (final s in stats) ...[s, const SizedBox(height: 16)]],
                );
        }),
        const SizedBox(height: 20),
        Container(height: 1, color: context.dc.divider),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final insights = [
            _InsightRow(
              icon: Icons.star_rounded,
              color: AppColors.chartAmber,
              label: 'Más usada hoy (D1)',
              value: topD1,
            ),
            _InsightRow(
              icon: Icons.trending_up_rounded,
              color: AppColors.chartBlue,
              label: 'Más usada (D7)',
              value: topD7,
            ),
            _InsightRow(
              icon: Icons.loop_rounded,
              color: AppColors.chartGreen,
              label: 'Mejor retención',
              value: topRetainName,
            ),
          ];
          if (isWide) {
            return Row(
              children: [
                for (int i = 0; i < insights.length; i++) ...[
                  Expanded(child: insights[i]),
                  if (i < insights.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          }
          return Column(children: [
            for (final ins in insights) ...[ins, const SizedBox(height: 8)],
          ]);
        }),
      ],
    );
  }
}

class _BehaviorStat extends StatelessWidget {
  const _BehaviorStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: context.dc.ink,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: context.dc.ink3)),
          ],
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: context.dc.ink3)),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.dc.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE ADOPTION BARS
// ─────────────────────────────────────────────────────────────────────────────

class _AdoptionSection extends StatefulWidget {
  const _AdoptionSection({required this.metrics});
  final FeaturesMetrics metrics;

  @override
  State<_AdoptionSection> createState() => _AdoptionSectionState();
}

class _AdoptionSectionState extends State<_AdoptionSection> {
  DateRange _range = DateRange.d7;

  Color _colorFor(FeatureEventRow e) => switch (e.category) {
    FeatureCategory.financial    => AppColors.chartGreen,
    FeatureCategory.budget       => AppColors.chartOlive,
    FeatureCategory.voice        => AppColors.chartPurple,
    FeatureCategory.widget       => AppColors.chartBlue,
    FeatureCategory.subscription => AppColors.chartAmber,
    FeatureCategory.conversion   => AppColors.pink,
    FeatureCategory.auth         => AppColors.chartRed,
    FeatureCategory.onboarding   => AppColors.chartPink,
    FeatureCategory.notification => AppColors.ink3,
    FeatureCategory.other        => AppColors.ink3,
  };

  @override
  Widget build(BuildContext context) {
    final events = widget.metrics.featureList(_range);
    final top = events.take(12).toList();
    final maxCount = top.fold(0, (acc, e) => math.max(acc, e.count));

    String rangeFullLabel(DateRange r) => switch (r) {
      DateRange.all => 'Hoy',
      DateRange.d7  => 'Últimos 7 días',
      DateRange.d30 => 'Últimos 30 días',
      DateRange.d90 => 'Últimos 90 días',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: PanelHeader(title: 'Adopción de features', trailing: ''),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.dc.elevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.dc.divider),
              ),
              child: DropdownButton<DateRange>(
                value: _range,
                underline: const SizedBox.shrink(),
                isDense: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.dc.ink3),
                dropdownColor: context.dc.elevated,
                borderRadius: BorderRadius.circular(10),
                style: TextStyle(fontSize: 12, color: context.dc.ink),
                items: DateRange.values.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(rangeFullLabel(r)),
                )).toList(),
                onChanged: (r) { if (r != null) setState(() => _range = r); },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (top.isEmpty)
          const SizedBox(
            height: 120,
            child: EmptyTablesComponent(
              title: 'Sin datos para este período',
              description: 'Sincroniza para actualizar.',
            ),
          )
        else
          for (final e in top)
            _FeatureBarRow(
              event: e,
              maxCount: maxCount,
              color: _colorFor(e),
            ),
      ],
    );
  }
}

class _FeatureBarRow extends StatelessWidget {
  const _FeatureBarRow({
    required this.event,
    required this.maxCount,
    required this.color,
  });
  final FeatureEventRow event;
  final int maxCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? event.count / maxCount : 0.0;
    final pct = maxCount > 0
        ? '${(event.count / maxCount * 100).toStringAsFixed(0)}%'
        : '0%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              event.displayName,
              style: TextStyle(fontSize: 13, color: context.dc.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                color: context.dc.progressBg,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0.01, 1.0),
                  child: Container(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(pct, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(width: 6),
                Text(
                  _fmtNum(event.count),
                  style: TextStyle(fontSize: 11, color: context.dc.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RETENTION TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _RetentionSection extends StatelessWidget {
  const _RetentionSection({required this.retention});
  final List<FeatureRetentionRow> retention;

  @override
  Widget build(BuildContext context) {
    final sorted = [...retention]
      ..sort((a, b) => b.retentionScore.compareTo(a.retentionScore));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelHeader(
          title: 'Retención por feature',
          trailing: 'D1 = hoy · D7 = 7 días · D30 = 30 días',
        ),
        const SizedBox(height: 16),
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text('Feature', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.dc.ink3))),
              retCell('D1',  context),
              retCell('D7',  context),
              retCell('D30', context),
              retCell('Score', context),
            ],
          ),
        ),
        Container(height: 1, color: context.dc.divider),
        for (int i = 0; i < sorted.length; i++)
          _RetentionRow(
            row: sorted[i],
            isEven: i.isEven,
          ),
      ],
    );
  }

  Widget retCell(String text, BuildContext context) {
    return SizedBox(
      width: 60,
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.dc.ink3),
      ),
    );
  }
}

class _RetentionRow extends StatelessWidget {
  const _RetentionRow({required this.row, required this.isEven});
  final FeatureRetentionRow row;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final displayName = FeatureEventRow(
      name: row.name, count: 0, uniqueUsers: 0, perSession: 0,
    ).displayName;

    final score = row.retentionScore;
    final scoreColor = score >= 0.5
        ? AppColors.success
        : score >= 0.2
        ? AppColors.chartAmber
        : context.dc.ink3;

    return Container(
      color: isEven ? context.dc.elevated.withAlpha(60) : null,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(fontSize: 13, color: context.dc.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          numCell('${row.d1Users}', context),
          numCell('${row.d7Users}', context),
          numCell('${row.d30Users}', context),
          SizedBox(
            width: 60,
            child: Text(
              '${(score * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget numCell(String text, BuildContext context) {
    return SizedBox(
      width: 60,
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 13, color: context.dc.ink2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesRefreshButton extends StatelessWidget {
  const _FeaturesRefreshButton({required this.refreshing, required this.onTap});
  final bool refreshing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.dc.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.dc.divider),
        ),
        child: refreshing
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pink),
              )
            : Icon(Icons.refresh_rounded, size: 18, color: context.dc.ink2),
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
          AppSkeletonBox(width: 240, height: 32, radius: 10),
          const SizedBox(height: 6),
          AppSkeletonBox(width: 160, height: 14, radius: 6),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: List.generate(4, (_) => AppSkeletonBox(width: 200, height: 100, radius: 20)),
          ),
          const SizedBox(height: 18),
          AppSkeletonBox(width: double.infinity, height: 180, radius: 20),
          const SizedBox(height: 18),
          AppSkeletonBox(width: double.infinity, height: 260, radius: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERIOD CHIP  (shared)
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink : context.dc.surface,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: context.dc.divider),
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
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _fmtNum(int n) {
  if (n < 1000) return '$n';
  final s = n.toString();
  if (s.length <= 6) return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
  return '${(n / 1000000).toStringAsFixed(1)}M';
}
