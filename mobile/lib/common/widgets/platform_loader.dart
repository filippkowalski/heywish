import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class PlatformLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const PlatformLoader({
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    
    if (Platform.isIOS) {
      return SizedBox(
        width: size,
        height: size,
        child: CupertinoActivityIndicator(
          color: effectiveColor,
          radius: size / 2.5, // Proportional radius based on size
        ),
      );
    } else {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: effectiveColor,
        ),
      );
    }
  }
}