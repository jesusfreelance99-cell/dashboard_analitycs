import 'dart:math' as math;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/app_constants.dart';
import 'package:dashboard_analitycs/core/providers/theme_provider.dart';
import 'package:dashboard_analitycs/core/routes/app_routes.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'shared_widgets.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    const countries = [
      CountryData('Colombia', '🇨🇴', 37, '92.5%', 0.93),
      CountryData('México', '🇲🇽', 1, '2.5%', 0.08),
      CountryData('Estados Unidos', '🇺🇸', 1, '2.5%', 0.08),
      CountryData('Otros', '🌐', 1, '2.5%', 0.08),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Usuarios',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Todos los usuarios registrados en Trevo.',
          style: TextStyle(fontSize: 18, color: AppColors.ink2),
        ),
        const SizedBox(height: 36),
        ResponsiveGrid(
          minTileWidth: 220,
          children: const [
            MetricCard(
              label: 'Total registrados',
              value: '40',
              badgeText: '↑ 3',
              badgeType: BadgeType.positive,
              helperText: 'hoy',
            ),
            MetricCard(
              label: 'Plan Pro',
              value: '11',
              accent: true,
              valueSuffix: FaIcon(
                FontAwesomeIcons.crown,
                color: Color(0xFFF0AB21),
                size: 24,
              ),
              badgeText: '27.5% del total',
              badgeType: BadgeType.neutral,
            ),
            MetricCard(
              label: 'Plan Gratuito',
              value: '29',
              badgeText: '72.5% del total',
              badgeType: BadgeType.neutral,
            ),
            MetricCard(
              label: 'Activos',
              value: '37',
              badgeText: '↑ 92.5%',
              badgeType: BadgeType.positive,
            ),
          ],
        ),
        const SizedBox(height: 18),
        ResponsiveSplit(
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                PanelHeader(
                  title: 'Usuarios por ubicación',
                  trailing: 'Américas',
                ),
                SizedBox(height: 18),
                MapPlaceholder(),
              ],
            ),
          ),
          right: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelHeader(title: 'Por país', trailing: 'Top 4'),
                const SizedBox(height: 14),
                for (final country in countries) ...[
                  CountryRow(data: country),
                  if (country != countries.last) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1040;
            return Flex(
              direction: stacked ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: stacked ? 0 : 5,
                  child: SearchField(controller: searchController),
                ),
                SizedBox(width: stacked ? 0 : 18, height: stacked ? 18 : 0),
                Expanded(
                  flex: stacked ? 0 : 3,
                  child: FilterSegment(
                    items: const ['Todos', 'Activos', 'Inactivos'],
                    selectedIndex: 0,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const UsersTablePlaceholder(),
      ],
    );
  }
}

