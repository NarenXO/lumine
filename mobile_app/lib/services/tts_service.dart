import 'dart:convert';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TtsService {
  // ═══════════════════════════════════════════════════════════
  // ELEVENLABS CONFIG — paste your API key on the next line
  // ═══════════════════════════════════════════════════════════
  static const String _elevenLabsApiKey = 'sk_d5523d50f7f642d239bac8fff2457222c6559a1e3bba5b04';
  static const String _voiceId = 'EXAVITQu4vr4xnSDxMaL'; // Sarah/Bella — soft female
  static const bool _useElevenLabs = true;
  static const String _model = 'eleven_turbo_v2_5';

  // ═══════════════════════════════════════════════════════════
  // INTERNAL
  // ═══════════════════════════════════════════════════════════
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _initialized = false;
  static Function()? _onComplete;

  static Future<void> _initTts() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      _onComplete?.call();
    });
    _initialized = true;
  }

  // ═══════════════════════════════════════════════════════════
  // PUBLIC API — same signatures as before
  // ═══════════════════════════════════════════════════════════

  static Future<void> speak(String text) async {
    if (_useElevenLabs) {
      await _speakWithElevenLabs(text);
    } else {
      await _initTts();
      await _tts.setSpeechRate(0.4);
      await _tts.speak(text);
    }
  }

  static Future<void> speakSynced(String text, double rate) async {
    if (_useElevenLabs) {
      await _speakWithElevenLabs(text);
    } else {
      await _initTts();
      await _tts.setSpeechRate(rate);
      await _tts.speak(text);
    }
  }

  static Future<void> speakWithCallback(
    String text,
    double rate,
    Function() onComplete, {
    Function()? onWord,
  }) async {
    if (_useElevenLabs) {
      await _speakWithElevenLabs(text, onComplete: onComplete);
    } else {
      await _initTts();
      _onComplete = onComplete;
      await _tts.setSpeechRate(rate);
      await _tts.speak(text);
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _onComplete = null;
  }

  // ═══════════════════════════════════════════════════════════
  // ELEVENLABS CORE
  // ═══════════════════════════════════════════════════════════

  static Future<void> _speakWithElevenLabs(String text, {Function()? onComplete}) async {
    try {
      await _audioPlayer.stop();

      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': _elevenLabsApiKey,
          'Accept': 'audio/mpeg',
        },
        body: jsonEncode({
          'text': text,
          'model_id': _model,
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
            'style': 0.15,
            'use_speaker_boost': true,
          },
        }),
      );

      if (response.statusCode != 200) {
        print('ElevenLabs error ${response.statusCode}: ${response.body}');
        await _initTts();
        await _tts.speak(text);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filename = 'lumine_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);

      await _audioPlayer.play(DeviceFileSource(file.path));

      if (onComplete != null) {
        _audioPlayer.onPlayerComplete.first.then((_) => onComplete());
      }
    } catch (e) {
      print('ElevenLabs exception: $e');
      try {
        await _initTts();
        await _tts.speak(text);
      } catch (_) {}
    }
  }
}