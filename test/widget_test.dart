import 'package:flutter_test/flutter_test.dart';

import 'package:tendousetsu/data/script.dart';
import 'package:tendousetsu/main.dart';

void main() {
  testWidgets('タイトルは隕石よけゲームの顔をしている', (tester) async {
    await tester.pumpWidget(const TendousetsuApp());
    expect(find.text('SOLAR  DODGE'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  test('台本の話者は全員 charas に存在する', () {
    const known = {'sun', 'moon', 'earth'};
    for (final line in script) {
      if (line.speaker != null) {
        expect(known, contains(line.speaker), reason: line.text);
      }
      for (final id in line.cast ?? const <String>[]) {
        expect(known, contains(id), reason: line.text);
      }
      for (final id in line.faces.keys) {
        expect(known, contains(id), reason: line.text);
      }
    }
  });

  test('種明かしは追いかけるパートより後に来る', () {
    final chase = script.indexWhere((l) => l.stage == LineStage.chase);
    final orbit = script.indexWhere((l) => l.stage == LineStage.orbit);
    expect(chase, greaterThan(-1));
    expect(orbit, greaterThan(chase));
  });
}
