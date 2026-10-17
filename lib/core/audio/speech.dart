import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../database/providers.dart';
import '../text/hangul.dart';

/// Reads Japanese or Korean aloud with the phone's own text-to-speech voice:
/// no audio files, and offline once the voice is installed.
abstract interface class Speech {
  /// Says [text] (Korean when it has Hangul); false when there is no voice
  /// for its language.
  Future<bool> speak(String text);

  Future<void> stop();
}

/// The voice language for [text].
String speechLanguageOf(String text) => hasHangul(text) ? 'ko-KR' : 'ja-JP';

class TtsSpeech implements Speech {
  FlutterTts? _tts;
  Future<bool>? _ready;
  final _available = <String, Future<bool>>{};
  String? _language;

  Future<bool> _init() async {
    try {
      final tts = _tts = FlutterTts();
      // A little slower than normal for learners (Android doubles the value,
      // iOS speaks normally at 0.5).
      await tts.setSpeechRate(defaultTargetPlatform == TargetPlatform.iOS ? 0.45 : 0.42);
      return true;
    } catch (e) {
      debugPrint('Speech: text-to-speech not available ($e)');
      return false;
    }
  }

  Future<bool> _isAvailable(String language) async {
    try {
      return await _tts!.isLanguageAvailable(language) == true;
    } catch (e) {
      debugPrint('Speech: $language not available ($e)');
      return false;
    }
  }

  @override
  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return true;
    if (!await (_ready ??= _init())) return false;
    final language = speechLanguageOf(text);
    // Browsers load their voices late, so an early check would wrongly say
    // there is none; the browser picks a voice for the language itself.
    if (!kIsWeb && !await _available.putIfAbsent(language, () => _isAvailable(language))) return false;
    try {
      await _tts!.stop();
      // On the web the voice is chosen anew each time, once voices are loaded.
      if (_language != language || kIsWeb) {
        await _tts!.setLanguage(language);
        _language = language;
      }
      await _tts!.speak(text);
      return true;
    } catch (e) {
      debugPrint('Speech: speak failed ($e)');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

final speechProvider = Provider<Speech>((ref) {
  final speech = TtsSpeech();
  ref.onDispose(speech.stop);
  return speech;
});

/// Whether a card or lesson item is read aloud when it appears (default on),
/// kept on this device.
const speechAutoplayKey = 'device.speech.autoplay';

final speechAutoplayProvider = StreamProvider<bool>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSetting(speechAutoplayKey).map((v) => v != 'off');
});

/// Says [text] if autoplay is on; silent when there is no Japanese voice.
Future<void> autoSpeak(WidgetRef ref, String text) async {
  final speech = ref.read(speechProvider);
  try {
    if (await ref.read(speechAutoplayProvider.future)) await speech.speak(text);
  } catch (e) {
    debugPrint('Speech: autoplay skipped ($e)');
  }
}
