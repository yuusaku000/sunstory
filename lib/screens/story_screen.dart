import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/charas.dart';
import '../data/script.dart';
import '../data/theme.dart';
import '../models/chara.dart';
import '../widgets/boom.dart';
import '../widgets/galaxy_background.dart';
import '../widgets/orbit_view.dart';
import 'ending_screen.dart';

/// 本編。タップで1行ずつ進む。
///
/// 台本(script.dart)の側に演出の指示を持たせて、この画面は
/// 「言われたとおりに立たせて、喋らせて、揺らす」だけにしてある。
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  /// 追いつくために必要な連打数。多すぎると飽きるが、
  /// 少ないと「追いつけない」が体に残らない。
  static const chaseTaps = 18;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin {
  int _index = 0;
  int _shown = 0;
  Timer? _typer;
  int _chaseTaps = 0;

  late final AnimationController _shakeC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _chapterC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _kickC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final AnimationController _boomC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  StoryLine get _line => script[_index];
  bool get _typing => _shown < _line.text.length;
  bool get _chaseLocked =>
      _line.stage == LineStage.chase && _chaseTaps < StoryScreen.chaseTaps;

  @override
  void initState() {
    super.initState();
    _enter();
  }

  @override
  void dispose() {
    _typer?.cancel();
    _shakeC.dispose();
    _chapterC.dispose();
    _kickC.dispose();
    _boomC.dispose();
    super.dispose();
  }

  void _enter() {
    _shown = 0;
    _typer?.cancel();
    _typer = Timer.periodic(const Duration(milliseconds: 26), (t) {
      if (_shown >= _line.text.length) {
        t.cancel();
        return;
      }
      setState(() => _shown++);
    });
    if (_line.shake) _shakeC.forward(from: 0);
    if (_line.chapter != null) _chapterC.forward(from: 0);
    if (_line.stage == LineStage.boom) _boomC.forward(from: 0);
  }

  void _onTap() {
    if (_typing) {
      _typer?.cancel();
      setState(() => _shown = _line.text.length);
      return;
    }
    if (_chaseLocked) return;
    _advance();
  }

  void _advance() {
    if (_index >= script.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EndingScreen()),
      );
      return;
    }
    setState(() {
      _index++;
      _chaseTaps = 0;
    });
    _enter();
  }

  void _chase() {
    _kickC.forward(from: 0);
    setState(() => _chaseTaps++);
    if (_chaseTaps >= StoryScreen.chaseTaps) {
      // 連打しきった瞬間に進むと手ごたえが消えるので、少し余韻を置く。
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _line.stage == LineStage.chase) _advance();
      });
    }
  }

  /// その行で誰が立っていて、どんな顔をしているかは、
  /// 台本を頭から畳んで求める。各行に全部書くと台本が読めなくなる。
  ({List<String> cast, Map<String, Face> faces}) _stageAt(int index) {
    var cast = <String>[];
    final faces = <String, Face>{};
    for (var i = 0; i <= index; i++) {
      final l = script[i];
      if (l.cast != null) cast = l.cast!;
      if (l.speaker != null && l.face != null) faces[l.speaker!] = l.face!;
      faces.addAll(l.faces);
    }
    return (cast: cast, faces: faces);
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    final speaker = line.speaker == null ? null : charaById(line.speaker!);
    final stage = _stageAt(_index);
    final isOrbit = line.stage == LineStage.orbit ||
        line.stage == LineStage.orbitFinal;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: GalaxyBackground(
          child: AnimatedBuilder(
            animation: _shakeC,
            builder: (context, child) {
              // 減衰する横揺れ。等速で揺らすと振動する箱になる。
              final a = (1 - _shakeC.value) * math.sin(_shakeC.value * 46) * 14;
              return Transform.translate(offset: Offset(a, a * 0.35), child: child);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 喋っている子の色を背景にうっすら混ぜる。誰の場面かが体に入る。
                // 濃くすると星空が濁って茶色くなるので、中心だけ色を置いて
                // 外側は紫のまま暗く落とす。
                AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.15,
                      stops: const [0.0, 0.45, 1.0],
                      colors: [
                        (speaker?.accent ?? AppColors.nebulaViolet)
                            .withValues(alpha: 0.10),
                        AppColors.nebulaViolet.withValues(alpha: 0.26),
                        AppColors.backgroundDeep.withValues(alpha: 0.80),
                      ],
                    ),
                  ),
                ),
                if (isOrbit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 190),
                    child: OrbitView(
                      mode: line.stage == LineStage.orbit
                          ? OrbitMode.earthAndMoon
                          : OrbitMode.moonOnly,
                    ),
                  )
                else
                  _figures(stage, line.speaker),
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(),
                      _panel(line, speaker),
                    ],
                  ),
                ),
                if (line.chapter != null) _chapterTitle(line.chapter!),
                // 爆発はいちばん上。台詞ごと白く飛ばしたいので前面に置く。
                AnimatedBuilder(
                  animation: _boomC,
                  builder: (context, _) => Boom(progress: _boomC.value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _figures(({List<String> cast, Map<String, Face> faces}) stage, String? speaking) {
    if (stage.cast.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight * 0.82;
        final w = h * 0.42;
        final n = stage.cast.length;

        return AnimatedBuilder(
          animation: _kickC,
          builder: (context, _) {
            // 連打パートの太陽だけ、前のめりに跳ねさせる。
            final kick = math.sin(_kickC.value * math.pi) * 18;

            return Stack(
              children: [
                for (var i = 0; i < n; i++)
                  _figure(
                    id: stage.cast[i],
                    face: stage.faces[stage.cast[i]] ?? Face.normal,
                    speaking: stage.cast[i] == speaking,
                    left: box.maxWidth * ((i + 0.5) / n) -
                        w / 2 +
                        (stage.cast[i] == 'sun' ? kick : 0),
                    width: w,
                    height: h,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _figure({
    required String id,
    required Face face,
    required bool speaking,
    required double left,
    required double width,
    required double height,
  }) {
    final chara = charaById(id);
    return Positioned(
      left: left,
      bottom: 0,
      width: width,
      height: height,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 260),
        scale: speaking ? 1.0 : 0.95,
        alignment: Alignment.bottomCenter,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (speaking)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      chara.accent.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 170),
              child: ColorFiltered(
                key: ValueKey('$id-${face.name}-$speaking'),
                // 喋っていない子は暗く落とす。全員同じ明るさだと台詞の主が迷子になる。
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: speaking ? 0.0 : 0.45),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  chara.face(face),
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(StoryLine line, Chara? speaker) {
    final accent = speaker?.accent ?? AppColors.moon;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.panelTop.withValues(alpha: 0.92),
                AppColors.panelBottom.withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.38)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (speaker != null) _namePlate(line.alias ?? speaker.name, accent),
              if (speaker != null) const SizedBox(height: 10),
              Text(
                line.text.substring(0, _shown),
                style: TextStyle(
                  fontSize: 17,
                  height: 1.9,
                  letterSpacing: 0.6,
                  // 地の文は少し引いた色にして、台詞と役割を分ける。
                  color: speaker == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontStyle: speaker == null ? FontStyle.italic : null,
                ),
              ),
              if (line.stage == LineStage.chase) ...[
                const SizedBox(height: 16),
                _chasePanel(),
              ] else ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: _nextMark(accent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _namePlate(String name, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.16),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: accent,
          shadows: [Shadow(color: accent.withValues(alpha: 0.6), blurRadius: 10)],
        ),
      ),
    );
  }

  Widget _nextMark(Color accent) {
    if (_typing) return const SizedBox(height: 18);
    return _Bounce(
      child: Icon(Icons.arrow_drop_down_rounded, color: accent, size: 26),
    );
  }

  /// 追いかけるパート。距離のバーは何回押しても満タンのまま動かない。
  /// ここで「おかしい」と思わせておくと、第四章が効く。
  Widget _chasePanel() {
    final done = _chaseTaps >= StoryScreen.chaseTaps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'きょり',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(height: 10, color: AppColors.hollow),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.moon.withValues(alpha: 0.9),
                            AppColors.earth.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ちぢまった距離 0.0%',
              style: TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MashButton(
                enabled: !done,
                label: done ? '……追いつかない' : '追いかける!',
                onTap: _chase,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$_chaseTaps / ${StoryScreen.chaseTaps}',
              style: const TextStyle(
                fontSize: 13,
                letterSpacing: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chapterTitle(String title) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _chapterC,
        builder: (context, _) {
          final v = _chapterC.value;
          // 出て、留まって、消える。留まりを長めに取らないと読めない。
          final opacity = v < 0.18
              ? v / 0.18
              : v > 0.78
                  ? (1 - v) / 0.22
                  : 1.0;
          if (opacity <= 0) return const SizedBox.shrink();
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Align(
              alignment: const Alignment(0, -0.62),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDeep.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    top: BorderSide(color: AppColors.sun.withValues(alpha: 0.5)),
                    bottom:
                        BorderSide(color: AppColors.sun.withValues(alpha: 0.5)),
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    letterSpacing: 5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    shadows: [Shadow(color: AppColors.sun, blurRadius: 18)],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ▼ の上下。止まっている三角だと「待っている」に見えない。
class _Bounce extends StatefulWidget {
  const _Bounce({required this.child});
  final Widget child;

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _c.value * 5), child: child),
      child: widget.child,
    );
  }
}

class _MashButton extends StatefulWidget {
  const _MashButton({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_MashButton> createState() => _MashButtonState();
}

class _MashButtonState extends State<_MashButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    return GestureDetector(
      onTapDown: on ? (_) => setState(() => _down = true) : null,
      onTapUp: on ? (_) => setState(() => _down = false) : null,
      onTapCancel: on ? () => setState(() => _down = false) : null,
      onTap: on ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: EdgeInsets.symmetric(vertical: _down ? 12 : 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: on ? AppColors.sunGradient : null,
          color: on ? null : AppColors.hollow,
          boxShadow: on
              ? [
                  BoxShadow(
                    color: AppColors.sun.withValues(alpha: _down ? 0.6 : 0.3),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: on ? const Color(0xFF2A1600) : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
