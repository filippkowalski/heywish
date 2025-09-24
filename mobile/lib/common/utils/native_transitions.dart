import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class NativeTransitions {
  /// Creates a platform-specific page route with native transitions
  static PageRoute<T> createRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    if (Platform.isIOS) {
      return CupertinoPageRoute<T>(
        builder: (context) => page,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    } else {
      return MaterialPageRoute<T>(
        builder: (context) => page,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }
  }

  /// Navigate to a new page with native transitions
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      createRoute<T>(
        page,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  /// Replace current page with native transitions
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      createRoute<T>(
        page,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      ),
      result: result,
    );
  }

  /// Push and remove all previous routes with native transitions
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      createRoute<T>(
        page,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      ),
      predicate,
    );
  }

  /// Get platform-specific slide transition animation
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.rightToLeft,
  }) {
    Offset begin;
    const Offset end = Offset.zero;

    switch (direction) {
      case SlideDirection.rightToLeft:
        begin = const Offset(1.0, 0.0);
        break;
      case SlideDirection.leftToRight:
        begin = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.topToBottom:
        begin = const Offset(0.0, -1.0);
        break;
      case SlideDirection.bottomToTop:
        begin = const Offset(0.0, 1.0);
        break;
    }

    const curve = Curves.easeInOut;

    var tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  /// Create animated page transitions for onboarding flow
  static Widget animatedPageTransition({
    required Widget child,
    required Animation<double> animation,
    required bool isForward,
  }) {
    if (Platform.isIOS) {
      // iOS-style slide transition
      return SlideTransition(
        position: Tween<Offset>(
          begin: isForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    } else {
      // Android-style material transition
      return SlideTransition(
        position: Tween<Offset>(
          begin: isForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    }
  }
}

enum SlideDirection {
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
}