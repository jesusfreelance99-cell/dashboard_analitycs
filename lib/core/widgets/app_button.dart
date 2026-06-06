import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum ButtonType { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isEnabled;
  final Icon? icon;
  final double? width;
  final double? height;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Text(label);
    if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: AppConstants.spacingSm),
          Text(label),
        ],
      );
    }

    if (isLoading) {
      child = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isEnabled && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height ?? 48),
          ),
          child: child,
        );
      case ButtonType.secondary:
        return ElevatedButton(
          onPressed: isEnabled && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height ?? 48),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          child: child,
        );
      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isEnabled && !isLoading ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height ?? 48),
          ),
          child: child,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isEnabled && !isLoading ? onPressed : null,
          child: child,
        );
    }
  }
}
