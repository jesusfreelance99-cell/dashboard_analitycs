import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';

class BadgeWidget extends StatelessWidget {
  const BadgeWidget({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.pink,
    this.textColor = Colors.white,
    this.size = BadgeSize.medium,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _getFontSize(),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      BadgeSize.small => const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
      BadgeSize.medium => const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
      BadgeSize.large => const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
    };
  }

  double _getFontSize() {
    return switch (size) {
      BadgeSize.small => 12,
      BadgeSize.medium => 14,
      BadgeSize.large => 16,
    };
  }
}

enum BadgeSize { small, medium, large }
