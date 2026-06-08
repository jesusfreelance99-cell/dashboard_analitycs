import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/models/appstore_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/revenuecat_metrics_model.dart';
import 'package:dashboard_analitycs/core/services/appstore_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/revenuecat_metrics_service.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
              Color(0xFFE8E8E6),
              Color(0xFFF5F5F3),
              Color(0xFFFFFFFF),
              Color(0xFFF5F5F3),
              Color(0xFFE8E8E6),
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
        color: const Color(0xFFE8E8E6),
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
                color: const Color(0xFFE8E8E6),
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
                color: const Color(0xFFE8E8E6),
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
                color: const Color(0xFFE8E8E6),
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
                    color: const Color(0xFFE8E8E6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E6),
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

  @override
  Widget build(BuildContext context) {
    final data = overviewRangeData(range);
    final as = appStore;
    final rc = revenueCat;
    final rcRange = rc?.range(range);
    final rcOverview = rc?.overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buenas noches, Jesús 👋',
          style: TextStyle(
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
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.clock_20_regular,
                        size: 14,
                        color: Color(0xFF856404),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Actualizando',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF856404),
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
                        color: Color(0xFFF5A524),
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
        ResponsiveGrid(
          minTileWidth: 250,
          children: [
            MetricCard(
              label: 'Registrados',
              value: data.users,
              badgeText: '↑ 3',
              badgeType: BadgeType.positive,
              helperText: 'hoy',
            ),
            MetricCard(
              label: 'Plan Pro',
              value: '${data.proUsers}',
              accent: true,
              valueSuffix: const FaIcon(
                FontAwesomeIcons.crown,
                color: Color(0xFFF0AB21),
                size: 24,
              ),
              badgeText:
                  '${(data.proUsers / 40 * 100).toStringAsFixed(1)}% del total',
              badgeType: BadgeType.neutral,
            ),
            MetricCard(
              label: 'Plan Gratuito',
              value: '${40 - data.proUsers}',
              badgeText:
                  '${(((40 - data.proUsers) / 40) * 100).toStringAsFixed(1)}% del total',
              badgeType: BadgeType.neutral,
            ),
            MetricCard(
              label: 'Activos',
              value: data.activeUsers,
              badgeText: '↑ 92.5%',
              badgeType: BadgeType.positive,
            ),
          ],
        ),
        const SizedBox(height: 34),

        // ── TENDENCIAS ───────────────────────────────────────────────────
        const SectionHeader(label: 'TENDENCIAS', source: ''),
        const SizedBox(height: 14),
        ResponsiveSplit(
          left: TrendMetricPanel(
            title: 'Descargas',
            value: as?.downloadsStr ?? data.downloads,
            delta: '↑ 23%',
            deltaType: BadgeType.positive,
            barColor: const Color(0xFFEF2F71),
            bars: data.downloadBars,
          ),
          right: TrendMetricPanel(
            title: 'Revenue',
            value: rcRange?.revenueLabel ?? data.revenue,
            delta: '↑ 18%',
            deltaType: BadgeType.positive,
            barColor: const Color(0xFF20BB68),
            bars: rcRange?.revenueBars ?? data.revenueBars,
          ),
        ),
        const SizedBox(height: 40),

        // ── DISTRIBUCIÓN ─────────────────────────────────────────────────
        const SectionHeader(label: 'DISTRIBUCIÓN', source: ''),
        const SizedBox(height: 14),
        ResponsiveSplit(
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelHeader(
                  title: 'Registros por país',
                  trailing: 'Top 4',
                ),
                const SizedBox(height: 18),
                for (final country in data.downloadCountries) ...[
                  CountryRow(data: country),
                  if (country != data.downloadCountries.last)
                    const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          right: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelHeader(
                  title: 'Distribución por plan',
                  trailing: '40 usuarios',
                ),
                const SizedBox(height: 28),
                PlanDistributionBar(proportion: data.proUsers / 40),
                const SizedBox(height: 28),
                PlanRow(
                  icon: const FaIcon(FontAwesomeIcons.crown, size: 24),
                  iconBackground: const Color(0xFFFFD760),
                  iconColor: const Color(0xFF8A6300),
                  title: 'Plan Pro',
                  subtitle: 'de pago',
                  value: '${data.proUsers}',
                  percentage:
                      '${(data.proUsers / 40 * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 26),
                PlanRow(
                  icon: const Icon(FluentIcons.gift_20_regular, size: 24),
                  iconBackground: const Color(0xFFF1F1EF),
                  iconColor: AppColors.ink3,
                  title: 'Plan Gratuito',
                  value: '${40 - data.proUsers}',
                  percentage:
                      '${(((40 - data.proUsers) / 40) * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
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
                  color: const Color(0xFFE8E8E6),
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
            backgroundColor: Color(0xFFD32F2F),
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
            backgroundColor: Color(0xFFD32F2F),
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
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: FractionallySizedBox(
        widthFactor: proportion.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFC61F), Color(0xFFF3B100)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
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
