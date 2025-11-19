import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'rotating_loading_messages.dart';

/// A native-looking loading overlay that shows a platform-specific loading indicator
/// above a darkened barrier overlay.
class NativeLoadingOverlay {
  /// Shows a native loading overlay above the current screen with a darkened backdrop.
  ///
  /// Returns a function that can be called to dismiss the overlay.
  ///
  /// If [messages] is provided, it will rotate through multiple messages.
  /// If only [message] is provided, it will show a single static message.
  ///
  /// Usage:
  /// ```dart
  /// // Single message
  /// final dismiss = NativeLoadingOverlay.show(context, message: 'Loading...');
  ///
  /// // Rotating messages
  /// final dismiss = NativeLoadingOverlay.show(
  ///   context,
  ///   messages: ['Message 1...', 'Message 2...', 'Message 3...'],
  /// );
  ///
  /// try {
  ///   await someAsyncOperation();
  /// } finally {
  ///   dismiss();
  /// }
  /// ```
  static VoidCallback show(
    BuildContext context, {
    String? message,
    List<String>? messages,
  }) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NativeLoadingOverlayWidget(
        message: message,
        messages: messages,
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    return () {
      overlayEntry.remove();
    };
  }
}

class _NativeLoadingOverlayWidget extends StatelessWidget {
  final String? message;
  final List<String>? messages;

  const _NativeLoadingOverlayWidget({
    this.message,
    this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Platform-specific loading indicator
              if (Platform.isIOS)
                const CupertinoActivityIndicator(
                  radius: 16,
                  color: Color(0xFF3B82F6), // Primary blue
                )
              else
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF3B82F6), // Primary blue
                  ),
                ),

              // Show rotating messages if provided, otherwise single message
              if (messages != null && messages!.isNotEmpty) ...[
                const SizedBox(height: 16),
                RotatingLoadingMessages(
                  messages: messages!,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937), // Dark gray
                  ),
                  messageDuration: const Duration(seconds: 3),
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              ] else if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937), // Dark gray
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
