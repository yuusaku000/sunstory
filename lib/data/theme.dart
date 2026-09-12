import 'package:flutter/material.dart';

/// 宇宙は「黒」で塗ると安いプラネタリウムになる。
/// 土台を紫寄りの暗色にして、紫・藍・赤紫の星雲を薄く重ねたうえで、
/// 光らせるのは太陽の金と月の銀だけに絞っている。
class AppColors {
  static const background = Color(0xFF090619);
  static const backgroundDeep = Color(0xFF03020C);

  static const nebulaViolet = Color(0xFF3B1E6E);
  static const nebulaMagenta = Color(0xFF6E1F5E);
  static const nebulaBlue = Color(0xFF122E6E);

  static const panelTop = Color(0xFF241A46);
  static const panelBottom = Color(0xFF120C2A);
  static const panelSoft = Color(0xFF1B1338);
  static const hollow = Color(0xFF0C0820);

  /// キャラの色。立ち絵の主色から取っている。名前プレートや発光に使う。
  static const sun = Color(0xFFFFC44D);
  static const sunDeep = Color(0xFFE07A1F);
  static const moon = Color(0xFFCFD8FF);
  static const moonDeep = Color(0xFF7C88D8);
  static const earth = Color(0xFF63D2FF);
  static const earthDeep = Color(0xFF2A6FD6);

  static const star = Color(0xFFF3EFFF);
  static const textPrimary = Color(0xFFEDE9FF);
  static const textMuted = Color(0xFF9A92C4);

  static const danger = Color(0xFFFF6B84);

  static const panelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [panelTop, panelBottom],
  );

  static const sunGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFE39B), Color(0xFFE8892A)],
  );

  static const galaxyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF120A2E), backgroundDeep, Color(0xFF1A0C2C)],
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.sun,
      surface: AppColors.panelSoft,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}
