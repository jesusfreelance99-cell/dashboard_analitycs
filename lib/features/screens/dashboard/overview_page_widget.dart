import 'package:dashboard_analitycs/core/constants/app_colors.dart';

import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'models.dart';
import 'shared_widgets.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.range, required this.isCompact});

  final DateRange range;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final data = overviewRangeData(range);
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
        const Text(
          'Esto es lo que está pasando en Trevo hoy.',
          style: TextStyle(fontSize: 18, color: AppColors.ink2),
        ),
        const SizedBox(height: 36),
        const SectionHeader(label: 'APP STORE CONNECT', source: 'iOS'),
        const SizedBox(height: 14),
        ResponsiveGrid(
          minTileWidth: 250,
          children: [
            MetricCard(
              label: 'Impresiones',
              value: data.impressions,
              badgeText: '↑ 18%',
              badgeType: BadgeType.positive,
              helperText: 'vs. anterior',
            ),
            MetricCard(
              label: 'Descargas',
              value: data.downloads,
              badgeText: '↑ 23%',
              badgeType: BadgeType.positive,
              helperText: 'vs. anterior',
            ),
            MetricCard(
              label: 'Conversión tienda',
              value: data.storeConversion,
              badgeText: '↓ 0.4pp',
              badgeType: BadgeType.negative,
              helperText: 'vs. anterior',
            ),
            const MetricCard(
              label: 'Rating',
              value: '4.6',
              valueSuffix: Icon(
                Icons.star_rounded,
                color: Color(0xFFF5A524),
                size: 26,
              ),
              badgeText: '38 reseñas',
              badgeType: BadgeType.neutral,
            ),
          ],
        ),
        const SizedBox(height: 42),
        const SectionHeader(label: 'REVENUE', source: 'RevenueCat'),
        const SizedBox(height: 14),
        ResponsiveGrid(
          minTileWidth: 250,
          children: [
            MetricCard(
              label: 'MRR',
              value: '\$142',
              accent: true,
              badgeText: '↑ \$31',
              badgeType: BadgeType.positive,
              helperText: 'esta semana',
            ),
            MetricCard(
              label: 'Revenue total',
              value: data.revenue,
              helperText: 'en el período',
            ),
            MetricCard(
              label: 'Suscriptores',
              value: data.subscribers,
              badgeText: '↑ 3',
              badgeType: BadgeType.positive,
              helperText: 'nuevos',
            ),
            MetricCard(
              label: 'Trials activos',
              value: data.trials,
              badgeText: '↑ 8',
              badgeType: BadgeType.positive,
              helperText: 'hoy',
            ),
            MetricCard(
              label: 'Churn',
              value: data.churn,
              badgeText: 'este mes',
              badgeType: BadgeType.neutral,
            ),
          ],
        ),
        const SizedBox(height: 42),
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
              valueSuffix: FaIcon(
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
        const SectionHeader(label: 'TENDENCIAS', source: ''),
        const SizedBox(height: 14),
        ResponsiveSplit(
          left: TrendMetricPanel(
            title: 'Descargas',
            value: data.downloads,
            delta: '↑ 23%',
            deltaType: BadgeType.positive,
            barColor: const Color(0xFFEF2F71),
            bars: data.downloadBars,
          ),
          right: TrendMetricPanel(
            title: 'Revenue',
            value: data.revenue,
            delta: '↑ 18%',
            deltaType: BadgeType.positive,
            barColor: const Color(0xFF20BB68),
            bars: data.revenueBars,
          ),
        ),
        const SizedBox(height: 40),
        const SectionHeader(label: 'DISTRIBUCIÓN', source: ''),
        const SizedBox(height: 14),
        ResponsiveSplit(
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelHeader(
                  title: 'Descargas por país',
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

class TrendMetricPanel extends StatelessWidget {
  const TrendMetricPanel({
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
  const PlanDistributionBar({required this.proportion});

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
        widthFactor: proportion.clamp(0, 1),
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
