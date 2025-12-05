import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';
import '../../models/voice_command.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        Logger.error('Microphone permission denied');
        return false;
      }
      
      _isInitialized = await _speech.initialize(
        onError: (error) => Logger.error('Speech error: ${error.errorMsg}'),
        onStatus: (status) => Logger.debug('Speech status: $status'),
      );
      
      if (_isInitialized) {
        Logger.info('Voice service initialized');
      }
      
      return _isInitialized;
    } catch (e) {
      Logger.error('Failed to initialize voice service', e);
      return false;
    }
  }
  
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'ko_KR',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          Logger.debug('Voice recognized: ${result.recognizedWords}');
        }
      },
      localeId: localeId,
      listenMode: ListenMode.confirmation,
    );
  }
  
  Future<void> stopListening() async {
    await _speech.stop();
  }
  
  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
  
  VoiceCommand parseCommand(String text) {
    final lowerText = text.toLowerCase().trim();
    
    if (lowerText.contains('다음') || lowerText.contains('넘어')) {
      return VoiceCommand.next;
    }
    if (lowerText.contains('이전') || lowerText.contains('뒤로')) {
      return VoiceCommand.previous;
    }
    if (lowerText.contains('타이머')) {
      final minutes = _extractMinutes(lowerText);
      if (minutes != null) {
        return VoiceCommand.timer(minutes);
      }
      return VoiceCommand.startTimer;
    }
    if (lowerText.contains('정지') || lowerText.contains('멈춰') || lowerText.contains('스톱')) {
      return VoiceCommand.stop;
    }
    if (lowerText.contains('다시') || lowerText.contains('반복')) {
      return VoiceCommand.repeat;
    }
    if (lowerText.contains('처음') || lowerText.contains('시작')) {
      return VoiceCommand.restart;
    }
    
    // If no keywords match, consider it a question for Gemini
    if (lowerText.isNotEmpty) {
      return VoiceCommand.question(text);
    }
    
    return VoiceCommand.unknown;
  }
  
  int? _extractMinutes(String text) {
    final patterns = [
      RegExp(r'(\d+)\s*분'),
      RegExp(r'(\d+)분'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }
}
