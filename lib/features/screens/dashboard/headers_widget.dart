import 'package:dashboard_analitycs/core/constants/app_colors.dart';

import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'shared_widgets.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({
    super.key,
    required this.isMobile,
    required this.title,
    required this.subtitle,
  });

  final bool isMobile;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 26,
        8,
        isMobile ? 16 : 26,
        0,
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(FluentIcons.navigation_20_regular),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 15, color: AppColors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DateToolbar extends StatelessWidget {
  const DateToolbar({
    required this.range,
    required this.isCompact,
    required this.onRangeChanged,
  });

  final DateRange range;
  final bool isCompact;
  final ValueChanged<DateRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final rangeInfo = rangePresentation(range);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 26,
        18,
        isCompact ? 16 : 26,
        0,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 14,
        spacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.calendar_ltr_20_regular,
                size: 22,
                color: AppColors.ink3,
              ),
              const SizedBox(width: 12),
              const Text(
                'Periodo: ',
                style: TextStyle(fontSize: 16, color: AppColors.ink2),
              ),
              Text(
                rangeInfo.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                ' · ${rangeInfo.dates}',
                style: const TextStyle(fontSize: 16, color: AppColors.ink3),
              ),
            ],
          ),
          RangeSegmentedControl(range: range, onChanged: onRangeChanged),
        ],
      ),
    );
  }
}
