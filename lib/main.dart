import 'package:flutter/material.dart';

import 'data/theme.dart';
import 'screens/title_screen.dart';

void main() => runApp(const TendousetsuApp());

class TendousetsuApp extends StatelessWidget {
  const TendousetsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1兆年と20歳',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const TitleScreen(),
    );
  }
}
