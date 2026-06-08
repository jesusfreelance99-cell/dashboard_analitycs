import 'dart:math' as math;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dashboard_analitycs/core/models/appstore_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/revenuecat_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/user_model.dart';
import 'package:dashboard_analitycs/core/services/appstore_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/country_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/revenuecat_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/user_metrics_service.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'empty_tables_component.dart';
import 'models.dart';
import 'shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              AppColors.shimmerBase,
              AppColors.shimmerLight,
              AppColors.white,
              AppColors.shimmerLight,
              AppColors.shimmerBase,
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ).createShader(bounds),
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class _ShimBox extends StatelessWidget {
  const _ShimBox({this.width, this.height = 20, this.radius = 10});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _AppStoreShimmer extends StatelessWidget {
  const _AppStoreShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          const _ShimBox(width: 340, height: 48, radius: 12),
          const SizedBox(height: 14),
          const _ShimBox(width: 260, height: 22, radius: 8),
          const SizedBox(height: 36),

          // APP STORE section header
          const _ShimBox(width: 180, height: 16, radius: 6),
          const SizedBox(height: 14),
          // 4 metric cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisExtent: 110,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 4,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 42),

          // REVENUE header + 5 cards
          const _ShimBox(width: 140, height: 16, radius: 6),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisExtent: 110,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 5,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 42),

          // USUARIOS header + 4 cards
          const _ShimBox(width: 120, height: 16, radius: 6),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisExtent: 110,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 4,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 42),

          // TENDENCIAS — 2 panels
          const _ShimBox(width: 160, height: 16, radius: 6),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW PAGE
// ─────────────────────────────────────────────────────────────────────────────

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.range, required this.isCompact});

  final DateRange range;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStoreMetrics?>(
      stream: AppStoreMetricsService.stream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _AppStoreShimmer();
        }
        return StreamBuilder<RevenueCatMetrics?>(
          stream: RevenueCatMetricsService.stream(),
          builder: (context, revenueSnap) {
            return _OverviewContent(
              range: range,
              isCompact: isCompact,
              appStore: snap.data,
              revenueCat: revenueSnap.data,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENIDO REAL
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({
    required this.range,
    required this.isCompact,
    required this.appStore,
    required this.revenueCat,
  });

  final DateRange range;
  final bool isCompact;
  final AppStoreMetrics? appStore;
  final RevenueCatMetrics? revenueCat;

  String _buildGreeting() {
    final hour = DateTime.now().hour;
    final saludo = hour < 12 ? 'Buenos días' : hour < 19 ? 'Buenas tardes' : 'Buenas noches';
    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName?.split(' ').first ?? 'Jesús';
    return '$saludo, $nombre 👋';
  }

  @override
  Widget build(BuildContext context) {
    final data = overviewRangeData(range);
    final as = appStore;
    final rc = revenueCat;
    final rcOverview = rc?.overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _buildGreeting(),
          style: const TextStyle(
            fontSize: 44,
            height: 1.03,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Esto es lo que está pasando en Trevo hoy.',
                style: TextStyle(fontSize: 18, color: AppColors.ink2),
              ),
            ),
            if (as != null && as.status == 'partial')
              Tooltip(
                message: 'Datos de Analytics en proceso',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.clock_20_regular,
                        size: 14,
                        color: AppColors.warningText,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Actualizando',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warningText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 36),

        // ── APP STORE CONNECT ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                label: 'APP STORE CONNECT',
                source: as == null ? 'iOS' : 'iOS · ${as.periodLabel}',
              ),
            ),
            const _AppStoreRefreshButton(),
          ],
        ),
        const SizedBox(height: 14),
        if (as != null && as.status == 'partial')
          const _AppStoreCardsShimmer()
        else
          ResponsiveGrid(
            minTileWidth: 250,
            children: [
              MetricCard(
                label: 'Impresiones',
                value: as?.impressionsStr ?? '—',
              ),
              MetricCard(
                label: 'Descargas',
                value: as?.downloadsStr ?? '—',
                helperText: as != null && as.periodLabel.isNotEmpty
                    ? as.periodLabel
                    : null,
              ),
              MetricCard(
                label: 'Descargas repetidas',
                value: as?.redownloadsStr ?? '—',
                helperText: as != null && as.periodLabel.isNotEmpty
                    ? as.periodLabel
                    : null,
              ),
              MetricCard(
                label: 'Tasa de conversión',
                value: as?.conversionStr ?? '—',
              ),
              MetricCard(
                label: 'Rating',
                value: as?.ratingStr ?? '—',
                valueSuffix: as?.rating != null && as!.rating > 0
                    ? const Icon(
                        Icons.star_rounded,
                        color: AppColors.starAmber,
                        size: 26,
                      )
                    : null,
                badgeText: as != null && as.totalReviews > 0
                    ? '${as.totalReviews} reseñas'
                    : 'Sin reseñas aún',
                badgeType: BadgeType.neutral,
              ),
            ],
          ),
        const SizedBox(height: 42),

        // ── REVENUE ───────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                label: 'REVENUE',
                source: rc == null
                    ? 'RevenueCat'
                    : rc.updatedAtLabel.isEmpty
                    ? rc.source
                    : '${rc.source} · ${rc.updatedAtLabel}',
              ),
            ),
            const _RevenueCatRefreshButton(),
          ],
        ),
        const SizedBox(height: 14),
        ResponsiveGrid(
          minTileWidth: 250,
          children: [
            MetricCard(
              label: 'Pruebas gratuitas',
              value: rcOverview?.activeTrialsLabel ?? '0',
              helperText: 'total acumulado',
            ),
            MetricCard(
              label: 'Suscripciones activas',
              value: rcOverview?.activeSubscriptionsLabel ?? '0',
              helperText: 'total acumulado',
            ),
            MetricCard(
              label: 'Ingresos recurrentes',
              value: rcOverview?.mrrLabel ?? '-',
              accent: true,
              helperText: 'mensuales · MRR',
            ),
            MetricCard(
              label: 'Ingresos',
              value: rcOverview?.revenue28dLabel ?? data.revenue,
              helperText: 'últimos 28 días',
            ),
            MetricCard(
              label: 'Nuevos clientes',
              value: rcOverview?.newCustomers28dLabel ?? '0',
              helperText: 'últimos 28 días',
            ),
            MetricCard(
              label: 'Clientes activos',
              value: rcOverview?.activeCustomers28dLabel ?? '0',
              helperText: 'últimos 28 días',
            ),
          ],
        ),
        const SizedBox(height: 42),

        // ── USUARIOS ─────────────────────────────────────────────────────
        const SectionHeader(label: 'USUARIOS', source: 'Firebase'),
        const SizedBox(height: 14),
        FutureBuilder<UserCounts>(
          future: UserMetricsService.future,
          builder: (context, snap) {
            final u = snap.data ?? UserCounts.empty;
            return ResponsiveGrid(
              minTileWidth: 250,
              children: [
                MetricCard(
                  label: 'Registrados',
                  value: u.total > 0 ? '${u.total}' : '—',
                  badgeText: u.newToday > 0 ? '↑ ${u.newToday} hoy' : null,
                  badgeType: BadgeType.positive,
                  helperText: 'total',
                ),
                MetricCard(
                  label: 'Plan Pro',
                  value: '${u.pro}',
                  accent: true,
                  valueSuffix: const FaIcon(
                    FontAwesomeIcons.crown,
                    color: AppColors.goldDark,
                    size: 24,
                  ),
                  badgeText: '${u.proPercent} del total',
                  badgeType: BadgeType.neutral,
                ),
                MetricCard(
                  label: 'Plan Gratuito',
                  value: '${u.free}',
                  badgeText: '${u.freePercent} del total',
                  badgeType: BadgeType.neutral,
                ),
                MetricCard(
                  label: 'Activos',
                  value: '${u.active}',
                  badgeText: '↑ ${u.activePercent}',
                  badgeType: BadgeType.positive,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 34),

        // ── TENDENCIAS ───────────────────────────────────────────────────
        const SectionHeader(label: 'TENDENCIAS', source: ''),
        const SizedBox(height: 14),
        ResponsiveSplit(
          left: _DownloadsTrendCard(appStore: as),
          right: _RevenueTrendCard(revenueCat: rc),
        ),
        const SizedBox(height: 40),

        // ── DISTRIBUCIÓN ─────────────────────────────────────────────────
        const SectionHeader(label: 'DISTRIBUCIÓN', source: ''),
        const SizedBox(height: 14),
        FutureBuilder<UserCounts>(
          future: UserMetricsService.future,
          builder: (context, snap) {
            final u = snap.data ?? UserCounts.empty;
            return ResponsiveSplit(
              left: FutureBuilder<List<CountryEntry>>(
                future: CountryMetricsService.future,
                builder: (context, countrySnap) {
                  final entries = countrySnap.data;
                  return Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PanelHeader(
                          title: 'Registros por país',
                          trailing: entries == null
                              ? 'Top 4'
                              : 'Top ${entries.length}',
                        ),
                        const SizedBox(height: 18),
                        if (entries == null) ...[
                          _CountryShimmer(),
                        ] else if (entries.isEmpty) ...[
                          const EmptyTablesComponent(
                            title: 'Sin datos de país',
                            description: 'Aún no hay registros de ubicación.',
                          ),
                        ] else ...[
                          for (int i = 0; i < entries.length; i++) ...[
                            _CountryEntryRow(entry: entries[i]),
                            if (i < entries.length - 1)
                              const SizedBox(height: 18),
                          ],
                        ],
                      ],
                    ),
                  );
                },
              ),
              right: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PanelHeader(
                      title: 'Distribución por plan',
                      trailing: '${u.total} usuarios',
                    ),
                    const SizedBox(height: 28),
                    PlanDistributionBar(proportion: u.proProportion),
                    const SizedBox(height: 28),
                    PlanRow(
                      icon: const FaIcon(FontAwesomeIcons.crown, size: 24),
                      iconBackground: AppColors.goldLight,
                      iconColor: AppColors.goldDark,
                      title: 'Plan Pro',
                      subtitle: 'de pago',
                      value: '${u.pro}',
                      percentage: u.proPercent,
                    ),
                    const SizedBox(height: 26),
                    PlanRow(
                      icon: const Icon(FluentIcons.gift_20_regular, size: 24),
                      iconBackground: AppColors.fieldBg,
                      iconColor: AppColors.ink3,
                      title: 'Plan Gratuito',
                      value: '${u.free}',
                      percentage: u.freePercent,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER DE CARDS — solo sección App Store Connect
// ─────────────────────────────────────────────────────────────────────────────

class _AppStoreCardsShimmer extends StatelessWidget {
  const _AppStoreCardsShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = ((constraints.maxWidth) / 250).floor().clamp(1, 5);
          final gap = 18.0;
          final tileWidth = (constraints.maxWidth - gap * (count - 1)) / count;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(
              5,
              (_) => Container(
                width: tileWidth,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON — App Store Connect
// ─────────────────────────────────────────────────────────────────────────────

class _AppStoreRefreshButton extends StatefulWidget {
  const _AppStoreRefreshButton();

  @override
  State<_AppStoreRefreshButton> createState() => _AppStoreRefreshButtonState();
}

class _AppStoreRefreshButtonState extends State<_AppStoreRefreshButton> {
  bool _loading = false;

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('dashboard_metrics')
          .doc('appstore')
          .collection('refresh_triggers')
          .add({'created_at': FieldValue.serverTimestamp()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualización en curso (~60s)'),
            backgroundColor: AppColors.ink,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al solicitar actualización'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Actualizar métricas App Store',
      child: InkWell(
        onTap: _refresh,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.pink,
                  ),
                )
              : const Icon(
                  FluentIcons.arrow_sync_20_regular,
                  size: 18,
                  color: AppColors.pink,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON — RevenueCat
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueCatRefreshButton extends StatefulWidget {
  const _RevenueCatRefreshButton();

  @override
  State<_RevenueCatRefreshButton> createState() =>
      _RevenueCatRefreshButtonState();
}

class _RevenueCatRefreshButtonState extends State<_RevenueCatRefreshButton> {
  bool _loading = false;

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await RevenueCatMetricsService.requestRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualización de RevenueCat en curso'),
            backgroundColor: AppColors.ink,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al solicitar actualización de RevenueCat'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Actualizar métricas RevenueCat',
      child: InkWell(
        onTap: _refresh,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.success,
                  ),
                )
              : const Icon(
                  FluentIcons.arrow_sync_20_regular,
                  size: 18,
                  color: AppColors.success,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS INTERNOS (sin cambios)
// ─────────────────────────────────────────────────────────────────────────────

class TrendMetricPanel extends StatelessWidget {
  const TrendMetricPanel({
    super.key,
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaType,
    required this.barColor,
    required this.bars,
  });

  final String title;
  final String value;
  final String delta;
  final BadgeType deltaType;
  final Color barColor;
  final List<double> bars;

  @override
  Widget build(BuildContext context) {
    const labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Hoy'];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.8,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              DashBadge(text: delta, type: deltaType),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: bars[i],
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: barColor.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          labels[i],
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != bars.length - 1) const SizedBox(width: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlanDistributionBar extends StatelessWidget {
  const PlanDistributionBar({super.key, required this.proportion});
  final double proportion;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Container(
            width: size.width * (1 - proportion),
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          FractionallySizedBox(
            widthFactor: proportion.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.goldGradStart, AppColors.goldGradEnd],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlanRow extends StatelessWidget {
  const PlanRow({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.percentage,
  });

  final Widget icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String value;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(color: iconColor, size: 26),
            child: icon,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  TextSpan(
                    text: ' · $subtitle',
                    style: const TextStyle(fontSize: 20, color: AppColors.ink3),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 22),
        SizedBox(
          width: 82,
          child: Text(
            percentage,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 20, color: AppColors.ink2),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TENDENCIAS — GRÁFICA DE DESCARGAS INTERACTIVA (fl_chart)
// ─────────────────────────────────────────────────────────────────────────────

enum _TrendRange { d7, d30, d90, ytd, all }

extension _TrendRangeX on _TrendRange {
  String get label => switch (this) {
    _TrendRange.d7 => 'Últimos 7 días',
    _TrendRange.d30 => 'Últimos 30 días',
    _TrendRange.d90 => 'Últimos 90 días',
    _TrendRange.ytd => 'Inicio de año',
    _TrendRange.all => 'Todo',
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _BarPoint {
  const _BarPoint(this.label, this.downloads);
  final String label;
  final int downloads;
}

List<_BarPoint> _aggregateDownloads(
  List<AppStoreDailyPoint> series,
  _TrendRange range,
) {
  const months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  final now = DateTime.now();

  DateTime? since;
  switch (range) {
    case _TrendRange.d7:
      since = now.subtract(const Duration(days: 7));
    case _TrendRange.d30:
      since = now.subtract(const Duration(days: 30));
    case _TrendRange.d90:
      since = now.subtract(const Duration(days: 90));
    case _TrendRange.ytd:
      since = DateTime(now.year);
    case _TrendRange.all:
      since = null;
  }

  final effectiveSince = since;
  final filtered = series.where((p) {
    if (effectiveSince == null) return true;
    try {
      return !DateTime.parse(p.date).isBefore(effectiveSince);
    } catch (_) {
      return false;
    }
  }).toList();

  if (filtered.isEmpty) return [];

  // d7: barras diarias individuales
  if (range == _TrendRange.d7) {
    return filtered.map((p) {
      final d = DateTime.tryParse(p.date);
      final label = d != null ? '${d.day} ${months[d.month - 1]}' : p.date;
      return _BarPoint(label, p.downloads);
    }).toList();
  }

  // Resto: agrupar por mes calendario
  final monthMap = <String, int>{};
  for (final p in filtered) {
    final d = DateTime.tryParse(p.date);
    if (d == null) continue;
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    monthMap[key] = (monthMap[key] ?? 0) + p.downloads;
  }
  final keys = monthMap.keys.toList()..sort();
  return keys.map((k) {
    final m = int.tryParse(k.split('-')[1]);
    return _BarPoint(m != null ? months[m - 1] : k, monthMap[k]!);
  }).toList();
}

(String, bool)? _computeDelta(List<_BarPoint> points) {
  if (points.length < 2) return null;
  final half = points.length ~/ 2;
  final first = points.sublist(0, half).fold(0, (s, p) => s + p.downloads);
  final second = points.sublist(half).fold(0, (s, p) => s + p.downloads);
  if (first == 0) return null;
  final pct = ((second - first) / first * 100).round();
  return (pct >= 0 ? '↑ $pct%' : '↓ ${pct.abs()}%', pct >= 0);
}

double _niceInterval(double maxVal, int steps) {
  if (maxVal <= 0) return 10;
  final raw = maxVal / steps;
  final exp = (math.log(raw) / math.ln10).floor();
  final power = math.pow(10, exp).toDouble();
  for (final f in [1.0, 2.0, 5.0, 10.0]) {
    if (f * power >= raw) return f * power;
  }
  return power * 10;
}

String _fmtNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

// ── Widget principal ──────────────────────────────────────────────────────────

class _DownloadsTrendCard extends StatefulWidget {
  const _DownloadsTrendCard({required this.appStore});
  final AppStoreMetrics? appStore;

  @override
  State<_DownloadsTrendCard> createState() => _DownloadsTrendCardState();
}

class _DownloadsTrendCardState extends State<_DownloadsTrendCard> {
  _TrendRange _range = _TrendRange.all;
  int? _touchedIndex;
  OverlayEntry? _overlay;
  final _pickerKey = GlobalKey();

  void _togglePicker() {
    if (_overlay != null) {
      _closeOverlay();
      return;
    }
    final box = _pickerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final sz = box.size;

    _overlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeOverlay,
            ),
          ),
          Positioned(
            left: pos.dx,
            top: pos.dy + sz.height + 6,
            child: _RangeMenu(
              selected: _range,
              onSelect: (r) {
                setState(() {
                  _range = r;
                  _touchedIndex = null;
                });
                _closeOverlay();
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.appStore?.timeSeries ?? [];
    final points = _aggregateDownloads(series, _range);
    final total = points.fold(0, (s, p) => s + p.downloads);
    final display = total > 0
        ? _fmtNum(total)
        : (widget.appStore?.downloadsStr ?? '—');
    final delta = _computeDelta(points);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ─────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.pink,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Descargas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink2,
                  ),
                ),
              ),
              GestureDetector(
                key: _pickerKey,
                onTap: _togglePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fieldBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _range.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.ink3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Valor + delta ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                display,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.6,
                  height: 1,
                  color: AppColors.ink,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: DashBadge(
                    text: delta.$1,
                    type: delta.$2 ? BadgeType.positive : BadgeType.negative,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          // ── Gráfica ──────────────────────────────────────────
          SizedBox(
            height: 210,
            child: points.isEmpty
                ? const EmptyTablesComponent(title: 'Sin datos disponibles aún')
                : _buildChart(points),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<_BarPoint> points) {
    final maxVal = points.map((p) => p.downloads).fold(0, math.max).toDouble();
    final interval = _niceInterval(maxVal, 4);
    final chartMax = interval * 5;
    final barW = points.length <= 7
        ? 28.0
        : points.length <= 12
        ? 18.0
        : 12.0;

    return BarChart(
      BarChartData(
        maxY: chartMax,
        barGroups: [
          for (int i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].downloads.toDouble(),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _touchedIndex == i
                        ? [AppColors.pinkDark, AppColors.pink]
                        : [AppColors.pink, AppColors.pinkLight],
                  ),
                  width: barW,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.line, strokeWidth: 1),
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
              reservedSize: 46,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _fmtNum(value.toInt()),
                    style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final step = points.length > 12
                    ? 3
                    : points.length > 7
                    ? 2
                    : 1;
                if (i % step != 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    points[i].label,
                    style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            setState(() {
              _touchedIndex = response?.spot?.touchedBarGroupIndex;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${points[group.x].label}\n',
              const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text: _fmtNum(rod.toY.toInt()),
                  style: const TextStyle(
                    color: AppColors.pinkLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRÁFICA DE REVENUE INTERACTIVA (fl_chart)
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueBarPoint {
  const _RevenueBarPoint(this.label, this.revenue);
  final String label;
  final double revenue;
}

DateRange _trendRangeToDateRange(_TrendRange r) => switch (r) {
      _TrendRange.d7  => DateRange.d7,
      _TrendRange.d30 => DateRange.d30,
      _TrendRange.d90 => DateRange.d90,
      _TrendRange.ytd => DateRange.all,
      _TrendRange.all => DateRange.all,
    };

List<_RevenueBarPoint> _aggregateRevenue(List<RevenueCatDailyPoint> series) {
  const months = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  if (series.isEmpty) return [];

  final monthMap = <String, double>{};
  for (final p in series) {
    final d = DateTime.tryParse(p.date);
    if (d == null) continue;
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    monthMap[key] = (monthMap[key] ?? 0) + p.revenue;
  }
  final keys = monthMap.keys.toList()..sort();
  return keys.map((k) {
    final m = int.tryParse(k.split('-')[1]);
    return _RevenueBarPoint(m != null ? months[m - 1] : k, monthMap[k]!);
  }).toList();
}

(String, bool)? _computeRevenueDelta(List<_RevenueBarPoint> points) {
  if (points.length < 2) return null;
  final half = points.length ~/ 2;
  final first  = points.sublist(0, half).fold(0.0, (s, p) => s + p.revenue);
  final second = points.sublist(half).fold(0.0, (s, p) => s + p.revenue);
  if (first == 0) return null;
  final pct = ((second - first) / first * 100).round();
  return (pct >= 0 ? '↑ $pct%' : '↓ ${pct.abs()}%', pct >= 0);
}

String _fmtRevenue(double v) {
  if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}K';
  return '\$${v.toStringAsFixed(0)}';
}

class _RevenueTrendCard extends StatefulWidget {
  const _RevenueTrendCard({required this.revenueCat});
  final RevenueCatMetrics? revenueCat;

  @override
  State<_RevenueTrendCard> createState() => _RevenueTrendCardState();
}

class _RevenueTrendCardState extends State<_RevenueTrendCard> {
  static const _ranges = [
    _TrendRange.d7,
    _TrendRange.d30,
    _TrendRange.d90,
    _TrendRange.all,
  ];

  _TrendRange _range = _TrendRange.all;
  int? _touchedIndex;
  OverlayEntry? _overlay;
  final _pickerKey = GlobalKey();

  void _togglePicker() {
    if (_overlay != null) { _closeOverlay(); return; }
    final box = _pickerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final sz  = box.size;

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeOverlay,
            ),
          ),
          Positioned(
            left: pos.dx,
            top: pos.dy + sz.height + 6,
            child: _RevenueRangeMenu(
              ranges: _ranges,
              selected: _range,
              onSelect: (r) {
                setState(() { _range = r; _touchedIndex = null; });
                _closeOverlay();
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() { _closeOverlay(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rc        = widget.revenueCat;
    final dateRange = _trendRangeToDateRange(_range);
    final rangeData = rc?.range(dateRange);
    final series    = rangeData?.timeSeries ?? [];
    final points    = _aggregateRevenue(series);
    final total     = points.fold(0.0, (s, p) => s + p.revenue);
    final display   = total > 0
        ? _fmtRevenue(total)
        : (rangeData?.revenueLabel ?? '—');
    final delta = _computeRevenueDelta(points);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.chartGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Revenue',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink2,
                  ),
                ),
              ),
              GestureDetector(
                key: _pickerKey,
                onTap: _togglePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.fieldBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _range.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.ink3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                display,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.6,
                  height: 1,
                  color: AppColors.ink,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: DashBadge(
                    text: delta.$1,
                    type: delta.$2 ? BadgeType.positive : BadgeType.negative,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 210,
            child: points.isEmpty
                ? const EmptyTablesComponent(title: 'Sin datos disponibles aún')
                : _buildRevenueChart(points),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<_RevenueBarPoint> points) {
    final maxVal  = points.map((p) => p.revenue).fold(0.0, (a, b) => a > b ? a : b);
    final interval = _niceInterval(maxVal, 4);
    final chartMax = interval * 5;
    final barW = points.length <= 7 ? 28.0 : points.length <= 12 ? 18.0 : 12.0;

    return BarChart(
      BarChartData(
        maxY: chartMax,
        barGroups: [
          for (int i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].revenue,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _touchedIndex == i
                        ? [AppColors.success, AppColors.chartGreen]
                        : [AppColors.chartGreen, AppColors.liveGreen],
                  ),
                  width: barW,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.line, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _fmtRevenue(value),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.ink3),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                final step =
                    points.length > 12 ? 3 : points.length > 7 ? 2 : 1;
                if (i % step != 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    points[i].label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.ink3),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            setState(() {
              _touchedIndex = response?.spot?.touchedBarGroupIndex;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${points[group.x].label}\n',
              const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text: _fmtRevenue(rod.toY),
                  style: const TextStyle(
                    color: AppColors.liveGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevenueRangeMenu extends StatelessWidget {
  const _RevenueRangeMenu({
    required this.ranges,
    required this.selected,
    required this.onSelect,
  });
  final List<_TrendRange> ranges;
  final _TrendRange selected;
  final void Function(_TrendRange) onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(14),
      color: AppColors.white,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ranges
              .map(
                (r) => InkWell(
                  onTap: () => onSelect(r),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: r == selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: r == selected
                                  ? AppColors.chartGreen
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                        if (r == selected)
                          const Icon(Icons.check_rounded,
                              size: 16, color: AppColors.chartGreen),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ── Menú de rangos (descargas) ────────────────────────────────────────────────

class _RangeMenu extends StatelessWidget {
  const _RangeMenu({required this.selected, required this.onSelect});
  final _TrendRange selected;
  final void Function(_TrendRange) onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(14),
      color: AppColors.white,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _TrendRange.values
              .map(
                (r) => InkWell(
                  onTap: () => onSelect(r),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: r == selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: r == selected
                                  ? AppColors.pink
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                        if (r == selected)
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.pink,
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ── Widgets de distribución por país ─────────────────────────────────────────

class _CountryEntryRow extends StatelessWidget {
  const _CountryEntryRow({required this.entry});

  final CountryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(entry.flag, style: const TextStyle(fontSize: 30)),
        ),
        Expanded(
          child: Text(
            entry.name,
            style: const TextStyle(
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: entry.fraction,
              minHeight: 14,
              backgroundColor: AppColors.progressBg,
              valueColor: const AlwaysStoppedAnimation(AppColors.progressFill),
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 42,
          child: Text(
            '${entry.count}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 56,
          child: Text(
            entry.percent,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.ink2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryShimmer extends StatelessWidget {
  const _CountryShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) => Padding(
        padding: EdgeInsets.only(bottom: i < 3 ? 18 : 0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: 42,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
