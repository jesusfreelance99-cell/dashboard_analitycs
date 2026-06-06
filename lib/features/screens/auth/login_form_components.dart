import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
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
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset('assets/img/app_icon.png', width: 34, height: 34),
        ),
        const SizedBox(width: 10),
        Text(
          'Trevo',
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

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginScreenProvider>(
      builder: (context, provider, _) {
        return AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: GestureDetector(
            onTapDown: (_) {
              if (!provider.isLoading) {
                _ctrl.forward();
                setState(() => _pressed = true);
              }
            },
            onTapUp: (_) {
              _ctrl.reverse();
              setState(() => _pressed = false);
            },
            onTapCancel: () {
              _ctrl.reverse();
              setState(() => _pressed = false);
            },
            onTap: provider.isLoading
                ? null
                : () {
                    provider.signInWithGoogle().then((success) {
                      if (mounted && success) {
                        context.go(AppRoutes.dashboard);
                      }
                    });
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _pressed ? AppColors.fieldBg : AppColors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                border: Border.all(color: AppColors.line2, width: 1.5),
              ),
              child: provider.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.pink,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.google),
                        const SizedBox(width: 8),
                        Text(
                          'Continuar con Google',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
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
              borderSide: const BorderSide(color: AppColors.line2, width: 1.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              borderSide: const BorderSide(color: AppColors.line2, width: 1.8),
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
                  borderSide: const BorderSide(
                    color: AppColors.line2,
                    width: 1.8,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  borderSide: const BorderSide(
                    color: AppColors.line2,
                    width: 1.8,
                  ),
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
          onPressed: provider.isLoading
              ? () {}
              : () async {
                  final success = await provider.login();
                  if (!context.mounted) return;
                  if (success) {
                    context.go(AppRoutes.dashboard);
                  } else if (provider.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage!),
                        backgroundColor: const Color(0xFFC0134F),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
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
