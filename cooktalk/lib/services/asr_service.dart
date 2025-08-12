import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class ASRService {
  static final ASRService _instance = ASRService._internal();
  factory ASRService() => _instance;
  ASRService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  StreamController<String>? _resultController;

  bool get isListening => _isListening;
  bool get isAvailable => _speechToText.isAvailable;

  /// ASR 초기화
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 마이크 권한 요청
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('마이크 권한이 거부되었습니다.');
        return false;
      }

      // Speech to Text 초기화
      final available = await _speechToText.initialize(
        onError: (error) {
          print('ASR Error: ${error.errorMsg}');
          _isListening = false;
          _resultController?.addError(error.errorMsg);
        },
        onStatus: (status) {
          print('ASR Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      _isInitialized = available;
      return available;
    } catch (e) {
      print('ASR 초기화 실패: $e');
      return false;
    }
  }

  /// 음성 인식 시작
  Future<void> startListening({
    Duration timeout = const Duration(seconds: 5),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('ASR 초기화 실패');
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _resultController = StreamController<String>();
      _isListening = true;

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final text = result.recognizedWords.trim();
            if (text.isNotEmpty) {
              _resultController?.add(text);
            }
          }
        },
        listenFor: timeout,
        pauseFor: pauseFor,
        partialResults: false,
        localeId: 'ko_KR',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      _isListening = false;
      _resultController?.addError(e);
      print('ASR 시작 실패: $e');
    }
  }

  /// 음성 인식 정지
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      await _resultController?.close();
      _resultController = null;
    } catch (e) {
      print('ASR 정지 실패: $e');
    }
  }

  /// 음성 인식 결과 스트림
  Stream<String> get resultStream {
    if (_resultController == null) {
      _resultController = StreamController<String>();
    }
    return _resultController!.stream;
  }

  /// 현재 음성 인식 상태 확인 (alias)
  bool get available => _speechToText.isAvailable;

  /// 리소스 정리
  void dispose() {
    stopListening();
    _resultController?.close();
  }
}
