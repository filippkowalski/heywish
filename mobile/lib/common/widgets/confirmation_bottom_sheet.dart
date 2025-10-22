import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../navigation/native_page_route.dart';

class ConfirmationBottomSheet extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final Color? confirmColor;
  final Future<bool> Function()? onConfirm;
  final bool isDestructive;

  const ConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.icon,
    this.confirmColor,
    this.onConfirm,
    this.isDestructive = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? confirmColor,
    Future<bool> Function()? onConfirm,
    bool isDestructive = false,
  }) {
    return NativeTransitions.showNativeModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      child: ConfirmationBottomSheet(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        confirmColor: confirmColor,
        onConfirm: onConfirm,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  State<ConfirmationBottomSheet> createState() => _ConfirmationBottomSheetState();
}

class _ConfirmationBottomSheetState extends State<ConfirmationBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    if (widget.onConfirm != null) {
      setState(() => _isLoading = true);
      
      try {
        final success = await widget.onConfirm!();
        if (mounted) {
          Navigator.of(context).pop(success);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Icon
              if (widget.icon != null) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.isDestructive
                        ? AppTheme.error.withValues(alpha: 0.1)
                        : AppTheme.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: widget.isDestructive 
                        ? AppTheme.error 
                        : AppTheme.primaryAccent,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Title
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                widget.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading 
                          ? null 
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.cancelText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Confirm button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.confirmColor ??
                            (widget.isDestructive ? AppTheme.error : AppTheme.primaryAccent),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            )
                          : Text(
                              widget.confirmText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}