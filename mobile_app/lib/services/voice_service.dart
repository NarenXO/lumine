import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  Function()? _onSilenceCallback;

  Future<bool> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> init() async {
    bool granted = await _requestMicPermission();
    if (!granted) return false;

    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onError: (error) => print('Voice Error: $error'),
      onStatus: (status) {
  print('Voice Status: $status');
  if (status == "done" || status == "notListening") {
    _isListening = false;
    if (_onSilenceCallback != null) {
      final cb = _onSilenceCallback;
      _onSilenceCallback = null; // fire only once
      cb!();
    }
  }
},
    );

    return _isInitialized;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) {
      bool ok = await init();
      if (!ok) return;
    }

    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }

    _isListening = true;

    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      pauseFor: const Duration(seconds: 2),
      listenFor: const Duration(seconds: 15),
    );
  }

  void onSilence(Function callback) {
    _onSilenceCallback = () => callback();
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  bool get isListening => _isListening;
}