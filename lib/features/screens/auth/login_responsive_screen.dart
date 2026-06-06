import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import 'login_form_components.dart';
import 'login_right_panel.dart';
import 'login_screen_provider.dart';

class LoginResponsiveScreen extends StatelessWidget {
  const LoginResponsiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > AppConstants.breakpointTablet;

    return ChangeNotifierProvider(
      create: (_) => LoginScreenProvider(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: isDesktop ? const _DesktopLayout() : const _MobileLayout(),
      ),
    );
  }
}

// ─── Desktop ──────────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(flex: 1, child: _LoginFormColumn()),
        Expanded(flex: 1, child: LoginRightPanel()),
      ],
    );
  }
}

// ─── Mobile ───────────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Mini hero strip at top on mobile
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: AppColors.brandGradient,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: LiveBadge(),
            ),
          ),
          const _LoginFormColumn(),
        ],
      ),
    );
  }
}

// ─── Form Column ──────────────────────────────────────────────────────────────

class _LoginFormColumn extends StatelessWidget {
  const _LoginFormColumn();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.loginFormPaddingH,
          vertical: AppConstants.loginFormPaddingV,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.loginFormMaxWidth + 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Logo
                TrevoLogo(),
                SizedBox(height: 52),

                // Header
                LoginFormHeader(),
                SizedBox(height: 32),

                // Google
                GoogleSignInButton(),
                OrDivider(),

                // Fields
                EmailInputField(),
                SizedBox(height: 16),
                PasswordInputField(),
                SizedBox(height: 16),

                // Remember / Forgot
                RememberMeCheckbox(),
                SizedBox(height: 24),

                // CTA
                LoginButtonWidget(),
                SizedBox(height: 20),

                SizedBox(height: 48),

                // Footer
                LoginFormFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
