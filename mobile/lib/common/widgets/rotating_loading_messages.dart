import 'dart:async';
import 'package:flutter/material.dart';

/// A widget that rotates through multiple loading messages with smooth fade transitions
class RotatingLoadingMessages extends StatefulWidget {
  /// List of messages to rotate through
  final List<String> messages;

  /// Duration to show each message before transitioning to the next
  final Duration messageDuration;

  /// Duration of the fade transition between messages
  final Duration transitionDuration;

  /// Text style for the messages
  final TextStyle? textStyle;

  /// Text alignment
  final TextAlign textAlign;

  const RotatingLoadingMessages({
    super.key,
    required this.messages,
    this.messageDuration = const Duration(seconds: 3),
    this.transitionDuration = const Duration(milliseconds: 500),
    this.textStyle,
    this.textAlign = TextAlign.center,
  });

  @override
  State<RotatingLoadingMessages> createState() =>
      _RotatingLoadingMessagesState();
}

class _RotatingLoadingMessagesState extends State<RotatingLoadingMessages> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRotation();
  }

  void _startRotation() {
    if (widget.messages.length <= 1) return;

    _timer = Timer.periodic(widget.messageDuration, (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: widget.transitionDuration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Text(
        widget.messages[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        style: widget.textStyle,
        textAlign: widget.textAlign,
      ),
    );
  }
}
