import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/theme.dart';

/// 全画面の銀河。どの画面でもいちばん下に敷く。
///
/// 星は「点を散らす」だけだと方眼紙に見えるので、
/// 大きさ・明るさ・またたく速さを1粒ずつずらしてある。
/// 星雲はぼかした円で、色を3つに絞って重ねている。
class GalaxyBackground extends StatefulWidget {
  const GalaxyBackground({
    super.key,
    this.child,
    this.starCount = 170,
    this.drift = 1.0,
  });

  final Widget? child;
  final int starCount;

  /// 星の流れる速さ。ミニゲーム中だけ速くして、宇宙を飛んでいる感じを出す。
  final double drift;

  @override
  State<GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<GalaxyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  )..repeat();

  late final List<_Star> _stars = _buildStars(widget.starCount);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.galaxyGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _GalaxyPainter(
                  t: _c.value * 120,
                  stars: _stars,
                  drift: widget.drift,
                ),
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _Star {
  _Star(this.x, this.y, this.r, this.speed, this.phase, this.tint);
  final double x;
  final double y;
  final double r;
  final double speed;
  final double phase;
  final Color tint;
}

List<_Star> _buildStars(int n) {
  final rnd = math.Random(20260912);
  const tints = [
    AppColors.star,
    Color(0xFFBFD4FF),
    Color(0xFFFFE6B8),
    Color(0xFFE3C4FF),
  ];
  return List.generate(n, (_) {
    final r = 0.4 + rnd.nextDouble() * rnd.nextDouble() * 2.2;
    return _Star(
      rnd.nextDouble(),
      rnd.nextDouble(),
      r,
      // 大きい星ほど手前にある想定で、速く流す。
      0.004 + r * 0.006 * rnd.nextDouble(),
      rnd.nextDouble() * math.pi * 2,
      tints[rnd.nextInt(tints.length)],
    );
  });
}

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter({required this.t, required this.stars, required this.drift});

  final double t;
  final List<_Star> stars;
  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    _nebula(canvas, size);

    final paint = Paint();
    for (final s in stars) {
      final y = (s.y + t * s.speed * drift) % 1.0;
      final twinkle = 0.45 + 0.55 * math.sin(t * 1.6 + s.phase).abs();
      final c = Offset(s.x * size.width, y * size.height);
      paint.color = s.tint.withValues(alpha: twinkle);
      canvas.drawCircle(c, s.r, paint);
      // 大粒だけにじませる。全部光らせると靄になる。
      if (s.r > 1.6) {
        paint
          ..color = s.tint.withValues(alpha: twinkle * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(c, s.r * 2.6, paint);
        paint.maskFilter = null;
      }
    }
  }

  void _nebula(Canvas canvas, Size size) {
    void blob(Offset at, double r, Color color, double alpha) {
      final rect = Rect.fromCircle(center: at, radius: r);
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    final w = size.width, h = size.height;
    final sway = math.sin(t * 0.12) * 0.02;
    blob(Offset(w * (0.18 + sway), h * 0.24), w * 0.55,
        AppColors.nebulaViolet, 0.42);
    blob(Offset(w * (0.84 - sway), h * 0.68), w * 0.5,
        AppColors.nebulaMagenta, 0.3);
    blob(Offset(w * 0.55, h * (0.92 + sway)), w * 0.7,
        AppColors.nebulaBlue, 0.28);
  }

  @override
  bool shouldRepaint(_GalaxyPainter old) => old.t != t || old.drift != drift;
}
