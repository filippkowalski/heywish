import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// A native-looking loading overlay that shows a platform-specific loading indicator
/// above a darkened barrier overlay.
class NativeLoadingOverlay {
  /// Shows a native loading overlay above the current screen with a darkened backdrop.
  ///
  /// Returns a function that can be called to dismiss the overlay.
  ///
  /// Usage:
  /// ```dart
  /// final dismiss = NativeLoadingOverlay.show(context);
  /// try {
  ///   await someAsyncOperation();
  /// } finally {
  ///   dismiss();
  /// }
  /// ```
  static VoidCallback show(BuildContext context, {String? message}) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NativeLoadingOverlayWidget(
        message: message,
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

  const _NativeLoadingOverlayWidget({this.message});

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

              if (message != null) ...[
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
