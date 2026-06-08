import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyTablesComponent extends StatelessWidget {
  const EmptyTablesComponent({
    super.key,
    required this.title,
    this.image,
    this.description,
  });

  final String title;
  final Widget? image;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svgAsset = isDark
        ? 'assets/svg/dark_empty_tables.svg'
        : 'assets/svg/empty_tables.svg';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            image ?? SvgPicture.asset(svgAsset, width: 160, height: 160),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.dc.ink,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                style: TextStyle(fontSize: 14, color: context.dc.ink2),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
