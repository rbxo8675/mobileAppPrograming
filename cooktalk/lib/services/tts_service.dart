import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// TTS 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 한국어 설정
      await _flutterTts.setLanguage("ko-KR");
      await _flutterTts.setSpeechRate(0.5); // 말하기 속도 (0.1 ~ 1.0)
      await _flutterTts.setVolume(1.0); // 볼륨 (0.0 ~ 1.0)
      await _flutterTts.setPitch(1.0); // 음조 (0.5 ~ 2.0)

      // 이벤트 리스너 설정
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        print('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      print('TTS 초기화 실패: $e');
    }
  }

  /// 텍스트를 음성으로 읽기
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isSpeaking) {
      await stop();
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS speak 실패: $e');
      _isSpeaking = false;
    }
  }

  /// 음성 정지
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('TTS stop 실패: $e');
    }
  }

  /// 단계 안내 음성 생성
  Future<void> speakStep(StepInfo stepInfo) async {
    final text = _generateStepText(stepInfo);
    await speak(text);
  }

  /// 타이머 안내 음성 생성
  Future<void> speakTimer(int seconds) async {
    final text = _generateTimerText(seconds);
    await speak(text);
  }

  /// 완료 안내 음성 생성
  Future<void> speakCompletion() async {
    const text = '조리가 완료되었습니다. 맛있게 드세요!';
    await speak(text);
  }

  /// 에러 안내 음성 생성
  Future<void> speakError(String error) async {
    final text = '오류가 발생했습니다. $error';
    await speak(text);
  }

  /// 단계 텍스트 생성
  String _generateStepText(StepInfo stepInfo) {
    final stepNumber = stepInfo.order;
    final stepText = stepInfo.text;
    final hasTimer = stepInfo.baseTimeSec > 0;
    
    String text = '${stepNumber}단계입니다. $stepText';
    
    if (hasTimer) {
      final timerText = _generateTimerText(stepInfo.baseTimeSec);
      text += ' $timerText';
    }
    
    return text;
  }

  /// 타이머 텍스트 생성
  String _generateTimerText(int seconds) {
    if (seconds <= 0) return '';
    
    if (seconds < 60) {
      return '타이머를 ${seconds}초로 설정했습니다.';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      
      if (remainingSeconds == 0) {
        return '타이머를 ${minutes}분으로 설정했습니다.';
      } else {
        return '타이머를 ${minutes}분 ${remainingSeconds}초로 설정했습니다.';
      }
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '타이머를 ${hours}시간 ${minutes}분으로 설정했습니다.';
    }
  }

  /// 리소스 정리
  void dispose() {
    _flutterTts.stop();
  }
}

/// 단계 정보를 담는 클래스
class StepInfo {
  final int order;
  final String text;
  final int baseTimeSec;
  final String actionTag;

  StepInfo({
    required this.order,
    required this.text,
    required this.baseTimeSec,
    required this.actionTag,
  });
}
