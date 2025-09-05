import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ModernFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;

  const ModernFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56.0,
  });

  @override
  State<ModernFloatingActionButton> createState() => _ModernFloatingActionButtonState();
}

class _ModernFloatingActionButtonState extends State<ModernFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: FloatingActionButton(
              onPressed: () {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                  widget.onPressed?.call();
                });
              },
              tooltip: widget.tooltip,
              backgroundColor: widget.backgroundColor ?? AppTheme.primaryColor,
              foregroundColor: widget.foregroundColor ?? Colors.white,
              elevation: 8,
              child: Icon(
                widget.icon,
                size: widget.size * 0.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedFloatingActionButton extends StatefulWidget {
  final List<FloatingActionButtonItem> items;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedFloatingActionButton({
    super.key,
    required this.items,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AnimatedFloatingActionButton> createState() => _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.items.map((item) {
          final index = widget.items.indexOf(item);
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: Transform.translate(
                  offset: Offset(0, -60 * (index + 1) * _animation.value),
                  child: Opacity(
                    opacity: _animation.value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: FloatingActionButton.small(
                        onPressed: item.onPressed,
                        tooltip: item.tooltip,
                        backgroundColor: item.backgroundColor ?? AppTheme.surfaceColor,
                        foregroundColor: item.foregroundColor ?? AppTheme.primaryColor,
                        elevation: 4,
                        child: Icon(item.icon),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        FloatingActionButton(
          onPressed: _toggle,
          tooltip: widget.tooltip,
          backgroundColor: widget.backgroundColor ?? AppTheme.primaryColor,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          elevation: 8,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(widget.icon),
          ),
        ),
      ],
    );
  }
}

class FloatingActionButtonItem {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FloatingActionButtonItem({
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });
}
