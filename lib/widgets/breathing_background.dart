import 'package:flutter/material.dart';

class BreathingBackground extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const BreathingBackground({
    super.key,
    required this.child,
    this.isActive = false,
  });

  @override
  State<BreathingBackground> createState() => _BreathingBackgroundState();
}

class _BreathingBackgroundState extends State<BreathingBackground>
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
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BreathingBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
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
        final opacity = widget.isActive
            ? 0.02 + (_animation.value * 0.03)
            : 0.0;
        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              widget.child,
              if (widget.isActive)
                Container(
                  color: Colors.white.withOpacity(opacity),
                ),
            ],
          ),
        );
      },
    );
  }
}

