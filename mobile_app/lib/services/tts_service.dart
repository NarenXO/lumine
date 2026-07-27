import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static Function()? _onWordSpoken;
  static Function()? _onComplete;

  static Future<void> _init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setProgressHandler((text, start, end, word) {
      _onWordSpoken?.call();
    });

    _tts.setCompletionHandler(() {
      _onComplete?.call();
    });

    _initialized = true;
  }

  static Future<void> speak(String text) async {
    await _init();
    _onWordSpoken = null;
    await _tts.setSpeechRate(0.4);
    await _tts.speak(text);
  }

  static Future<void> speakSynced(String text, double rate) async {
    await _init();
    _onWordSpoken = null;
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  static Future<void> speakWithCallback(
    String text,
    double rate,
    Function() onComplete, {
    Function()? onWord,
  }) async {
    await _init();
    _onComplete = onComplete;
    _onWordSpoken = onWord;
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
    _onWordSpoken = null;
    _onComplete = null;
  }
}