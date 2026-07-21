import 'package:flutter/material.dart';
import '../services/app_controller.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import 'sacred_interruption_screen.dart';
import '../services/tts_service.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    String userMessage = _controller.text.trim();
_controller.clear();


    setState(() {
      _messages.add({"role": "user", "text": userMessage});
      _isLoading = true;
    });

    _controller.clear();

    try {
      final result = await ApiService.analyzeMessage(userMessage);

String emotion = result["emotion"];
String response = result["response"];

var scripture = result["scripture"];
String scriptureText = scripture["text"];
String scriptureRef = scripture["reference"];

AppController().updateEmotion(emotion);

if (mounted) {
  setState(() {
    _messages.add({"role": "lumine", "text": response});
    _messages.add({
      "role": "scripture",
      "text": "\"$scriptureText\"\n— $scriptureRef"
    });
    _isLoading = false;
  });

  TtsService.speak("$response. $scriptureText. $scriptureRef.");
  
  // Sacred Interruption Trigger
  final controller = AppController();
  if (controller.anxiety >= 0.3 || controller.reactivity >= 0.3) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SacredInterruptionScreen(
            scriptureText: scriptureText,
            scriptureRef: scriptureRef,
          ),
        ),
      );
    });
  }
}
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({"role": "lumine", "text": "Connection error."});
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reflection"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.amberAccent.withOpacity(0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Builder(
  builder: (context) {
    if (msg["role"] == "scripture") {
      return Text(
        msg["text"] ?? "",
        style: const TextStyle(
          color: Colors.lightBlueAccent,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      );
    }

    return Text(
      isUser ? "You: ${msg['text']}" : "Lumíne: ${msg['text']}",
      style: TextStyle(
        color: isUser ? Colors.amberAccent : Colors.white70,
        fontSize: 15,
      ),
    );
  },
),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Lumíne is thinking...",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
             IconButton(
  icon: const Icon(Icons.mic, color: Colors.amberAccent),
  onPressed: () async {
    bool available = await _voiceService.init();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mic not available")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Listening... speak now")),
    );

    String finalText = "";
    bool alreadySent = false;
    bool acceptUpdates = true;

    _voiceService.startListening((text) {
      if (!mounted) return;
      if (!acceptUpdates) return;

      finalText = text;
      setState(() {
        _controller.text = text;
      });
    });

    _voiceService.onSilence(() async {
      if (alreadySent) return;
      alreadySent = true;
      acceptUpdates = false;

      await _voiceService.stopListening();
      if (!mounted) return;

      String captured = finalText.trim();
      if (captured.isEmpty) return;

      _controller.text = captured;
      _sendMessage();

      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _controller.clear();
        });
      });
    });
  },
),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Share what you're feeling...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.amberAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}