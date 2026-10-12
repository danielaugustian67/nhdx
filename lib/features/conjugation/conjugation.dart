/// Rule-based conjugation of verbs and adjectives (PRD F14): godan, ichidan,
/// する / 来る and the special verbs (行く, ある, くださる, 問う, -ずる), i- and
/// na-adjectives (いい included). Pure functions, no database.
library;

/// The forms a word can be put in, in the order the table lists them.
enum ConjForm {
  plain,
  polite,
  negative,
  politeNegative,
  past,
  politePast,
  pastNegative,
  politePastNegative,
  te,
  potential,
  passive,
  causative,
  imperative,
  volitional,
  conditionalBa,
  conditionalTara,
  want,

  /// Adjectives only: 〜く / 〜に.
  adverb;

  static ConjForm? parse(String name) => values.where((f) => f.name == name).firstOrNull;
}

/// How a word conjugates.
enum WordClass {
  ichidan,

  /// くれる: imperative くれ.
  kureru,
  godan,

  /// 行く: 行って, 行った.
  iku,

  /// ある: ない, なかった.
  aru,

  /// くださる, いらっしゃる, …: ください, くださいます.
  honorific,

  /// 問う, 請う: 問うて, 問うた.
  uSpecial,
  suru,
  kuru,

  /// 論ずる: conjugates as 論じる.
  zuru,
  adjI,

  /// いい / かっこいい: よくない, よかった.
  adjIi,
  adjNa;

  bool get isAdjective => this == adjI || this == adjIi || this == adjNa;

  /// Forms that apply to this class, in table order.
  List<ConjForm> get forms => isAdjective
      ? const [
          ConjForm.plain,
          ConjForm.polite,
          ConjForm.negative,
          ConjForm.politeNegative,
          ConjForm.past,
          ConjForm.politePast,
          ConjForm.pastNegative,
          ConjForm.politePastNegative,
          ConjForm.te,
          ConjForm.conditionalBa,
          ConjForm.conditionalTara,
          ConjForm.adverb,
        ]
      : [
          for (final f in ConjForm.values)
            if (f != ConjForm.adverb) f,
        ];

  /// The class from JMdict part-of-speech codes (`v5k`, `vs-i`, `adj-na`, …),
  /// sense by sense; null when the word does not conjugate. Verb codes win
  /// over adjectives, and a noun with `vs` (勉強) conjugates as 勉強する.
  static ({WordClass cls, bool addSuru})? fromPos(Iterable<String> codes) {
    final list = codes.toList();
    for (final c in list) {
      final cls = switch (c) {
        'v1' => WordClass.ichidan,
        'v1-s' => WordClass.kureru,
        'v5k-s' => WordClass.iku,
        'v5r-i' => WordClass.aru,
        'v5aru' => WordClass.honorific,
        'v5u-s' => WordClass.uSpecial,
        'v5b' || 'v5g' || 'v5k' || 'v5m' || 'v5n' || 'v5r' || 'v5s' || 'v5t' || 'v5u' => WordClass.godan,
        'vk' => WordClass.kuru,
        'vs-i' || 'vs-s' => WordClass.suru,
        'vz' => WordClass.zuru,
        _ => null,
      };
      if (cls != null) return (cls: cls, addSuru: false);
    }
    if (list.contains('adj-ix')) return (cls: WordClass.adjIi, addSuru: false);
    if (list.contains('adj-i')) return (cls: WordClass.adjI, addSuru: false);
    if (list.contains('adj-na')) return (cls: WordClass.adjNa, addSuru: false);
    if (list.contains('vs')) return (cls: WordClass.suru, addSuru: true);
    return null;
  }
}

/// One conjugated form, written with the word's kanji and in kana.
class Conjugated {
  const Conjugated(this.written, this.kana);
  final String written;
  final String kana;

  @override
  bool operator ==(Object other) => other is Conjugated && other.written == written && other.kana == kana;

  @override
  int get hashCode => Object.hash(written, kana);

  @override
  String toString() => written == kana ? written : '$written（$kana）';
}

/// A word ready to conjugate: its class and dictionary form.
class Conjugator {
  Conjugator(this.cls, {required String written, required String kana, bool addSuru = false})
    : written = _dictionaryForm(cls, addSuru ? '$writtenする' : written),
      kana = addSuru ? '$kanaする' : kana;

  /// From JMdict codes; null when the word does not conjugate or its
  /// spelling does not end the way its class says (a data slip).
  static Conjugator? fromPos(Iterable<String> codes, {required String written, required String kana}) {
    final c = WordClass.fromPos(codes);
    if (c == null) return null;
    final conj = Conjugator(c.cls, written: written, kana: kana, addSuru: c.addSuru);
    return conj._valid ? conj : null;
  }

  final WordClass cls;

  /// Dictionary form; 為る is shown as する.
  final String written;
  final String kana;

  static String _dictionaryForm(WordClass cls, String written) =>
      cls == WordClass.suru && written.endsWith('為る') ? '${written.substring(0, written.length - 2)}する' : written;

  bool get _valid {
    bool ends(String s) => written.endsWith(s) && kana.endsWith(s);
    return switch (cls) {
      WordClass.ichidan || WordClass.kureru => ends('る'),
      WordClass.godan ||
      WordClass.iku ||
      WordClass.honorific ||
      WordClass.uSpecial => _rows.containsKey(_last(kana)) && _last(kana) == _last(written),
      WordClass.aru => ends('る'),
      WordClass.suru => ends('する'),
      WordClass.kuru => kana.endsWith('くる') && (written.endsWith('来る') || written.endsWith('くる')),
      WordClass.zuru => ends('ずる'),
      WordClass.adjI => ends('い'),
      WordClass.adjIi => ends('いい') || (kana.endsWith('いい') && written.endsWith('い')),
      WordClass.adjNa => true,
    };
  }

  List<ConjForm> get forms => cls.forms;

  Conjugated conjugate(ConjForm form) {
    if (cls == WordClass.kuru) return _kuru(form);
    return Conjugated(_apply(written, form), _apply(kana, form));
  }

  /// Every form of [forms], in table order.
  Map<ConjForm, Conjugated> table() => {for (final f in forms) f: conjugate(f)};

  // ---- rules ----

  String _apply(String s, ConjForm form) => switch (cls) {
    WordClass.ichidan || WordClass.kureru => _ichidan(_cut(s, 1), form),
    WordClass.zuru => _ichidan('${_cut(s, 2)}じ', form),
    WordClass.godan || WordClass.iku || WordClass.honorific || WordClass.uSpecial || WordClass.aru => _godan(s, form),
    WordClass.suru => _suru(_cut(s, 2), form),
    WordClass.kuru => s,
    WordClass.adjI => _adjI(s, _cut(s, 1), form),
    WordClass.adjIi => _adjI(s, '${_cut(s, s.endsWith('いい') ? 2 : 1)}よ', form),
    WordClass.adjNa => _adjNa(s, form),
  };

  String _ichidan(String stem, ConjForm form) => switch (form) {
    ConjForm.plain => '$stemる',
    ConjForm.polite => '$stemます',
    ConjForm.negative => '$stemない',
    ConjForm.politeNegative => '$stemません',
    ConjForm.past => '$stemた',
    ConjForm.politePast => '$stemました',
    ConjForm.pastNegative => '$stemなかった',
    ConjForm.politePastNegative => '$stemませんでした',
    ConjForm.te => '$stemて',
    ConjForm.potential || ConjForm.passive => '$stemられる',
    ConjForm.causative => '$stemさせる',
    ConjForm.imperative => cls == WordClass.kureru ? stem : '$stemろ',
    ConjForm.volitional => '$stemよう',
    ConjForm.conditionalBa => '$stemれば',
    ConjForm.conditionalTara => '$stemたら',
    ConjForm.want => '$stemたい',
    ConjForm.adverb => '$stemる',
  };

  /// u-row ending → (a, i, e, o) rows.
  static const _rows = {
    'う': ('わ', 'い', 'え', 'お'),
    'く': ('か', 'き', 'け', 'こ'),
    'ぐ': ('が', 'ぎ', 'げ', 'ご'),
    'す': ('さ', 'し', 'せ', 'そ'),
    'つ': ('た', 'ち', 'て', 'と'),
    'ぬ': ('な', 'に', 'ね', 'の'),
    'ぶ': ('ば', 'び', 'べ', 'ぼ'),
    'む': ('ま', 'み', 'め', 'も'),
    'る': ('ら', 'り', 'れ', 'ろ'),
  };

  String _godan(String s, ConjForm form) {
    final stem = _cut(s, 1);
    final (a, i, e, o) = _rows[_last(s)]!;
    // くださる → ください(ます)
    final iStem = cls == WordClass.honorific ? '$stemい' : '$stem$i';
    final (te, ta) = _teTa(s);
    // ある → ない
    final negative = cls == WordClass.aru ? '${_cut(s, 2)}な' : '$stem$aな';
    return switch (form) {
      ConjForm.plain => s,
      ConjForm.polite => '$iStemます',
      ConjForm.negative => '$negativeい',
      ConjForm.politeNegative => '$iStemません',
      ConjForm.past => ta,
      ConjForm.politePast => '$iStemました',
      ConjForm.pastNegative => '$negativeかった',
      ConjForm.politePastNegative => '$iStemませんでした',
      ConjForm.te => te,
      ConjForm.potential => '$stem$eる',
      ConjForm.passive => '$stem$aれる',
      ConjForm.causative => '$stem$aせる',
      ConjForm.imperative => cls == WordClass.honorific ? '$stemい' : '$stem$e',
      ConjForm.volitional => '$stem$oう',
      ConjForm.conditionalBa => '$stem$eば',
      ConjForm.conditionalTara => '$taら',
      ConjForm.want => '$iStemたい',
      ConjForm.adverb => s,
    };
  }

  /// て and た forms of a godan verb.
  (String, String) _teTa(String s) {
    final stem = _cut(s, 1);
    if (cls == WordClass.iku) return ('$stemって', '$stemった');
    if (cls == WordClass.uSpecial) return ('$sて', '$sた');
    return switch (_last(s)) {
      'う' || 'つ' || 'る' => ('$stemって', '$stemった'),
      'ぬ' || 'ぶ' || 'む' => ('$stemんで', '$stemんだ'),
      'く' => ('$stemいて', '$stemいた'),
      'ぐ' => ('$stemいで', '$stemいだ'),
      _ => ('$stemして', '$stemした'),
    };
  }

  static String _suru(String base, ConjForm form) =>
      base +
      switch (form) {
        ConjForm.plain || ConjForm.adverb => 'する',
        ConjForm.polite => 'します',
        ConjForm.negative => 'しない',
        ConjForm.politeNegative => 'しません',
        ConjForm.past => 'した',
        ConjForm.politePast => 'しました',
        ConjForm.pastNegative => 'しなかった',
        ConjForm.politePastNegative => 'しませんでした',
        ConjForm.te => 'して',
        ConjForm.potential => 'できる',
        ConjForm.passive => 'される',
        ConjForm.causative => 'させる',
        ConjForm.imperative => 'しろ',
        ConjForm.volitional => 'しよう',
        ConjForm.conditionalBa => 'すれば',
        ConjForm.conditionalTara => 'したら',
        ConjForm.want => 'したい',
      };

  static const _kuruKana = {
    ConjForm.plain: 'くる',
    ConjForm.polite: 'きます',
    ConjForm.negative: 'こない',
    ConjForm.politeNegative: 'きません',
    ConjForm.past: 'きた',
    ConjForm.politePast: 'きました',
    ConjForm.pastNegative: 'こなかった',
    ConjForm.politePastNegative: 'きませんでした',
    ConjForm.te: 'きて',
    ConjForm.potential: 'こられる',
    ConjForm.passive: 'こられる',
    ConjForm.causative: 'こさせる',
    ConjForm.imperative: 'こい',
    ConjForm.volitional: 'こよう',
    ConjForm.conditionalBa: 'くれば',
    ConjForm.conditionalTara: 'きたら',
    ConjForm.want: 'きたい',
    ConjForm.adverb: 'くる',
  };

  /// 来る keeps its kanji; only the reading of 来 changes (き, こ, く).
  Conjugated _kuru(ConjForm form) {
    final tail = _kuruKana[form]!;
    final kana = '${_cut(this.kana, 2)}$tail';
    final written = this.written.endsWith('来る')
        ? '${_cut(this.written, 2)}来${tail.substring(1)}'
        : '${_cut(this.written, 2)}$tail';
    return Conjugated(written, kana);
  }

  static String _adjI(String s, String stem, ConjForm form) => switch (form) {
    ConjForm.plain => s,
    ConjForm.polite => '$sです',
    ConjForm.negative => '$stemくない',
    ConjForm.politeNegative => '$stemくないです',
    ConjForm.past => '$stemかった',
    ConjForm.politePast => '$stemかったです',
    ConjForm.pastNegative => '$stemくなかった',
    ConjForm.politePastNegative => '$stemくなかったです',
    ConjForm.te => '$stemくて',
    ConjForm.conditionalBa => '$stemければ',
    ConjForm.conditionalTara => '$stemかったら',
    ConjForm.adverb => '$stemく',
    _ => s,
  };

  static String _adjNa(String s, ConjForm form) => switch (form) {
    ConjForm.plain => '$sだ',
    ConjForm.polite => '$sです',
    ConjForm.negative => '$sじゃない',
    ConjForm.politeNegative => '$sじゃありません',
    ConjForm.past => '$sだった',
    ConjForm.politePast => '$sでした',
    ConjForm.pastNegative => '$sじゃなかった',
    ConjForm.politePastNegative => '$sじゃありませんでした',
    ConjForm.te => '$sで',
    ConjForm.conditionalBa => '$sなら',
    ConjForm.conditionalTara => '$sだったら',
    ConjForm.adverb => '$sに',
    _ => s,
  };

  /// Plausible wrong answers for [form]: the same form by the rules of a
  /// class learners mix it up with (帰る as ichidan → 帰ます), and other forms
  /// of the word. Never the right answer, no duplicates.
  List<Conjugated> distractors(ConjForm form, {int count = 3}) {
    final right = conjugate(form);
    final out = <Conjugated>{};
    void add(Conjugated c) {
      if (c != right && c.written != right.written) out.add(c);
    }

    // An る verb taken for the other group: 帰る → 帰ます, 食べる → 食べらない.
    final mixUp = switch (cls) {
      WordClass.godan || WordClass.aru when _last(kana) == 'る' => WordClass.ichidan,
      WordClass.ichidan || WordClass.kureru => WordClass.godan,
      _ => null,
    };
    if (mixUp != null) {
      final c = Conjugator(mixUp, written: written, kana: kana);
      if (c._valid) add(c.conjugate(form));
    }
    // A godan verb's other て-form patterns: 書いて → 書って / 書んで.
    if (cls == WordClass.godan && (form == ConjForm.te || form == ConjForm.past)) {
      final stem = _cut(written, 1);
      final kStem = _cut(kana, 1);
      final ending = form == ConjForm.te ? ['って', 'んで', 'いて', 'して'] : ['った', 'んだ', 'いた', 'した'];
      for (final e in ending) {
        add(Conjugated('$stem$e', '$kStem$e'));
      }
    }
    if (cls == WordClass.adjNa) {
      // Treating a na-adjective like an i-adjective: 静かくない.
      final wrong = switch (form) {
        ConjForm.negative => ['くない', 'じゃなかった'],
        ConjForm.past => ['かった', 'だ'],
        ConjForm.te => ['くて', 'に'],
        ConjForm.adverb => ['く', 'で'],
        _ => const <String>[],
      };
      for (final w in wrong) {
        add(Conjugated('$written$w', '$kana$w'));
      }
    }
    if (cls == WordClass.adjI || cls == WordClass.adjIi) {
      // Treating an i-adjective like a na-adjective: 高いじゃない.
      final wrong = switch (form) {
        ConjForm.negative => ['じゃない', 'ない'],
        ConjForm.past => ['でした', 'だった'],
        ConjForm.pastNegative => ['じゃなかった'],
        ConjForm.te => ['で'],
        ConjForm.adverb => ['に'],
        _ => const <String>[],
      };
      for (final w in wrong) {
        add(Conjugated('$written$w', '$kana$w'));
      }
    }
    for (final f in forms) {
      if (out.length >= count + 2) break;
      if (f != form && f != ConjForm.plain) add(conjugate(f));
    }
    return out.take(count).toList();
  }

  static String _last(String s) => s.isEmpty ? '' : s.substring(s.length - 1);
  static String _cut(String s, int n) => s.length < n ? '' : s.substring(0, s.length - n);
}
