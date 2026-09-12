import '../models/chara.dart';

/// その行で画面がどう振る舞うか。台本の途中に演出を差し込みたいだけなので、
/// 画面を分けずに1行の属性として持たせている。
enum LineStage {
  /// ふつうの会話。タップで次へ。
  talk,

  /// 連打パート。追いかけても距離が縮まらないのを、指で体験させる。
  chase,

  /// 種明かし。立ち絵を引っ込めて、公転アニメを大きく出す。
  orbit,

  /// 地球が吹き飛ぶ瞬間。閃光と衝撃波を重ねる。
  boom,

  /// 決着後の公転。地球が消えて、月が太陽のまわりを回っている。
  orbitFinal,
}

class StoryLine {
  const StoryLine(
    this.text, {
    this.speaker,
    this.face,
    this.cast,
    this.faces = const {},
    this.alias,
    this.stage = LineStage.talk,
    this.chapter,
    this.shake = false,
  });

  /// nullなら地の文。
  final String? speaker;
  final String text;

  /// 話者の表情。省略すると前の行のまま。
  final Face? face;

  /// その行で立っているキャラ。左から並ぶ。省略すると前の行を引き継ぐ。
  final List<String>? cast;

  /// 話者以外の表情を変えたいときに使う。連れ去られる月など。
  final Map<String, Face> faces;

  /// 名前プレートの上書き。正体を伏せたいときだけ。
  final String? alias;

  final LineStage stage;

  /// 指定すると、その行の頭で章タイトルが浮かぶ。
  final String? chapter;

  /// 画面を揺らす。多用すると効かなくなるので、重力が歪む瞬間だけ。
  final bool shake;
}

const script = <StoryLine>[
  // ------------------------------------------------------------ 第一章
  StoryLine(
    '宇宙のまんなか。ひとつの恒星が、朝からずっとそわそわしていた。',
    cast: ['sun'],
    faces: {'sun': Face.normal},
    chapter: '第一章　1兆年と20歳',
  ),
  StoryLine('ふふ……ついに来た。ついに、この日が来た。',
      speaker: 'sun', face: Face.happy),
  StoryLine('今日は俺の誕生日だ。ちょうど——1兆年と20歳。',
      speaker: 'sun', face: Face.normal),
  StoryLine('1兆年のほうはさすがに大台である。20歳のほうは、正直おまけである。'),
  StoryLine('そして今夜は、前々から付き合ってる月ちゃんと、ふたりきりの誕生日会……!',
      speaker: 'sun', face: Face.happy),
  StoryLine('1兆年と20年ぶんの生涯で、いちばん浮かれた顔をしていた。'),
  StoryLine('たいようくーん! おたんじょうび、おめでとう!',
      speaker: 'moon', face: Face.happy, cast: ['sun', 'moon']),
  StoryLine('月ちゃん! 来てくれたんだ!', speaker: 'sun', face: Face.happy),
  StoryLine('ケーキ焼いてきたの。クレーターの形にしてみた。',
      speaker: 'moon', face: Face.happy),
  StoryLine('それ、ただの穴じゃない?', speaker: 'sun', face: Face.surprise),
  StoryLine('……へこみ、って言って。', speaker: 'moon', face: Face.sad),
  StoryLine('へこみ。うん、へこみだ。宇宙でいちばんかわいいへこみだ。',
      speaker: 'sun', face: Face.happy),
  StoryLine('ふふっ。じゃあ、ろうそく1兆本、いっしょに消そうね。',
      speaker: 'moon', face: Face.happy),
  StoryLine('1兆本は燃えるだろ。主に俺が。', speaker: 'sun', face: Face.normal),

  // ------------------------------------------------------------ 第二章
  StoryLine('——そのときだった。', chapter: '第二章　連れ去られた月'),
  StoryLine('重力が、ぐにゃりと歪んだ。',
      faces: {'sun': Face.surprise, 'moon': Face.surprise}, shake: true),
  StoryLine('——見つけた。', speaker: 'earth', alias: '???', face: Face.normal),
  StoryLine('だ、誰だ!?', speaker: 'sun', face: Face.surprise),
  StoryLine('地球。悪いが、その月はうちのだ。',
      speaker: 'earth', face: Face.normal, cast: ['sun', 'earth', 'moon']),
  StoryLine('え、えっ!? わたし、うちのって……', speaker: 'moon', face: Face.surprise),
  StoryLine('衛星は惑星のもとへ帰る。宇宙のルールだろう。',
      speaker: 'earth', face: Face.normal),
  StoryLine('衛星!? 月ちゃんは俺の彼女だ!!', speaker: 'sun', face: Face.surprise),
  StoryLine('恒星の言うことは、いつもスケールばかりでかい。',
      speaker: 'earth', face: Face.happy),
  StoryLine('ぐっ……', speaker: 'sun', face: Face.sad),
  StoryLine('じゃあな、今日の主役。月は連れていく。',
      speaker: 'earth', face: Face.happy),
  StoryLine('地球は月の手をつかみ、とんでもない速度で遠ざかっていった。',
      faces: {'moon': Face.sad, 'sun': Face.surprise}, shake: true),
  StoryLine('たいようくーーーん!!', speaker: 'moon', face: Face.sad),
  StoryLine('月ちゃーーーーん!!!',
      speaker: 'sun', face: Face.sad, cast: ['sun']),

  // ------------------------------------------------------------ 第三章
  StoryLine('たいようは走った。1兆年ぶんの本気で走った。',
      chapter: '第三章　追いつかない'),
  StoryLine('待て! 待てーーーっ!!',
      speaker: 'sun', face: Face.surprise, stage: LineStage.chase),
  StoryLine('はぁっ……はぁっ……', speaker: 'sun', face: Face.sad),
  StoryLine('なんで……なんで、ぜんぜん近づかないんだ……',
      speaker: 'sun', face: Face.sad),
  StoryLine('距離、0.0%。どれだけ足を動かしても、数字は1ミリも動かなかった。'),
  StoryLine('俺、こんなに全力なのに……', speaker: 'sun', face: Face.sad),

  // ------------------------------------------------------------ 第四章
  StoryLine('——そのとき、たいようは気づいてしまった。',
      cast: [], stage: LineStage.orbit, chapter: '第四章　動いていたのは'),
  StoryLine('たいようは、一歩も動いていなかった。', stage: LineStage.orbit),
  StoryLine('……え?',
      speaker: 'sun', face: Face.surprise, stage: LineStage.orbit),
  StoryLine('たいようはただ、その場でぐるぐると自転していただけだった。',
      stage: LineStage.orbit),
  StoryLine('走っているつもりで、回っていただけだった。', stage: LineStage.orbit),
  StoryLine('そして、その周りを——', stage: LineStage.orbit),
  StoryLine('月と地球のほうが、回っていたのだ。', stage: LineStage.orbit),
  StoryLine('……俺が、中心……?',
      speaker: 'sun', face: Face.sad, cast: ['sun']),
  StoryLine('やっと気づいた? それ、いつか『地動説』って呼ばれるやつだよ。',
      speaker: 'earth', face: Face.happy, cast: ['sun', 'earth']),
  StoryLine('じゃあ、今まで俺が信じてたのは……', speaker: 'sun', face: Face.normal),
  StoryLine('『天動説』。おめでとう、失恋といっしょに科学史まで始まった。',
      speaker: 'earth', face: Face.happy),
  StoryLine('うるさい', speaker: 'sun', face: Face.sad),
  StoryLine('——これが、地動説と天動説のはじまりであった。'),

  // ------------------------------------------------------------ 第五章
  StoryLine('……ところで。',
      cast: ['sun', 'earth', 'moon'],
      faces: {'sun': Face.normal, 'earth': Face.happy, 'moon': Face.sad},
      chapter: '第五章　軌道修正'),
  StoryLine('なあ、地球。', speaker: 'sun', face: Face.normal),
  StoryLine('なんだ。負け惜しみなら短く頼む。',
      speaker: 'earth', face: Face.happy),
  StoryLine('さっき、もうひとつ気づいたことがあってさ。',
      speaker: 'sun', face: Face.normal),
  StoryLine('へえ。', speaker: 'earth', face: Face.normal),
  StoryLine('俺——恒星なんだよな。', speaker: 'sun', face: Face.happy),
  StoryLine('……は?', speaker: 'earth', face: Face.surprise),
  StoryLine('1兆年と20年ぶんの熱が、一点に集まった。',
      faces: {'sun': Face.happy}),
  StoryLine('ちょっ、待て、話し合お——', speaker: 'earth', face: Face.surprise),
  StoryLine('——次の瞬間、宇宙がまばゆく光った。',
      stage: LineStage.boom, shake: true),
  StoryLine('地球は、木っ端みじんに吹き飛んだ。',
      cast: ['sun', 'moon'], shake: true),
  StoryLine('あとに残ったのは、ちいさな岩のかけらだけだった。'),
  StoryLine('……たいようくん?', speaker: 'moon', face: Face.surprise),
  StoryLine('月ちゃん。おいで。', speaker: 'sun', face: Face.happy),
  StoryLine('月をつかまえていた重力が、消えた。',
      cast: [], stage: LineStage.orbitFinal),
  StoryLine('月は、いちばん近くにあった重力に引き寄せられた。',
      stage: LineStage.orbitFinal),
  StoryLine('——たいようの、重力に。', stage: LineStage.orbitFinal),
  StoryLine('わ、わたし、たいようくんの周りを回ってる!',
      speaker: 'moon',
      face: Face.happy,
      cast: ['sun', 'moon'],
      faces: {'sun': Face.happy}),
  StoryLine('うん。もう、誰にも連れていかせない。',
      speaker: 'sun', face: Face.happy),
  StoryLine('公転周期、どれくらいにする?', speaker: 'moon', face: Face.happy),
  StoryLine('決めなくていい。ずっとでいい。', speaker: 'sun', face: Face.happy),
  StoryLine('ふふっ。じゃあ、ケーキのつづき、しよ。',
      speaker: 'moon', face: Face.happy),
  StoryLine('こうして宇宙は、たいようを中心に回りはじめた。', cast: []),
  StoryLine('これが、地動説の——ほんとうの始まりである。'),
  StoryLine('1兆年と20回目の、ある誕生日の話。'),
];
