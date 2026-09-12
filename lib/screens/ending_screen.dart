import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/charas.dart';
import '../data/theme.dart';
import '../models/chara.dart';
import '../widgets/galaxy_background.dart';
import '../widgets/glow_button.dart';
import 'title_screen.dart';

/// 最後。文字が1つずつ下から浮かび上がってくる。
///
/// ここだけは急がせない。全部出そろってからボタンを出す。
class EndingScreen extends StatefulWidget {
  const EndingScreen({super.key});

  static const message = '誕生日おめでとう';

  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6200),
  )..forward();

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _reveal.dispose();
    _drift.dispose();
    super.dispose();
  }

  /// 0〜1 の区間を切り出して、そこだけで 0→1 にする。
  double _at(double start, double end) {
    final v = (_reveal.value - start) / (end - start);
    return v.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GalaxyBackground(
        starCount: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _drift,
                builder: (context, _) => CustomPaint(
                  painter: _RisingSparkPainter(_drift.value),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _reveal,
              builder: (context, _) => SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    _title(),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: _at(0.58, 0.76),
                      child: const Text(
                        '1兆年と20歳のたいようへ',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 4,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    _cast(),
                    const SizedBox(height: 26),
                    Opacity(
                      opacity: _at(0.82, 0.96),
                      child: GlowButton(
                        label: '最初から始める',
                        icon: Icons.replay_rounded,
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const TitleScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title() {
    const chars = EndingScreen.message;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chars.length; i++)
              _risingChar(chars[i], i / chars.length),
          ],
        ),
      ),
    );
  }

  Widget _risingChar(String c, double order) {
    // 1文字ずつ、少しずつ遅らせて浮かせる。
    final t = _at(0.06 + order * 0.42, 0.30 + order * 0.42);
    final eased = Curves.easeOutCubic.transform(t);
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            c,
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.textPrimary,
              shadows: [
                Shadow(
                  color: AppColors.sun.withValues(alpha: 0.9 * eased),
                  blurRadius: 26,
                ),
                Shadow(
                  color: AppColors.nebulaMagenta.withValues(alpha: 0.8 * eased),
                  blurRadius: 48,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3人ならべて締める。主役の太陽だけ少し大きい。
  Widget _cast() {
    Widget one(Chara c, double size, double start) {
      final t = _at(start, start + 0.12);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.45),
                    blurRadius: size * 0.45,
                  ),
                ],
              ),
              child: Image.asset(c.icon, fit: BoxFit.contain),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        one(moon, 82, 0.70),
        one(sun, 112, 0.64),
        one(earth, 82, 0.76),
      ],
    );
  }
}

/// 下から昇っていく光。紙吹雪だと誕生会になってしまうので、星のかけらにした。
class _RisingSparkPainter extends CustomPainter {
  _RisingSparkPainter(this.t);

  final double t;
  static final _seeds = List.generate(
    46,
    (i) => math.Random(900 + i).nextDouble(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (var i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final speed = 0.35 + s * 0.6;
      final y = 1.08 - ((t * speed + s) % 1.0) * 1.16;
      final x = s + math.sin((t * 2 + s * 9) * math.pi) * 0.03;
      final fade = math.sin(((t * speed + s) % 1.0) * math.pi).clamp(0.0, 1.0);
      paint.color = (i.isEven ? AppColors.sun : AppColors.moon)
          .withValues(alpha: fade * 0.75);
      canvas.drawCircle(
        Offset(x % 1.0 * size.width, y * size.height),
        1.4 + s * 2.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RisingSparkPainter old) => old.t != t;
}
