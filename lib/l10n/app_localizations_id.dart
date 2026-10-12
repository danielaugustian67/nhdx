// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Nihondx';

  @override
  String get tabToday => 'Hari ini';

  @override
  String get tabKana => 'Kana';

  @override
  String get tabDictionary => 'Kamus';

  @override
  String get tabCollection => 'Koleksi';

  @override
  String get tabMe => 'Saya';

  @override
  String get searchHint => 'Cari kata, kanji, atau arti';

  @override
  String get searchClear => 'Hapus teks';

  @override
  String get modeHiragana => 'あ Hiragana';

  @override
  String get modeKatakana => 'ア Katakana';

  @override
  String get modeLatin => 'Abc teks latin';

  @override
  String searchNoResults(String query) {
    return 'Tidak ada hasil untuk \'$query\'. Coba ketik dengan Romaji atau kana, atau cari artinya dalam bahasa Inggris.';
  }

  @override
  String get searchAsLatin => 'Cari sebagai teks latin';

  @override
  String get searchEmptyHint =>
      'Ketik dengan Romaji, kana, kanji, atau arti dalam bahasa Inggris.';

  @override
  String get preparingDictionary =>
      'Menyiapkan kamus. Ini hanya terjadi sekali.';

  @override
  String get dictionaryFailed =>
      'Kamus tidak bisa dibuka. Coba tutup lalu buka lagi aplikasinya.';

  @override
  String get notBuiltYet => 'Bagian ini sedang dibangun.';

  @override
  String get exactMatch => 'Cocok persis';

  @override
  String get greetingMorning => 'Selamat pagi';

  @override
  String get greetingAfternoon => 'Selamat siang';

  @override
  String get greetingEvening => 'Selamat sore';

  @override
  String get greetingNight => 'Selamat malam';

  @override
  String xpAmount(int xp) {
    return '$xp XP';
  }

  @override
  String get heroStartTitle => 'Mulai dari hiragana';

  @override
  String get heroStartBody =>
      'Kenali 46 huruf dasar lewat game singkat, 5 menit sehari.';

  @override
  String get heroContinueTitle => 'Lanjutkan kana';

  @override
  String heroContinueBody(int count) {
    return '$count huruf masih perlu latihan.';
  }

  @override
  String get playNow => 'Main sekarang';

  @override
  String get sectionLearn => 'Belajar';

  @override
  String get moduleKana => 'Kana';

  @override
  String get moduleKanaBody => 'Hiragana & katakana, 4 game';

  @override
  String get moduleVocab => 'Kosakata N5';

  @override
  String get moduleReview => 'Review harian';

  @override
  String get moduleKanji => 'Kanji';

  @override
  String get hiragana => 'Hiragana';

  @override
  String get katakana => 'Katakana';

  @override
  String get kindBasic => 'Dasar';

  @override
  String get kindDakuten => 'Dakuten';

  @override
  String get kindYoon => 'Yōon';

  @override
  String get games => 'Game';

  @override
  String get gameQuiz => 'Kuis';

  @override
  String get gameQuizBody => '4 pilihan, 10 soal';

  @override
  String get gameMatch => 'Cocokkan';

  @override
  String get gameMatchBody => 'Cari pasangan';

  @override
  String get gameSpeed => 'Cepat';

  @override
  String get gameSpeedBody => '60 detik, kejar combo';

  @override
  String get gameWrite => 'Tulis';

  @override
  String get gameWriteBody => 'Latih urutan goresan';

  @override
  String get allCharacters => 'Semua huruf';

  @override
  String strokeCount(int count) {
    return '$count goresan';
  }

  @override
  String get exampleWord => 'Contoh kata';

  @override
  String get practiceWriting => 'Latihan menulis';

  @override
  String get replay => 'Putar ulang';

  @override
  String questionProgress(int current, int total) {
    return '$current dari $total';
  }

  @override
  String get askRomaji => 'Bagaimana cara membacanya?';

  @override
  String get askKana => 'Mana hurufnya?';

  @override
  String get correct => 'Benar!';

  @override
  String answerWas(String answer) {
    return 'Jawabannya $answer';
  }

  @override
  String get next => 'Lanjut';

  @override
  String get quit => 'Keluar';

  @override
  String movesCount(int count) {
    return '$count langkah';
  }

  @override
  String secondsLeft(int seconds) {
    return '$seconds dtk';
  }

  @override
  String comboCount(int count) {
    return 'Combo ×$count';
  }

  @override
  String get speedStart =>
      'Jawab sebanyak mungkin dalam 60 detik. Jawaban benar beruntun menaikkan combo dan XP.';

  @override
  String get start => 'Mulai';

  @override
  String get writeHint => 'Tulis mengikuti panduan, goresan demi goresan.';

  @override
  String get check => 'Periksa';

  @override
  String get clear => 'Hapus';

  @override
  String get guide => 'Panduan';

  @override
  String get writeGood =>
      'Bagus! Jumlah, urutan, dan arah goresan sudah benar.';

  @override
  String writeCountWrong(int drawn, int expected) {
    return 'Kamu menulis $drawn goresan, seharusnya $expected.';
  }

  @override
  String writeReversed(int n) {
    return 'Goresan ke-$n terbalik arahnya.';
  }

  @override
  String writeWrongOrder(int n) {
    return 'Goresan ke-$n tidak sesuai urutan.';
  }

  @override
  String writeMisplaced(int n) {
    return 'Goresan ke-$n terlalu jauh dari panduan.';
  }

  @override
  String writeWrongShape(int n) {
    return 'Bentuk goresan ke-$n belum pas.';
  }

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get sessionDone => 'Sesi selesai';

  @override
  String accuracyPercent(int percent) {
    return 'Akurasi $percent%';
  }

  @override
  String xpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get needsPractice => 'Perlu latihan';

  @override
  String get playAgain => 'Main lagi';

  @override
  String get done => 'Selesai';

  @override
  String unitNumber(int n) {
    return 'Unit $n';
  }

  @override
  String unitRows(String rows) {
    return 'Baris $rows';
  }

  @override
  String get unitDakuten => 'Dakuten & handakuten';

  @override
  String get unitYoon => 'Yōon (huruf gabungan)';

  @override
  String nodeIntro(String kana) {
    return 'Kenali $kana';
  }

  @override
  String get nodeWrite => 'Tulis huruf unit ini';

  @override
  String get nodeMatch => 'Cocokkan pasangan';

  @override
  String get nodeSpeed => 'Tantangan 60 detik';

  @override
  String get nodeChest => 'Peti hadiah';

  @override
  String nodePosition(int current, int total) {
    return 'Pelajaran $current dari $total';
  }

  @override
  String get nodeLocked => 'Selesaikan pelajaran sebelumnya untuk membuka ini.';

  @override
  String get nodeReplay => 'Ulangi';

  @override
  String get openChest => 'Buka peti';

  @override
  String chestOpened(int xp) {
    return 'Peti terbuka! +$xp XP';
  }

  @override
  String get startHere => 'Mulai';

  @override
  String get kanaTable => 'Tabel kana';

  @override
  String get newCharacters => 'Huruf baru';

  @override
  String get startQuiz => 'Mulai latihan';

  @override
  String get practiceOneMode => 'Atau latih satu jenis:';

  @override
  String get modeChoice => 'Pilihan';

  @override
  String get modeType => 'Ketik';

  @override
  String get exWrite => 'Tulis huruf ini';

  @override
  String exBuild(String script) {
    return 'Susun dalam $script';
  }

  @override
  String get exRead => 'Ketik cara bacanya dalam romaji';

  @override
  String get romajiHint => 'romaji';

  @override
  String get notQuite => 'Belum tepat';

  @override
  String get trackKana => 'Kana';

  @override
  String get trackKanji => 'Kanji';

  @override
  String kanjiTheme(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'numbers': 'Angka',
      'people': 'Orang & tubuh',
      'week': 'Hari',
      'nature': 'Alam',
      'position': 'Posisi & arah',
      'qualities': 'Sifat',
      'clock': 'Waktu',
      'intro': 'Perkenalan',
      'actions': 'Kegiatan',
      'school': 'Sekolah & bahasa',
      'town': 'Kota',
      'colors': 'Warna & cahaya',
      'family': 'Keluarga',
      'health': 'Tubuh & kesehatan',
      'landscape': 'Pemandangan',
      'seasons': 'Musim & waktu',
      'food': 'Hewan & makanan',
      'regions': 'Wilayah',
      'buildings': 'Bangunan',
      'travel': 'Perjalanan',
      'size': 'Ukuran & kekuatan',
      'judgement': 'Penilaian',
      'mind': 'Pikiran & rasa',
      'study': 'Belajar',
      'arts': 'Bahasa & seni',
      'work': 'Pekerjaan',
      'shopping': 'Belanja',
      'doing': 'Tindakan',
      'daily': 'Sehari-hari',
      'other': 'Kanji',
    });
    return '$_temp0';
  }

  @override
  String unitLevel(int n, int level) {
    return 'Unit $n · N$level';
  }

  @override
  String get nodeReview => 'Ulasan unit';

  @override
  String get askMeaning => 'Apa artinya?';

  @override
  String get askKanji => 'Mana kanjinya?';

  @override
  String get onyomi => 'On';

  @override
  String get kunyomi => 'Kun';

  @override
  String get bookmarkAdd => 'Simpan ke koleksi';

  @override
  String get bookmarkRemove => 'Hapus dari koleksi';

  @override
  String get bookmarked => 'Disimpan ke koleksi';

  @override
  String get copied => 'Disalin';

  @override
  String get commonWord => 'Umum';

  @override
  String get verbGodan => 'Kata kerja godan';

  @override
  String get verbIchidan => 'Kata kerja ichidan';

  @override
  String get verbIrregular => 'Kata kerja tak beraturan';

  @override
  String get adjI => 'Kata sifat-i';

  @override
  String get adjNa => 'Kata sifat-na';

  @override
  String get meanings => 'Arti';

  @override
  String get otherForms => 'Penulisan lain';

  @override
  String get entryMissing => 'Entri ini tidak lagi tersedia di kamus.';

  @override
  String get recentSearches => 'Pencarian terakhir';

  @override
  String get clearHistory => 'Hapus riwayat';

  @override
  String get removeFromHistory => 'Hapus dari riwayat';

  @override
  String get wordOfTheDay => 'Kata hari ini';

  @override
  String get browseByLevel => 'Telusur per level';

  @override
  String levelWordCount(int count) {
    return '$count kata';
  }

  @override
  String get collectionEmpty =>
      'Belum ada kata tersimpan. Ketuk ☆ di Kamus untuk menyimpan kata.';

  @override
  String get collectionSearchHint => 'Cari di koleksi';

  @override
  String get allLevels => 'Semua';

  @override
  String get removedFromCollection => 'Dihapus dari koleksi.';

  @override
  String get undo => 'Urungkan';

  @override
  String get remove => 'Hapus';

  @override
  String get noLevel => 'Tanpa level';

  @override
  String get addToStudy => 'Tambah ke belajar';

  @override
  String get inStudy => 'Sudah di belajar';

  @override
  String get showAnswer => 'Tampilkan jawaban';

  @override
  String get tapToFlip => 'Ketuk untuk balik';

  @override
  String get rateAgain => 'Lagi';

  @override
  String get rateHard => 'Sulit';

  @override
  String get rateGood => 'Baik';

  @override
  String get rateEasy => 'Mudah';

  @override
  String intervalMinutes(int n) {
    return '$n mnt';
  }

  @override
  String intervalHours(int n) {
    return '$n jam';
  }

  @override
  String intervalDays(int n) {
    return '$n hr';
  }

  @override
  String intervalMonths(int n) {
    return '$n bln';
  }

  @override
  String intervalYears(int n) {
    return '$n thn';
  }

  @override
  String reviewLeft(int count) {
    return '$count kartu lagi';
  }

  @override
  String reviewSummary(int count, int correct, int again, int minutes) {
    return '$count jawaban · $correct benar · $again Lagi · ±$minutes menit';
  }

  @override
  String get reviewEmpty =>
      'Tidak ada kartu untuk saat ini. Tambahkan kata dari Kamus (Tambah ke belajar) atau mulai dari kata N5.';

  @override
  String addN5Words(int count) {
    return 'Tambah $count kata N5';
  }

  @override
  String newLimitReached(int limit, int count) {
    return 'Batas $limit kartu baru hari ini sudah tercapai. $count kartu baru menunggu, besok muncul di sini.';
  }

  @override
  String get reviewButton => 'Review';

  @override
  String reviewDue(int count) {
    return '$count kartu siap direview';
  }

  @override
  String get almostThere => 'Hampir!';

  @override
  String passMarkNeeded(int percent) {
    return 'Butuh akurasi minimal $percent% untuk lulus. Coba sekali lagi!';
  }

  @override
  String passMarkHint(int percent) {
    return 'Lulus dengan akurasi ≥ $percent%';
  }

  @override
  String get dailyGoal => 'Target harian';

  @override
  String get goalCardsUnit => 'kartu';

  @override
  String get goalReached => 'Target harian tercapai';

  @override
  String goalLeft(int count) {
    return '$count kartu lagi untuk target hari ini';
  }

  @override
  String streakDays(int count) {
    return 'Streak $count hari';
  }

  @override
  String streakLongest(int count) {
    return 'Terpanjang $count hari';
  }

  @override
  String get streakKeep => 'Belajar hari ini agar streak berlanjut.';

  @override
  String get streakStart => 'Mulai hari ini, 1 sesi cukup.';

  @override
  String get statNew => 'Baru';

  @override
  String get statReviews => 'Review';

  @override
  String get statAccuracy => 'Akurasi';

  @override
  String get statTime => 'Waktu';

  @override
  String get activity => 'Aktivitas';

  @override
  String lastDays(int count) {
    return '$count hari';
  }

  @override
  String activityTotal(int cards, int xp) {
    return '$cards kartu · $xp XP';
  }

  @override
  String activityBar(String date, int cards) {
    return '$date: $cards kartu';
  }

  @override
  String get stampBook => 'Buku stempel';

  @override
  String stampDay(String date) {
    return '$date, belajar';
  }

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan berikutnya';

  @override
  String get jlptProgress => 'Progres JLPT';

  @override
  String wordsOf(int learned, int total) {
    return '$learned dari $total kata';
  }

  @override
  String get cardStages => 'Kartu';

  @override
  String get stageNew => 'Baru';

  @override
  String get stageLearning => 'Dipelajari';

  @override
  String get stageYoung => 'Muda';

  @override
  String get stageMature => 'Matang';

  @override
  String get hardestItems => 'Item tersulit';

  @override
  String lapsesCount(int count) {
    return 'Lupa $count×';
  }

  @override
  String get settings => 'Pengaturan';

  @override
  String get settingsLearning => 'Belajar';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String cardsCount(int count) {
    return '$count kartu';
  }

  @override
  String get newPerDay => 'Kartu baru per hari';

  @override
  String get newPerDayNote =>
      'Lebih banyak = lebih cepat maju, tapi review beberapa hari ke depan ikut bertambah.';

  @override
  String get reviewsPerDay => 'Batas review per hari';

  @override
  String get reviewsPerDayNote =>
      'Kartu yang melewati batas tetap menunggu dan muncul di sesi berikutnya.';

  @override
  String get dayStart => 'Hari baru dimulai';

  @override
  String get dayStartNote =>
      'Belajar sebelum jam ini masih dihitung untuk hari sebelumnya (streak & target).';

  @override
  String get language => 'Bahasa';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeLight => 'Terang';

  @override
  String get followSystem => 'Ikuti sistem';

  @override
  String get textSize => 'Ukuran teks';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Besar';

  @override
  String get textLarger => 'Lebih besar';

  @override
  String newLimitDone(int limit) {
    return 'Kamu sudah mempelajari $limit kartu baru hari ini. Lanjut besok!';
  }

  @override
  String get goalRelaxed => 'Santai';

  @override
  String get goalRegular => 'Rutin';

  @override
  String get goalSerious => 'Serius';

  @override
  String goalOption(int minutes, int cards, int fresh) {
    return '±$minutes menit sehari · $cards kartu · $fresh kata baru';
  }

  @override
  String totalXp(int xp) {
    return '$xp XP total';
  }

  @override
  String get aboutAttribution => 'Tentang & atribusi';

  @override
  String get dataSources => 'Sumber data';

  @override
  String get openSourceLicenses => 'Lisensi open source';

  @override
  String datasetVersion(String version) {
    return 'Versi kamus $version';
  }

  @override
  String get recallJapanese => 'Apa bahasa Jepangnya?';

  @override
  String get cardDirection => 'Arah kartu kata';

  @override
  String get directionJpToMeaning => 'Jepang → arti';

  @override
  String get directionMeaningToJp => 'Arti → Jepang';

  @override
  String get directionBoth => 'Dua arah (2 kartu per kata)';

  @override
  String get directionNote => 'Berlaku untuk kata yang ditambahkan berikutnya';

  @override
  String get trackVocab => 'Kata';

  @override
  String vocabLevel(int level) {
    return 'Kosakata N$level';
  }

  @override
  String nodeWords(int count, String words) {
    return '$count kata: $words';
  }

  @override
  String get newWords => 'Kata baru';

  @override
  String get askWord => 'Mana katanya?';

  @override
  String get exRecall => 'Ketik kata Jepangnya dalam romaji';

  @override
  String get exMatch => 'Pasangkan kata dengan artinya';

  @override
  String matchMistakes(int count) {
    return 'Salah pasang $count×';
  }

  @override
  String get settingsNotifications => 'Notifikasi';

  @override
  String get dailyReminder => 'Pengingat harian';

  @override
  String get reminderNote =>
      'Sekali sehari. Tidak muncul bila target hari ini sudah tercapai.';

  @override
  String get reminderTime => 'Jam pengingat';

  @override
  String get reminderDenied =>
      'Notifikasi belum diizinkan. Izinkan di pengaturan HP agar pengingat bisa muncul.';

  @override
  String get openSettings => 'Buka pengaturan';

  @override
  String get reminderChannel => 'Pengingat harian';

  @override
  String get reminderChannelNote => 'Pengingat belajar sekali sehari';

  @override
  String reminderCards(int count, int minutes) {
    return 'Ada $count kartu menunggu. Sekitar $minutes menit.';
  }

  @override
  String reminderStreak(int count) {
    return 'Streak $count hari menunggumu. Satu sesi singkat sudah cukup.';
  }

  @override
  String get reminderPlain =>
      'Saatnya belajar sebentar. Beberapa menit sudah cukup.';

  @override
  String get quickSearch => 'Cari di kamus';

  @override
  String appVersion(String version) {
    return 'Versi $version';
  }

  @override
  String contentVersion(String version) {
    return 'konten $version';
  }

  @override
  String schemaVersion(int version) {
    return 'skema data $version';
  }

  @override
  String onboardingStep(int step, int total) {
    return 'Langkah $step dari $total';
  }

  @override
  String get levelQuestion => 'Kamu di level mana?';

  @override
  String get levelChangeLater => 'Bisa diubah kapan saja di Pengaturan.';

  @override
  String get levelFromZero => 'Baru mulai dari nol';

  @override
  String get levelFromZeroBody => 'Belum bisa membaca hiragana dan katakana';

  @override
  String get levelBeginner => 'Pemula';

  @override
  String get levelBeginnerBody => 'Sudah kenal kana, tahu beberapa kata dasar';

  @override
  String get levelBasic => 'Dasar';

  @override
  String get levelBasicBody => 'Bisa kalimat sederhana dan kanji dasar';

  @override
  String get levelIntermediate => 'Menengah';

  @override
  String get levelIntermediateBody => 'Bisa percakapan sehari-hari';

  @override
  String get levelUpperIntermediate => 'Menengah atas';

  @override
  String get levelUpperIntermediateBody => 'Bisa membaca teks umum';

  @override
  String get levelAdvanced => 'Mahir';

  @override
  String get levelAdvancedBody => 'Menargetkan kefasihan atau ujian tertinggi';

  @override
  String get levelUnsure => 'Belum tahu';

  @override
  String get levelUnsureBody => 'Jawab 3 pertanyaan singkat';

  @override
  String get selfCheckHiragana => 'Bisa membaca hiragana?';

  @override
  String get selfCheckKatakana => 'Bisa membaca katakana?';

  @override
  String get selfCheckWords =>
      'Mengenal sekitar 100 kata dasar, seperti 食べる dan 学校?';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';

  @override
  String selfCheckResult(String level) {
    return 'Kami sarankan mulai dari $level. Kamu tetap bisa memilih yang lain di atas.';
  }

  @override
  String get goalQuestion => 'Berapa lama belajar setiap hari?';

  @override
  String get goalQuestionBody =>
      'Target dihitung dalam kartu; menitnya hanya perkiraan. Bisa diubah kapan saja.';

  @override
  String get reminderQuestion => 'Mau diingatkan setiap hari?';

  @override
  String get reminderQuestionBody =>
      'Satu pengingat sehari di jam pilihanmu. Tidak muncul bila target hari ini sudah tercapai.';

  @override
  String get remindMe => 'Ingatkan saya';

  @override
  String get skip => 'Lewati';

  @override
  String get learningLevel => 'Level belajar';

  @override
  String get learningLevelNote =>
      'Menentukan jalur di Hari ini. Progres yang sudah ada tidak hilang.';

  @override
  String get levelNotChosen => 'Belum dipilih';

  @override
  String get dailyGoalNote =>
      'Kartu baru per hari ikut disesuaikan; bisa diubah sendiri di bawah.';

  @override
  String get freezeUsed =>
      'Kemarin terlewat; pembekuan streak menjaganya. Belajar hari ini agar berlanjut.';

  @override
  String freezesHeld(int count) {
    return '$count pembekuan tersimpan';
  }

  @override
  String freezeNext(int days) {
    return '$days hari lagi untuk pembekuan berikutnya';
  }

  @override
  String stampFrozen(String date) {
    return '$date, dijaga pembekuan streak';
  }

  @override
  String get signInTitle => 'Masuk ke akunmu';

  @override
  String get signInNote =>
      'Setelah masuk, aplikasi tetap bisa dipakai tanpa internet.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Kata sandi';

  @override
  String get newPasswordLabel => 'Kata sandi baru';

  @override
  String passwordRule(int count) {
    return 'Minimal $count karakter';
  }

  @override
  String get showPassword => 'Tampilkan kata sandi';

  @override
  String get hidePassword => 'Sembunyikan kata sandi';

  @override
  String get signIn => 'Masuk';

  @override
  String get forgotPassword => 'Lupa kata sandi?';

  @override
  String get noAccountYet => 'Belum punya akun?';

  @override
  String get haveAccount => 'Sudah punya akun?';

  @override
  String get confirmEmailTitle => 'Cek emailmu';

  @override
  String get signUpTitle => 'Buat akun';

  @override
  String get signUpNote =>
      'Pakai email yang bisa kamu buka. Kami kirim kode untuk memastikan email itu milikmu.';

  @override
  String get signUp => 'Daftar';

  @override
  String get confirmSignUp => 'Konfirmasi dan masuk';

  @override
  String get forgotTitle => 'Atur ulang kata sandi';

  @override
  String get codeNote =>
      'Masukkan email akunmu. Kami kirim kode untuk membuat kata sandi baru.';

  @override
  String codeSent(String email) {
    return 'Kode dikirim ke $email. Cek juga folder spam.';
  }

  @override
  String get sendCode => 'Kirim kode';

  @override
  String get codeLabel => 'Kode dari email';

  @override
  String get savePassword => 'Simpan dan masuk';

  @override
  String get resendCode => 'Kirim ulang kode';

  @override
  String resendIn(int seconds) {
    return 'Kirim ulang dalam $seconds detik';
  }

  @override
  String get authWrongPassword => 'Email atau kata sandi salah.';

  @override
  String get authNotConfirmed =>
      'Email ini belum dikonfirmasi. Pilih \"Lupa kata sandi?\" untuk menerima kode.';

  @override
  String get authAlreadyRegistered =>
      'Email ini sudah terdaftar. Masuk, atau pilih \"Lupa kata sandi?\".';

  @override
  String get authSignUpClosed => 'Pendaftaran sedang ditutup. Coba lagi nanti.';

  @override
  String get authBadCode =>
      'Kode salah atau sudah kedaluwarsa. Minta kode baru.';

  @override
  String get authWeakPassword =>
      'Kata sandi terlalu lemah. Pakai yang lebih panjang, campur huruf dan angka.';

  @override
  String get authSamePassword =>
      'Kata sandi baru harus berbeda dari yang lama.';

  @override
  String get authTooMany =>
      'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';

  @override
  String get authOffline =>
      'Tidak ada koneksi internet. Masuk pertama kali butuh internet.';

  @override
  String get authUnknown => 'Gagal. Coba lagi sebentar lagi.';

  @override
  String get settingsAccount => 'Akun';

  @override
  String get signedInAs => 'Masuk sebagai';

  @override
  String get signOut => 'Keluar';

  @override
  String get signOutTitle => 'Keluar dari akun?';

  @override
  String get signOutBody =>
      'Progresmu tersimpan di akun dan dihapus dari HP ini. Masuk lagi kapan saja untuk memulihkannya.';

  @override
  String get signOutUnsyncedTitle => 'Ada perubahan yang belum tersimpan';

  @override
  String signOutUnsyncedBody(int count) {
    return '$count perubahan terakhir belum terkirim ke akun karena tidak ada koneksi. Bila keluar sekarang, perubahan itu hilang.';
  }

  @override
  String get signOutAnyway => 'Keluar saja';

  @override
  String get savingToAccount => 'Menyimpan progres ke akun…';

  @override
  String get restoringData => 'Memulihkan datamu…';

  @override
  String get syncLabel => 'Sinkronisasi';

  @override
  String get syncDone => 'Tersinkron';

  @override
  String syncDoneAt(String time) {
    return 'Tersinkron · $time';
  }

  @override
  String syncPending(int count) {
    return 'Menunggu sinkron · $count perubahan';
  }

  @override
  String get syncRunning => 'Menyinkronkan…';

  @override
  String get syncOffline => 'Offline · disinkronkan saat tersambung lagi';

  @override
  String get syncFailed => 'Gagal menyinkronkan · ketuk untuk mencoba lagi';

  @override
  String get syncNowHint => 'sinkronkan sekarang';

  @override
  String get deleteAccount => 'Hapus akun';

  @override
  String get deleteAccountTitle => 'Hapus akun dan semua progresmu?';

  @override
  String get deleteAccountProgress =>
      'Kartu, riwayat review, pelajaran, simpanan, statistik, dan streak dihapus dari akunmu.';

  @override
  String get deleteAccountDevices =>
      'HP lain yang memakai akun ini akan otomatis keluar.';

  @override
  String get deleteAccountSignIn =>
      'Akun ini tidak bisa dipulihkan. Email yang sama bisa didaftarkan lagi sebagai akun baru yang kosong.';

  @override
  String get deleteAccountUndo => 'Tidak bisa dibatalkan atau dipulihkan.';

  @override
  String get deleteAccountKeyword => 'HAPUS';

  @override
  String deleteAccountType(String keyword) {
    return 'Ketik $keyword untuk konfirmasi';
  }

  @override
  String get deleteAccountButton => 'Hapus akun selamanya';

  @override
  String get deleteAccountOffline =>
      'Butuh internet untuk menghapus akun. Coba lagi saat tersambung.';

  @override
  String get deleteAccountFailed =>
      'Akun belum terhapus. Coba lagi sebentar lagi.';

  @override
  String kanjiLevel(int level) {
    return 'Kanji N$level';
  }

  @override
  String nodeDoneLabel(String title) {
    return '$title, selesai';
  }

  @override
  String nodeLockedLabel(String title) {
    return '$title, terkunci';
  }
}
