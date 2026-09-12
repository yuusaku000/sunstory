import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/theme.dart';

/// 地球が吹き飛ぶ瞬間の光。
///
/// 「白い丸がパッと出る」だけだと事故にしか見えないので、
/// 閃光・衝撃波の輪・放射状の光条・飛び散る破片を、
/// それぞれ違う速さで走らせている。速さがそろうと花火になってしまう。
class Boom extends StatelessWidget {
  const Boom({super.key, required this.progress, this.at = const Alignment(0, -0.36)});

  /// 0→1。1で消える。
  final double progress;

  /// 爆発の中心。立ち絵の頭のあたりに置きたいので、既定は画面のやや上。
  final Alignment at;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _BoomPainter(progress, at),
      ),
    );
  }
}

class _BoomPainter extends CustomPainter {
  _BoomPainter(this.t, this.at);

  final double t;
  final Alignment at;

  static final _rnd = List.generate(64, (i) => math.Random(400 + i).nextDouble());

  @override
  void paint(Canvas canvas, Size size) {
    final c = at.alongSize(size);
    final maxR = size.longestSide * 0.75;

    // 1. 画面全体の閃光。最初の一瞬だけ。
    final flash = (1 - t * 3.2).clamp(0.0, 1.0);
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: flash * 0.85),
      );
    }

    // 2. 衝撃波の輪。外へ行くほど細く、薄くなる。
    final ringT = Curves.easeOutCubic.transform(t);
    canvas.drawCircle(
      c,
      ringT * maxR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1 - ringT) * 26 + 1
        ..color = Color.lerp(Colors.white, AppColors.sunDeep, ringT)!
            .withValues(alpha: (1 - ringT) * 0.8),
    );

    // 3. 光条。星形に伸びて、輪より少し遅れて消える。
    final rayT = Curves.easeOutQuart.transform(t);
    final ray = Paint()
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (var i = 0; i < 22; i++) {
      final a = i / 22 * math.pi * 2 + _rnd[i] * 0.3;
      final len = maxR * (0.35 + _rnd[i] * 0.8) * rayT;
      ray
        ..strokeWidth = (1 - rayT) * 10 + 1
        ..color = const Color(0xFFFFE6A8).withValues(alpha: (1 - rayT) * 0.7);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * 18,
        c + Offset(math.cos(a), math.sin(a)) * len,
        ray,
      );
    }

    // 4. 破片。地球だったもの。少し重力で落とす。
    final dot = Paint();
    for (var i = 0; i < 44; i++) {
      final a = _rnd[i] * math.pi * 2;
      final sp = maxR * (0.2 + _rnd[(i + 11) % 64] * 0.75);
      final p = c +
          Offset(math.cos(a), math.sin(a)) * sp * Curves.easeOutQuad.transform(t) +
          Offset(0, t * t * size.height * 0.22);
      dot.color = (i.isEven ? AppColors.earth : AppColors.earthDeep)
          .withValues(alpha: (1 - t) * 0.95);
      canvas.drawCircle(p, (1 - t) * 4 + 1, dot);
    }
  }

  @override
  bool shouldRepaint(_BoomPainter old) => old.t != t;
}
