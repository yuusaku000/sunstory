import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../data/charas.dart';
import '../data/theme.dart';
import '../widgets/galaxy_background.dart';
import '../widgets/glow_button.dart';
import 'story_screen.dart';
import 'title_screen.dart';

/// 隕石よけ。30秒。
///
/// このゲームの「表向きの本編」。プレイヤーにはここが全部だと思わせたいので、
/// クリアまでの手触りだけは真面目に作ってある。
class DodgeScreen extends StatefulWidget {
  const DodgeScreen({super.key});

  static const survive = 30.0;

  @override
  State<DodgeScreen> createState() => _DodgeScreenState();
}

enum _Phase { playing, dead, cleared }

class _DodgeScreenState extends State<DodgeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rnd = math.Random();
  final _keys = <LogicalKeyboardKey>{};

  Size _field = Size.zero;
  Offset _player = Offset.zero;
  Offset _aim = Offset.zero;
  double _lastMs = 0;

  final _meteors = <_Meteor>[];
  final _sparks = <_Spark>[];

  double _elapsed = 0;
  double _spawnIn = 0.9;
  int _lives = 3;
  double _invuln = 0;
  double _flash = 0;
  _Phase _phase = _Phase.playing;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _reset() {
    _meteors.clear();
    _sparks.clear();
    _elapsed = 0;
    _spawnIn = 0.9;
    _lives = 3;
    _invuln = 0;
    _flash = 0;
    _phase = _Phase.playing;
    _player = _field.center(Offset.zero);
    _aim = _player;
    setState(() {});
  }

  /// 画面の大きさが変わっても難度が変わらないよう、速さも大きさも
  /// 短辺を基準にしてスケールさせる。
  double get _k => (_field.shortestSide / 520).clamp(0.6, 1.6);
  double get _playerR => 30 * _k;

  void _tick(Duration d) {
    final ms = d.inMicroseconds / 1000.0;
    var dt = (ms - _lastMs) / 1000.0;
    _lastMs = ms;
    if (dt <= 0) return;
    // タブを切り替えて戻ってきた瞬間に一気に進むのを防ぐ。
    dt = dt.clamp(0.0, 0.05);

    if (_field == Size.zero) return;

    if (_phase == _Phase.playing) {
      _elapsed += dt;
      _moveByKeys(dt);
      _movePlayer(dt);
      _spawn(dt);
      _moveMeteors(dt);
      _collide(dt);
      if (_elapsed >= DodgeScreen.survive) {
        _phase = _Phase.cleared;
        _flash = 1;
      }
    } else {
      // クリア後も隕石は流し続ける。急に止まると絵が死ぬ。
      _moveMeteors(dt);
    }

    _flash = math.max(0, _flash - dt * 1.6);
    for (final s in _sparks) {
      s.life -= dt;
      s.pos += s.vel * dt;
      s.vel *= 0.94;
    }
    _sparks.removeWhere((s) => s.life <= 0);

    setState(() {});
  }

  void _moveByKeys(double dt) {
    var dx = 0.0, dy = 0.0;
    if (_keys.contains(LogicalKeyboardKey.arrowLeft) ||
        _keys.contains(LogicalKeyboardKey.keyA)) {
      dx -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowRight) ||
        _keys.contains(LogicalKeyboardKey.keyD)) {
      dx += 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowUp) ||
        _keys.contains(LogicalKeyboardKey.keyW)) {
      dy -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.arrowDown) ||
        _keys.contains(LogicalKeyboardKey.keyS)) {
      dy += 1;
    }
    if (dx == 0 && dy == 0) return;
    final v = Offset(dx, dy) / math.sqrt(dx * dx + dy * dy);
    _aim = _clampToField(_aim + v * 420 * _k * dt);
  }

  void _movePlayer(double dt) {
    // 指にぴったり張り付くとよけた実感が出ないので、少し遅れて追わせる。
    final diff = _aim - _player;
    final maxStep = 620 * _k * dt;
    _player =
        diff.distance <= maxStep ? _aim : _player + diff / diff.distance * maxStep;
    _player = _clampToField(_player);
  }

  Offset _clampToField(Offset p) => Offset(
        p.dx.clamp(_playerR, math.max(_playerR, _field.width - _playerR)),
        p.dy.clamp(_playerR, math.max(_playerR, _field.height - _playerR)),
      );

  void _spawn(double dt) {
    _spawnIn -= dt;
    if (_spawnIn > 0) return;
    final p = (_elapsed / DodgeScreen.survive).clamp(0.0, 1.0);
    _spawnIn = (0.80 - 0.52 * p) * (0.7 + _rnd.nextDouble() * 0.6);

    final r = (11 + _rnd.nextDouble() * 19) * _k;
    final speed = (150 + 200 * p + _rnd.nextDouble() * 70) * _k;

    // 画面外から入れる。真横だけだと単調なので四辺から。
    final w = _field.width, h = _field.height;
    late Offset from;
    switch (_rnd.nextInt(4)) {
      case 0:
        from = Offset(_rnd.nextDouble() * w, -r * 2);
      case 1:
        from = Offset(w + r * 2, _rnd.nextDouble() * h);
      case 2:
        from = Offset(_rnd.nextDouble() * w, h + r * 2);
      default:
        from = Offset(-r * 2, _rnd.nextDouble() * h);
    }

    // 自機の少し手前や奥を狙う。完全な直撃ばかりだと避けゲーにならない。
    final jitter = Offset(
      (_rnd.nextDouble() - 0.5) * w * 0.45,
      (_rnd.nextDouble() - 0.5) * h * 0.45,
    );
    final dir = _player + jitter - from;
    final v = dir.distance == 0 ? const Offset(0, 1) : dir / dir.distance;

    _meteors.add(_Meteor(
      pos: from,
      vel: v * speed,
      r: r,
      spin: (_rnd.nextDouble() - 0.5) * 4,
      seed: _rnd.nextDouble() * 100,
    ));
  }

  void _moveMeteors(double dt) {
    for (final m in _meteors) {
      m.pos += m.vel * dt;
      m.angle += m.spin * dt;
    }
    final pad = 140 * _k;
    _meteors.removeWhere((m) =>
        m.pos.dx < -pad ||
        m.pos.dy < -pad ||
        m.pos.dx > _field.width + pad ||
        m.pos.dy > _field.height + pad);
  }

  void _collide(double dt) {
    _invuln = math.max(0, _invuln - dt);
    if (_invuln > 0) return;
    for (final m in _meteors) {
      // 見た目より少し甘く判定する。理不尽に当たると誕生日どころではない。
      if ((m.pos - _player).distance < m.r + _playerR * 0.62) {
        _hit(m);
        return;
      }
    }
  }

  void _hit(_Meteor m) {
    _lives--;
    _invuln = 1.4;
    _flash = 1;
    for (var i = 0; i < 22; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final sp = (60 + _rnd.nextDouble() * 260) * _k;
      _sparks.add(_Spark(
        pos: _player,
        vel: Offset(math.cos(a), math.sin(a)) * sp,
        life: 0.4 + _rnd.nextDouble() * 0.4,
      ));
    }
    m.vel = -m.vel * 0.4;
    if (_lives <= 0) _phase = _Phase.dead;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GalaxyBackground(
        drift: 3.2,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _hud(),
                const SizedBox(height: 10),
                Expanded(child: _playfield()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hud() {
    final left =
        (DodgeScreen.survive - _elapsed).clamp(0.0, DodgeScreen.survive);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'のこり ${left.toStringAsFixed(1)} 秒',
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(height: 8, color: AppColors.hollow),
                    FractionallySizedBox(
                      widthFactor: 1 - left / DodgeScreen.survive,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: AppColors.sunGradient,
                          boxShadow: [
                            BoxShadow(color: AppColors.sun, blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Opacity(
                opacity: i < _lives ? 1 : 0.22,
                child: Image.asset(sun.icon, width: 26, height: 26),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _playfield() {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        if (_field != size) {
          _field = size;
          if (_player == Offset.zero) {
            _player = size.center(Offset.zero);
            _aim = _player;
          }
        }

        final blink = _invuln > 0 &&
            (_invuln * 12).floor().isEven &&
            _phase == _Phase.playing;

        return Focus(
          autofocus: true,
          onKeyEvent: (node, e) {
            if (e is KeyDownEvent) {
              _keys.add(e.logicalKey);
            } else if (e is KeyUpEvent) {
              _keys.remove(e.logicalKey);
            }
            return KeyEventResult.handled;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _aim = _clampToField(d.localPosition),
            onPanUpdate: (d) => _aim = _clampToField(d.localPosition),
            onTapDown: (d) => _aim = _clampToField(d.localPosition),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.moon.withValues(alpha: 0.14)),
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _FieldPainter(
                        meteors: List.of(_meteors),
                        sparks: List.of(_sparks),
                      ),
                    ),
                    Positioned(
                      left: _player.dx - _playerR,
                      top: _player.dy - _playerR,
                      child: Opacity(
                        opacity: blink ? 0.35 : 1,
                        child: Container(
                          width: _playerR * 2,
                          height: _playerR * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.sun.withValues(alpha: 0.55),
                                blurRadius: 26,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset(sun.icon, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    if (_flash > 0)
                      IgnorePointer(
                        child: ColoredBox(
                          color: (_phase == _Phase.cleared
                                  ? AppColors.star
                                  : AppColors.danger)
                              .withValues(alpha: _flash * 0.45),
                        ),
                      ),
                    if (_phase != _Phase.playing) _overlay(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _overlay() {
    final cleared = _phase == _Phase.cleared;
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: ColoredBox(
        color: AppColors.backgroundDeep.withValues(alpha: 0.62),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cleared ? '回 避 成 功' : '被 弾',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: cleared ? AppColors.sun : AppColors.danger,
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  cleared
                      ? 'ところで、今日が何の日か知ってる?'
                      : '隕石は、誕生日を知らない。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                if (cleared)
                  GlowButton(
                    label: 'つづきを見る',
                    icon: Icons.auto_awesome,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const StoryScreen()),
                    ),
                  )
                else
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      GlowButton(
                        label: 'もういちど',
                        icon: Icons.refresh_rounded,
                        onTap: _reset,
                      ),
                      GlowButton(
                        label: 'タイトルへ',
                        accent: AppColors.moon,
                        filled: false,
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const TitleScreen()),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meteor {
  _Meteor({
    required this.pos,
    required this.vel,
    required this.r,
    required this.spin,
    required this.seed,
  });

  Offset pos;
  Offset vel;
  final double r;
  final double spin;
  final double seed;
  double angle = 0;
}

class _Spark {
  _Spark({required this.pos, required this.vel, required this.life});

  Offset pos;
  Offset vel;
  double life;
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({required this.meteors, required this.sparks});

  final List<_Meteor> meteors;
  final List<_Spark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in meteors) {
      _tail(canvas, m);
      _rock(canvas, m);
    }
    final paint = Paint();
    for (final s in sparks) {
      paint.color = AppColors.sun.withValues(alpha: s.life.clamp(0.0, 1.0));
      canvas.drawCircle(s.pos, 2.4, paint);
    }
  }

  /// 尾は「進行方向の逆に並べたぼかし円」。三角形1枚で描くより先細りが自然に出る。
  /// 長く伸ばすと画面が靄だらけになるので、石の3倍ほどで切り上げる。
  void _tail(Canvas canvas, _Meteor m) {
    final dir = m.vel.distance == 0 ? Offset.zero : m.vel / m.vel.distance;
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (var i = 1; i <= 6; i++) {
      final t = i / 6;
      paint.color = Color.lerp(
        const Color(0xFFFFE3A8),
        const Color(0xFFFF4D1C),
        t,
      )!
          .withValues(alpha: (1 - t) * (1 - t) * 0.85);
      canvas.drawCircle(
        m.pos - dir * (m.r * 0.72 * i),
        m.r * (1 - t * 0.7),
        paint,
      );
    }
    // 石の直前で燃えている部分。ここが一番明るいと、進行方向が一目でわかる。
    canvas.drawCircle(
      m.pos,
      m.r * 1.5,
      Paint()
        ..color = const Color(0xFFFFA23C).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _rock(Canvas canvas, _Meteor m) {
    canvas.save();
    canvas.translate(m.pos.dx, m.pos.dy);
    canvas.rotate(m.angle);

    // 真円だと石に見えないので、半径をゆらした多角形にする。
    final path = Path();
    const n = 9;
    for (var i = 0; i < n; i++) {
      final a = i / n * math.pi * 2;
      final wobble = 0.78 + 0.3 * math.sin(a * 3 + m.seed);
      final p = Offset(math.cos(a), math.sin(a)) * m.r * wobble;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [Color(0xFF9C8AA6), Color(0xFF191124)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: m.r)),
    );
    // クレーター。のっぺりした多角形だと紙に見える。
    final pit = Paint()..color = const Color(0xFF120C1C).withValues(alpha: 0.55);
    for (var i = 0; i < 3; i++) {
      final a = m.seed + i * 2.1;
      canvas.drawCircle(
        Offset(math.cos(a), math.sin(a)) * m.r * 0.38,
        m.r * (0.16 + 0.07 * i),
        pit,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFFFC489).withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FieldPainter old) => true;
}
