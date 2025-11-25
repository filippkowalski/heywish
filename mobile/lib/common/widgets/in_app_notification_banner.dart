import 'package:flutter/material.dart';
import 'dart:async';

/// In-app notification banner that slides down from the top
/// Similar to Instagram/WhatsApp notification style
class InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.type,
    required this.onDismiss,
    this.onTap,
    this.duration = const Duration(seconds: 4),
  });

  /// Show an in-app notification banner
  static void show({
    required BuildContext context,
    required String title,
    required String body,
    required String type,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => InAppNotificationBanner(
        title: title,
        body: body,
        type: type,
        onTap: onTap,
        duration: duration,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start entry animation
    _controller.forward();

    // Auto-dismiss after duration
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  void _handleTap() {
    widget.onTap?.call();
    _dismiss();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accepted':
        return Icons.people;
      case 'wish_reserved':
        return Icons.bookmark;
      case 'wish_purchased':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.type) {
      case 'friend_request':
        return const Color(0xFF6366F1); // Blue
      case 'friend_accepted':
        return const Color(0xFF10B981); // Green
      case 'wish_reserved':
        return const Color(0xFFF59E0B); // Orange
      case 'wish_purchased':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap != null ? _handleTap : null,
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragDistance += details.delta.dy;
              if (_dragDistance < 0) {
                // Only allow upward drag
                final progress = (-_dragDistance / 100).clamp(0.0, 1.0);
                _controller.value = 1.0 - progress;
              }
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragDistance < -50) {
              // Dismiss if dragged up more than 50 pixels
              _dismiss();
            } else {
              // Reset position
              _controller.forward();
            }
            _dragDistance = 0;
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getIconBackgroundColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.body,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFF9CA3AF),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
