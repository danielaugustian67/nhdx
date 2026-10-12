// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nihondx';

  @override
  String get tabToday => 'Today';

  @override
  String get tabKana => 'Kana';

  @override
  String get tabDictionary => 'Dictionary';

  @override
  String get tabCollection => 'Collection';

  @override
  String get tabMe => 'Me';

  @override
  String get searchHint => 'Search words, kanji or meanings';

  @override
  String get searchClear => 'Clear text';

  @override
  String get modeHiragana => 'あ Hiragana';

  @override
  String get modeKatakana => 'ア Katakana';

  @override
  String get modeLatin => 'Abc Latin text';

  @override
  String searchNoResults(String query) {
    return 'No results for \'$query\'. Try romaji or kana, or search the meaning in English.';
  }

  @override
  String get searchAsLatin => 'Search as Latin text';

  @override
  String get searchEmptyHint =>
      'Type in romaji, kana, kanji or an English meaning.';

  @override
  String get preparingDictionary =>
      'Preparing the dictionary. This only happens once.';

  @override
  String get dictionaryFailed =>
      'The dictionary could not be opened. Close and reopen the app.';

  @override
  String get notBuiltYet => 'This section is being built.';

  @override
  String get exactMatch => 'Exact match';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String xpAmount(int xp) {
    return '$xp XP';
  }

  @override
  String get heroStartTitle => 'Start with hiragana';

  @override
  String get heroStartBody =>
      'Learn the 46 basic characters through short games, 5 minutes a day.';

  @override
  String get heroContinueTitle => 'Continue kana';

  @override
  String heroContinueBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters still need practice.',
      one: '1 character still needs practice.',
    );
    return '$_temp0';
  }

  @override
  String get playNow => 'Play now';

  @override
  String get sectionLearn => 'Learn';

  @override
  String get moduleKana => 'Kana';

  @override
  String get moduleKanaBody => 'Hiragana & katakana, 4 games';

  @override
  String get moduleVocab => 'N5 vocabulary';

  @override
  String get moduleReview => 'Daily review';

  @override
  String get moduleKanji => 'Kanji';

  @override
  String get hiragana => 'Hiragana';

  @override
  String get katakana => 'Katakana';

  @override
  String get kindBasic => 'Basic';

  @override
  String get kindDakuten => 'Dakuten';

  @override
  String get kindYoon => 'Yōon';

  @override
  String get games => 'Games';

  @override
  String get gameQuiz => 'Quiz';

  @override
  String get gameQuizBody => '4 choices, 10 questions';

  @override
  String get gameMatch => 'Match';

  @override
  String get gameMatchBody => 'Find the pairs';

  @override
  String get gameSpeed => 'Speed';

  @override
  String get gameSpeedBody => '60 s, build combos';

  @override
  String get gameWrite => 'Write';

  @override
  String get gameWriteBody => 'Practice stroke order';

  @override
  String get allCharacters => 'All characters';

  @override
  String strokeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count strokes',
      one: '1 stroke',
    );
    return '$_temp0';
  }

  @override
  String get exampleWord => 'Example word';

  @override
  String get practiceWriting => 'Practice writing';

  @override
  String get replay => 'Replay';

  @override
  String questionProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get askRomaji => 'How is it read?';

  @override
  String get askKana => 'Which character is it?';

  @override
  String get correct => 'Correct!';

  @override
  String answerWas(String answer) {
    return 'The answer is $answer';
  }

  @override
  String get next => 'Next';

  @override
  String get quit => 'Quit';

  @override
  String movesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
    );
    return '$_temp0';
  }

  @override
  String secondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String comboCount(int count) {
    return 'Combo ×$count';
  }

  @override
  String get speedStart =>
      'Answer as many as you can in 60 seconds. Correct answers in a row raise the combo and XP.';

  @override
  String get start => 'Start';

  @override
  String get writeHint => 'Write over the guide, stroke by stroke.';

  @override
  String get check => 'Check';

  @override
  String get clear => 'Clear';

  @override
  String get guide => 'Guide';

  @override
  String get writeGood =>
      'Nice! Stroke count, order and direction are correct.';

  @override
  String writeCountWrong(int drawn, int expected) {
    return 'You wrote $drawn strokes, it should be $expected.';
  }

  @override
  String writeReversed(int n) {
    return 'Stroke $n goes the wrong direction.';
  }

  @override
  String writeWrongOrder(int n) {
    return 'Stroke $n is out of order.';
  }

  @override
  String writeMisplaced(int n) {
    return 'Stroke $n is too far from the guide.';
  }

  @override
  String writeWrongShape(int n) {
    return 'The shape of stroke $n is off.';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get sessionDone => 'Session complete';

  @override
  String accuracyPercent(int percent) {
    return 'Accuracy $percent%';
  }

  @override
  String xpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get needsPractice => 'Needs practice';

  @override
  String get playAgain => 'Play again';

  @override
  String get done => 'Done';

  @override
  String unitNumber(int n) {
    return 'Unit $n';
  }

  @override
  String unitRows(String rows) {
    return 'Rows $rows';
  }

  @override
  String get unitDakuten => 'Dakuten & handakuten';

  @override
  String get unitYoon => 'Yōon (combined kana)';

  @override
  String nodeIntro(String kana) {
    return 'Meet $kana';
  }

  @override
  String get nodeWrite => 'Write this unit\'s kana';

  @override
  String get nodeMatch => 'Match the pairs';

  @override
  String get nodeSpeed => '60-second challenge';

  @override
  String get nodeChest => 'Reward chest';

  @override
  String nodePosition(int current, int total) {
    return 'Lesson $current of $total';
  }

  @override
  String get nodeLocked => 'Finish the previous lessons to unlock this.';

  @override
  String get nodeReplay => 'Replay';

  @override
  String get openChest => 'Open chest';

  @override
  String chestOpened(int xp) {
    return 'Chest opened! +$xp XP';
  }

  @override
  String get startHere => 'Start';

  @override
  String get kanaTable => 'Kana table';

  @override
  String get newCharacters => 'New characters';

  @override
  String get startQuiz => 'Start practice';

  @override
  String get practiceOneMode => 'Or practise one type:';

  @override
  String get modeChoice => 'Choice';

  @override
  String get modeType => 'Type';

  @override
  String get exWrite => 'Write this character';

  @override
  String exBuild(String script) {
    return 'Spell it in $script';
  }

  @override
  String get exRead => 'Type the reading in romaji';

  @override
  String get romajiHint => 'romaji';

  @override
  String get notQuite => 'Not quite';

  @override
  String get trackKana => 'Kana';

  @override
  String get trackKanji => 'Kanji';

  @override
  String kanjiTheme(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'numbers': 'Numbers',
      'people': 'People & body',
      'week': 'Days',
      'nature': 'Nature',
      'position': 'Position & direction',
      'qualities': 'Qualities',
      'clock': 'Time',
      'intro': 'Introductions',
      'actions': 'Actions',
      'school': 'School & language',
      'town': 'Town',
      'colors': 'Colors & light',
      'family': 'Family',
      'health': 'Body & health',
      'landscape': 'Landscape',
      'seasons': 'Seasons & time',
      'food': 'Animals & food',
      'regions': 'Regions',
      'buildings': 'Buildings',
      'travel': 'Travel',
      'size': 'Size & strength',
      'judgement': 'Judgement',
      'mind': 'Mind & feelings',
      'study': 'Study',
      'arts': 'Language & arts',
      'work': 'Work',
      'shopping': 'Shopping',
      'doing': 'Doing things',
      'daily': 'Daily life',
      'other': 'Kanji',
    });
    return '$_temp0';
  }

  @override
  String unitLevel(int n, int level) {
    return 'Unit $n · N$level';
  }

  @override
  String get nodeReview => 'Unit review';

  @override
  String get askMeaning => 'What does it mean?';

  @override
  String get askKanji => 'Which kanji is it?';

  @override
  String get onyomi => 'On';

  @override
  String get kunyomi => 'Kun';

  @override
  String get bookmarkAdd => 'Save to collection';

  @override
  String get bookmarkRemove => 'Remove from collection';

  @override
  String get bookmarked => 'Saved to collection';

  @override
  String get copied => 'Copied';

  @override
  String get commonWord => 'Common';

  @override
  String get verbGodan => 'Godan verb';

  @override
  String get verbIchidan => 'Ichidan verb';

  @override
  String get verbIrregular => 'Irregular verb';

  @override
  String get adjI => 'i-adjective';

  @override
  String get adjNa => 'na-adjective';

  @override
  String get meanings => 'Meanings';

  @override
  String get otherForms => 'Other spellings';

  @override
  String get entryMissing => 'This entry is no longer in the dictionary.';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get removeFromHistory => 'Remove from history';

  @override
  String get wordOfTheDay => 'Word of the day';

  @override
  String get browseByLevel => 'Browse by level';

  @override
  String levelWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get collectionEmpty =>
      'No saved words yet. Tap ☆ in the Dictionary to save a word.';

  @override
  String get collectionSearchHint => 'Search your collection';

  @override
  String get allLevels => 'All';

  @override
  String get removedFromCollection => 'Removed from collection.';

  @override
  String get undo => 'Undo';

  @override
  String get remove => 'Remove';

  @override
  String get noLevel => 'No level';

  @override
  String get addToStudy => 'Add to study';

  @override
  String get inStudy => 'In your study deck';

  @override
  String get showAnswer => 'Show answer';

  @override
  String get tapToFlip => 'Tap to flip';

  @override
  String get rateAgain => 'Again';

  @override
  String get rateHard => 'Hard';

  @override
  String get rateGood => 'Good';

  @override
  String get rateEasy => 'Easy';

  @override
  String intervalMinutes(int n) {
    return '$n min';
  }

  @override
  String intervalHours(int n) {
    return '$n h';
  }

  @override
  String intervalDays(int n) {
    return '$n d';
  }

  @override
  String intervalMonths(int n) {
    return '$n mo';
  }

  @override
  String intervalYears(int n) {
    return '$n y';
  }

  @override
  String reviewLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards left',
      one: '1 card left',
    );
    return '$_temp0';
  }

  @override
  String reviewSummary(int count, int correct, int again, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count answers',
      one: '1 answer',
    );
    return '$_temp0 · $correct correct · $again Again · ~$minutes min';
  }

  @override
  String get reviewEmpty =>
      'Nothing to review right now. Add words from the Dictionary (Add to study) or start with N5 words.';

  @override
  String addN5Words(int count) {
    return 'Add $count N5 words';
  }

  @override
  String newLimitReached(int limit, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new cards are waiting and will show up here tomorrow.',
      one: '1 new card is waiting and will show up here tomorrow.',
    );
    return 'You\'ve reached today\'s limit of $limit new cards. $_temp0';
  }

  @override
  String get reviewButton => 'Review';

  @override
  String reviewDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards ready to review',
      one: '1 card ready to review',
    );
    return '$_temp0';
  }

  @override
  String get almostThere => 'Almost!';

  @override
  String passMarkNeeded(int percent) {
    return 'You need at least $percent% accuracy to pass. Give it another go!';
  }

  @override
  String passMarkHint(int percent) {
    return 'Pass with ≥ $percent% accuracy';
  }

  @override
  String get dailyGoal => 'Daily goal';

  @override
  String get goalCardsUnit => 'cards';

  @override
  String get goalReached => 'Daily goal reached';

  @override
  String goalLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more cards for today\'s goal',
      one: '1 more card for today\'s goal',
    );
    return '$_temp0';
  }

  @override
  String streakDays(int count) {
    return '$count-day streak';
  }

  @override
  String streakLongest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Longest $count days',
      one: 'Longest 1 day',
    );
    return '$_temp0';
  }

  @override
  String get streakKeep => 'Study today to keep your streak going.';

  @override
  String get streakStart => 'Start today, one session is enough.';

  @override
  String get statNew => 'New';

  @override
  String get statReviews => 'Reviews';

  @override
  String get statAccuracy => 'Accuracy';

  @override
  String get statTime => 'Time';

  @override
  String get activity => 'Activity';

  @override
  String lastDays(int count) {
    return '$count days';
  }

  @override
  String activityTotal(int cards, int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cards',
      one: '1 card',
    );
    return '$_temp0 · $xp XP';
  }

  @override
  String activityBar(String date, int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cards',
      one: '1 card',
    );
    return '$date: $_temp0';
  }

  @override
  String get stampBook => 'Stamp book';

  @override
  String stampDay(String date) {
    return '$date, studied';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get jlptProgress => 'JLPT progress';

  @override
  String wordsOf(int learned, int total) {
    return '$learned of $total words';
  }

  @override
  String get cardStages => 'Cards';

  @override
  String get stageNew => 'New';

  @override
  String get stageLearning => 'Learning';

  @override
  String get stageYoung => 'Young';

  @override
  String get stageMature => 'Mature';

  @override
  String get hardestItems => 'Hardest items';

  @override
  String lapsesCount(int count) {
    return 'Forgotten $count×';
  }

  @override
  String get settings => 'Settings';

  @override
  String get settingsLearning => 'Learning';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String cardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String get newPerDay => 'New cards per day';

  @override
  String get newPerDayNote =>
      'More means faster progress, but also more reviews over the next days.';

  @override
  String get reviewsPerDay => 'Review limit per day';

  @override
  String get reviewsPerDayNote =>
      'Cards over the limit keep waiting and show up in the next session.';

  @override
  String get dayStart => 'New day starts at';

  @override
  String get dayStartNote =>
      'Studying before this hour still counts for the day before (streak and goal).';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get followSystem => 'System default';

  @override
  String get textSize => 'Text size';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Large';

  @override
  String get textLarger => 'Larger';

  @override
  String newLimitDone(int limit) {
    return 'You\'ve learned $limit new cards today. See you tomorrow!';
  }

  @override
  String get goalRelaxed => 'Relaxed';

  @override
  String get goalRegular => 'Regular';

  @override
  String get goalSerious => 'Serious';

  @override
  String goalOption(int minutes, int cards, int fresh) {
    return '±$minutes min a day · $cards cards · $fresh new words';
  }

  @override
  String totalXp(int xp) {
    return '$xp XP total';
  }

  @override
  String get aboutAttribution => 'About & attribution';

  @override
  String get dataSources => 'Data sources';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String datasetVersion(String version) {
    return 'Dictionary version $version';
  }

  @override
  String get recallJapanese => 'What is it in Japanese?';

  @override
  String get cardDirection => 'Word card direction';

  @override
  String get directionJpToMeaning => 'Japanese → meaning';

  @override
  String get directionMeaningToJp => 'Meaning → Japanese';

  @override
  String get directionBoth => 'Both ways (2 cards per word)';

  @override
  String get directionNote => 'Applies to words added from now on';

  @override
  String get trackVocab => 'Words';

  @override
  String vocabLevel(int level) {
    return 'Vocabulary N$level';
  }

  @override
  String nodeWords(int count, String words) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words: $words',
      one: '1 word: $words',
    );
    return '$_temp0';
  }

  @override
  String get newWords => 'New words';

  @override
  String get askWord => 'Which word is it?';

  @override
  String get exRecall => 'Type the Japanese word in romaji';

  @override
  String get exMatch => 'Match each word to its meaning';

  @override
  String matchMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wrong pairs',
      one: '1 wrong pair',
    );
    return '$_temp0';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get reminderNote =>
      'Once a day. Skipped when today\'s goal is already reached.';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get reminderDenied =>
      'Notifications aren\'t allowed yet. Allow them in your phone settings so reminders can appear.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get reminderChannel => 'Daily reminder';

  @override
  String get reminderChannelNote => 'A once-a-day study reminder';

  @override
  String reminderCards(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards are waiting.',
      one: '1 card is waiting.',
    );
    return '$_temp0 About $minutes min.';
  }

  @override
  String reminderStreak(int count) {
    return 'Your $count-day streak is waiting. One short session is enough.';
  }

  @override
  String get reminderPlain =>
      'Time for a little Japanese. A few minutes is enough.';

  @override
  String get quickSearch => 'Search the dictionary';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String contentVersion(String version) {
    return 'content $version';
  }

  @override
  String schemaVersion(int version) {
    return 'data schema $version';
  }

  @override
  String onboardingStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get levelQuestion => 'What\'s your level?';

  @override
  String get levelChangeLater => 'You can change it any time in Settings.';

  @override
  String get levelFromZero => 'Starting from zero';

  @override
  String get levelFromZeroBody => 'Can\'t read hiragana and katakana yet';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelBeginnerBody => 'Know kana and a few basic words';

  @override
  String get levelBasic => 'Elementary';

  @override
  String get levelBasicBody => 'Simple sentences and basic kanji';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelIntermediateBody => 'Everyday conversation';

  @override
  String get levelUpperIntermediate => 'Upper intermediate';

  @override
  String get levelUpperIntermediateBody => 'Can read general texts';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get levelAdvancedBody => 'Aiming for fluency or the top exam';

  @override
  String get levelUnsure => 'Not sure';

  @override
  String get levelUnsureBody => 'Answer 3 quick questions';

  @override
  String get selfCheckHiragana => 'Can you read hiragana?';

  @override
  String get selfCheckKatakana => 'Can you read katakana?';

  @override
  String get selfCheckWords =>
      'Do you know about 100 basic words, like 食べる and 学校?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String selfCheckResult(String level) {
    return 'We suggest starting at $level. You can still pick another one above.';
  }

  @override
  String get goalQuestion => 'How much a day?';

  @override
  String get goalQuestionBody =>
      'The goal counts cards; minutes are a rough guess. You can change it any time.';

  @override
  String get reminderQuestion => 'Want a daily reminder?';

  @override
  String get reminderQuestionBody =>
      'One reminder a day at your time. Skipped when today\'s goal is already reached.';

  @override
  String get remindMe => 'Remind me';

  @override
  String get skip => 'Skip';

  @override
  String get learningLevel => 'Learning level';

  @override
  String get learningLevelNote =>
      'Sets the path on Today. Progress you already have is kept.';

  @override
  String get levelNotChosen => 'Not chosen';

  @override
  String get dailyGoalNote =>
      'New cards per day follow along; you can still change them below.';

  @override
  String get freezeUsed =>
      'You missed yesterday; a streak freeze kept it. Study today to keep going.';

  @override
  String freezesHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count streak freezes saved',
      one: '1 streak freeze saved',
    );
    return '$_temp0';
  }

  @override
  String freezeNext(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days more days to the next freeze',
      one: '1 more day to the next freeze',
    );
    return '$_temp0';
  }

  @override
  String stampFrozen(String date) {
    return '$date, kept by a streak freeze';
  }

  @override
  String get signInTitle => 'Sign in to your account';

  @override
  String get signInNote => 'Once signed in, the app works without internet.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String passwordRule(int count) {
    return 'At least $count characters';
  }

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccountYet => 'No account yet?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get confirmEmailTitle => 'Check your email';

  @override
  String get signUpTitle => 'Create an account';

  @override
  String get signUpNote =>
      'Use an email you can open. We\'ll send a code to confirm it\'s yours.';

  @override
  String get signUp => 'Sign up';

  @override
  String get confirmSignUp => 'Confirm and sign in';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get codeNote =>
      'Enter your account\'s email. We\'ll send a code to set a new password.';

  @override
  String codeSent(String email) {
    return 'Code sent to $email. Check your spam folder too.';
  }

  @override
  String get sendCode => 'Send code';

  @override
  String get codeLabel => 'Code from the email';

  @override
  String get savePassword => 'Save and sign in';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get authWrongPassword => 'Wrong email or password.';

  @override
  String get authNotConfirmed =>
      'This email isn\'t confirmed yet. Choose \"Forgot password?\" to get a code.';

  @override
  String get authAlreadyRegistered =>
      'This email already has an account. Sign in, or choose \"Forgot password?\".';

  @override
  String get authSignUpClosed =>
      'Sign-up is closed right now. Try again later.';

  @override
  String get authBadCode =>
      'The code is wrong or has expired. Ask for a new one.';

  @override
  String get authWeakPassword =>
      'That password is too weak. Use a longer one with letters and numbers.';

  @override
  String get authSamePassword =>
      'The new password must differ from the old one.';

  @override
  String get authTooMany =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get authOffline =>
      'No internet connection. The first sign-in needs internet.';

  @override
  String get authUnknown => 'Something went wrong. Try again in a moment.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Your progress is saved to your account and removed from this phone. Sign in again any time to get it back.';

  @override
  String get signOutUnsyncedTitle => 'Some changes aren\'t saved yet';

  @override
  String signOutUnsyncedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your last $count changes haven\'t reached your account',
      one: 'Your last change hasn\'t reached your account',
    );
    return '$_temp0 because there\'s no connection. If you sign out now, they\'ll be lost.';
  }

  @override
  String get signOutAnyway => 'Sign out anyway';

  @override
  String get savingToAccount => 'Saving your progress to your account…';

  @override
  String get restoringData => 'Restoring your data…';

  @override
  String get syncLabel => 'Sync';

  @override
  String get syncDone => 'Synced';

  @override
  String syncDoneAt(String time) {
    return 'Synced · $time';
  }

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return 'Waiting to sync · $_temp0';
  }

  @override
  String get syncRunning => 'Syncing…';

  @override
  String get syncOffline => 'Offline · will sync when you\'re back online';

  @override
  String get syncFailed => 'Couldn\'t sync · tap to try again';

  @override
  String get syncNowHint => 'sync now';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account and all your progress?';

  @override
  String get deleteAccountProgress =>
      'Cards, review history, lessons, saved words, stats and streak are deleted from your account.';

  @override
  String get deleteAccountDevices =>
      'Other phones using this account will be signed out.';

  @override
  String get deleteAccountSignIn =>
      'The account can\'t be recovered. The same email can sign up again as a new, empty account.';

  @override
  String get deleteAccountUndo => 'This can\'t be undone or recovered.';

  @override
  String get deleteAccountKeyword => 'DELETE';

  @override
  String deleteAccountType(String keyword) {
    return 'Type $keyword to confirm';
  }

  @override
  String get deleteAccountButton => 'Delete account forever';

  @override
  String get deleteAccountOffline =>
      'Deleting your account needs internet. Try again when you\'re connected.';

  @override
  String get deleteAccountFailed =>
      'Your account wasn\'t deleted. Try again in a moment.';

  @override
  String kanjiLevel(int level) {
    return 'Kanji N$level';
  }

  @override
  String nodeDoneLabel(String title) {
    return '$title, done';
  }

  @override
  String nodeLockedLabel(String title) {
    return '$title, locked';
  }

  @override
  String get freeStudy => 'Free study';

  @override
  String get freeStudyHint =>
      'Pick the groups to memorise. No scores, no limits.';

  @override
  String freeStudyContinue(String title) {
    return 'Continue: $title';
  }

  @override
  String freeStudyNotYetGroup(int count) {
    return 'Not memorised yet ($count)';
  }

  @override
  String freeStudyStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Start ($count cards)',
      one: 'Start (1 card)',
    );
    return '$_temp0';
  }

  @override
  String get freeStudyPickFirst => 'Pick a group first';

  @override
  String get freeStudyShuffle => 'Shuffle';

  @override
  String get freeStudyMeaningFirst => 'Meaning first';

  @override
  String get freeStudyKnown => 'Got it';

  @override
  String get freeStudyNotYet => 'Not yet';

  @override
  String get freeStudySwipeHint => 'Swipe right if you know it, left if not';

  @override
  String freeStudyGroupLabel(String title, int known, int total) {
    return '$title, $known of $total memorised';
  }

  @override
  String freeStudySummary(int known, int notYet) {
    return 'Got it $known · Not yet $notYet';
  }

  @override
  String freeStudyRepeat(int count) {
    return 'Repeat the not-yet cards ($count)';
  }

  @override
  String get freeStudyAddToReview => 'Add to daily review';

  @override
  String get freeStudyAdded => 'Added to review';

  @override
  String get freeStudyAllKnown => 'You know them all. Nice!';

  @override
  String get freeStudyRecallReading => 'Which character is this?';

  @override
  String get freeStudyRecallKanji => 'Which kanji means this?';
}
