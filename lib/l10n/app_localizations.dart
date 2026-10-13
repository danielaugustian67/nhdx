import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'Nihondx'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get tabToday;

  /// No description provided for @tabKana.
  ///
  /// In id, this message translates to:
  /// **'Kana'**
  String get tabKana;

  /// No description provided for @tabDictionary.
  ///
  /// In id, this message translates to:
  /// **'Kamus'**
  String get tabDictionary;

  /// No description provided for @tabCollection.
  ///
  /// In id, this message translates to:
  /// **'Koleksi'**
  String get tabCollection;

  /// No description provided for @tabMe.
  ///
  /// In id, this message translates to:
  /// **'Saya'**
  String get tabMe;

  /// No description provided for @searchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari kata, kanji, atau arti'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In id, this message translates to:
  /// **'Hapus teks'**
  String get searchClear;

  /// No description provided for @modeHiragana.
  ///
  /// In id, this message translates to:
  /// **'あ Hiragana'**
  String get modeHiragana;

  /// No description provided for @modeKatakana.
  ///
  /// In id, this message translates to:
  /// **'ア Katakana'**
  String get modeKatakana;

  /// No description provided for @modeLatin.
  ///
  /// In id, this message translates to:
  /// **'Abc teks latin'**
  String get modeLatin;

  /// No description provided for @searchNoResults.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada hasil untuk \'{query}\'. Coba ketik dengan Romaji atau kana, atau cari artinya dalam bahasa Inggris.'**
  String searchNoResults(String query);

  /// No description provided for @searchAsLatin.
  ///
  /// In id, this message translates to:
  /// **'Cari sebagai teks latin'**
  String get searchAsLatin;

  /// No description provided for @searchEmptyHint.
  ///
  /// In id, this message translates to:
  /// **'Ketik dengan Romaji, kana, kanji, atau arti dalam bahasa Inggris.'**
  String get searchEmptyHint;

  /// No description provided for @preparingDictionary.
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan kamus. Ini hanya terjadi sekali.'**
  String get preparingDictionary;

  /// No description provided for @dictionaryFailed.
  ///
  /// In id, this message translates to:
  /// **'Kamus tidak bisa dibuka. Coba tutup lalu buka lagi aplikasinya.'**
  String get dictionaryFailed;

  /// No description provided for @notBuiltYet.
  ///
  /// In id, this message translates to:
  /// **'Bagian ini sedang dibangun.'**
  String get notBuiltYet;

  /// No description provided for @exactMatch.
  ///
  /// In id, this message translates to:
  /// **'Cocok persis'**
  String get exactMatch;

  /// No description provided for @greetingMorning.
  ///
  /// In id, this message translates to:
  /// **'Selamat pagi'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In id, this message translates to:
  /// **'Selamat siang'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In id, this message translates to:
  /// **'Selamat sore'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In id, this message translates to:
  /// **'Selamat malam'**
  String get greetingNight;

  /// No description provided for @xpAmount.
  ///
  /// In id, this message translates to:
  /// **'{xp} XP'**
  String xpAmount(int xp);

  /// No description provided for @heroStartTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai dari hiragana'**
  String get heroStartTitle;

  /// No description provided for @heroStartBody.
  ///
  /// In id, this message translates to:
  /// **'Kenali 46 huruf dasar lewat game singkat, 5 menit sehari.'**
  String get heroStartBody;

  /// No description provided for @heroContinueTitle.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan kana'**
  String get heroContinueTitle;

  /// No description provided for @heroContinueBody.
  ///
  /// In id, this message translates to:
  /// **'{count} huruf masih perlu latihan.'**
  String heroContinueBody(int count);

  /// No description provided for @playNow.
  ///
  /// In id, this message translates to:
  /// **'Main sekarang'**
  String get playNow;

  /// No description provided for @sectionLearn.
  ///
  /// In id, this message translates to:
  /// **'Belajar'**
  String get sectionLearn;

  /// No description provided for @moduleKana.
  ///
  /// In id, this message translates to:
  /// **'Kana'**
  String get moduleKana;

  /// No description provided for @moduleKanaBody.
  ///
  /// In id, this message translates to:
  /// **'Hiragana & katakana, 4 game'**
  String get moduleKanaBody;

  /// No description provided for @moduleVocab.
  ///
  /// In id, this message translates to:
  /// **'Kosakata N5'**
  String get moduleVocab;

  /// No description provided for @moduleReview.
  ///
  /// In id, this message translates to:
  /// **'Review harian'**
  String get moduleReview;

  /// No description provided for @moduleKanji.
  ///
  /// In id, this message translates to:
  /// **'Kanji'**
  String get moduleKanji;

  /// No description provided for @hiragana.
  ///
  /// In id, this message translates to:
  /// **'Hiragana'**
  String get hiragana;

  /// No description provided for @katakana.
  ///
  /// In id, this message translates to:
  /// **'Katakana'**
  String get katakana;

  /// No description provided for @kindBasic.
  ///
  /// In id, this message translates to:
  /// **'Dasar'**
  String get kindBasic;

  /// No description provided for @kindDakuten.
  ///
  /// In id, this message translates to:
  /// **'Dakuten'**
  String get kindDakuten;

  /// No description provided for @kindYoon.
  ///
  /// In id, this message translates to:
  /// **'Yōon'**
  String get kindYoon;

  /// No description provided for @games.
  ///
  /// In id, this message translates to:
  /// **'Game'**
  String get games;

  /// No description provided for @gameQuiz.
  ///
  /// In id, this message translates to:
  /// **'Kuis'**
  String get gameQuiz;

  /// No description provided for @gameQuizBody.
  ///
  /// In id, this message translates to:
  /// **'4 pilihan, 10 soal'**
  String get gameQuizBody;

  /// No description provided for @gameMatch.
  ///
  /// In id, this message translates to:
  /// **'Cocokkan'**
  String get gameMatch;

  /// No description provided for @gameMatchBody.
  ///
  /// In id, this message translates to:
  /// **'Cari pasangan'**
  String get gameMatchBody;

  /// No description provided for @gameSpeed.
  ///
  /// In id, this message translates to:
  /// **'Cepat'**
  String get gameSpeed;

  /// No description provided for @gameSpeedBody.
  ///
  /// In id, this message translates to:
  /// **'60 detik, kejar combo'**
  String get gameSpeedBody;

  /// No description provided for @gameWrite.
  ///
  /// In id, this message translates to:
  /// **'Tulis'**
  String get gameWrite;

  /// No description provided for @gameWriteBody.
  ///
  /// In id, this message translates to:
  /// **'Latih urutan goresan'**
  String get gameWriteBody;

  /// No description provided for @allCharacters.
  ///
  /// In id, this message translates to:
  /// **'Semua huruf'**
  String get allCharacters;

  /// No description provided for @strokeCount.
  ///
  /// In id, this message translates to:
  /// **'{count} goresan'**
  String strokeCount(int count);

  /// No description provided for @exampleWord.
  ///
  /// In id, this message translates to:
  /// **'Contoh kata'**
  String get exampleWord;

  /// No description provided for @practiceWriting.
  ///
  /// In id, this message translates to:
  /// **'Latihan menulis'**
  String get practiceWriting;

  /// No description provided for @replay.
  ///
  /// In id, this message translates to:
  /// **'Putar ulang'**
  String get replay;

  /// No description provided for @questionProgress.
  ///
  /// In id, this message translates to:
  /// **'{current} dari {total}'**
  String questionProgress(int current, int total);

  /// No description provided for @askRomaji.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara membacanya?'**
  String get askRomaji;

  /// No description provided for @askKana.
  ///
  /// In id, this message translates to:
  /// **'Mana hurufnya?'**
  String get askKana;

  /// No description provided for @correct.
  ///
  /// In id, this message translates to:
  /// **'Benar!'**
  String get correct;

  /// No description provided for @answerWas.
  ///
  /// In id, this message translates to:
  /// **'Jawabannya {answer}'**
  String answerWas(String answer);

  /// No description provided for @next.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get next;

  /// No description provided for @quit.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get quit;

  /// No description provided for @movesCount.
  ///
  /// In id, this message translates to:
  /// **'{count} langkah'**
  String movesCount(int count);

  /// No description provided for @secondsLeft.
  ///
  /// In id, this message translates to:
  /// **'{seconds} dtk'**
  String secondsLeft(int seconds);

  /// No description provided for @comboCount.
  ///
  /// In id, this message translates to:
  /// **'Combo ×{count}'**
  String comboCount(int count);

  /// No description provided for @speedStart.
  ///
  /// In id, this message translates to:
  /// **'Jawab sebanyak mungkin dalam 60 detik. Jawaban benar beruntun menaikkan combo dan XP.'**
  String get speedStart;

  /// No description provided for @start.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get start;

  /// No description provided for @writeHint.
  ///
  /// In id, this message translates to:
  /// **'Tulis mengikuti panduan, goresan demi goresan.'**
  String get writeHint;

  /// No description provided for @check.
  ///
  /// In id, this message translates to:
  /// **'Periksa'**
  String get check;

  /// No description provided for @clear.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get clear;

  /// No description provided for @guide.
  ///
  /// In id, this message translates to:
  /// **'Panduan'**
  String get guide;

  /// No description provided for @writeGood.
  ///
  /// In id, this message translates to:
  /// **'Bagus! Jumlah, urutan, dan arah goresan sudah benar.'**
  String get writeGood;

  /// No description provided for @writeCountWrong.
  ///
  /// In id, this message translates to:
  /// **'Kamu menulis {drawn} goresan, seharusnya {expected}.'**
  String writeCountWrong(int drawn, int expected);

  /// No description provided for @writeReversed.
  ///
  /// In id, this message translates to:
  /// **'Goresan ke-{n} terbalik arahnya.'**
  String writeReversed(int n);

  /// No description provided for @writeWrongOrder.
  ///
  /// In id, this message translates to:
  /// **'Goresan ke-{n} tidak sesuai urutan.'**
  String writeWrongOrder(int n);

  /// No description provided for @writeMisplaced.
  ///
  /// In id, this message translates to:
  /// **'Goresan ke-{n} terlalu jauh dari panduan.'**
  String writeMisplaced(int n);

  /// No description provided for @writeWrongShape.
  ///
  /// In id, this message translates to:
  /// **'Bentuk goresan ke-{n} belum pas.'**
  String writeWrongShape(int n);

  /// No description provided for @tryAgain.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get tryAgain;

  /// No description provided for @sessionDone.
  ///
  /// In id, this message translates to:
  /// **'Sesi selesai'**
  String get sessionDone;

  /// No description provided for @accuracyPercent.
  ///
  /// In id, this message translates to:
  /// **'Akurasi {percent}%'**
  String accuracyPercent(int percent);

  /// No description provided for @xpGained.
  ///
  /// In id, this message translates to:
  /// **'+{xp} XP'**
  String xpGained(int xp);

  /// No description provided for @needsPractice.
  ///
  /// In id, this message translates to:
  /// **'Perlu latihan'**
  String get needsPractice;

  /// No description provided for @playAgain.
  ///
  /// In id, this message translates to:
  /// **'Main lagi'**
  String get playAgain;

  /// No description provided for @done.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get done;

  /// No description provided for @unitNumber.
  ///
  /// In id, this message translates to:
  /// **'Unit {n}'**
  String unitNumber(int n);

  /// No description provided for @unitRows.
  ///
  /// In id, this message translates to:
  /// **'Baris {rows}'**
  String unitRows(String rows);

  /// No description provided for @unitDakuten.
  ///
  /// In id, this message translates to:
  /// **'Dakuten & handakuten'**
  String get unitDakuten;

  /// No description provided for @unitYoon.
  ///
  /// In id, this message translates to:
  /// **'Yōon (huruf gabungan)'**
  String get unitYoon;

  /// No description provided for @nodeIntro.
  ///
  /// In id, this message translates to:
  /// **'Kenali {kana}'**
  String nodeIntro(String kana);

  /// No description provided for @nodeWrite.
  ///
  /// In id, this message translates to:
  /// **'Tulis huruf unit ini'**
  String get nodeWrite;

  /// No description provided for @nodeMatch.
  ///
  /// In id, this message translates to:
  /// **'Cocokkan pasangan'**
  String get nodeMatch;

  /// No description provided for @nodeSpeed.
  ///
  /// In id, this message translates to:
  /// **'Tantangan 60 detik'**
  String get nodeSpeed;

  /// No description provided for @nodeChest.
  ///
  /// In id, this message translates to:
  /// **'Peti hadiah'**
  String get nodeChest;

  /// No description provided for @nodePosition.
  ///
  /// In id, this message translates to:
  /// **'Pelajaran {current} dari {total}'**
  String nodePosition(int current, int total);

  /// No description provided for @nodeLocked.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan pelajaran sebelumnya untuk membuka ini.'**
  String get nodeLocked;

  /// No description provided for @nodeReplay.
  ///
  /// In id, this message translates to:
  /// **'Ulangi'**
  String get nodeReplay;

  /// No description provided for @openChest.
  ///
  /// In id, this message translates to:
  /// **'Buka peti'**
  String get openChest;

  /// No description provided for @chestOpened.
  ///
  /// In id, this message translates to:
  /// **'Peti terbuka! +{xp} XP'**
  String chestOpened(int xp);

  /// No description provided for @startHere.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get startHere;

  /// No description provided for @kanaTable.
  ///
  /// In id, this message translates to:
  /// **'Tabel kana'**
  String get kanaTable;

  /// No description provided for @newCharacters.
  ///
  /// In id, this message translates to:
  /// **'Huruf baru'**
  String get newCharacters;

  /// No description provided for @startQuiz.
  ///
  /// In id, this message translates to:
  /// **'Mulai latihan'**
  String get startQuiz;

  /// No description provided for @practiceOneMode.
  ///
  /// In id, this message translates to:
  /// **'Atau latih satu jenis:'**
  String get practiceOneMode;

  /// No description provided for @modeChoice.
  ///
  /// In id, this message translates to:
  /// **'Pilihan'**
  String get modeChoice;

  /// No description provided for @modeType.
  ///
  /// In id, this message translates to:
  /// **'Ketik'**
  String get modeType;

  /// No description provided for @exWrite.
  ///
  /// In id, this message translates to:
  /// **'Tulis huruf ini'**
  String get exWrite;

  /// No description provided for @exBuild.
  ///
  /// In id, this message translates to:
  /// **'Susun dalam {script}'**
  String exBuild(String script);

  /// No description provided for @exRead.
  ///
  /// In id, this message translates to:
  /// **'Ketik cara bacanya dalam romaji'**
  String get exRead;

  /// No description provided for @romajiHint.
  ///
  /// In id, this message translates to:
  /// **'romaji'**
  String get romajiHint;

  /// No description provided for @notQuite.
  ///
  /// In id, this message translates to:
  /// **'Belum tepat'**
  String get notQuite;

  /// No description provided for @trackKana.
  ///
  /// In id, this message translates to:
  /// **'Kana'**
  String get trackKana;

  /// No description provided for @trackKanji.
  ///
  /// In id, this message translates to:
  /// **'Kanji'**
  String get trackKanji;

  /// No description provided for @kanjiTheme.
  ///
  /// In id, this message translates to:
  /// **'{theme, select, numbers{Angka} people{Orang & tubuh} week{Hari} nature{Alam} position{Posisi & arah} qualities{Sifat} clock{Waktu} intro{Perkenalan} actions{Kegiatan} school{Sekolah & bahasa} town{Kota} colors{Warna & cahaya} family{Keluarga} health{Tubuh & kesehatan} landscape{Pemandangan} seasons{Musim & waktu} food{Hewan & makanan} regions{Wilayah} buildings{Bangunan} travel{Perjalanan} size{Ukuran & kekuatan} judgement{Penilaian} mind{Pikiran & rasa} study{Belajar} arts{Bahasa & seni} work{Pekerjaan} shopping{Belanja} doing{Tindakan} daily{Sehari-hari} other{Kanji}}'**
  String kanjiTheme(String theme);

  /// No description provided for @unitLevel.
  ///
  /// In id, this message translates to:
  /// **'Unit {n} · N{level}'**
  String unitLevel(int n, int level);

  /// No description provided for @nodeReview.
  ///
  /// In id, this message translates to:
  /// **'Ulasan unit'**
  String get nodeReview;

  /// No description provided for @askMeaning.
  ///
  /// In id, this message translates to:
  /// **'Apa artinya?'**
  String get askMeaning;

  /// No description provided for @askKanji.
  ///
  /// In id, this message translates to:
  /// **'Mana kanjinya?'**
  String get askKanji;

  /// No description provided for @onyomi.
  ///
  /// In id, this message translates to:
  /// **'On'**
  String get onyomi;

  /// No description provided for @kunyomi.
  ///
  /// In id, this message translates to:
  /// **'Kun'**
  String get kunyomi;

  /// No description provided for @bookmarkAdd.
  ///
  /// In id, this message translates to:
  /// **'Simpan ke koleksi'**
  String get bookmarkAdd;

  /// No description provided for @bookmarkRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus dari koleksi'**
  String get bookmarkRemove;

  /// No description provided for @bookmarked.
  ///
  /// In id, this message translates to:
  /// **'Disimpan ke koleksi'**
  String get bookmarked;

  /// No description provided for @copied.
  ///
  /// In id, this message translates to:
  /// **'Disalin'**
  String get copied;

  /// No description provided for @commonWord.
  ///
  /// In id, this message translates to:
  /// **'Umum'**
  String get commonWord;

  /// No description provided for @verbGodan.
  ///
  /// In id, this message translates to:
  /// **'Kata kerja godan'**
  String get verbGodan;

  /// No description provided for @verbIchidan.
  ///
  /// In id, this message translates to:
  /// **'Kata kerja ichidan'**
  String get verbIchidan;

  /// No description provided for @verbIrregular.
  ///
  /// In id, this message translates to:
  /// **'Kata kerja tak beraturan'**
  String get verbIrregular;

  /// No description provided for @adjI.
  ///
  /// In id, this message translates to:
  /// **'Kata sifat-i'**
  String get adjI;

  /// No description provided for @adjNa.
  ///
  /// In id, this message translates to:
  /// **'Kata sifat-na'**
  String get adjNa;

  /// No description provided for @meanings.
  ///
  /// In id, this message translates to:
  /// **'Arti'**
  String get meanings;

  /// No description provided for @otherForms.
  ///
  /// In id, this message translates to:
  /// **'Penulisan lain'**
  String get otherForms;

  /// No description provided for @entryMissing.
  ///
  /// In id, this message translates to:
  /// **'Entri ini tidak lagi tersedia di kamus.'**
  String get entryMissing;

  /// No description provided for @recentSearches.
  ///
  /// In id, this message translates to:
  /// **'Pencarian terakhir'**
  String get recentSearches;

  /// No description provided for @clearHistory.
  ///
  /// In id, this message translates to:
  /// **'Hapus riwayat'**
  String get clearHistory;

  /// No description provided for @removeFromHistory.
  ///
  /// In id, this message translates to:
  /// **'Hapus dari riwayat'**
  String get removeFromHistory;

  /// No description provided for @wordOfTheDay.
  ///
  /// In id, this message translates to:
  /// **'Kata hari ini'**
  String get wordOfTheDay;

  /// No description provided for @browseByLevel.
  ///
  /// In id, this message translates to:
  /// **'Telusur per level'**
  String get browseByLevel;

  /// No description provided for @levelWordCount.
  ///
  /// In id, this message translates to:
  /// **'{count} kata'**
  String levelWordCount(int count);

  /// No description provided for @collectionEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kata tersimpan. Ketuk ☆ di Kamus untuk menyimpan kata.'**
  String get collectionEmpty;

  /// No description provided for @collectionSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari di koleksi'**
  String get collectionSearchHint;

  /// No description provided for @allLevels.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get allLevels;

  /// No description provided for @removedFromCollection.
  ///
  /// In id, this message translates to:
  /// **'Dihapus dari koleksi.'**
  String get removedFromCollection;

  /// No description provided for @undo.
  ///
  /// In id, this message translates to:
  /// **'Urungkan'**
  String get undo;

  /// No description provided for @remove.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get remove;

  /// No description provided for @noLevel.
  ///
  /// In id, this message translates to:
  /// **'Tanpa level'**
  String get noLevel;

  /// No description provided for @addToStudy.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke belajar'**
  String get addToStudy;

  /// No description provided for @inStudy.
  ///
  /// In id, this message translates to:
  /// **'Sudah di belajar'**
  String get inStudy;

  /// No description provided for @showAnswer.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan jawaban'**
  String get showAnswer;

  /// No description provided for @tapToFlip.
  ///
  /// In id, this message translates to:
  /// **'Ketuk untuk balik'**
  String get tapToFlip;

  /// No description provided for @rateAgain.
  ///
  /// In id, this message translates to:
  /// **'Lagi'**
  String get rateAgain;

  /// No description provided for @rateHard.
  ///
  /// In id, this message translates to:
  /// **'Sulit'**
  String get rateHard;

  /// No description provided for @rateGood.
  ///
  /// In id, this message translates to:
  /// **'Baik'**
  String get rateGood;

  /// No description provided for @rateEasy.
  ///
  /// In id, this message translates to:
  /// **'Mudah'**
  String get rateEasy;

  /// No description provided for @intervalMinutes.
  ///
  /// In id, this message translates to:
  /// **'{n} mnt'**
  String intervalMinutes(int n);

  /// No description provided for @intervalHours.
  ///
  /// In id, this message translates to:
  /// **'{n} jam'**
  String intervalHours(int n);

  /// No description provided for @intervalDays.
  ///
  /// In id, this message translates to:
  /// **'{n} hr'**
  String intervalDays(int n);

  /// No description provided for @intervalMonths.
  ///
  /// In id, this message translates to:
  /// **'{n} bln'**
  String intervalMonths(int n);

  /// No description provided for @intervalYears.
  ///
  /// In id, this message translates to:
  /// **'{n} thn'**
  String intervalYears(int n);

  /// No description provided for @reviewLeft.
  ///
  /// In id, this message translates to:
  /// **'{count} kartu lagi'**
  String reviewLeft(int count);

  /// No description provided for @reviewSummary.
  ///
  /// In id, this message translates to:
  /// **'{count} jawaban · {correct} benar · {again} Lagi · ±{minutes} menit'**
  String reviewSummary(int count, int correct, int again, int minutes);

  /// No description provided for @reviewEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada kartu untuk saat ini. Tambahkan kata dari Kamus (Tambah ke belajar) atau mulai dari kata N5.'**
  String get reviewEmpty;

  /// No description provided for @addN5Words.
  ///
  /// In id, this message translates to:
  /// **'Tambah {count} kata N5'**
  String addN5Words(int count);

  /// No description provided for @newLimitReached.
  ///
  /// In id, this message translates to:
  /// **'Batas {limit} kartu baru hari ini sudah tercapai. {count} kartu baru menunggu, besok muncul di sini.'**
  String newLimitReached(int limit, int count);

  /// No description provided for @reviewButton.
  ///
  /// In id, this message translates to:
  /// **'Review'**
  String get reviewButton;

  /// No description provided for @reviewDue.
  ///
  /// In id, this message translates to:
  /// **'{count} kartu siap direview'**
  String reviewDue(int count);

  /// No description provided for @almostThere.
  ///
  /// In id, this message translates to:
  /// **'Hampir!'**
  String get almostThere;

  /// No description provided for @passMarkNeeded.
  ///
  /// In id, this message translates to:
  /// **'Butuh akurasi minimal {percent}% untuk lulus. Coba sekali lagi!'**
  String passMarkNeeded(int percent);

  /// No description provided for @passMarkHint.
  ///
  /// In id, this message translates to:
  /// **'Lulus dengan akurasi ≥ {percent}%'**
  String passMarkHint(int percent);

  /// No description provided for @dailyGoal.
  ///
  /// In id, this message translates to:
  /// **'Target harian'**
  String get dailyGoal;

  /// No description provided for @goalCardsUnit.
  ///
  /// In id, this message translates to:
  /// **'kartu'**
  String get goalCardsUnit;

  /// No description provided for @goalReached.
  ///
  /// In id, this message translates to:
  /// **'Target harian tercapai'**
  String get goalReached;

  /// No description provided for @goalLeft.
  ///
  /// In id, this message translates to:
  /// **'{count} kartu lagi untuk target hari ini'**
  String goalLeft(int count);

  /// No description provided for @streakDays.
  ///
  /// In id, this message translates to:
  /// **'Streak {count} hari'**
  String streakDays(int count);

  /// No description provided for @streakLongest.
  ///
  /// In id, this message translates to:
  /// **'Terpanjang {count} hari'**
  String streakLongest(int count);

  /// No description provided for @streakKeep.
  ///
  /// In id, this message translates to:
  /// **'Belajar hari ini agar streak berlanjut.'**
  String get streakKeep;

  /// No description provided for @streakStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai hari ini, 1 sesi cukup.'**
  String get streakStart;

  /// No description provided for @statNew.
  ///
  /// In id, this message translates to:
  /// **'Baru'**
  String get statNew;

  /// No description provided for @statReviews.
  ///
  /// In id, this message translates to:
  /// **'Review'**
  String get statReviews;

  /// No description provided for @statAccuracy.
  ///
  /// In id, this message translates to:
  /// **'Akurasi'**
  String get statAccuracy;

  /// No description provided for @statTime.
  ///
  /// In id, this message translates to:
  /// **'Waktu'**
  String get statTime;

  /// No description provided for @activity.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas'**
  String get activity;

  /// No description provided for @lastDays.
  ///
  /// In id, this message translates to:
  /// **'{count} hari'**
  String lastDays(int count);

  /// No description provided for @activityTotal.
  ///
  /// In id, this message translates to:
  /// **'{cards} kartu · {xp} XP'**
  String activityTotal(int cards, int xp);

  /// No description provided for @activityBar.
  ///
  /// In id, this message translates to:
  /// **'{date}: {cards} kartu'**
  String activityBar(String date, int cards);

  /// No description provided for @stampBook.
  ///
  /// In id, this message translates to:
  /// **'Buku stempel'**
  String get stampBook;

  /// No description provided for @stampDay.
  ///
  /// In id, this message translates to:
  /// **'{date}, belajar'**
  String stampDay(String date);

  /// No description provided for @previousMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan sebelumnya'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan berikutnya'**
  String get nextMonth;

  /// No description provided for @jlptProgress.
  ///
  /// In id, this message translates to:
  /// **'Progres JLPT'**
  String get jlptProgress;

  /// No description provided for @wordsOf.
  ///
  /// In id, this message translates to:
  /// **'{learned} dari {total} kata'**
  String wordsOf(int learned, int total);

  /// No description provided for @cardStages.
  ///
  /// In id, this message translates to:
  /// **'Kartu'**
  String get cardStages;

  /// No description provided for @stageNew.
  ///
  /// In id, this message translates to:
  /// **'Baru'**
  String get stageNew;

  /// No description provided for @stageLearning.
  ///
  /// In id, this message translates to:
  /// **'Dipelajari'**
  String get stageLearning;

  /// No description provided for @stageYoung.
  ///
  /// In id, this message translates to:
  /// **'Muda'**
  String get stageYoung;

  /// No description provided for @stageMature.
  ///
  /// In id, this message translates to:
  /// **'Matang'**
  String get stageMature;

  /// No description provided for @hardestItems.
  ///
  /// In id, this message translates to:
  /// **'Item tersulit'**
  String get hardestItems;

  /// No description provided for @lapsesCount.
  ///
  /// In id, this message translates to:
  /// **'Lupa {count}×'**
  String lapsesCount(int count);

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @settingsLearning.
  ///
  /// In id, this message translates to:
  /// **'Belajar'**
  String get settingsLearning;

  /// No description provided for @settingsAppearance.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get settingsAppearance;

  /// No description provided for @cardsCount.
  ///
  /// In id, this message translates to:
  /// **'{count} kartu'**
  String cardsCount(int count);

  /// No description provided for @newPerDay.
  ///
  /// In id, this message translates to:
  /// **'Kartu baru per hari'**
  String get newPerDay;

  /// No description provided for @newPerDayNote.
  ///
  /// In id, this message translates to:
  /// **'Lebih banyak = lebih cepat maju, tapi review beberapa hari ke depan ikut bertambah.'**
  String get newPerDayNote;

  /// No description provided for @reviewsPerDay.
  ///
  /// In id, this message translates to:
  /// **'Batas review per hari'**
  String get reviewsPerDay;

  /// No description provided for @reviewsPerDayNote.
  ///
  /// In id, this message translates to:
  /// **'Kartu yang melewati batas tetap menunggu dan muncul di sesi berikutnya.'**
  String get reviewsPerDayNote;

  /// No description provided for @dayStart.
  ///
  /// In id, this message translates to:
  /// **'Hari baru dimulai'**
  String get dayStart;

  /// No description provided for @dayStartNote.
  ///
  /// In id, this message translates to:
  /// **'Belajar sebelum jam ini masih dihitung untuk hari sebelumnya (streak & target).'**
  String get dayStartNote;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In id, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @followSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get followSystem;

  /// No description provided for @textSize.
  ///
  /// In id, this message translates to:
  /// **'Ukuran teks'**
  String get textSize;

  /// No description provided for @textNormal.
  ///
  /// In id, this message translates to:
  /// **'Normal'**
  String get textNormal;

  /// No description provided for @textLarge.
  ///
  /// In id, this message translates to:
  /// **'Besar'**
  String get textLarge;

  /// No description provided for @textLarger.
  ///
  /// In id, this message translates to:
  /// **'Lebih besar'**
  String get textLarger;

  /// No description provided for @newLimitDone.
  ///
  /// In id, this message translates to:
  /// **'Kamu sudah mempelajari {limit} kartu baru hari ini. Lanjut besok!'**
  String newLimitDone(int limit);

  /// No description provided for @goalRelaxed.
  ///
  /// In id, this message translates to:
  /// **'Santai'**
  String get goalRelaxed;

  /// No description provided for @goalRegular.
  ///
  /// In id, this message translates to:
  /// **'Rutin'**
  String get goalRegular;

  /// No description provided for @goalSerious.
  ///
  /// In id, this message translates to:
  /// **'Serius'**
  String get goalSerious;

  /// No description provided for @goalOption.
  ///
  /// In id, this message translates to:
  /// **'±{minutes} menit sehari · {cards} kartu · {fresh} kata baru'**
  String goalOption(int minutes, int cards, int fresh);

  /// No description provided for @totalXp.
  ///
  /// In id, this message translates to:
  /// **'{xp} XP total'**
  String totalXp(int xp);

  /// No description provided for @aboutAttribution.
  ///
  /// In id, this message translates to:
  /// **'Tentang & atribusi'**
  String get aboutAttribution;

  /// No description provided for @dataSources.
  ///
  /// In id, this message translates to:
  /// **'Sumber data'**
  String get dataSources;

  /// No description provided for @openSourceLicenses.
  ///
  /// In id, this message translates to:
  /// **'Lisensi open source'**
  String get openSourceLicenses;

  /// No description provided for @datasetVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi kamus {version}'**
  String datasetVersion(String version);

  /// No description provided for @recallJapanese.
  ///
  /// In id, this message translates to:
  /// **'Apa bahasa Jepangnya?'**
  String get recallJapanese;

  /// No description provided for @cardDirection.
  ///
  /// In id, this message translates to:
  /// **'Arah kartu kata'**
  String get cardDirection;

  /// No description provided for @directionJpToMeaning.
  ///
  /// In id, this message translates to:
  /// **'Jepang → arti'**
  String get directionJpToMeaning;

  /// No description provided for @directionMeaningToJp.
  ///
  /// In id, this message translates to:
  /// **'Arti → Jepang'**
  String get directionMeaningToJp;

  /// No description provided for @directionBoth.
  ///
  /// In id, this message translates to:
  /// **'Dua arah (2 kartu per kata)'**
  String get directionBoth;

  /// No description provided for @directionNote.
  ///
  /// In id, this message translates to:
  /// **'Berlaku untuk kata yang ditambahkan berikutnya'**
  String get directionNote;

  /// No description provided for @trackVocab.
  ///
  /// In id, this message translates to:
  /// **'Kata'**
  String get trackVocab;

  /// No description provided for @vocabLevel.
  ///
  /// In id, this message translates to:
  /// **'Kosakata N{level}'**
  String vocabLevel(int level);

  /// No description provided for @nodeWords.
  ///
  /// In id, this message translates to:
  /// **'{count} kata: {words}'**
  String nodeWords(int count, String words);

  /// No description provided for @newWords.
  ///
  /// In id, this message translates to:
  /// **'Kata baru'**
  String get newWords;

  /// No description provided for @askWord.
  ///
  /// In id, this message translates to:
  /// **'Mana katanya?'**
  String get askWord;

  /// No description provided for @exRecall.
  ///
  /// In id, this message translates to:
  /// **'Ketik kata Jepangnya dalam romaji'**
  String get exRecall;

  /// No description provided for @exMatch.
  ///
  /// In id, this message translates to:
  /// **'Pasangkan kata dengan artinya'**
  String get exMatch;

  /// No description provided for @matchMistakes.
  ///
  /// In id, this message translates to:
  /// **'Salah pasang {count}×'**
  String matchMistakes(int count);

  /// No description provided for @settingsNotifications.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get settingsNotifications;

  /// No description provided for @dailyReminder.
  ///
  /// In id, this message translates to:
  /// **'Pengingat harian'**
  String get dailyReminder;

  /// No description provided for @reminderNote.
  ///
  /// In id, this message translates to:
  /// **'Sekali sehari. Tidak muncul bila target hari ini sudah tercapai.'**
  String get reminderNote;

  /// No description provided for @reminderTime.
  ///
  /// In id, this message translates to:
  /// **'Jam pengingat'**
  String get reminderTime;

  /// No description provided for @reminderDenied.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi belum diizinkan. Izinkan di pengaturan HP agar pengingat bisa muncul.'**
  String get reminderDenied;

  /// No description provided for @openSettings.
  ///
  /// In id, this message translates to:
  /// **'Buka pengaturan'**
  String get openSettings;

  /// No description provided for @reminderChannel.
  ///
  /// In id, this message translates to:
  /// **'Pengingat harian'**
  String get reminderChannel;

  /// No description provided for @reminderChannelNote.
  ///
  /// In id, this message translates to:
  /// **'Pengingat belajar sekali sehari'**
  String get reminderChannelNote;

  /// No description provided for @reminderCards.
  ///
  /// In id, this message translates to:
  /// **'Ada {count} kartu menunggu. Sekitar {minutes} menit.'**
  String reminderCards(int count, int minutes);

  /// No description provided for @reminderStreak.
  ///
  /// In id, this message translates to:
  /// **'Streak {count} hari menunggumu. Satu sesi singkat sudah cukup.'**
  String reminderStreak(int count);

  /// No description provided for @reminderPlain.
  ///
  /// In id, this message translates to:
  /// **'Saatnya belajar sebentar. Beberapa menit sudah cukup.'**
  String get reminderPlain;

  /// No description provided for @quickSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari di kamus'**
  String get quickSearch;

  /// No description provided for @appVersion.
  ///
  /// In id, this message translates to:
  /// **'Versi {version}'**
  String appVersion(String version);

  /// No description provided for @contentVersion.
  ///
  /// In id, this message translates to:
  /// **'konten {version}'**
  String contentVersion(String version);

  /// No description provided for @schemaVersion.
  ///
  /// In id, this message translates to:
  /// **'skema data {version}'**
  String schemaVersion(int version);

  /// No description provided for @onboardingStep.
  ///
  /// In id, this message translates to:
  /// **'Langkah {step} dari {total}'**
  String onboardingStep(int step, int total);

  /// No description provided for @levelQuestion.
  ///
  /// In id, this message translates to:
  /// **'Kamu di level mana?'**
  String get levelQuestion;

  /// No description provided for @levelChangeLater.
  ///
  /// In id, this message translates to:
  /// **'Bisa diubah kapan saja di Pengaturan.'**
  String get levelChangeLater;

  /// No description provided for @levelFromZero.
  ///
  /// In id, this message translates to:
  /// **'Baru mulai dari nol'**
  String get levelFromZero;

  /// No description provided for @levelFromZeroBody.
  ///
  /// In id, this message translates to:
  /// **'Belum bisa membaca hiragana dan katakana'**
  String get levelFromZeroBody;

  /// No description provided for @levelBeginner.
  ///
  /// In id, this message translates to:
  /// **'Pemula'**
  String get levelBeginner;

  /// No description provided for @levelBeginnerBody.
  ///
  /// In id, this message translates to:
  /// **'Sudah kenal kana, tahu beberapa kata dasar'**
  String get levelBeginnerBody;

  /// No description provided for @levelBasic.
  ///
  /// In id, this message translates to:
  /// **'Dasar'**
  String get levelBasic;

  /// No description provided for @levelBasicBody.
  ///
  /// In id, this message translates to:
  /// **'Bisa kalimat sederhana dan kanji dasar'**
  String get levelBasicBody;

  /// No description provided for @levelIntermediate.
  ///
  /// In id, this message translates to:
  /// **'Menengah'**
  String get levelIntermediate;

  /// No description provided for @levelIntermediateBody.
  ///
  /// In id, this message translates to:
  /// **'Bisa percakapan sehari-hari'**
  String get levelIntermediateBody;

  /// No description provided for @levelUpperIntermediate.
  ///
  /// In id, this message translates to:
  /// **'Menengah atas'**
  String get levelUpperIntermediate;

  /// No description provided for @levelUpperIntermediateBody.
  ///
  /// In id, this message translates to:
  /// **'Bisa membaca teks umum'**
  String get levelUpperIntermediateBody;

  /// No description provided for @levelAdvanced.
  ///
  /// In id, this message translates to:
  /// **'Mahir'**
  String get levelAdvanced;

  /// No description provided for @levelAdvancedBody.
  ///
  /// In id, this message translates to:
  /// **'Menargetkan kefasihan atau ujian tertinggi'**
  String get levelAdvancedBody;

  /// No description provided for @levelUnsure.
  ///
  /// In id, this message translates to:
  /// **'Belum tahu'**
  String get levelUnsure;

  /// No description provided for @levelUnsureBody.
  ///
  /// In id, this message translates to:
  /// **'Jawab 3 pertanyaan singkat'**
  String get levelUnsureBody;

  /// No description provided for @selfCheckHiragana.
  ///
  /// In id, this message translates to:
  /// **'Bisa membaca hiragana?'**
  String get selfCheckHiragana;

  /// No description provided for @selfCheckKatakana.
  ///
  /// In id, this message translates to:
  /// **'Bisa membaca katakana?'**
  String get selfCheckKatakana;

  /// No description provided for @selfCheckWords.
  ///
  /// In id, this message translates to:
  /// **'Mengenal sekitar 100 kata dasar, seperti 食べる dan 学校?'**
  String get selfCheckWords;

  /// No description provided for @yes.
  ///
  /// In id, this message translates to:
  /// **'Ya'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In id, this message translates to:
  /// **'Tidak'**
  String get no;

  /// No description provided for @selfCheckResult.
  ///
  /// In id, this message translates to:
  /// **'Kami sarankan mulai dari {level}. Kamu tetap bisa memilih yang lain di atas.'**
  String selfCheckResult(String level);

  /// No description provided for @goalQuestion.
  ///
  /// In id, this message translates to:
  /// **'Berapa lama belajar setiap hari?'**
  String get goalQuestion;

  /// No description provided for @goalQuestionBody.
  ///
  /// In id, this message translates to:
  /// **'Target dihitung dalam kartu; menitnya hanya perkiraan. Bisa diubah kapan saja.'**
  String get goalQuestionBody;

  /// No description provided for @reminderQuestion.
  ///
  /// In id, this message translates to:
  /// **'Mau diingatkan setiap hari?'**
  String get reminderQuestion;

  /// No description provided for @reminderQuestionBody.
  ///
  /// In id, this message translates to:
  /// **'Satu pengingat sehari di jam pilihanmu. Tidak muncul bila target hari ini sudah tercapai.'**
  String get reminderQuestionBody;

  /// No description provided for @remindMe.
  ///
  /// In id, this message translates to:
  /// **'Ingatkan saya'**
  String get remindMe;

  /// No description provided for @skip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get skip;

  /// No description provided for @learningLevel.
  ///
  /// In id, this message translates to:
  /// **'Level belajar'**
  String get learningLevel;

  /// No description provided for @learningLevelNote.
  ///
  /// In id, this message translates to:
  /// **'Menentukan jalur di Hari ini. Progres yang sudah ada tidak hilang.'**
  String get learningLevelNote;

  /// No description provided for @levelNotChosen.
  ///
  /// In id, this message translates to:
  /// **'Belum dipilih'**
  String get levelNotChosen;

  /// No description provided for @dailyGoalNote.
  ///
  /// In id, this message translates to:
  /// **'Kartu baru per hari ikut disesuaikan; bisa diubah sendiri di bawah.'**
  String get dailyGoalNote;

  /// No description provided for @freezeUsed.
  ///
  /// In id, this message translates to:
  /// **'Kemarin terlewat; pembekuan streak menjaganya. Belajar hari ini agar berlanjut.'**
  String get freezeUsed;

  /// No description provided for @freezesHeld.
  ///
  /// In id, this message translates to:
  /// **'{count} pembekuan tersimpan'**
  String freezesHeld(int count);

  /// No description provided for @freezeNext.
  ///
  /// In id, this message translates to:
  /// **'{days} hari lagi untuk pembekuan berikutnya'**
  String freezeNext(int days);

  /// No description provided for @stampFrozen.
  ///
  /// In id, this message translates to:
  /// **'{date}, dijaga pembekuan streak'**
  String stampFrozen(String date);

  /// No description provided for @signInTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke akunmu'**
  String get signInTitle;

  /// No description provided for @signInNote.
  ///
  /// In id, this message translates to:
  /// **'Setelah masuk, aplikasi tetap bisa dipakai tanpa internet.'**
  String get signInNote;

  /// No description provided for @emailLabel.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi'**
  String get passwordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi baru'**
  String get newPasswordLabel;

  /// No description provided for @passwordRule.
  ///
  /// In id, this message translates to:
  /// **'Minimal {count} karakter'**
  String passwordRule(int count);

  /// No description provided for @showPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan kata sandi'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan kata sandi'**
  String get hidePassword;

  /// No description provided for @signIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get signIn;

  /// No description provided for @forgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa kata sandi?'**
  String get forgotPassword;

  /// No description provided for @noAccountYet.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun?'**
  String get noAccountYet;

  /// No description provided for @haveAccount.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun?'**
  String get haveAccount;

  /// No description provided for @confirmEmailTitle.
  ///
  /// In id, this message translates to:
  /// **'Cek emailmu'**
  String get confirmEmailTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In id, this message translates to:
  /// **'Buat akun'**
  String get signUpTitle;

  /// No description provided for @signUpNote.
  ///
  /// In id, this message translates to:
  /// **'Pakai email yang bisa kamu buka. Kami kirim kode untuk memastikan email itu milikmu.'**
  String get signUpNote;

  /// No description provided for @signUp.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get signUp;

  /// No description provided for @confirmSignUp.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi dan masuk'**
  String get confirmSignUp;

  /// No description provided for @forgotTitle.
  ///
  /// In id, this message translates to:
  /// **'Atur ulang kata sandi'**
  String get forgotTitle;

  /// No description provided for @codeNote.
  ///
  /// In id, this message translates to:
  /// **'Masukkan email akunmu. Kami kirim kode untuk membuat kata sandi baru.'**
  String get codeNote;

  /// No description provided for @codeSent.
  ///
  /// In id, this message translates to:
  /// **'Kode dikirim ke {email}. Cek juga folder spam.'**
  String codeSent(String email);

  /// No description provided for @sendCode.
  ///
  /// In id, this message translates to:
  /// **'Kirim kode'**
  String get sendCode;

  /// No description provided for @codeLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode dari email'**
  String get codeLabel;

  /// No description provided for @savePassword.
  ///
  /// In id, this message translates to:
  /// **'Simpan dan masuk'**
  String get savePassword;

  /// No description provided for @resendCode.
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang kode'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang dalam {seconds} detik'**
  String resendIn(int seconds);

  /// No description provided for @authWrongPassword.
  ///
  /// In id, this message translates to:
  /// **'Email atau kata sandi salah.'**
  String get authWrongPassword;

  /// No description provided for @authNotConfirmed.
  ///
  /// In id, this message translates to:
  /// **'Email ini belum dikonfirmasi. Pilih \"Lupa kata sandi?\" untuk menerima kode.'**
  String get authNotConfirmed;

  /// No description provided for @authAlreadyRegistered.
  ///
  /// In id, this message translates to:
  /// **'Email ini sudah terdaftar. Masuk, atau pilih \"Lupa kata sandi?\".'**
  String get authAlreadyRegistered;

  /// No description provided for @authSignUpClosed.
  ///
  /// In id, this message translates to:
  /// **'Pendaftaran sedang ditutup. Coba lagi nanti.'**
  String get authSignUpClosed;

  /// No description provided for @authBadCode.
  ///
  /// In id, this message translates to:
  /// **'Kode salah atau sudah kedaluwarsa. Minta kode baru.'**
  String get authBadCode;

  /// No description provided for @authWeakPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi terlalu lemah. Pakai yang lebih panjang, campur huruf dan angka.'**
  String get authWeakPassword;

  /// No description provided for @authSamePassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi baru harus berbeda dari yang lama.'**
  String get authSamePassword;

  /// No description provided for @authTooMany.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.'**
  String get authTooMany;

  /// No description provided for @authOffline.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada koneksi internet. Masuk pertama kali butuh internet.'**
  String get authOffline;

  /// No description provided for @authUnknown.
  ///
  /// In id, this message translates to:
  /// **'Gagal. Coba lagi sebentar lagi.'**
  String get authUnknown;

  /// No description provided for @settingsAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get settingsAccount;

  /// No description provided for @signedInAs.
  ///
  /// In id, this message translates to:
  /// **'Masuk sebagai'**
  String get signedInAs;

  /// No description provided for @signOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In id, this message translates to:
  /// **'Progresmu tersimpan di akun dan dihapus dari HP ini. Masuk lagi kapan saja untuk memulihkannya.'**
  String get signOutBody;

  /// No description provided for @signOutUnsyncedTitle.
  ///
  /// In id, this message translates to:
  /// **'Ada perubahan yang belum tersimpan'**
  String get signOutUnsyncedTitle;

  /// No description provided for @signOutUnsyncedBody.
  ///
  /// In id, this message translates to:
  /// **'{count} perubahan terakhir belum terkirim ke akun karena tidak ada koneksi. Bila keluar sekarang, perubahan itu hilang.'**
  String signOutUnsyncedBody(int count);

  /// No description provided for @signOutAnyway.
  ///
  /// In id, this message translates to:
  /// **'Keluar saja'**
  String get signOutAnyway;

  /// No description provided for @savingToAccount.
  ///
  /// In id, this message translates to:
  /// **'Menyimpan progres ke akun…'**
  String get savingToAccount;

  /// No description provided for @restoringData.
  ///
  /// In id, this message translates to:
  /// **'Memulihkan datamu…'**
  String get restoringData;

  /// No description provided for @syncLabel.
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi'**
  String get syncLabel;

  /// No description provided for @syncDone.
  ///
  /// In id, this message translates to:
  /// **'Tersinkron'**
  String get syncDone;

  /// No description provided for @syncDoneAt.
  ///
  /// In id, this message translates to:
  /// **'Tersinkron · {time}'**
  String syncDoneAt(String time);

  /// No description provided for @syncPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu sinkron · {count} perubahan'**
  String syncPending(int count);

  /// No description provided for @syncRunning.
  ///
  /// In id, this message translates to:
  /// **'Menyinkronkan…'**
  String get syncRunning;

  /// No description provided for @syncOffline.
  ///
  /// In id, this message translates to:
  /// **'Offline · disinkronkan saat tersambung lagi'**
  String get syncOffline;

  /// No description provided for @syncFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyinkronkan · ketuk untuk mencoba lagi'**
  String get syncFailed;

  /// No description provided for @syncNowHint.
  ///
  /// In id, this message translates to:
  /// **'sinkronkan sekarang'**
  String get syncNowHint;

  /// No description provided for @deleteAccount.
  ///
  /// In id, this message translates to:
  /// **'Hapus akun'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus akun dan semua progresmu?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountProgress.
  ///
  /// In id, this message translates to:
  /// **'Kartu, riwayat review, pelajaran, simpanan, statistik, dan streak dihapus dari akunmu.'**
  String get deleteAccountProgress;

  /// No description provided for @deleteAccountDevices.
  ///
  /// In id, this message translates to:
  /// **'HP lain yang memakai akun ini akan otomatis keluar.'**
  String get deleteAccountDevices;

  /// No description provided for @deleteAccountSignIn.
  ///
  /// In id, this message translates to:
  /// **'Akun ini tidak bisa dipulihkan. Email yang sama bisa didaftarkan lagi sebagai akun baru yang kosong.'**
  String get deleteAccountSignIn;

  /// No description provided for @deleteAccountUndo.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa dibatalkan atau dipulihkan.'**
  String get deleteAccountUndo;

  /// No description provided for @deleteAccountKeyword.
  ///
  /// In id, this message translates to:
  /// **'HAPUS'**
  String get deleteAccountKeyword;

  /// No description provided for @deleteAccountType.
  ///
  /// In id, this message translates to:
  /// **'Ketik {keyword} untuk konfirmasi'**
  String deleteAccountType(String keyword);

  /// No description provided for @deleteAccountButton.
  ///
  /// In id, this message translates to:
  /// **'Hapus akun selamanya'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountOffline.
  ///
  /// In id, this message translates to:
  /// **'Butuh internet untuk menghapus akun. Coba lagi saat tersambung.'**
  String get deleteAccountOffline;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In id, this message translates to:
  /// **'Akun belum terhapus. Coba lagi sebentar lagi.'**
  String get deleteAccountFailed;

  /// No description provided for @kanjiLevel.
  ///
  /// In id, this message translates to:
  /// **'Kanji N{level}'**
  String kanjiLevel(int level);

  /// No description provided for @nodeDoneLabel.
  ///
  /// In id, this message translates to:
  /// **'{title}, selesai'**
  String nodeDoneLabel(String title);

  /// No description provided for @nodeLockedLabel.
  ///
  /// In id, this message translates to:
  /// **'{title}, terkunci'**
  String nodeLockedLabel(String title);

  /// No description provided for @freeStudy.
  ///
  /// In id, this message translates to:
  /// **'Hafalan Bebas'**
  String get freeStudy;

  /// No description provided for @freeStudyHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih grup yang mau dihafal. Tanpa nilai, tanpa batas.'**
  String get freeStudyHint;

  /// No description provided for @freeStudyContinue.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan: {title}'**
  String freeStudyContinue(String title);

  /// No description provided for @freeStudyNotYetGroup.
  ///
  /// In id, this message translates to:
  /// **'Yang belum hafal ({count})'**
  String freeStudyNotYetGroup(int count);

  /// No description provided for @freeStudyStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai ({count} kartu)'**
  String freeStudyStart(int count);

  /// No description provided for @freeStudyPickFirst.
  ///
  /// In id, this message translates to:
  /// **'Pilih grup dulu'**
  String get freeStudyPickFirst;

  /// No description provided for @freeStudyShuffle.
  ///
  /// In id, this message translates to:
  /// **'Acak'**
  String get freeStudyShuffle;

  /// No description provided for @freeStudyMeaningFirst.
  ///
  /// In id, this message translates to:
  /// **'Arti dulu'**
  String get freeStudyMeaningFirst;

  /// No description provided for @freeStudyKnown.
  ///
  /// In id, this message translates to:
  /// **'Hafal'**
  String get freeStudyKnown;

  /// No description provided for @freeStudyNotYet.
  ///
  /// In id, this message translates to:
  /// **'Belum'**
  String get freeStudyNotYet;

  /// No description provided for @freeStudySwipeHint.
  ///
  /// In id, this message translates to:
  /// **'Geser ke kanan kalau hafal, ke kiri kalau belum'**
  String get freeStudySwipeHint;

  /// No description provided for @freeStudyGroupLabel.
  ///
  /// In id, this message translates to:
  /// **'{title}, {known} dari {total} hafal'**
  String freeStudyGroupLabel(String title, int known, int total);

  /// No description provided for @freeStudySummary.
  ///
  /// In id, this message translates to:
  /// **'Hafal {known} · Belum {notYet}'**
  String freeStudySummary(int known, int notYet);

  /// No description provided for @freeStudyRepeat.
  ///
  /// In id, this message translates to:
  /// **'Ulangi yang belum ({count})'**
  String freeStudyRepeat(int count);

  /// No description provided for @freeStudyAddToReview.
  ///
  /// In id, this message translates to:
  /// **'Masukkan ke review harian'**
  String get freeStudyAddToReview;

  /// No description provided for @freeStudyAdded.
  ///
  /// In id, this message translates to:
  /// **'Sudah masuk review'**
  String get freeStudyAdded;

  /// No description provided for @freeStudyAllKnown.
  ///
  /// In id, this message translates to:
  /// **'Semua sudah hafal. Mantap!'**
  String get freeStudyAllKnown;

  /// No description provided for @freeStudyRecallReading.
  ///
  /// In id, this message translates to:
  /// **'Huruf apa ini?'**
  String get freeStudyRecallReading;

  /// No description provided for @freeStudyRecallKanji.
  ///
  /// In id, this message translates to:
  /// **'Kanji apa yang artinya ini?'**
  String get freeStudyRecallKanji;

  /// No description provided for @listen.
  ///
  /// In id, this message translates to:
  /// **'Dengarkan'**
  String get listen;

  /// No description provided for @speechUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Suara bahasa Jepang belum ada di HP ini. Pasang lewat Setelan HP › Text-to-speech › Bahasa Jepang.'**
  String get speechUnavailable;

  /// No description provided for @speechAutoplay.
  ///
  /// In id, this message translates to:
  /// **'Putar suara otomatis'**
  String get speechAutoplay;

  /// No description provided for @speechAutoplayNote.
  ///
  /// In id, this message translates to:
  /// **'Baca huruf dan kata saat kartu dibalik atau pelajaran dibuka'**
  String get speechAutoplayNote;

  /// No description provided for @settingsSound.
  ///
  /// In id, this message translates to:
  /// **'Suara'**
  String get settingsSound;

  /// No description provided for @conjugation.
  ///
  /// In id, this message translates to:
  /// **'Konjugasi'**
  String get conjugation;

  /// No description provided for @conjPlain.
  ///
  /// In id, this message translates to:
  /// **'Bentuk kamus'**
  String get conjPlain;

  /// No description provided for @conjPolite.
  ///
  /// In id, this message translates to:
  /// **'Sopan'**
  String get conjPolite;

  /// No description provided for @conjNegative.
  ///
  /// In id, this message translates to:
  /// **'Negatif'**
  String get conjNegative;

  /// No description provided for @conjPoliteNegative.
  ///
  /// In id, this message translates to:
  /// **'Negatif sopan'**
  String get conjPoliteNegative;

  /// No description provided for @conjPast.
  ///
  /// In id, this message translates to:
  /// **'Lampau'**
  String get conjPast;

  /// No description provided for @conjPolitePast.
  ///
  /// In id, this message translates to:
  /// **'Lampau sopan'**
  String get conjPolitePast;

  /// No description provided for @conjPastNegative.
  ///
  /// In id, this message translates to:
  /// **'Lampau negatif'**
  String get conjPastNegative;

  /// No description provided for @conjPolitePastNegative.
  ///
  /// In id, this message translates to:
  /// **'Lampau negatif sopan'**
  String get conjPolitePastNegative;

  /// No description provided for @conjTe.
  ///
  /// In id, this message translates to:
  /// **'Bentuk te'**
  String get conjTe;

  /// No description provided for @conjPotential.
  ///
  /// In id, this message translates to:
  /// **'Potensial (bisa …)'**
  String get conjPotential;

  /// No description provided for @conjPassive.
  ///
  /// In id, this message translates to:
  /// **'Pasif (di-…)'**
  String get conjPassive;

  /// No description provided for @conjCausative.
  ///
  /// In id, this message translates to:
  /// **'Kausatif (menyuruh …)'**
  String get conjCausative;

  /// No description provided for @conjImperative.
  ///
  /// In id, this message translates to:
  /// **'Perintah'**
  String get conjImperative;

  /// No description provided for @conjVolitional.
  ///
  /// In id, this message translates to:
  /// **'Ajakan (ayo …)'**
  String get conjVolitional;

  /// No description provided for @conjConditionalBa.
  ///
  /// In id, this message translates to:
  /// **'Pengandaian 〜ば'**
  String get conjConditionalBa;

  /// No description provided for @conjConditionalTara.
  ///
  /// In id, this message translates to:
  /// **'Pengandaian 〜たら'**
  String get conjConditionalTara;

  /// No description provided for @conjWant.
  ///
  /// In id, this message translates to:
  /// **'Ingin (〜たい)'**
  String get conjWant;

  /// No description provided for @conjAdverb.
  ///
  /// In id, this message translates to:
  /// **'Kata keterangan'**
  String get conjAdverb;

  /// No description provided for @conjShowAll.
  ///
  /// In id, this message translates to:
  /// **'Semua bentuk ({count})'**
  String conjShowAll(int count);

  /// No description provided for @conjShowLess.
  ///
  /// In id, this message translates to:
  /// **'Lebih sedikit'**
  String get conjShowLess;

  /// No description provided for @conjPractice.
  ///
  /// In id, this message translates to:
  /// **'Latihan konjugasi'**
  String get conjPractice;

  /// No description provided for @conjPracticeBody.
  ///
  /// In id, this message translates to:
  /// **'Ubah kata kerja dan kata sifat ke bentuk ます, ない, た, て, dan lainnya.'**
  String get conjPracticeBody;

  /// No description provided for @conjPracticeWord.
  ///
  /// In id, this message translates to:
  /// **'Latih kata ini'**
  String get conjPracticeWord;

  /// No description provided for @conjVerbs.
  ///
  /// In id, this message translates to:
  /// **'Kata kerja'**
  String get conjVerbs;

  /// No description provided for @conjAdjectives.
  ///
  /// In id, this message translates to:
  /// **'Kata sifat'**
  String get conjAdjectives;

  /// No description provided for @conjWordTypes.
  ///
  /// In id, this message translates to:
  /// **'Jenis kata'**
  String get conjWordTypes;

  /// No description provided for @conjLevels.
  ///
  /// In id, this message translates to:
  /// **'Level kata'**
  String get conjLevels;

  /// No description provided for @conjForms.
  ///
  /// In id, this message translates to:
  /// **'Bentuk yang dilatih'**
  String get conjForms;

  /// No description provided for @conjStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai ({count} soal)'**
  String conjStart(int count);

  /// No description provided for @conjAsk.
  ///
  /// In id, this message translates to:
  /// **'Ubah ke bentuk'**
  String get conjAsk;

  /// No description provided for @conjAnswerWas.
  ///
  /// In id, this message translates to:
  /// **'Jawabannya: {answer}'**
  String conjAnswerWas(String answer);

  /// No description provided for @conjScore.
  ///
  /// In id, this message translates to:
  /// **'{correct} dari {total} benar'**
  String conjScore(int correct, int total);

  /// No description provided for @conjMistakes.
  ///
  /// In id, this message translates to:
  /// **'Yang perlu diulang'**
  String get conjMistakes;

  /// No description provided for @conjAddMistakes.
  ///
  /// In id, this message translates to:
  /// **'Masukkan yang salah ke review'**
  String get conjAddMistakes;

  /// No description provided for @conjNoWords.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada kata yang cocok. Pilih jenis kata, level atau bentuk lain.'**
  String get conjNoWords;

  /// No description provided for @grammar.
  ///
  /// In id, this message translates to:
  /// **'Tata bahasa'**
  String get grammar;

  /// No description provided for @grammarBody.
  ///
  /// In id, this message translates to:
  /// **'Pola kalimat dengan penjelasan, contoh, dan latihan'**
  String get grammarBody;

  /// No description provided for @grammarDoneCount.
  ///
  /// In id, this message translates to:
  /// **'{done} dari {total} selesai'**
  String grammarDoneCount(int done, int total);

  /// No description provided for @grammarFormation.
  ///
  /// In id, this message translates to:
  /// **'Pembentukan'**
  String get grammarFormation;

  /// No description provided for @grammarExplanation.
  ///
  /// In id, this message translates to:
  /// **'Penjelasan'**
  String get grammarExplanation;

  /// No description provided for @grammarExamples.
  ///
  /// In id, this message translates to:
  /// **'Contoh kalimat'**
  String get grammarExamples;

  /// No description provided for @grammarPractice.
  ///
  /// In id, this message translates to:
  /// **'Latihan'**
  String get grammarPractice;

  /// No description provided for @grammarPracticeMixed.
  ///
  /// In id, this message translates to:
  /// **'Latihan campuran'**
  String get grammarPracticeMixed;

  /// No description provided for @grammarFillGap.
  ///
  /// In id, this message translates to:
  /// **'Isi bagian yang kosong'**
  String get grammarFillGap;

  /// No description provided for @grammarBuild.
  ///
  /// In id, this message translates to:
  /// **'Susun kalimatnya'**
  String get grammarBuild;

  /// No description provided for @grammarCheck.
  ///
  /// In id, this message translates to:
  /// **'Periksa'**
  String get grammarCheck;

  /// No description provided for @grammarClear.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get grammarClear;

  /// No description provided for @grammarAddReview.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke review'**
  String get grammarAddReview;

  /// No description provided for @grammarInReview.
  ///
  /// In id, this message translates to:
  /// **'Ada di review'**
  String get grammarInReview;

  /// No description provided for @grammarDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get grammarDone;

  /// No description provided for @grammarPassToFinish.
  ///
  /// In id, this message translates to:
  /// **'Benar 80% di latihan untuk menandai pola ini selesai.'**
  String get grammarPassToFinish;

  /// No description provided for @grammarAndConjugation.
  ///
  /// In id, this message translates to:
  /// **'Tata bahasa & konjugasi'**
  String get grammarAndConjugation;

  /// No description provided for @freeStudyCollection.
  ///
  /// In id, this message translates to:
  /// **'Koleksiku'**
  String get freeStudyCollection;

  /// No description provided for @freeStudyForgotten.
  ///
  /// In id, this message translates to:
  /// **'Sering lupa'**
  String get freeStudyForgotten;

  /// No description provided for @freeStudyRange.
  ///
  /// In id, this message translates to:
  /// **'{from}–{to}'**
  String freeStudyRange(int from, int to);

  /// No description provided for @freeStudyCollectionEmpty.
  ///
  /// In id, this message translates to:
  /// **'Koleksimu masih kosong. Ketuk ☆ pada kata di Kamus untuk menyimpannya, lalu hafalkan di sini.'**
  String get freeStudyCollectionEmpty;

  /// No description provided for @freeStudyForgottenEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kartu review yang terlupa. Mantap!'**
  String get freeStudyForgottenEmpty;

  /// No description provided for @freeStudyReset.
  ///
  /// In id, this message translates to:
  /// **'Reset tanda hafal'**
  String get freeStudyReset;

  /// No description provided for @freeStudyResetTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset tanda hafal?'**
  String get freeStudyResetTitle;

  /// No description provided for @freeStudyResetSelected.
  ///
  /// In id, this message translates to:
  /// **'Tanda Hafal dan Belum di {count, plural, other{{count} grup}} yang dipilih akan dihapus.'**
  String freeStudyResetSelected(int count);

  /// No description provided for @freeStudyResetAll.
  ///
  /// In id, this message translates to:
  /// **'Semua tanda Hafal dan Belum di {kind} akan dihapus.'**
  String freeStudyResetAll(String kind);

  /// No description provided for @freeStudyResetConfirm.
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get freeStudyResetConfirm;

  /// No description provided for @freeStudyResetDone.
  ///
  /// In id, this message translates to:
  /// **'Tanda hafal sudah direset'**
  String get freeStudyResetDone;

  /// No description provided for @hardestStudy.
  ///
  /// In id, this message translates to:
  /// **'Hafalkan'**
  String get hardestStudy;

  /// No description provided for @themeNote.
  ///
  /// In id, this message translates to:
  /// **'Pilih gelap atau terang dan warna untuk seluruh aplikasi.'**
  String get themeNote;

  /// No description provided for @themeMode.
  ///
  /// In id, this message translates to:
  /// **'Mode'**
  String get themeMode;

  /// No description provided for @themeColor.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get themeColor;

  /// No description provided for @themePreview.
  ///
  /// In id, this message translates to:
  /// **'Pratinjau'**
  String get themePreview;

  /// No description provided for @themePreviewMeaning.
  ///
  /// In id, this message translates to:
  /// **'bunga sakura'**
  String get themePreviewMeaning;

  /// No description provided for @themePreviewMain.
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get themePreviewMain;

  /// No description provided for @themePreviewOther.
  ///
  /// In id, this message translates to:
  /// **'Detail'**
  String get themePreviewOther;

  /// No description provided for @paletteCustom.
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get paletteCustom;

  /// No description provided for @paletteSakuraNote.
  ///
  /// In id, this message translates to:
  /// **'Merah muda sakura dan plum (bawaan)'**
  String get paletteSakuraNote;

  /// No description provided for @paletteMatchaNote.
  ///
  /// In id, this message translates to:
  /// **'Hijau teh dan bambu yang tenang'**
  String get paletteMatchaNote;

  /// No description provided for @paletteAoiNote.
  ///
  /// In id, this message translates to:
  /// **'Biru laut dan Gunung Fuji'**
  String get paletteAoiNote;

  /// No description provided for @paletteMikanNote.
  ///
  /// In id, this message translates to:
  /// **'Jingga hangat jeruk mikan'**
  String get paletteMikanNote;

  /// No description provided for @paletteMurasakiNote.
  ///
  /// In id, this message translates to:
  /// **'Ungu bunga wisteria'**
  String get paletteMurasakiNote;

  /// No description provided for @paletteKuroNote.
  ///
  /// In id, this message translates to:
  /// **'Abu-abu monokrom yang minimalis'**
  String get paletteKuroNote;

  /// No description provided for @paletteCustomNote.
  ///
  /// In id, this message translates to:
  /// **'Pilih warna aksenmu sendiri'**
  String get paletteCustomNote;

  /// No description provided for @themeAccent.
  ///
  /// In id, this message translates to:
  /// **'Warna aksen'**
  String get themeAccent;

  /// No description provided for @themeHex.
  ///
  /// In id, this message translates to:
  /// **'Kode hex'**
  String get themeHex;

  /// No description provided for @themeHexHint.
  ///
  /// In id, this message translates to:
  /// **'6 karakter, mis. 3B82F6'**
  String get themeHexHint;

  /// No description provided for @themeHexInvalid.
  ///
  /// In id, this message translates to:
  /// **'Pakai 6 karakter 0–9 atau A–F'**
  String get themeHexInvalid;

  /// No description provided for @themeApply.
  ///
  /// In id, this message translates to:
  /// **'Terapkan'**
  String get themeApply;

  /// No description provided for @themePureBlack.
  ///
  /// In id, this message translates to:
  /// **'Hitam pekat (AMOLED)'**
  String get themePureBlack;

  /// No description provided for @themePureBlackNote.
  ///
  /// In id, this message translates to:
  /// **'Latar hitam murni di mode gelap, hemat baterai di layar OLED.'**
  String get themePureBlackNote;

  /// No description provided for @themePureBlackLight.
  ///
  /// In id, this message translates to:
  /// **'Hanya berlaku di mode gelap.'**
  String get themePureBlackLight;

  /// No description provided for @studyLanguage.
  ///
  /// In id, this message translates to:
  /// **'Bahasa yang dipelajari'**
  String get studyLanguage;

  /// No description provided for @studyLanguageNote.
  ///
  /// In id, this message translates to:
  /// **'Kemajuan tiap bahasa disimpan terpisah, jadi kamu bisa bolak-balik kapan saja.'**
  String get studyLanguageNote;

  /// No description provided for @languageJapanese.
  ///
  /// In id, this message translates to:
  /// **'Bahasa Jepang'**
  String get languageJapanese;

  /// No description provided for @languageKorean.
  ///
  /// In id, this message translates to:
  /// **'Bahasa Korea'**
  String get languageKorean;

  /// No description provided for @languageJapaneseBody.
  ///
  /// In id, this message translates to:
  /// **'Hiragana, katakana, kanji, kosakata JLPT dan tata bahasa'**
  String get languageJapaneseBody;

  /// No description provided for @languageKoreanBody.
  ///
  /// In id, this message translates to:
  /// **'Hangul dan kosakata dasar (TOPIK I)'**
  String get languageKoreanBody;

  /// No description provided for @languageQuestion.
  ///
  /// In id, this message translates to:
  /// **'Mau belajar bahasa apa?'**
  String get languageQuestion;

  /// No description provided for @languageQuestionBody.
  ///
  /// In id, this message translates to:
  /// **'Bisa diganti kapan saja lewat tombol bendera di Hari ini atau di Pengaturan.'**
  String get languageQuestionBody;

  /// No description provided for @switchLanguage.
  ///
  /// In id, this message translates to:
  /// **'Ganti bahasa'**
  String get switchLanguage;

  /// No description provided for @hangul.
  ///
  /// In id, this message translates to:
  /// **'Hangul'**
  String get hangul;

  /// No description provided for @trackHangul.
  ///
  /// In id, this message translates to:
  /// **'Hangul'**
  String get trackHangul;

  /// No description provided for @koreanVocab.
  ///
  /// In id, this message translates to:
  /// **'Kosakata Korea'**
  String get koreanVocab;

  /// No description provided for @hangulVowels.
  ///
  /// In id, this message translates to:
  /// **'Vokal'**
  String get hangulVowels;

  /// No description provided for @hangulConsonants.
  ///
  /// In id, this message translates to:
  /// **'Konsonan'**
  String get hangulConsonants;

  /// No description provided for @hangulSyllables.
  ///
  /// In id, this message translates to:
  /// **'Suku kata'**
  String get hangulSyllables;

  /// No description provided for @hangulTable.
  ///
  /// In id, this message translates to:
  /// **'Tabel Hangul'**
  String get hangulTable;

  /// No description provided for @moduleHangulBody.
  ///
  /// In id, this message translates to:
  /// **'Vokal, konsonan & suku kata, 3 game'**
  String get moduleHangulBody;

  /// No description provided for @exReadKorean.
  ///
  /// In id, this message translates to:
  /// **'Ketik cara bacanya dalam huruf Latin'**
  String get exReadKorean;

  /// No description provided for @exRecallKorean.
  ///
  /// In id, this message translates to:
  /// **'Ketik kata Koreanya dalam huruf Latin'**
  String get exRecallKorean;

  /// No description provided for @romajaHint.
  ///
  /// In id, this message translates to:
  /// **'romanisasi'**
  String get romajaHint;

  /// No description provided for @recallKorean.
  ///
  /// In id, this message translates to:
  /// **'Apa bahasa Koreanya?'**
  String get recallKorean;

  /// No description provided for @speechUnavailableKorean.
  ///
  /// In id, this message translates to:
  /// **'Suara bahasa Korea belum ada di HP ini. Pasang lewat Setelan HP › Text-to-speech › Bahasa Korea.'**
  String get speechUnavailableKorean;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
