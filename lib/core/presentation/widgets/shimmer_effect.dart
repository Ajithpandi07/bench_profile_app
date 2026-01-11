import 'package:flutter/material.dart';

class ShimmerEffect extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final ShapeBorder shapeBorder;

  const ShimmerEffect.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 0,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerEffect.circular({
    super.key,
    required this.width,
    required this.height,
    this.radius = 0,
  }) : shapeBorder = const CircleBorder();

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.shapeBorder is CircleBorder
                ? null
                : BorderRadius.circular(widget.radius),
            shape: widget.shapeBorder is CircleBorder
                ? BoxShape.circle
                : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                0.1,
                0.3 + (_animation.value * 0.3), // Dynamic stop for shimmer
                0.6,
              ],
              transform: GradientRotation(_animation.value), // Moving gradient
            ),
          ),
        );
      },
    );
  }
}
