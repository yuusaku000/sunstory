import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/charas.dart';
import '../data/theme.dart';
import '../models/chara.dart';

/// 種明かしの絵。太陽は中心で自転しているだけ、地球と月がその周りを回る。
///
/// 真円の軌道を真上から見せると図解になってしまうので、
/// 縦をつぶした楕円にして、奥にいるときは小さく・暗く・太陽の後ろに隠す。
/// 「太陽は動いていない」が一目で伝わることだけを優先した。
/// 誰が誰の周りを回っているか。第四章と第五章で入れ替わる。
enum OrbitMode {
  /// 太陽のまわりを地球が、地球のまわりを月が回る。連れ去られたままの図。
  earthAndMoon,

  /// 地球がいなくなり、月が直接まわりを回る。
  moonOnly,
}

class OrbitView extends StatefulWidget {
  const OrbitView({super.key, this.mode = OrbitMode.earthAndMoon});

  final OrbitMode mode;

  @override
  State<OrbitView> createState() => _OrbitViewState();
}

class _OrbitViewState extends State<OrbitView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final center = Offset(w / 2, h / 2);
        final rx = math.min(w * 0.38, h * 0.9);
        final ry = rx * 0.32;

        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * math.pi * 2;

            // sin が正のとき手前。これで太陽の前後どちらに置くかを決める。
            final onOrbit = center + Offset(math.cos(t) * rx, math.sin(t) * ry);
            final orbitDepth = (math.sin(t) + 1) / 2;

            // 奥の子 → 太陽 → 手前の子 の順に重ねる。
            // これをやらないと、軌道がただの楕円の絵になってしまう。
            final bodies = <({Chara c, Offset at, double depth, double size})>[
              (c: sun, at: center, depth: 0.5, size: rx * 0.44),
              if (widget.mode == OrbitMode.earthAndMoon) ...[
                (c: earth, at: onOrbit, depth: orbitDepth, size: rx * 0.27),
                // 月は地球のまわり。速く回すと「連れ回されている」ように見える。
                (
                  c: moon,
                  at: onOrbit +
                      Offset(math.cos(t * 3.6) * rx * 0.30,
                          math.sin(t * 3.6) * ry * 0.62),
                  depth: (math.sin(t * 3.6) + 1) / 2,
                  size: rx * 0.21,
                ),
              ] else
                (c: moon, at: onOrbit, depth: orbitDepth, size: rx * 0.25),
            ]..sort((a, b) => a.depth.compareTo(b.depth));

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OrbitPainter(center: center, rx: rx, ry: ry),
                  ),
                ),
                for (final b in bodies)
                  _body(
                    b.c,
                    b.at,
                    b.depth,
                    b.size,
                    spin: b.c.id == 'sun' ? t * 1.6 : 0,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _body(
    Chara chara,
    Offset at,
    double depth,
    double base, {
    double spin = 0,
  }) {
    // 奥にいるほど小さく、暗い。太陽(depth 0.5)は常に等倍でいい。
    final size = chara.id == 'sun' ? base : base * (0.78 + depth * 0.42);
    Widget child = Image.asset(chara.icon, fit: BoxFit.contain);
    if (spin != 0) child = Transform.rotate(angle: spin, child: child);

    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: chara.id == 'sun' ? 1 : 0.55 + depth * 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: chara.accent.withValues(alpha: 0.5 * depth + 0.15),
                blurRadius: size * 0.55,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.center, required this.rx, required this.ry});

  final Offset center;
  final double rx;
  final double ry;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.moon.withValues(alpha: 0.24),
    );
    // 中心の十字。ここが動いていないことを、線で名指ししておく。
    final p = Paint()
      ..color = AppColors.sun.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final arm = rx * 0.30;
    canvas.drawLine(
      Offset(center.dx - arm, center.dy),
      Offset(center.dx + arm, center.dy),
      p,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - arm * 0.5),
      Offset(center.dx, center.dy + arm * 0.5),
      p,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.center != center || old.rx != rx || old.ry != ry;
}
