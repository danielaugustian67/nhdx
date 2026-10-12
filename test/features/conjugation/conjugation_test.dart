import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/features/conjugation/conjugation.dart';

/// Conjugation engine (PRD F14): every class, the special verbs and the
/// wrong answers offered in drills.
void main() {
  Map<ConjForm, String> table(List<String> pos, String written, String kana) {
    final c = Conjugator.fromPos(pos, written: written, kana: kana)!;
    return {for (final e in c.table().entries) e.key: e.value.written};
  }

  String kanaOf(List<String> pos, String written, String kana, ConjForm f) =>
      Conjugator.fromPos(pos, written: written, kana: kana)!.conjugate(f).kana;

  test('ichidan: 食べる', () {
    expect(table(['v1', 'vt'], '食べる', 'たべる'), {
      ConjForm.plain: '食べる',
      ConjForm.polite: '食べます',
      ConjForm.negative: '食べない',
      ConjForm.politeNegative: '食べません',
      ConjForm.past: '食べた',
      ConjForm.politePast: '食べました',
      ConjForm.pastNegative: '食べなかった',
      ConjForm.politePastNegative: '食べませんでした',
      ConjForm.te: '食べて',
      ConjForm.potential: '食べられる',
      ConjForm.passive: '食べられる',
      ConjForm.causative: '食べさせる',
      ConjForm.imperative: '食べろ',
      ConjForm.volitional: '食べよう',
      ConjForm.conditionalBa: '食べれば',
      ConjForm.conditionalTara: '食べたら',
      ConjForm.want: '食べたい',
    });
    expect(kanaOf(['v1'], '食べる', 'たべる', ConjForm.polite), 'たべます');
  });

  test('godan: every ending in te / ta / negative / polite', () {
    const cases = {
      '会う': ('会って', '会った', '会わない', '会います'),
      '書く': ('書いて', '書いた', '書かない', '書きます'),
      '泳ぐ': ('泳いで', '泳いだ', '泳がない', '泳ぎます'),
      '話す': ('話して', '話した', '話さない', '話します'),
      '待つ': ('待って', '待った', '待たない', '待ちます'),
      '死ぬ': ('死んで', '死んだ', '死なない', '死にます'),
      '遊ぶ': ('遊んで', '遊んだ', '遊ばない', '遊びます'),
      '読む': ('読んで', '読んだ', '読まない', '読みます'),
      '帰る': ('帰って', '帰った', '帰らない', '帰ります'),
    };
    const codes = {
      'う': 'v5u',
      'く': 'v5k',
      'ぐ': 'v5g',
      'す': 'v5s',
      'つ': 'v5t',
      'ぬ': 'v5n',
      'ぶ': 'v5b',
      'む': 'v5m',
      'る': 'v5r',
    };
    for (final MapEntry(key: verb, value: (te, ta, nai, masu)) in cases.entries) {
      final t = table([codes[verb.substring(verb.length - 1)]!], verb, verb);
      expect(
        [t[ConjForm.te], t[ConjForm.past], t[ConjForm.negative], t[ConjForm.polite]],
        [te, ta, nai, masu],
        reason: verb,
      );
    }
  });

  test('godan advanced forms: 書く', () {
    final t = table(['v5k'], '書く', 'かく');
    expect(t[ConjForm.potential], '書ける');
    expect(t[ConjForm.passive], '書かれる');
    expect(t[ConjForm.causative], '書かせる');
    expect(t[ConjForm.imperative], '書け');
    expect(t[ConjForm.volitional], '書こう');
    expect(t[ConjForm.conditionalBa], '書けば');
    expect(t[ConjForm.conditionalTara], '書いたら');
    expect(t[ConjForm.want], '書きたい');
    expect(t[ConjForm.pastNegative], '書かなかった');
    expect(t[ConjForm.politePastNegative], '書きませんでした');
  });

  test('special verbs: 行く, ある, くださる, 問う, くれる', () {
    final iku = table(['v5k-s', 'vi'], '行く', 'いく');
    expect([iku[ConjForm.te], iku[ConjForm.past], iku[ConjForm.conditionalTara]], ['行って', '行った', '行ったら']);
    expect(iku[ConjForm.polite], '行きます');

    final aru = table(['v5r-i', 'vi'], 'ある', 'ある');
    expect([aru[ConjForm.negative], aru[ConjForm.pastNegative], aru[ConjForm.polite]], ['ない', 'なかった', 'あります']);
    expect(table(['v5r-i'], '有る', 'ある')[ConjForm.negative], 'ない');

    final kudasaru = table(['v5aru', 'vt'], '下さる', 'くださる');
    expect([kudasaru[ConjForm.polite], kudasaru[ConjForm.imperative], kudasaru[ConjForm.te]], ['下さいます', '下さい', '下さって']);
    expect(table(['v5aru'], 'いらっしゃる', 'いらっしゃる')[ConjForm.politePast], 'いらっしゃいました');

    final tou = table(['v5u-s', 'vt'], '問う', 'とう');
    expect([tou[ConjForm.te], tou[ConjForm.past], tou[ConjForm.negative]], ['問うて', '問うた', '問わない']);

    expect(table(['v1-s'], 'くれる', 'くれる')[ConjForm.imperative], 'くれ');
  });

  test('する, 来る and suru nouns', () {
    final suru = table(['vs-i'], '為る', 'する');
    expect(suru[ConjForm.plain], 'する');
    expect([suru[ConjForm.negative], suru[ConjForm.potential], suru[ConjForm.te]], ['しない', 'できる', 'して']);

    final kuru = Conjugator.fromPos(['vk', 'vi'], written: '来る', kana: 'くる')!;
    expect(kuru.conjugate(ConjForm.negative), const Conjugated('来ない', 'こない'));
    expect(kuru.conjugate(ConjForm.polite), const Conjugated('来ます', 'きます'));
    expect(kuru.conjugate(ConjForm.conditionalBa), const Conjugated('来れば', 'くれば'));
    expect(kuru.conjugate(ConjForm.imperative), const Conjugated('来い', 'こい'));
    expect(kuru.conjugate(ConjForm.potential), const Conjugated('来られる', 'こられる'));

    final benkyou = Conjugator.fromPos(['n', 'vs', 'vt'], written: '勉強', kana: 'べんきょう')!;
    expect(benkyou.written, '勉強する');
    expect(benkyou.conjugate(ConjForm.polite), const Conjugated('勉強します', 'べんきょうします'));
    expect(table(['vs-s', 'vt'], '愛する', 'あいする')[ConjForm.past], '愛した');
    expect(table(['vz', 'vt'], '論ずる', 'ろんずる')[ConjForm.negative], '論じない');
  });

  test('adjectives: 高い, いい, 綺麗', () {
    final takai = table(['adj-i'], '高い', 'たかい');
    expect(takai.keys, WordClass.adjI.forms);
    expect(
      [
        takai[ConjForm.negative],
        takai[ConjForm.past],
        takai[ConjForm.pastNegative],
        takai[ConjForm.te],
        takai[ConjForm.conditionalBa],
        takai[ConjForm.adverb],
        takai[ConjForm.polite],
      ],
      ['高くない', '高かった', '高くなかった', '高くて', '高ければ', '高く', '高いです'],
    );

    final ii = table(['adj-ix'], 'いい', 'いい');
    expect(
      [ii[ConjForm.plain], ii[ConjForm.negative], ii[ConjForm.past], ii[ConjForm.te]],
      ['いい', 'よくない', 'よかった', 'よくて'],
    );
    expect(table(['adj-ix'], 'かっこいい', 'かっこいい')[ConjForm.past], 'かっこよかった');

    final kirei = table(['adj-na', 'n'], '綺麗', 'きれい');
    expect(
      [
        kirei[ConjForm.plain],
        kirei[ConjForm.negative],
        kirei[ConjForm.past],
        kirei[ConjForm.te],
        kirei[ConjForm.adverb],
        kirei[ConjForm.politePastNegative],
      ],
      ['綺麗だ', '綺麗じゃない', '綺麗だった', '綺麗で', '綺麗に', '綺麗じゃありませんでした'],
    );
  });

  test('class from part of speech: verbs win, nouns and slips are left out', () {
    expect(WordClass.fromPos(['n', 'vs', 'adj-na'])!.cls, WordClass.adjNa);
    expect(WordClass.fromPos(['aux-v', 'v5r-i'])!.cls, WordClass.aru);
    expect(WordClass.fromPos(['n']), isNull);
    expect(WordClass.fromPos(['adj-no', 'n']), isNull);
    // Spelling that does not fit its class.
    expect(Conjugator.fromPos(['v1'], written: '食べ', kana: 'たべ'), isNull);
  });

  test('wrong answers are plausible and never the right one', () {
    final kaeru = Conjugator.fromPos(['v5r'], written: '帰る', kana: 'かえる')!;
    final wrong = kaeru.distractors(ConjForm.polite);
    expect(wrong, hasLength(3));
    expect(wrong.map((c) => c.written), contains('帰ます'));
    expect(wrong.map((c) => c.written), isNot(contains('帰ります')));

    final kaku = Conjugator.fromPos(['v5k'], written: '書く', kana: 'かく')!;
    final te = kaku.distractors(ConjForm.te).map((c) => c.written);
    expect(te, isNot(contains('書いて')));
    expect(te.toSet(), hasLength(3));

    final shizuka = Conjugator.fromPos(['adj-na'], written: '静か', kana: 'しずか')!;
    expect(shizuka.distractors(ConjForm.negative).map((c) => c.written), contains('静かくない'));

    for (final c in [kaeru, kaku, shizuka]) {
      for (final f in c.forms) {
        final right = c.conjugate(f).written;
        final d = c.distractors(f);
        expect(d.map((x) => x.written), isNot(contains(right)), reason: '${c.written} $f');
        expect(d.map((x) => x.written).toSet(), hasLength(d.length));
      }
    }
  });
}
