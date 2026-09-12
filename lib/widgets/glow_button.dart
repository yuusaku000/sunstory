import 'package:flutter/material.dart';

import '../data/theme.dart';

/// 銀河UIのボタン。押した瞬間に少し沈んで、光が強くなる。
/// Material の標準ボタンだと角が丸いだけの板になってしまうので自前。
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.accent = AppColors.sun,
    this.filled = true,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final Color accent;

  /// falseだと輪郭だけ。主ボタンと副ボタンを並べたときに主役を1つに保つ。
  final bool filled;
  final IconData? icon;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final glow = _down ? 0.55 : (_hover ? 0.42 : 0.25);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.accent.withValues(alpha: _hover ? 0.95 : 0.6),
                width: 1.4,
              ),
              gradient: widget.filled
                  ? LinearGradient(
                      colors: [
                        widget.accent.withValues(alpha: 0.32),
                        widget.accent.withValues(alpha: 0.10),
                      ],
                    )
                  : null,
              color: widget.filled ? null : AppColors.hollow.withValues(alpha: 0.5),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: glow),
                  blurRadius: _down ? 26 : 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: widget.accent),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(color: widget.accent.withValues(alpha: 0.8), blurRadius: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
