import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? elevation;

  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.elevation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? AppConstants.elevationMd,
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppConstants.spacingMd),
          child: child,
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatCard({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (icon != null)
                Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
