import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

// ─── Right Panel ──────────────────────────────────────────────────────────────

class LoginRightPanel extends StatelessWidget {
  const LoginRightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: AppColors.brandGradient,
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -80,
            right: -80,
            child: _DecorBlob(size: 300, opacity: 0.07),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: _DecorBlob(size: 380, opacity: 0.04),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.loginPanelPaddingH,
              vertical: AppConstants.loginPanelPaddingV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LiveBadge(),
                const SizedBox(height: 28),
                _RightHeading(),
                const SizedBox(height: 16),
                _RightSubtext(),
                const SizedBox(height: 36),
                const Expanded(child: PanelCards()),
                const SizedBox(height: 20),
                const PanelFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorBlob extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorBlob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _RightHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          height: 1.18,
          letterSpacing: -1.0,
        ),
        children: const [
          TextSpan(text: 'Cada peso y cada\nusuario, '),
          TextSpan(
            text: 'en tiempo real.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _RightSubtext extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Embudo, retención, CAC y revenue de tu app en un solo panel. '
      'Toma decisiones con datos, no con corazonadas.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.white.withValues(alpha: 0.65),
        height: 1.6,
      ),
    );
  }
}

// ─── Live Badge ───────────────────────────────────────────────────────────────

class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Opacity(
              opacity: _pulse.value,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.liveGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'EN VIVO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel Cards ──────────────────────────────────────────────────────────────

class PanelCards extends StatefulWidget {
  const PanelCards({super.key});

  @override
  State<PanelCards> createState() => _PanelCardsState();
}

class _PanelCardsState extends State<PanelCards> with TickerProviderStateMixin {
  late AnimationController _c1, _c2, _c3, _c4;

  AnimationController _makeCtrl(int ms, int offsetMs) {
    final c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    Future.delayed(Duration(milliseconds: offsetMs), () {
      if (mounted) c.repeat(reverse: true);
    });
    return c;
  }

  @override
  void initState() {
    super.initState();
    _c1 = _makeCtrl(3800, 0);
    _c2 = _makeCtrl(4200, 600);
    _c3 = _makeCtrl(3600, 1200);
    _c4 = _makeCtrl(4400, 300);
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    _c4.dispose();
    super.dispose();
  }

  Widget _floatWrap(AnimationController ctrl, double dy, Widget child) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(ctrl.value);
        return Transform.translate(offset: Offset(0, -dy * t), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          width: w,
          height: constraints.maxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Vista general (main card) — left, center-top
              Positioned(
                left: 0,
                top: 20,
                child: _floatWrap(
                  _c1,
                  7,
                  _MetricCard(
                    width: w * 0.52,
                    label: 'Vista general',
                    metric: 'MRR · ingresos recurrentes',
                    value: '\$142',
                    change: '↑ \$31 esta semana',
                    positive: true,
                    showChart: true,
                  ),
                ),
              ),

              // Suscriptores — right, top
              Positioned(
                right: 0,
                top: 0,
                child: _floatWrap(_c2, 5, _SubsCard(width: w * 0.38)),
              ),

              // Nueva suscripción — left, bottom
              Positioned(
                left: 8,
                bottom: 8,
                child: _floatWrap(_c3, 4, _NotifCard(width: w * 0.54)),
              ),

              // Embudo — right, bottom
              Positioned(
                right: 0,
                bottom: 0,
                child: _floatWrap(_c4, 6, _FunnelCard(width: w * 0.42)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Card base ────────────────────────────────────────────────────────────────

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white.withValues(alpha: 0.97),
  borderRadius: BorderRadius.circular(AppConstants.radiusXl),
  border: Border.all(
    color: Colors.white.withValues(alpha: 0.55),
    width: 1,
  ),
);

// ─── MetricCard ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final double width;
  final String label;
  final String metric;
  final String value;
  final String change;
  final bool positive;
  final bool showChart;

  const _MetricCard({
    required this.width,
    required this.label,
    required this.metric,
    required this.value,
    required this.change,
    required this.positive,
    this.showChart = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pink,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2,
                ),
              ),
              const Spacer(),
              Text(
                'Últimos 30d',
                style: TextStyle(fontSize: 10, color: AppColors.ink3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric,
            style: const TextStyle(fontSize: 11, color: AppColors.ink3),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            change,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: positive ? AppColors.success : AppColors.danger,
            ),
          ),
          if (showChart) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: CustomPaint(
                size: const Size(double.infinity, 42),
                painter: _MiniChartPainter(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Data points (normalized 0–1 from bottom)
    final points = [
      0.15,
      0.20,
      0.18,
      0.28,
      0.25,
      0.40,
      0.38,
      0.52,
      0.50,
      0.68,
      0.65,
      0.80,
      0.85,
      0.95,
    ];
    final n = points.length;
    final step = w / (n - 1);

    List<Offset> pts = List.generate(
      n,
      (i) => Offset(i * step, h - points[i] * h),
    );

    // Fill
    final fillPath = Path();
    fillPath.moveTo(pts.first.dx, h);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      fillPath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    fillPath.lineTo(pts.last.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.pink.withValues(alpha: 0.20),
          AppColors.pink.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path();
    linePath.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── SubsCard ─────────────────────────────────────────────────────────────────

class _SubsCard extends StatefulWidget {
  final double width;
  const _SubsCard({required this.width});

  @override
  State<_SubsCard> createState() => _SubsCardState();
}

class _SubsCardState extends State<_SubsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Suscriptores',
                style: TextStyle(fontSize: 12, color: AppColors.ink2),
              ),
              const SizedBox(height: 4),
              const Text(
                '11',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '↑ 3 nuevos',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (_, __) => Transform.rotate(
                angle: _spin.value * 2 * math.pi,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CustomPaint(painter: _SpinnerPainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFEEEEEE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 0.75,
      false,
      Paint()
        ..color = AppColors.pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── NotifCard ────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final double width;
  const _NotifCard({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Nueva suscripción Pro',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sofía · Medellín · hace 2 min',
                  style: TextStyle(fontSize: 11, color: AppColors.ink3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FunnelCard ───────────────────────────────────────────────────────────────

class _FunnelCard extends StatelessWidget {
  final double width;
  const _FunnelCard({required this.width});

  @override
  Widget build(BuildContext context) {
    const bars = [
      _BarData(AppColors.chartGreen, 1.0),
      _BarData(AppColors.chartBlue, 0.82),
      _BarData(AppColors.chartPurple, 0.65),
      _BarData(AppColors.chartPink, 0.78),
      _BarData(AppColors.chartAmber, 0.50),
      _BarData(AppColors.chartRed, 0.38),
      _BarData(AppColors.chartGreen, 0.44),
    ];

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Embudo de conversión',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Descarga → suscripción · 7.2%',
            style: TextStyle(fontSize: 11, color: AppColors.ink3),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (b) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: _Bar(color: b.color, ratio: b.ratio),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final Color color;
  final double ratio;
  const _BarData(this.color, this.ratio);
}

class _Bar extends StatelessWidget {
  final Color color;
  final double ratio;
  const _Bar({required this.color, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.bottomCenter,
      heightFactor: ratio,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }
}

// ─── Panel Footer ─────────────────────────────────────────────────────────────

class PanelFooter extends StatelessWidget {
  const PanelFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          'Conectado con',
          style: style?.copyWith(color: Colors.white.withValues(alpha: 0.45)),
        ),
        Text(
          'RevenueCat',
          style: style?.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '·',
          style: style?.copyWith(color: Colors.white.withValues(alpha: 0.3)),
        ),
        Text(
          'Mixpanel',
          style: style?.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '·',
          style: style?.copyWith(color: Colors.white.withValues(alpha: 0.3)),
        ),
        Text(
          'Firebase',
          style: style?.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
