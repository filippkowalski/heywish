import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

/// Custom page route that provides native transitions on both iOS and Android
/// Falls back to iOS-style transitions when platform-specific is not available
class NativePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  @override
  final RouteSettings settings;

  NativePageRoute({
    required this.child,
    RouteSettings? settings,
  })  : settings = settings ?? const RouteSettings(),
        super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (Platform.isIOS) {
              // iOS native slide transition
              return CupertinoPageTransition(
                primaryRouteAnimation: animation,
                secondaryRouteAnimation: secondaryAnimation,
                linearTransition: false,
                child: child,
              );
            } else {
              // Android native slide transition
              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(
                    CurveTween(curve: Curves.fastOutSlowIn),
                  ),
                ),
                child: child,
              );
            }
          },
          transitionDuration: Platform.isIOS 
              ? const Duration(milliseconds: 350)
              : const Duration(milliseconds: 300),
          reverseTransitionDuration: Platform.isIOS 
              ? const Duration(milliseconds: 350) 
              : const Duration(milliseconds: 300),
        );
}

/// Extension methods for native navigation
extension NativeNavigation on BuildContext {
  /// Push a new screen with native transitions
  Future<T?> pushNative<T>(Widget screen, [RouteSettings? settings]) {
    return Navigator.of(this).push<T>(
      NativePageRoute<T>(
        child: screen,
        settings: settings,
      ),
    );
  }

  /// Replace the current screen with native transitions
  Future<T?> pushReplacementNative<T, TO>(Widget screen, [RouteSettings? settings]) {
    return Navigator.of(this).pushReplacement<T, TO>(
      NativePageRoute<T>(
        child: screen,
        settings: settings,
      ),
    );
  }

  /// Push and remove all previous routes with native transitions
  Future<T?> pushAndRemoveUntilNative<T>(
    Widget screen, 
    RoutePredicate predicate, [
    RouteSettings? settings
  ]) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      NativePageRoute<T>(
        child: screen,
        settings: settings,
      ),
      predicate,
    );
  }
}

/// GoRouter custom page for native transitions
class NativeGoPage<T> extends Page<T> {
  final Widget child;

  const NativeGoPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return NativePageRoute<T>(
      child: child,
      settings: this,
    );
  }
}

/// Utility class for creating native transitions in GoRouter
class NativeTransitions {
  /// Creates a GoRouter page with native transitions
  static Page<T> page<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return NativeGoPage<T>(
      key: key,
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
    );
  }

  /// Modal bottom sheet with native presentation
  static Future<T?> showNativeModalBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    if (Platform.isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        useRootNavigator: useRootNavigator,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: child,
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        backgroundColor: backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => child,
      );
    }
  }

  /// Native dialog presentation
  static Future<T?> showNativeDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = Colors.black54,
  }) {
    if (Platform.isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => child,
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        builder: (context) => child,
      );
    }
  }
}