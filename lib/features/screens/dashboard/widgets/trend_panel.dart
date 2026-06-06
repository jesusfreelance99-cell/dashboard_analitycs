import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TrendPanel extends StatelessWidget {
  final String label;
  final String value;
  final String deltaText;
  final bool deltaUp;
  final List<double> points; // normalized 0–1

  const TrendPanel({
    super.key,
    required this.label,
    required this.value,
    required this.deltaText,
    required this.deltaUp,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.ink2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: deltaUp
                      ? const Color(0xFF1f9d57).withValues(alpha: 0.11)
                      : const Color(0xFFd8584f).withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deltaText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: deltaUp
                        ? const Color(0xFF1f9d57)
                        : const Color(0xFFd8584f),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _TrendChartPainter(points: points),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> points;
  const _TrendChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final w = size.width;
    final h = size.height;
    final step = w / (points.length - 1);

    final pts = List.generate(
      points.length,
      (i) => Offset(i * step, h - points[i] * (h - 4) - 2),
    );

    // Fill
    final fillPath = Path()..moveTo(pts.first.dx, h);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    fillPath.lineTo(pts.last.dx, h);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.pink.withValues(alpha: 0.15),
            AppColors.pink.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Last point dot
    canvas.drawCircle(pts.last, 4, Paint()..color = AppColors.pink);
    canvas.drawCircle(pts.last, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) => old.points != points;
}

// Utility: generate fake trend data
List<double> trendData(int length, {double start = 0.15, double end = 0.85}) {
  final rand = math.Random(42);
  final result = <double>[];
  double v = start;
  for (int i = 0; i < length; i++) {
    final progress = i / (length - 1);
    final target = start + (end - start) * progress;
    v = v * 0.7 + target * 0.3 + (rand.nextDouble() - 0.5) * 0.1;
    v = v.clamp(0.0, 1.0);
    result.add(v);
  }
  return result;
}
