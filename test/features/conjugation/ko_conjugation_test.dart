import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/features/conjugation/ko_conjugation.dart';

void main() {
  KoConjugator verb(String w) => KoConjugator.of(w, adjective: false)!;
  KoConjugator adj(String w) => KoConjugator.of(w, adjective: true)!;

  // word: polite, past, formal, future, honorific, so
  const verbs = {
    '가다': ['가요', '갔어요', '갑니다', '갈 거예요', '가세요', '가서'],
    '오다': ['와요', '왔어요', '옵니다', '올 거예요', '오세요', '와서'],
    '먹다': ['먹어요', '먹었어요', '먹습니다', '먹을 거예요', '드세요', '먹어서'],
    '마시다': ['마셔요', '마셨어요', '마십니다', '마실 거예요', '마시세요', '마셔서'],
    '보다': ['봐요', '봤어요', '봅니다', '볼 거예요', '보세요', '봐서'],
    '하다': ['해요', '했어요', '합니다', '할 거예요', '하세요', '해서'],
    '자다': ['자요', '잤어요', '잡니다', '잘 거예요', '주무세요', '자서'],
    '읽다': ['읽어요', '읽었어요', '읽습니다', '읽을 거예요', '읽으세요', '읽어서'],
    '쓰다': ['써요', '썼어요', '씁니다', '쓸 거예요', '쓰세요', '써서'],
    '듣다': ['들어요', '들었어요', '듣습니다', '들을 거예요', '들으세요', '들어서'],
    '배우다': ['배워요', '배웠어요', '배웁니다', '배울 거예요', '배우세요', '배워서'],
    '가르치다': ['가르쳐요', '가르쳤어요', '가르칩니다', '가르칠 거예요', '가르치세요', '가르쳐서'],
    '알다': ['알아요', '알았어요', '압니다', '알 거예요', '아세요', '알아서'],
    '모르다': ['몰라요', '몰랐어요', '모릅니다', '모를 거예요', '모르세요', '몰라서'],
    '주다': ['줘요', '줬어요', '줍니다', '줄 거예요', '주세요', '줘서'],
    '받다': ['받아요', '받았어요', '받습니다', '받을 거예요', '받으세요', '받아서'],
    '앉다': ['앉아요', '앉았어요', '앉습니다', '앉을 거예요', '앉으세요', '앉아서'],
    '서다': ['서요', '섰어요', '섭니다', '설 거예요', '서세요', '서서'],
    '걷다': ['걸어요', '걸었어요', '걷습니다', '걸을 거예요', '걸으세요', '걸어서'],
    '뛰다': ['뛰어요', '뛰었어요', '뜁니다', '뛸 거예요', '뛰세요', '뛰어서'],
    '만들다': ['만들어요', '만들었어요', '만듭니다', '만들 거예요', '만드세요', '만들어서'],
    '열다': ['열어요', '열었어요', '엽니다', '열 거예요', '여세요', '열어서'],
    '닫다': ['닫아요', '닫았어요', '닫습니다', '닫을 거예요', '닫으세요', '닫아서'],
    '입다': ['입어요', '입었어요', '입습니다', '입을 거예요', '입으세요', '입어서'],
    '씻다': ['씻어요', '씻었어요', '씻습니다', '씻을 거예요', '씻으세요', '씻어서'],
    '웃다': ['웃어요', '웃었어요', '웃습니다', '웃을 거예요', '웃으세요', '웃어서'],
    '되다': ['돼요', '됐어요', '됩니다', '될 거예요', '되세요', '돼서'],
    '쉬다': ['쉬어요', '쉬었어요', '쉽니다', '쉴 거예요', '쉬세요', '쉬어서'],
    '부르다': ['불러요', '불렀어요', '부릅니다', '부를 거예요', '부르세요', '불러서'],
    '도와주다': ['도와줘요', '도와줬어요', '도와줍니다', '도와줄 거예요', '도와주세요', '도와줘서'],
    '내리다': ['내려요', '내렸어요', '내립니다', '내릴 거예요', '내리세요', '내려서'],
    '돕다': ['도와요', '도왔어요', '돕습니다', '도울 거예요', '도우세요', '도와서'],
    '낫다': ['나아요', '나았어요', '낫습니다', '나을 거예요', '나으세요', '나아서'],
    '공부하다': ['공부해요', '공부했어요', '공부합니다', '공부할 거예요', '공부하세요', '공부해서'],
  };

  // word: polite, past, formal, future
  const adjectives = {
    '좋다': ['좋아요', '좋았어요', '좋습니다', '좋을 거예요'],
    '크다': ['커요', '컸어요', '큽니다', '클 거예요'],
    '바쁘다': ['바빠요', '바빴어요', '바쁩니다', '바쁠 거예요'],
    '예쁘다': ['예뻐요', '예뻤어요', '예쁩니다', '예쁠 거예요'],
    '배고프다': ['배고파요', '배고팠어요', '배고픕니다', '배고플 거예요'],
    '슬프다': ['슬퍼요', '슬펐어요', '슬픕니다', '슬플 거예요'],
    '덥다': ['더워요', '더웠어요', '덥습니다', '더울 거예요'],
    '춥다': ['추워요', '추웠어요', '춥습니다', '추울 거예요'],
    '가깝다': ['가까워요', '가까웠어요', '가깝습니다', '가까울 거예요'],
    '쉽다': ['쉬워요', '쉬웠어요', '쉽습니다', '쉬울 거예요'],
    '빠르다': ['빨라요', '빨랐어요', '빠릅니다', '빠를 거예요'],
    '다르다': ['달라요', '달랐어요', '다릅니다', '다를 거예요'],
    '길다': ['길어요', '길었어요', '깁니다', '길 거예요'],
    '멀다': ['멀어요', '멀었어요', '멉니다', '멀 거예요'],
    '많다': ['많아요', '많았어요', '많습니다', '많을 거예요'],
    '짧다': ['짧아요', '짧았어요', '짧습니다', '짧을 거예요'],
    '느리다': ['느려요', '느렸어요', '느립니다', '느릴 거예요'],
    '비싸다': ['비싸요', '비쌌어요', '비쌉니다', '비쌀 거예요'],
    '맛있다': ['맛있어요', '맛있었어요', '맛있습니다', '맛있을 거예요'],
    '피곤하다': ['피곤해요', '피곤했어요', '피곤합니다', '피곤할 거예요'],
    '그렇다': ['그래요', '그랬어요', '그렇습니다', '그럴 거예요'],
    '빨갛다': ['빨개요', '빨갰어요', '빨갛습니다', '빨갈 거예요'],
    '하얗다': ['하얘요', '하얬어요', '하얗습니다', '하얄 거예요'],
    '같다': ['같아요', '같았어요', '같습니다', '같을 거예요'],
  };

  test('verbs in the polite, past, formal, future, honorific and -아서 forms', () {
    for (final MapEntry(key: word, value: want) in verbs.entries) {
      final c = verb(word);
      expect(
        [KoForm.polite, KoForm.past, KoForm.formal, KoForm.future, KoForm.honorific, KoForm.so].map(c.conjugate),
        want,
        reason: '$word (${c.cls.name})',
      );
    }
  });

  test('adjectives, with the ㅂ, 르, 으 and ㅎ irregulars', () {
    for (final MapEntry(key: word, value: want) in adjectives.entries) {
      final c = adj(word);
      expect([KoForm.polite, KoForm.past, KoForm.formal, KoForm.future].map(c.conjugate), want, reason: word);
    }
  });

  test('formal past, -고, -지 않아요 and -고 싶어요', () {
    expect(verb('가다').conjugate(KoForm.formalPast), '갔습니다');
    expect(verb('듣다').conjugate(KoForm.formalPast), '들었습니다');
    expect(verb('먹다').conjugate(KoForm.and), '먹고');
    expect(adj('춥다').conjugate(KoForm.longNegative), '춥지 않아요');
    expect(verb('보다').conjugate(KoForm.want), '보고 싶어요');
  });

  test('안 goes before 하다 in noun + 하다 verbs, else before the word', () {
    expect(verb('가다').conjugate(KoForm.negative), '안 가요');
    expect(verb('공부하다').conjugate(KoForm.negative), '공부 안 해요');
    expect(verb('좋아하다').conjugate(KoForm.negative), '안 좋아해요');
    expect(verb('하다').conjugate(KoForm.negative), '안 해요');
    expect(adj('피곤하다').conjugate(KoForm.negative), '안 피곤해요');
    expect(adj('바쁘다').conjugate(KoForm.negative), '안 바빠요');
  });

  test('forms that do not apply are left out', () {
    expect(adj('크다').forms, isNot(contains(KoForm.want)));
    expect(verb('있다').forms, isNot(contains(KoForm.negative)));
    expect(verb('없다').forms, isNot(contains(KoForm.want)));
    expect(verb('알다').forms, isNot(contains(KoForm.negative)));
    expect(KoConjugator.of('이다', adjective: false), isNull);
    expect(KoConjugator.of('사과', adjective: false), isNull);
  });

  test('three distinct wrong answers for every form of every word', () {
    for (final (word, isAdj) in [
      for (final w in verbs.keys) (w, false),
      for (final w in adjectives.keys) (w, true),
    ]) {
      final c = KoConjugator.of(word, adjective: isAdj)!;
      for (final f in c.forms) {
        final wrong = c.distractors(f);
        expect(wrong, hasLength(3), reason: '$word ${f.name}');
        expect(wrong.toSet(), hasLength(3), reason: '$word ${f.name}');
        expect(wrong, isNot(contains(c.conjugate(f))), reason: '$word ${f.name}');
      }
    }
    // The typical mistakes come first.
    expect(verb('듣다').distractors(KoForm.polite), contains('듣어요'));
    expect(adj('덥다').distractors(KoForm.polite), contains('덥어요'));
    expect(verb('먹다').distractors(KoForm.polite), contains('먹아요'));
    // The other negative says the same thing.
    expect(verb('가다').distractors(KoForm.longNegative), isNot(contains('안 가요')));
  });
}
