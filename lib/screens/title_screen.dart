import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/charas.dart';
import '../data/theme.dart';
import '../widgets/galaxy_background.dart';
import '../widgets/glow_button.dart';
import 'dodge_screen.dart';

/// 入口。ここではまだ「隕石をよけるだけのゲーム」の顔をしておく。
/// 本当のタイトルはミニゲームをクリアしたあとに出る。
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GalaxyBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sunMark(),
                  const SizedBox(height: 28),
                  const Text(
                    'SOLAR  DODGE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 44,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: AppColors.textPrimary,
                      shadows: [
                        Shadow(color: AppColors.sun, blurRadius: 26),
                        Shadow(color: AppColors.nebulaMagenta, blurRadius: 44),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'たいようを動かして、隕石をよけろ。',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 36),
                  GlowButton(
                    label: 'START',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DodgeScreen()),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'ドラッグ / 矢印キー・WASD で移動　　30秒 生きのびろ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// タイトルの太陽。自転しているだけ、というのは実は伏線でもある。
  Widget _sunMark() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final pulse = 0.5 + 0.5 * math.sin(_c.value * math.pi * 4);
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.sun.withValues(alpha: 0.25 + pulse * 0.22),
                blurRadius: 60 + pulse * 24,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: _c.value * math.pi * 2,
            child: child,
          ),
        );
      },
      child: Image.asset(sun.icon, fit: BoxFit.contain),
    );
  }
}
