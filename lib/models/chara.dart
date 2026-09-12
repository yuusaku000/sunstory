import 'package:flutter/material.dart';

/// 立ち絵の表情差分。素材は1枚に4枚並んでいたものを切り出してあり、
/// 左から この順番。名前はファイル名にそのまま使う。
enum Face { normal, surprise, sad, happy }

class Chara {
  const Chara({
    required this.id,
    required this.name,
    required this.accent,
    required this.accentDeep,
  });

  final String id;
  final String name;

  /// 名前プレートと、その子が喋っているときの背景の光。
  final Color accent;
  final Color accentDeep;

  String face(Face f) => 'assets/chara/${id}_${f.name}.png';

  /// 顔だけ切り出した丸アイコン。ミニゲームの自機と、公転アニメで使う。
  String get icon => 'assets/chara/${id}_face.png';
}
