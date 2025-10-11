import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class AsrService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;

  Future<void> initialize({
    void Function(SpeechRecognitionError)? onError,
    void Function(String)? onStatus,
  }) async {
    _isAvailable = await _speechToText.initialize(
      onError: onError,
      onStatus: onStatus,
    );
  }

  bool get isAvailable => _isAvailable;
  bool get isListening => _speechToText.isListening;

  Future<List<LocaleName>> getLocales() async {
    return await _speechToText.locales();
  }

  Future<String?> getSystemLocaleId() async {
    final locale = await _speechToText.systemLocale();
    return locale?.localeId;
  }

  void startListening({
    required Function(String) onResult,
    Function? onListening,
    String? localeId,
    bool partialResults = false,
    Duration listenFor = const Duration(seconds: 5),
  }) {
    if (_isAvailable) {
      _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: listenFor,
        partialResults: partialResults,
        cancelOnError: true,
        localeId: localeId,
      );
      onListening?.call();
    }
  }

  void stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
  }

  void cancelListening() {
    if (_speechToText.isListening) {
      _speechToText.cancel();
    }
  }
}
