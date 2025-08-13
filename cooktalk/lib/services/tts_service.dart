import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  Function? _onComplete;

  TtsService() {
    _flutterTts.setCompletionHandler(() {
      _onComplete?.call();
    });
  }

  Future<void> speak(String text, {Function? onComplete}) async {
    _onComplete = onComplete;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}