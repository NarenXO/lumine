import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  Future<bool> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> init() async {
    bool granted = await _requestMicPermission();
    if (!granted) return false;

    return await _speech.initialize(
      onError: (error) => print('Voice Error: $error'),
      onStatus: (status) => print('Voice Status: $status'),
    );
  }

  Future<void> startListening(Function(String) onResult) async {
    if (_isListening) return;

    bool available = await init();
    if (!available) return;

    _isListening = true;
    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
  }

  bool get isListening => _isListening;
}