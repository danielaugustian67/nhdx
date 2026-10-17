# Nihondx (nhdx)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/Database-SQLite%20%2B%20Drift-003B57)](https://drift.simonbinder.eu)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E)](https://supabase.com)
[![JLPT](https://img.shields.io/badge/JLPT-N5%20to%20N1-E74C3C)](#jalur-belajar-jlpt-n5---n1--pelajaran-harian)
[![License](https://img.shields.io/badge/License-Private-lightgrey)](#)

> **Nihondx** adalah aplikasi belajar bahasa Jepang dan kamus offline *all-in-one* yang cepat, komprehensif, dan modern — terinspirasi dari Nihondex. Dirancang untuk membantu pembelajar dari level pemula (nol) hingga persiapan JLPT N1 dengan pendekatan *offline-first* dan *spaced repetition system* (SRS).

---

## Fitur Utama

### 1. Kamus Cerdas & Cepat (Offline-First)
- **Pencarian Instan (< 100 ms)** tanpa koneksi internet menggunakan SQLite B-tree & FTS5 full-text search.
- **Konversi Romaji Otomatis:** Deteksi cerdas input huruf Latin langsung ke Hiragana/Katakana secara *real-time* (Hepburn & Kunrei).
- **Pencarian Dwiarah:** Mencari kata berdasarkan Kanji, Kana, Romaji, maupun arti dalam bahasa Inggris dan Indonesia.
- **Detail Kosakata Lengkap:** Informasi level JLPT, part of speech (POS), tag dialek/keigo, frekuensi kata, dan daftar contoh.

### 2. Modul Kana & Interaktif
- **Tabel Lengkap Hiragana & Katakana:** Termasuk Dakuten, Handakuten, dan Youon.
- **Stroke Order & Drawing:** Animasi urutan goresan berbasis vektor KanjiVG dengan kanvas interaktif dan algoritma penilaian akurasi goresan (*stroke scorer*).
- **Mini Games & Latihan:**
  - *Speed Drill* (Tes refleks cepat)
  - *Memory Match* (Game mencocokkan kartu)
  - *Writing Practice* (Latihan menulis langsung di layar)
  - *Kana Quiz* (Kuis pilihan ganda terarah)

### 3. Jalur Belajar JLPT (N5 - N1) & Pelajaran Harian
- Kurikulum terstruktur per level (JLPT N5 hingga N1).
- Pembelajaran harian bertahap dengan pengenalan kata baru dan contoh kalimat.
- Target harian (*daily goal*) yang disesuaikan dengan ritme belajar pengguna.

### 4. Sistem Spaced Repetition (SRS)
- Algoritma **SM-2** teroptimasi untuk retensi jangka panjang.
- Penjadwalan review otomatis berdasarkan kemudahan mengingat kartu.
- Batasan review harian agar proses belajar tetap konsisten tanpa beban berlebih (*burnout*).

### 5. Gamifikasi & Motivasi
- **Pelacak Streak & Aktivitas:** Pantau konsistensi belajar harian.
- **XP & Level Badges:** Raih level baru seiring bertambahnya kosakata yang dikuasai.
- **Hanko Stamps:** Cap virtual khas Jepang untuk merayakan pencapaian harian.
- **Statistik Mendalam:** Grafik retensi kartu, waktu belajar, dan akumulasi kata yang dihafal.

### 6. Cloud Sync & Multi-Device
- Didukung oleh **Supabase** (Auth, PostgreSQL, Row-Level Security, Edge Functions).
- Arsitektur sinkronisasi *offline-first* dengan resolusi konflik **Last-Write-Wins (LWW)** dan identifikasi deterministik UUIDv5.
- Data tersimpan lokal di SQLite dan otomatis tersinkronisasi saat terhubung ke internet.

---

## Tech Stack & Arsitektur

| Komponen | Teknologi |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart 3) |
| State Management | [Riverpod](https://riverpod.dev) (v3) |
| Routing | [GoRouter](https://pub.dev/packages/go_router) |
| Local Database | [SQLite3](https://pub.dev/packages/sqlite3) + [Drift](https://drift.simonbinder.eu) (FTS5 trigram + unicode61) |
| Backend / Sync | [Supabase](https://supabase.com) (PostgreSQL, Auth, RLS, Edge Functions) |
| Notifikasi | `flutter_local_notifications` + `timezone` |
| Internationalization | Flutter Localizations (Bahasa Indonesia & English) |
| Asset Pipeline | Python (Automated extraction & compression dari JMdict & KanjiVG) |

---

## Struktur Direktori

```text
nihondx/
├── android/                   # Konfigurasi native Android
├── ios/                       # Konfigurasi native iOS
├── assets/                    # Asset font dan database terkompresi (.gz)
├── data_pipeline/             # Skrip Python pemrosesan dataset JMdict/KanjiVG
│   ├── build_all.py           # Pipeline pembuatan database kamus
│   ├── parsers/               # Parser XML/JSON data sumber
│   └── output/                # Output SQLite terkompresi
├── env/                       # Konfigurasi environment (Supabase URL, Keys)
│   └── example.json           # Template konfigurasi env
├── lib/
│   ├── core/                  # Utilitas bersama, tema, widget umum, database lokal
│   │   ├── database/          # Drift database wrapper & migration
│   │   ├── text/              # Romaji-to-Kana converter & normalizer
│   │   ├── theme/             # Token desain, warna, tipografi
│   │   └── widgets/           # Reusable UI components
│   ├── features/              # Fitur modular (Feature-first architecture)
│   │   ├── auth/              # Otentikasi Supabase & session storage
│   │   ├── kana/              # Modul Kana, game, kanvas menulis
│   │   ├── learn/             # Jalur belajar JLPT N5-N1
│   │   ├── search/            # Pencarian kamus cepat & riwayat
│   │   ├── srs/               # Spaced Repetition System & review screen
│   │   ├── progress/          # Statistik pengguna, streak, profil
│   │   └── sync/              # Sinkronisasi dua arah offline-first
│   └── main.dart              # Entry point aplikasi Flutter
├── supabase/                  # Skrip migrasi PostgreSQL, RLS, & Edge Functions
└── test/                      # Unit test, golden test, widget test
```

---

## Memulai (Getting Started)

### Prasyarat
1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.13+ atau yang kompatibel)
2. [Git](https://git-scm.com/)
3. [Python 3.10+](https://www.python.org/) *(hanya jika ingin rebuild data kamus lokal)*
4. Android Studio / Xcode / VS Code dengan ekstensi Flutter & Dart

### Instalasi & Menjalankan Aplikasi

1. **Clone repositori:**
   ```bash
   git clone https://github.com/danielaugustian67/nhdx.git
   cd nhdx
   ```

2. **Pasang dependensi Flutter:**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Environment:**
   Salin berkas template environment:
   ```bash
   cp env/example.json env/prod.json
   ```
   Isi `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` (Dashboard → Project Settings → API Keys) sesuai project Supabase kamu.

4. **Jalankan Code Generator (Drift & Riverpod):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Jalankan Aplikasi:**
   ```bash
   flutter run --dart-define-from-file=env/prod.json
   ```

---

## Pengujian (Testing)

Proyek ini dilengkapi dengan unit test, widget test, dan golden test:

```bash
# Menjalankan seluruh unit & widget tests
flutter test

# Menjalankan test tertentu
flutter test test/core/text/romaji_to_kana_test.dart
flutter test test/features/srs/sm2_test.dart
```

---

## Sumber Data & Lisensi Konten

- **JMdict / Kanjidic2:** [Electronic Dictionary Research and Development Group (EDRDG)](http://www.edrdg.org/) di bawah lisensi Creative Commons Attribution-ShareAlike.
- **KanjiVG:** Data stroke order kanji dan kana oleh Ulrich Apel di bawah lisensi Creative Commons Attribution-Share Alike 3.0.
- **Tatoeba:** Contoh kalimat bahasa Jepang disediakan oleh komunitas [Tatoeba Project](https://tatoeba.org/) di bawah CC-BY 2.0 FR.
