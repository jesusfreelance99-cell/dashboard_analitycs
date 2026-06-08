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

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final availH = h.isFinite ? h : 280.0;
        final compact = availH < 240;
        final vPad = compact ? 8.0 : 20.0;
        final showDesc = description != null && !compact;

        // Reserve space for: padding (x2) + spacing + title + optional description
        final reserved = vPad * 2 + 10.0 + 22.0 + (showDesc ? 42.0 : 0.0);
        final maxImgH = compact ? 80.0 : 140.0;
        final imgH = (availH - reserved).clamp(0.0, maxImgH);
        final showImg = image != null || imgH > 20;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: vPad),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showImg) ...[
                  SizedBox(
                    child:
                        image ??
                        SvgPicture.asset(svgAsset, width: imgH, height: imgH),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: context.dc.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showDesc) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    style: TextStyle(fontSize: 13, color: context.dc.ink2),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
