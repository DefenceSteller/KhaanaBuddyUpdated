import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();

  Future speak(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.2);
    await _tts.speak(text);
  }

  Future stop() async {
    await _tts.stop();
  }
}
