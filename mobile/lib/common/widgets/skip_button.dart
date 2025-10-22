import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SkipButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SkipButton({
    super.key,
    this.text = 'Skip',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textSecondary,
        overlayColor: Colors.grey.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}