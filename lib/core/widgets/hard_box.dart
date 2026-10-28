import 'package:flutter/material.dart';

import '../theme/yaadly_colors.dart';

/// The design's signature look: a 2px ink outline plus a hard, unblurred offset shadow.
/// `.hard` = 4px shadow, `.hard-sm` = 2px shadow.
class HardBox extends StatelessWidget {
  const HardBox({
    super.key,
    required this.child,
    this.color = YaadlyColors.paper,
    this.radius = const BorderRadius.all(Radius.circular(20)),
    this.shadow = 4,
    this.padding,
  });

  const HardBox.small({
    super.key,
    required this.child,
    this.color = YaadlyColors.paper,
    this.radius = const BorderRadius.all(Radius.circular(999)),
    this.padding,
  }) : shadow = 2;

  final Widget child;
  final Color color;
  final BorderRadius radius;
  final double shadow;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: YaadlyColors.ink, width: 2),
        boxShadow: [
          if (shadow > 0) BoxShadow(color: YaadlyColors.ink, offset: Offset(shadow, shadow)),
        ],
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// Wraps a child with the design's `.press` effect: it shifts into its shadow while pressed.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          offset: _down ? const Offset(0.006, 0.03) : Offset.zero,
          child: Opacity(opacity: widget.onTap == null ? 0.5 : 1, child: widget.child),
        ),
      ),
    );
  }
}
