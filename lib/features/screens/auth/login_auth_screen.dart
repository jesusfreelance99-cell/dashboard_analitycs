import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import 'login_screen_provider.dart';

// ─── Logo ─────────────────────────────────────────────────────────────────────

class TrevoLogo extends StatelessWidget {
  const TrevoLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pink blob shape
        SizedBox(
          width: 34,
          height: 34,
          child: CustomPaint(painter: _BlobPainter()),
        ),
        const SizedBox(width: 10),
        Text(
          'trevo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.pink;
    final path = Path();
    // Organic blob: circle with slight deformation
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    path.moveTo(cx, cy - r);
    path.cubicTo(cx + r * 1.1, cy - r, cx + r * 1.1, cy + r * 0.6, cx, cy + r);
    path.cubicTo(
      cx - r * 0.8,
      cy + r,
      cx - r * 1.0,
      cy + r * 0.2,
      cx - r,
      cy - r * 0.2,
    );
    path.cubicTo(cx - r, cy - r * 0.8, cx - r * 0.3, cy - r, cx, cy - r);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Form Header ──────────────────────────────────────────────────────────────

class LoginFormHeader extends StatelessWidget {
  const LoginFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PANEL DE CRECIMIENTO',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.pink,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Bienvenido de nuevo',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para ver cómo crece Trevo en tiempo real.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.ink2, height: 1.5),
        ),
      ],
    );
  }
}

// ─── Google Button ────────────────────────────────────────────────────────────

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.line2, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleIcon(),
            const SizedBox(width: 10),
            Text(
              'Continuar con Google',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    void drawArc(Color c, double start, double sweep, double r, Offset center) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sweep,
        false,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.18,
      );
    }

    // Simplified G in 4 colors
    final cx = s / 2;
    final cy = s / 2;
    final r = s * 0.42;

    const pi = 3.14159265358979;

    // Blue (top → right)
    drawArc(const Color(0xFF4285F4), -pi / 2, pi / 2 + 0.15, r, Offset(cx, cy));
    // Green (right → bottom)
    drawArc(const Color(0xFF34A853), 0.15, pi / 2, r, Offset(cx, cy));
    // Yellow (bottom → left)
    drawArc(const Color(0xFFFBBC05), pi / 2 + 0.15, pi / 2, r, Offset(cx, cy));
    // Red (left → top)
    drawArc(const Color(0xFFEA4335), pi + 0.15, pi / 2, r, Offset(cx, cy));

    // White fill for inner circle
    canvas.drawCircle(
      Offset(cx, cy),
      r - s * 0.18,
      Paint()..color = Colors.white,
    );

    // Horizontal bar of G
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - s * 0.09, r + s * 0.04, s * 0.18),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.line2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'o con tu correo',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.ink3),
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.line2)),
        ],
      ),
    );
  }
}

// ─── Email Field ──────────────────────────────────────────────────────────────

class EmailInputField extends StatelessWidget {
  const EmailInputField({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LoginScreenProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo electrónico',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: provider.emailController,
          keyboardType: TextInputType.emailAddress,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'tu@correo.com',
            hintStyle: TextStyle(color: AppColors.ink3),
            filled: true,
            fillColor: AppColors.fieldBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              borderSide: const BorderSide(color: AppColors.line2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              borderSide: const BorderSide(color: AppColors.line2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Password Field ───────────────────────────────────────────────────────────

class PasswordInputField extends StatelessWidget {
  const PasswordInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginScreenProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contraseña',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: provider.passwordController,
              obscureText: provider.obscurePassword,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: TextStyle(color: AppColors.ink3),
                filled: true,
                fillColor: AppColors.fieldBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    provider.obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.ink3,
                    size: 20,
                  ),
                  onPressed: provider.togglePasswordVisibility,
                  splashRadius: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  borderSide: const BorderSide(color: AppColors.line2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  borderSide: const BorderSide(color: AppColors.line2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  borderSide: const BorderSide(
                    color: AppColors.pink,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Remember Me + Forgot ─────────────────────────────────────────────────────

class RememberMeCheckbox extends StatelessWidget {
  const RememberMeCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginScreenProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: provider.rememberMe,
                onChanged: (v) => provider.setRememberMe(v ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppColors.line2, width: 1.5),
                activeColor: AppColors.pink,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Recordarme',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.ink2),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.pink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Login Button ─────────────────────────────────────────────────────────────

class LoginButtonWidget extends StatelessWidget {
  const LoginButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginScreenProvider>(
      builder: (context, provider, _) {
        return AppButton(
          label: 'Iniciar sesión',
          onPressed: provider.isLoading ? () {} : provider.login,
          type: ButtonType.primary,
        );
      },
    );
  }
}

// ─── Sign-up Prompt ───────────────────────────────────────────────────────────

class SignUpPrompt extends StatelessWidget {
  const SignUpPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: '¿No tienes acceso aún? ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.ink2),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  'Solicita una invitación',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.pink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class LoginFormFooter extends StatelessWidget {
  const LoginFormFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '© 2026 Trevo  ·  Términos  ·  Privacidad',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.ink3, fontSize: 12),
      ),
    );
  }
}
