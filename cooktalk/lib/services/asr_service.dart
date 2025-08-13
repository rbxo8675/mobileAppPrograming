import 'package:speech_to_text/speech_to_text.dart';

class AsrService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;

  Future<void> initialize({Function(String)? onError}) async {
    _isAvailable = await _speechToText.initialize(onError: onError);
  }

  bool get isAvailable => _isAvailable;

  void startListening({required Function(String) onResult, Function? onListening}) {
    if (_isAvailable) {
      _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 5),
        cancelOnError: true,
      );
      onListening?.call();
    }
  }

  void stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
  }
}
