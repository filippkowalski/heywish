import 'package:flutter/material.dart';

class HeartIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool isPulsing;

  const HeartIcon({
    super.key,
    this.size = 128,
    this.color = const Color(0xFF38e07b),
    this.isPulsing = true,
  });

  @override
  State<HeartIcon> createState() => _HeartIconState();
}

class _HeartIconState extends State<HeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget heart = CustomPaint(
      size: Size(widget.size, widget.size),
      painter: HeartPainter(color: widget.color),
    );

    if (widget.isPulsing) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: heart,
          );
        },
      );
    }

    return heart;
  }
}

class HeartPainter extends CustomPainter {
  final Color color;

  HeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    
    // Scale factor to convert from 256x256 SVG to actual size
    final scaleX = size.width / 256;
    final scaleY = size.height / 256;
    
    // Convert SVG path data to Flutter path
    // M178 32c-20.65 0-38.73 8.88-50 23.89C116.73 40.88 98.65 32 78 32A62.07 62.07 0 0 0 16 94c0 70 103.79 126.66 108.21 129a8 8 0 0 0 7.58 0C136.21 220.66 240 164 240 94a62.07 62.07 0 0 0-62.07-62.07Zm-50 180.8c-18.26-10.64-96-59.11-96-112.8A46.06 46.06 0 0 1 78 48c19.45 0 35.78 10.36 42.6 27a8 8 0 0 0 14.8 0c6.82-16.67 23.15-27 42.6-27a46.06 46.06 0 0 1 46 46c0 53.61-77.76 102.15-96 112.8Z
    
    // Heart shape using cubic bezier curves (simplified version)
    path.moveTo(128 * scaleX, 60 * scaleY); // Center top
    
    // Left side of heart
    path.cubicTo(
      90 * scaleX, 20 * scaleY,    // Control point 1
      40 * scaleX, 20 * scaleY,    // Control point 2
      40 * scaleX, 70 * scaleY,    // End point
    );
    
    path.cubicTo(
      40 * scaleX, 120 * scaleY,   // Control point 1
      128 * scaleX, 180 * scaleY,  // Control point 2
      128 * scaleX, 220 * scaleY,  // Bottom center
    );
    
    // Right side of heart
    path.cubicTo(
      128 * scaleX, 180 * scaleY,  // Control point 1
      216 * scaleX, 120 * scaleY,  // Control point 2
      216 * scaleX, 70 * scaleY,   // End point
    );
    
    path.cubicTo(
      216 * scaleX, 20 * scaleY,   // Control point 1
      166 * scaleX, 20 * scaleY,   // Control point 2
      128 * scaleX, 60 * scaleY,   // Back to start
    );
    
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}