import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

RangePresentation rangePresentation(DateRange range) {
  switch (range) {
    case DateRange.d7:
      return const RangePresentation(
        'últimos 7 días',
        '29 may 2026 – 5 jun 2026',
      );
    case DateRange.d30:
      return const RangePresentation(
        'últimos 30 días',
        '6 may 2026 – 5 jun 2026',
      );
    case DateRange.d90:
      return const RangePresentation(
        'últimos 90 días',
        '7 mar 2026 – 5 jun 2026',
      );
    case DateRange.all:
      return const RangePresentation('todo', '1 ene 2026 – 5 jun 2026');
  }
}

OverviewRangeData overviewRangeData(DateRange range) {
  switch (range) {
    case DateRange.d7:
      return const OverviewRangeData(
        impressions: '3,100',
        downloads: '61',
        storeConversion: '1.9%',
        revenue: '\$48',
        subscribers: '3',
        trials: '8',
        churn: '0%',
        users: '40',
        activeUsers: '37',
        proUsers: 11,
        downloadBars: [78, 132, 138, 174, 28],
        revenueBars: [66, 124, 148, 102, 34],
        downloadCountries: [
          CountryData('Colombia', '🇨🇴', 56, '91.8%', 0.92),
          CountryData('México', '🇲🇽', 2, '3.3%', 0.10),
          CountryData('Estados Unidos', '🇺🇸', 2, '3.3%', 0.10),
          CountryData('Otros', '🌐', 1, '1.6%', 0.06),
        ],
      );
    case DateRange.d30:
      return const OverviewRangeData(
        impressions: '12,400',
        downloads: '284',
        storeConversion: '2.3%',
        revenue: '\$198',
        subscribers: '11',
        trials: '23',
        churn: '9%',
        users: '40',
        activeUsers: '37',
        proUsers: 11,
        downloadBars: [84, 132, 138, 168, 26],
        revenueBars: [58, 126, 148, 110, 28],
        downloadCountries: [
          CountryData('Colombia', '🇨🇴', 261, '91.9%', 0.92),
          CountryData('México', '🇲🇽', 11, '3.9%', 0.12),
          CountryData('Estados Unidos', '🇺🇸', 7, '2.5%', 0.09),
          CountryData('Otros', '🌐', 5, '1.8%', 0.07),
        ],
      );
    case DateRange.d90:
      return const OverviewRangeData(
        impressions: '28,000',
        downloads: '610',
        storeConversion: '2.2%',
        revenue: '\$420',
        subscribers: '11',
        trials: '31',
        churn: '12%',
        users: '40',
        activeUsers: '37',
        proUsers: 11,
        downloadBars: [92, 138, 154, 178, 40],
        revenueBars: [74, 144, 166, 124, 38],
        downloadCountries: [
          CountryData('Colombia', '🇨🇴', 560, '91.8%', 0.92),
          CountryData('México', '🇲🇽', 24, '3.9%', 0.12),
          CountryData('Estados Unidos', '🇺🇸', 15, '2.5%', 0.09),
          CountryData('Otros', '🌐', 11, '1.8%', 0.07),
        ],
      );
    case DateRange.all:
      return const OverviewRangeData(
        impressions: '28,000',
        downloads: '610',
        storeConversion: '2.2%',
        revenue: '\$420',
        subscribers: '11',
        trials: '31',
        churn: '12%',
        users: '40',
        activeUsers: '37',
        proUsers: 11,
        downloadBars: [92, 138, 154, 178, 40],
        revenueBars: [74, 144, 166, 124, 38],
        downloadCountries: [
          CountryData('Colombia', '🇨🇴', 560, '91.8%', 0.92),
          CountryData('México', '🇲🇽', 24, '3.9%', 0.12),
          CountryData('Estados Unidos', '🇺🇸', 15, '2.5%', 0.09),
          CountryData('Otros', '🌐', 11, '1.8%', 0.07),
        ],
      );
  }
}

class RangePresentation {
  const RangePresentation(this.label, this.dates);

  final String label;
  final String dates;
}

class OverviewRangeData {
  const OverviewRangeData({
    required this.impressions,
    required this.downloads,
    required this.storeConversion,
    required this.revenue,
    required this.subscribers,
    required this.trials,
    required this.churn,
    required this.users,
    required this.activeUsers,
    required this.proUsers,
    required this.downloadBars,
    required this.revenueBars,
    required this.downloadCountries,
  });

  final String impressions;
  final String downloads;
  final String storeConversion;
  final String revenue;
  final String subscribers;
  final String trials;
  final String churn;
  final String users;
  final String activeUsers;
  final int proUsers;
  final List<double> downloadBars;
  final List<double> revenueBars;
  final List<CountryData> downloadCountries;
}

class PageMeta {
  const PageMeta({
    required this.title,
    required this.subtitle,
    required this.navLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String navLabel;
  final IconData icon;
}

PageMeta pageMeta(DashPage page) {
  switch (page) {
    case DashPage.overview:
      return const PageMeta(
        title: 'Vista general',
        subtitle: 'Resumen ejecutivo del crecimiento de Trevo',
        navLabel: 'Vista general',
        icon: FluentIcons.grid_20_regular,
      );
    case DashPage.funnel:
      return const PageMeta(
        title: 'Embudo de onboarding',
        subtitle: 'Del primer open hasta la suscripción',
        navLabel: 'Embudo',
        icon: FluentIcons.filter_20_regular,
      );
    case DashPage.cac:
      return const PageMeta(
        title: 'CAC / LTV',
        subtitle: 'Costo de adquisición y valor por cliente',
        navLabel: 'CAC / LTV',
        icon: FluentIcons.money_20_regular,
      );
    case DashPage.features:
      return const PageMeta(
        title: 'Uso de features',
        subtitle: 'Qué funciones usan tus usuarios',
        navLabel: 'Features',
        icon: FluentIcons.flash_20_regular,
      );
    case DashPage.retention:
      return const PageMeta(
        title: 'Retención',
        subtitle: 'Cuántos usuarios vuelven a abrir la app',
        navLabel: 'Retención',
        icon: FluentIcons.arrow_trending_lines_20_regular,
      );
    case DashPage.users:
      return const PageMeta(
        title: 'Usuarios',
        subtitle: 'Tabla completa de usuarios registrados',
        navLabel: 'Usuarios',
        icon: FluentIcons.people_20_regular,
      );
    case DashPage.notifications:
      return const PageMeta(
        title: 'Notificaciones',
        subtitle: 'Envía mensajes push a tus usuarios',
        navLabel: 'Notificaciones',
        icon: FluentIcons.alert_20_regular,
      );
  }
}

enum BadgeType { positive, negative, neutral }

enum RecipientMode { all, segment }

enum PreviewSendMode { now, scheduled }

class CountryData {
  const CountryData(
    this.name,
    this.flag,
    this.value,
    this.percent,
    this.progress,
  );

  final String name;
  final String flag;
  final int value;
  final String percent;
  final double progress;
}

class SidebarSectionData {
  const SidebarSectionData({required this.title, required this.items});

  final String title;
  final List<DashPage> items;
}
