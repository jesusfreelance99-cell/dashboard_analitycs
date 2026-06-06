import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum DeltaType { up, down, neutral }

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? deltaText;
  final DeltaType? deltaType;
  final String? note;
  final bool accent;
  final Widget? valueSuffix;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.deltaText,
    this.deltaType,
    this.note,
    this.accent = false,
    this.valueSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.pink.withValues(alpha: 0.045)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.ink2),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                  height: 1,
                ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: 6),
                valueSuffix!,
              ],
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 4,
            children: [
              if (deltaText != null)
                _DeltaBadge(text: deltaText!, type: deltaType ?? DeltaType.neutral),
              if (note != null)
                Text(
                  note!,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final String text;
  final DeltaType type;

  const _DeltaBadge({required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    Color fg, bg;
    switch (type) {
      case DeltaType.up:
        fg = const Color(0xFF1f9d57);
        bg = const Color(0xFF1f9d57).withValues(alpha: 0.11);
        break;
      case DeltaType.down:
        fg = const Color(0xFFd8584f);
        bg = const Color(0xFFd8584f).withValues(alpha: 0.11);
        break;
      case DeltaType.neutral:
        fg = AppColors.ink2;
        bg = const Color(0xFFf1f1ef);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
