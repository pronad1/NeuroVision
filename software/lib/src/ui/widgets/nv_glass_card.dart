// lib/src/ui/widgets/nv_glass_card.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Glassmorphism card widget — the core visual element of NeuroVision AI UI
class NVGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool hoverable;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Gradient? gradient;

  const NVGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.borderColor,
    this.backgroundColor,
    this.hoverable = false,
    this.onTap,
    this.width,
    this.height,
    this.gradient,
  });

  @override
  State<NVGlassCard> createState() => _NVGlassCardState();
}

class _NVGlassCardState extends State<NVGlassCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverEnter(bool h) {
    if (!widget.hoverable) return;
    setState(() => _hovered = h);
    if (h) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor ??
        (_hovered ? NVColors.primary.withValues(alpha: 0.6) : NVColors.border);
    final bgColor = widget.backgroundColor ?? NVColors.bgCard;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => _onHoverEnter(true),
        onExit: (_) => _onHoverEnter(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: widget.gradient,
              color: widget.gradient == null ? bgColor : null,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: NVColors.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 0,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(20),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
