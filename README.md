# 1兆年と20歳

たいようくんの誕生日ゲーム。

隕石をよけるだけのミニゲーム……だと思わせておいて、クリアすると立ち絵つきの
ストーリーが始まる。最後に「誕生日おめでとう」が浮かび上がる。

## 遊ぶ

https://yuusaku000.github.io/sunstory/

更新するときは、コードを直してから:

```bash
bash tool/deploy.sh
```

`flutter build web` した結果を `gh-pages` ブランチに push し直す。
GitHub Pages はそのブランチを見ている（`main` にはソースしか入っていない）。

## 手元で動かす

```bash
flutter run -d chrome
```

Web サーバーだけ立てたいときは `flutter run -d web-server --web-port=5123`
（`.claude/launch.json` にも同じ設定を入れてある）。

1. **SOLAR DODGE** — たいようをドラッグ（または矢印キー/WASD）で動かして30秒よける。ライフ3。
2. クリアすると本編へ。画面タップで1行ずつ進む。
3. 第三章の連打パートは、何回押しても距離が縮まらない。これは仕様。
4. 第四章で種明かし、第五章で決着（地球が吹き飛ぶ）。
5. 最後に誕生日メッセージと「最初から始める」ボタン。

## 中身

| 場所 | 何が入っているか |
| --- | --- |
| `lib/data/script.dart` | 台本。セリフ・表情・誰が立っているか・演出の指示が全部ここ |
| `lib/data/charas.dart` | たいよう・月・地球の定義（名前と色） |
| `lib/data/theme.dart` | 銀河の配色 |
| `lib/screens/title_screen.dart` | タイトル（まだ「ただの避けゲー」の顔をしている） |
| `lib/screens/dodge_screen.dart` | 隕石よけ本体 |
| `lib/screens/story_screen.dart` | ノベルパート。台本の指示どおりに立たせて喋らせる |
| `lib/screens/ending_screen.dart` | 誕生日おめでとう |
| `lib/widgets/galaxy_background.dart` | 全画面の星空と星雲 |
| `lib/widgets/orbit_view.dart` | 公転アニメ。第四章は地球＋月、第五章は月だけがたいようを回る |
| `lib/widgets/boom.dart` | 地球が吹き飛ぶ閃光と衝撃波 |

セリフを足したり表情を変えたいときは `lib/data/script.dart` だけ触ればいい。

## 立ち絵

元絵は `art/` に置いてある。1枚に4表情が横並びになっているもの3枚。

```bash
python tool/cut_sprites.py    # art/ → assets/chara/ を作り直す
```

ゲームが読むのは切り出し後の `assets/chara/` のほう。

- `{sun,moon,earth}_{normal,surprise,sad,happy}.png` … 全身（左から 普通・驚き・落ち込み・喜び）
- `{sun,moon,earth}_face.png` … 顔だけ。ミニゲームの自機と公転アニメで使う
