import 'voice_service.dart';
import '../../core/utils/logger.dart';

class VoiceInputService {
  final VoiceService _voiceService = VoiceService();
  bool _isRecording = false;
  
  bool get isRecording => _isRecording;

  Future<String> recordIngredients() async {
    try {
      Logger.info('Starting voice input for ingredients');
      _isRecording = true;
      
      final StringBuffer ingredients = StringBuffer();
      
      await _voiceService.startListening((text) {
        ingredients.write(text);
        ingredients.write('\n');
      });
      
      await Future.delayed(const Duration(seconds: 5));
      await _voiceService.stopListening();
      
      _isRecording = false;
      
      return ingredients.toString().trim();
    } catch (e) {
      Logger.error('Failed to record ingredients', e);
      _isRecording = false;
      rethrow;
    }
  }

  Future<String> recordStep() async {
    try {
      Logger.info('Starting voice input for step');
      _isRecording = true;
      
      final StringBuffer stepText = StringBuffer();
      
      await _voiceService.startListening((text) {
        stepText.write(text);
      });
      
      await Future.delayed(const Duration(seconds: 10));
      await _voiceService.stopListening();
      
      _isRecording = false;
      
      return stepText.toString().trim();
    } catch (e) {
      Logger.error('Failed to record step', e);
      _isRecording = false;
      rethrow;
    }
  }

  Future<List<String>> parseIngredientsFromVoice(String voiceText) async {
    final lines = voiceText.split('\n');
    final ingredients = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        ingredients.add(trimmed);
      }
    }
    
    return ingredients;
  }

  void stopRecording() {
    _voiceService.stopListening();
    _isRecording = false;
  }

  void dispose() {
    _voiceService.dispose();
  }
}
