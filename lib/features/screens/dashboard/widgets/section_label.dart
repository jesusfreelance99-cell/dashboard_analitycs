import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SectionLabel extends StatelessWidget {
  final String title;
  final String? source;

  const SectionLabel({super.key, required this.title, this.source});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: const Color(0x12000000)),
          ),
          if (source != null) ...[
            const SizedBox(width: 12),
            Text(
              source!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.ink3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
