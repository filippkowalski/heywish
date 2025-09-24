import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated skeleton loading widget for placeholder content
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  
  const SkeletonLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });
  
  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? AppColors.surfaceVariant;
    final highlightColor = widget.highlightColor ?? AppColors.surface;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                _animation.value.clamp(0.0, 1.0),
                1.0,
              ],
              transform: GradientRotation(_animation.value * 0.5),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading widget for text lines
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final int lines;
  final double spacing;
  
  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.lines = 1,
    this.spacing = 8,
  });
  
  @override
  Widget build(BuildContext context) {
    if (lines == 1) {
      return SkeletonLoading(
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(height / 2),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        final lineWidth = isLast ? width * 0.7 : width; // Last line shorter
        
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: SkeletonLoading(
            width: lineWidth,
            height: height,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        );
      }),
    );
  }
}

/// Skeleton loading widget for circular avatars
class SkeletonAvatar extends StatelessWidget {
  final double radius;
  
  const SkeletonAvatar({
    super.key,
    this.radius = 24,
  });
  
  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      width: radius * 2,
      height: radius * 2,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Skeleton loading widget for cards/containers
class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsets padding;
  final Widget? child;
  
  const SkeletonCard({
    super.key,
    required this.width,
    required this.height,
    this.padding = const EdgeInsets.all(16),
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

/// Skeleton loading for wishlist cards
class SkeletonWishlistCard extends StatelessWidget {
  const SkeletonWishlistCard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SkeletonText(height: 20, lines: 1),
              ),
              const SizedBox(width: 16),
              SkeletonLoading(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonText(height: 14, lines: 2, width: double.infinity),
          const Spacer(),
          Row(
            children: [
              const SkeletonText(width: 80, height: 12),
              const SizedBox(width: 16),
              const SkeletonText(width: 100, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading for wish items
class SkeletonWishItem extends StatelessWidget {
  const SkeletonWishItem({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      width: double.infinity,
      height: 100,
      child: Row(
        children: [
          SkeletonLoading(
            width: 68,
            height: 68,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(height: 16, lines: 1),
                const SizedBox(height: 8),
                const SkeletonText(height: 12, lines: 2, width: double.infinity),
                const Spacer(),
                Row(
                  children: [
                    const SkeletonText(width: 60, height: 14),
                    const SizedBox(width: 16),
                    const SkeletonText(width: 80, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading for friend suggestions
class SkeletonFriendItem extends StatelessWidget {
  const SkeletonFriendItem({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SkeletonAvatar(radius: 24),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 120, height: 16),
                SizedBox(height: 4),
                SkeletonText(width: 80, height: 12),
              ],
            ),
          ),
          SkeletonLoading(
            width: 80,
            height: 32,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }
}