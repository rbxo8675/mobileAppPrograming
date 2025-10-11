import 'package:flutter_tts/flutter_tts.dart';

class StepInfo {
  final int order;
  final String text;
  final int baseTimeSec;
  final String actionTag;

  const StepInfo({
    required this.order,
    required this.text,
    required this.baseTimeSec,
    required this.actionTag,
  });
}

class TTSService {
  static final TTSService _instance = TTSService._internal();
  bool isSpeaking = false;

  factory TTSService() {
    return _instance;
  }

  TTSService._internal();
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  Function? _onComplete;

  TtsService() {
    _flutterTts.setCompletionHandler(() {
      _onComplete?.call();
    });
    // Sensible defaults
    _flutterTts.setLanguage('ko-KR');
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text, {Function? onComplete}) async {
    _onComplete = onComplete;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }
}
