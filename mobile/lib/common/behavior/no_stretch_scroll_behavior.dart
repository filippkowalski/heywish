import 'package:flutter/material.dart';

/// Disables Android's StretchingOverscrollIndicator inside the wrapped subtree.
/// Flutter currently crashes when stretch animations trigger during animated
/// route transitions, so we bypass the indicator on Android/Fuchsia only.
class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return child;
      default:
        return super.buildOverscrollIndicator(context, child, details);
    }
  }
}
