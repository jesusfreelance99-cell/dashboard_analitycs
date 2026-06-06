import 'package:dashboard_analitycs/core/constants/app_colors.dart';

import 'package:flutter/material.dart';

import 'shared_widgets.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 720,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TrevoMark(size: 76),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                height: 1.45,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'EN EL SIGUIENTE PASO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: AppColors.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
