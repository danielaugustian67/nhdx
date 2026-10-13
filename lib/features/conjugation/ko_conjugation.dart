/// Rule-based conjugation of Korean verbs and adjectives: the endings a
/// beginner (TOPIK I) learns, with the 하다 verbs, ㄹ stems and the ㅂ, ㄷ,
/// ㅅ, 르, 으 and ㅎ irregulars. Pure functions, no database.
library;

/// The forms a word can be put in, in the order the table lists them.
enum KoForm {
  /// -아요/어요: polite present (해요체).
  polite,

  /// -았어요/었어요.
  past,

  /// -(스)ㅂ니다: formal present.
  formal,

  /// -았습니다/었습니다.
  formalPast,

  /// 안 + -아요/어요.
  negative,

  /// -지 않아요.
  longNegative,

  /// -고 싶어요: want to (verbs).
  want,

  /// -(으)ㄹ 거예요: will, probably.
  future,

  /// -(으)세요: polite request / honorific.
  honorific,

  /// -고: and.
  and,

  /// -아서/어서: so, and then.
  so;

  static KoForm? parse(String name) => values.where((f) => f.name == name).firstOrNull;
}

/// How a stem changes before an ending.
enum KoClass {
  regular,

  /// 하다: 해요, 합니다.
  ha,

  /// ㄹ stems drop the ㄹ before ㄴ, ㅂ, ㅅ: 살다 → 삽니다, 사세요.
  rieul,

  /// ㅂ → 우 before a vowel: 덥다 → 더워요 (돕다, 곱다 → 도와요).
  bieup,

  /// ㄷ → ㄹ before a vowel: 듣다 → 들어요.
  digeut,

  /// ㅅ drops before a vowel: 낫다 → 나아요.
  siot,

  /// 르 → ㄹㄹ: 모르다 → 몰라요.
  reu,

  /// ㅡ drops: 쓰다 → 써요, 바쁘다 → 바빠요.
  eu,

  /// ㅎ drops and the vowel becomes ㅐ: 그렇다 → 그래요.
  hieut,
}

/// One Hangul syllable as initial, vowel and final jamo indexes.
class _Syl {
  const _Syl(this.initial, this.vowel, this.last);

  factory _Syl.of(String ch) {
    final n = ch.codeUnitAt(0) - 0xAC00;
    return _Syl(n ~/ 588, n % 588 ~/ 28, n % 28);
  }

  final int initial;
  final int vowel;

  /// Final consonant, 0 for none.
  final int last;

  _Syl withVowel(int v) => _Syl(initial, v, last);
  _Syl withLast(int f) => _Syl(initial, vowel, f);

  @override
  String toString() => String.fromCharCode(0xAC00 + (initial * 21 + vowel) * 28 + last);
}

// Jamo indexes used by the rules.
const _a = 0, _ae = 1, _ya = 2, _yae = 3, _eo = 4, _e = 5, _yeo = 6, _o = 8, _wa = 9, _wae = 10, _oe = 11;
const _u = 13, _wo = 14, _eu = 18, _i = 20;
const _ng = 11, _h = 18, _r = 5;
const _finalB = 17, _finalD = 7, _finalS = 19, _finalH = 27, _finalL = 8, _finalSs = 20;

/// ㅏ, ㅑ, ㅗ take -아; every other vowel takes -어.
bool _bright(int vowel) => vowel == _a || vowel == _ya || vowel == _o;

String _join(List<_Syl> syllables) => syllables.join();

extension on List<_Syl> {
  List<_Syl> replaceLast(_Syl s) => [...take(length - 1), s];
  List<_Syl> plusVowel(int vowel) => [...this, _Syl(_ng, vowel, 0)];
}

// Stems whose ㅂ, ㄷ or ㅅ looks regular but is not, and the reverse.
const _bieupRegular = {'입', '잡', '씹', '뽑', '접', '업', '집', '좁', '수줍', '굽히'};
const _bieupVerbsIrregular = {'돕', '눕', '줍', '굽'};
const _bieupWa = {'돕', '곱'};
const _digeutIrregular = {'듣', '걷', '묻', '싣', '깨닫', '붇', '일컫'};
const _siotIrregular = {'낫', '짓', '붓', '잇', '긋', '젓'};
const _reuRegular = {'따르', '치르', '들르', '우러르'};

/// Special honorific verbs: 먹다 → 드세요, 자다 → 주무세요.
const _honorificVerbs = {'먹다': '드세요', '자다': '주무세요'};

class KoConjugator {
  KoConjugator._(this.word, this.adjective, this._stem, this.cls);

  /// The conjugator of a dictionary form ending in 다, or null for words it
  /// does not handle (이다, 아니다, phrases).
  static KoConjugator? of(String word, {required bool adjective}) {
    if (!RegExp(r'^[가-힣]+다$').hasMatch(word) || word.length < 2) return null;
    if (word == '이다' || word == '아니다') return null;
    final stemText = word.substring(0, word.length - 1);
    final stem = [for (final ch in stemText.split('')) _Syl.of(ch)];
    return KoConjugator._(word, adjective, stem, _classify(stemText, stem, adjective: adjective));
  }

  static KoClass _classify(String text, List<_Syl> stem, {required bool adjective}) {
    final last = stem.last;
    bool endsWithAny(Set<String> stems) => stems.any(text.endsWith);
    if (last.initial == _h && last.vowel == _a && last.last == 0) return KoClass.ha;
    switch (last.last) {
      case _finalL:
        return KoClass.rieul;
      case _finalB:
        if (endsWithAny(_bieupRegular)) return KoClass.regular;
        return adjective || endsWithAny(_bieupVerbsIrregular) ? KoClass.bieup : KoClass.regular;
      case _finalD:
        return endsWithAny(_digeutIrregular) ? KoClass.digeut : KoClass.regular;
      case _finalS:
        return endsWithAny(_siotIrregular) ? KoClass.siot : KoClass.regular;
      case _finalH:
        return adjective && !text.endsWith('좋') ? KoClass.hieut : KoClass.regular;
      case 0 when last.vowel == _eu:
        if (last.initial == _r && stem.length > 1 && !endsWithAny(_reuRegular)) return KoClass.reu;
        return KoClass.eu;
    }
    return KoClass.regular;
  }

  /// The dictionary form: 먹다.
  final String word;
  final bool adjective;
  final List<_Syl> _stem;
  final KoClass cls;

  String get stem => _join(_stem);

  bool get _hasIt => word.endsWith('있다') || word.endsWith('없다');

  /// Forms that apply to this word, in table order.
  List<KoForm> get forms => [
    for (final f in KoForm.values)
      if (!(f == KoForm.want && (adjective || word.endsWith('없다'))) &&
          !(f == KoForm.negative && (_hasIt || word == '알다' || word == '모르다')) &&
          !(f == KoForm.honorific && _hasIt))
        f,
  ];

  String conjugate(KoForm form) => _conjugate(form, cls);

  String _conjugate(KoForm form, KoClass cls, {bool flip = false}) => switch (form) {
    KoForm.polite => '${_infinitive(cls, flip: flip)}요',
    KoForm.past => '${_past(cls, flip: flip)}어요',
    KoForm.formal => _formal(cls),
    KoForm.formalPast => '${_past(cls, flip: flip)}습니다',
    KoForm.negative => _negative(cls, flip: flip),
    KoForm.longNegative => '$stem지 않아요',
    KoForm.want => '$stem고 싶어요',
    KoForm.future => '${_withRieul(cls)} 거예요',
    KoForm.honorific => (cls == this.cls ? _honorificVerbs[word] : null) ?? _honorific(cls),
    KoForm.and => '$stem고',
    KoForm.so => '${_infinitive(cls, flip: flip)}서',
  };

  /// The -아/어 form every vowel ending builds on: 먹어, 가, 해, 들어.
  String _infinitive(KoClass cls, {bool flip = false}) {
    final s = _stem;
    final last = s.last;
    bool bright(int vowel) => _bright(vowel) != flip;
    switch (cls) {
      case KoClass.ha:
        return _join(s.replaceLast(last.withVowel(flip ? _a : _ae)));
      case KoClass.bieup:
        final wa = _bieupWa.any(stem.endsWith) != flip;
        return _join([...s.replaceLast(last.withLast(0)), _Syl(_ng, wa ? _wa : _wo, 0)]);
      case KoClass.digeut:
        return _join(s.replaceLast(last.withLast(_finalL)).plusVowel(bright(last.vowel) ? _a : _eo));
      case KoClass.siot:
        return _join(s.replaceLast(last.withLast(0)).plusVowel(bright(last.vowel) ? _a : _eo));
      case KoClass.reu:
        final before = s[s.length - 2];
        return _join([...s.take(s.length - 2), before.withLast(_finalL), _Syl(_r, bright(before.vowel) ? _a : _eo, 0)]);
      case KoClass.eu:
        final lead = s.length > 1 ? bright(s[s.length - 2].vowel) : flip;
        return _join(s.replaceLast(last.withVowel(lead ? _a : _eo)));
      case KoClass.hieut:
        final vowel = last.vowel == _ya ? _yae : (flip ? _e : _ae);
        return _join(s.replaceLast(_Syl(last.initial, vowel, 0)));
      case KoClass.regular || KoClass.rieul:
        final ending = bright(last.vowel) ? _a : _eo;
        if (last.last != 0) return _join(s.plusVowel(ending));
        // Vowel stems contract: 가 + 아 → 가, 오 + 아 → 와, 마시 + 어 → 마셔.
        final contracted = switch ((last.vowel, ending)) {
          (_a, _a) || (_eo, _eo) || (_ae, _eo) || (_e, _eo) || (_yeo, _eo) => last.vowel,
          (_o, _a) => _wa,
          (_u, _eo) => _wo,
          (_i, _eo) => _yeo,
          (_oe, _eo) => _wae,
          _ => null,
        };
        if (contracted == null) return _join(s.plusVowel(ending));
        return _join(s.replaceLast(last.withVowel(contracted)));
    }
  }

  /// The past stem: the infinitive with ㅆ: 먹었, 갔, 했.
  String _past(KoClass cls, {bool flip = false}) {
    final inf = [for (final ch in _infinitive(cls, flip: flip).split('')) _Syl.of(ch)];
    return _join(inf.replaceLast(inf.last.withLast(_finalSs)));
  }

  String _formal(KoClass cls) {
    final last = _stem.last;
    if (cls == KoClass.rieul) return '${_join(_stem.replaceLast(last.withLast(_finalB)))}니다';
    if (last.last != 0) return '$stem습니다';
    return '${_join(_stem.replaceLast(last.withLast(_finalB)))}니다';
  }

  /// 안 before the verb; a noun + 하다 verb takes it before 하다
  /// (공부 안 해요), unless the part before 하 is itself a verb (좋아하다).
  String _negative(KoClass cls, {bool flip = false}) {
    final compound = cls == KoClass.ha && _stem.length > 1;
    final nounHa = compound && !adjective && !_endsInAEo(_stem[_stem.length - 2]);
    if (compound && nounHa != flip) return '${_join(_stem.take(_stem.length - 1).toList())} 안 해요';
    return '안 ${_infinitive(cls, flip: flip && !compound)}요';
  }

  static bool _endsInAEo(_Syl s) => s.initial == _ng && s.last == 0 && (s.vowel == _a || s.vowel == _eo);

  /// The stem before -(으)ㄹ: 갈, 먹을, 살, 도울, 들을.
  String _withRieul(KoClass cls) {
    final s = _stem;
    final last = s.last;
    return switch (cls) {
      KoClass.rieul => stem,
      KoClass.bieup => _join([...s.replaceLast(last.withLast(0)), const _Syl(_ng, _u, _finalL)]),
      KoClass.digeut => '${_join(s.replaceLast(last.withLast(_finalL)))}을',
      KoClass.siot => '${_join(s.replaceLast(last.withLast(0)))}을',
      KoClass.hieut => _join(s.replaceLast(last.withLast(_finalL))),
      _ when last.last != 0 => '$stem을',
      _ => _join(s.replaceLast(last.withLast(_finalL))),
    };
  }

  String _honorific(KoClass cls) {
    final s = _stem;
    final last = s.last;
    return switch (cls) {
      KoClass.rieul || KoClass.hieut => '${_join(s.replaceLast(last.withLast(0)))}세요',
      KoClass.bieup => '${_join(s.replaceLast(last.withLast(0)))}우세요',
      KoClass.digeut => '${_join(s.replaceLast(last.withLast(_finalL)))}으세요',
      KoClass.siot => '${_join(s.replaceLast(last.withLast(0)))}으세요',
      _ when last.last != 0 => '$stem으세요',
      _ => '$stem세요',
    };
  }

  /// Three wrong answers for [form]: the mistakes a learner makes (the
  /// irregular treated as regular or the reverse, the wrong 아/어, the wrong
  /// ending after a vowel or consonant), then the word in other forms.
  List<String> distractors(KoForm form) {
    final right = conjugate(form);
    final wrong = <String>[];
    void add(String? s) {
      if (s != null && s != right && !wrong.contains(s)) wrong.add(s);
    }

    final last = _stem.last;
    final misread = <KoClass>[
      if (cls != KoClass.regular && cls != KoClass.ha) KoClass.regular,
      if (cls == KoClass.regular)
        ?switch (last.last) {
          _finalB => KoClass.bieup,
          _finalD => KoClass.digeut,
          _finalS => KoClass.siot,
          _finalH => KoClass.hieut,
          _ => null,
        },
      if (cls == KoClass.reu) KoClass.eu,
    ];
    final mistakes = <String?>[
      _conjugate(form, cls, flip: true),
      for (final c in misread) _conjugate(form, c),
      switch (form) {
        KoForm.formal when cls != KoClass.rieul && last.last == 0 => '$stem습니다',
        KoForm.formal => '$stem읍니다',
        KoForm.future when last.last == 0 => '$stem을 거예요',
        KoForm.future => '$stem 거예요',
        KoForm.honorific when last.last == 0 => '$stem으세요',
        KoForm.honorific => '$stem세요',
        KoForm.longNegative => '$stem지 안아요',
        KoForm.want => '$stem고 싶아요',
        KoForm.and || KoForm.so => '$stem서',
        _ => null,
      },
    ];
    for (final m in mistakes) {
      if (wrong.length < 2) add(m);
    }
    // Then the same word in other forms, nearest first; not the other
    // negative, which says the same.
    const negatives = {KoForm.negative, KoForm.longNegative};
    final others = [
      for (final f in forms)
        if (!(negatives.contains(f) && negatives.contains(form))) f,
    ]..sort((a, b) => (a.index - form.index).abs() - (b.index - form.index).abs());
    for (final f in others) {
      if (wrong.length >= 3) break;
      add(conjugate(f));
    }
    for (final m in mistakes) {
      if (wrong.length < 3) add(m);
    }
    return wrong.take(3).toList();
  }
}
