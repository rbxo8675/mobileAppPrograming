import 'package:flutter_tts/flutter_tts.dart';
import '../../core/utils/logger.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _state = TtsState.stopped;
  
  // 완료 콜백 함수
  Function()? _onCompletionCallback;
  
  TtsState get state => _state;
  bool get isPlaying => _state == TtsState.playing;
  bool get isStopped => _state == TtsState.stopped;

  Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage('ko-KR');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _state = TtsState.playing;
        Logger.info('TTS started');
      });

      _flutterTts.setCompletionHandler(() {
        _state = TtsState.stopped;
        Logger.info('TTS completed');
        // 완료 콜백 실행
        _onCompletionCallback?.call();
      });

      _flutterTts.setCancelHandler(() {
        _state = TtsState.stopped;
        Logger.info('TTS cancelled');
      });

      _flutterTts.setErrorHandler((msg) {
        _state = TtsState.stopped;
        Logger.error('TTS error: $msg');
      });

      _flutterTts.setPauseHandler(() {
        _state = TtsState.paused;
        Logger.info('TTS paused');
      });

      _flutterTts.setContinueHandler(() {
        _state = TtsState.continued;
        Logger.info('TTS continued');
      });

      Logger.info('TTS service initialized');
    } catch (e) {
      Logger.error('Failed to initialize TTS', e);
    }
  }

  Future<void> speak(String text, {Function()? onComplete}) async {
    try {
      if (text.isEmpty) return;
      
      // 완료 콜백 설정
      _onCompletionCallback = onComplete;
      
      await stop();
      await _flutterTts.speak(text);
      Logger.info('Speaking: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
    } catch (e) {
      Logger.error('Failed to speak', e);
    }
  }
  
  /// 완료 콜백을 설정합니다
  void setOnCompletionCallback(Function()? callback) {
    _onCompletionCallback = callback;
  }
  
  /// 완료 콜백을 제거합니다
  void clearOnCompletionCallback() {
    _onCompletionCallback = null;
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      Logger.error('Failed to pause TTS', e);
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _state = TtsState.stopped;
    } catch (e) {
      Logger.error('Failed to stop TTS', e);
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      Logger.info('TTS speech rate set to $rate');
    } catch (e) {
      Logger.error('Failed to set speech rate', e);
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
      Logger.info('TTS volume set to $volume');
    } catch (e) {
      Logger.error('Failed to set volume', e);
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
      Logger.info('TTS pitch set to $pitch');
    } catch (e) {
      Logger.error('Failed to set pitch', e);
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}
