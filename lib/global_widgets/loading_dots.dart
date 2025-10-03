import 'package:flutter/material.dart';

/// Widget animado de puntos de carga
class LoadingDots extends StatefulWidget {
  final Color? color;
  final double fontSize;
  final Duration duration;

  const LoadingDots({
    super.key,
    this.color,
    this.fontSize = 16,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = IntTween(
      begin: 1,
      end: 4, // 1, 2, 3, luego vuelve a 1
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
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
        int dotCount = _animation.value;
        String dots = '.' * dotCount;
        
        return Text(
          'Cargando$dots',
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w500,
            color: widget.color ?? Colors.white.withOpacity(0.8),
          ),
        );
      },
    );
  }
}
