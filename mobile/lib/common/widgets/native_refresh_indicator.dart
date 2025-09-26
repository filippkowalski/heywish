import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class NativeRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;
  final Color? color;

  const NativeRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.backgroundColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: onRefresh,
            builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
              return Container(
                alignment: Alignment.center,
                child: CupertinoActivityIndicator(
                  color: color ?? CupertinoColors.systemBlue,
                  radius: 12,
                ),
              );
            },
          ),
          SliverFillRemaining(
            child: child,
          ),
        ],
      );
    } else {
      return RefreshIndicator(
        onRefresh: onRefresh,
        backgroundColor: backgroundColor,
        color: color,
        strokeWidth: 2.5,
        displacement: 40,
        child: child,
      );
    }
  }
}