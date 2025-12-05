import '../../core/utils/logger.dart';

enum VoiceIntent {
  next,
  previous,
  repeat,
  restart,
  summary,
  startTimer,
  stopTimer,
  pauseTimer,
  resumeTimer,
  checkTimer,
  question,
  quietMode,
  slower,
  faster,
  stop,
  unknown,
}

class VoiceIntentResult {
  final VoiceIntent intent;
  final Map<String, dynamic> parameters;
  final String originalText;

  VoiceIntentResult({
    required this.intent,
    this.parameters = const {},
    required this.originalText,
  });
}

class VoiceIntentParser {
  static VoiceIntentResult parse(String text) {
    final normalized = text.toLowerCase().trim();
    Logger.debug('Parsing voice command: $normalized');

    if (_matchesNext(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.next,
        originalText: text,
      );
    }

    if (_matchesPrevious(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.previous,
        originalText: text,
      );
    }

    if (_matchesRepeat(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.repeat,
        originalText: text,
      );
    }

    if (_matchesRestart(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.restart,
        originalText: text,
      );
    }

    if (_matchesSummary(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.summary,
        originalText: text,
      );
    }

    final timerResult = _parseTimer(normalized);
    if (timerResult != null) {
      return VoiceIntentResult(
        intent: timerResult['intent'],
        parameters: timerResult,
        originalText: text,
      );
    }

    if (_matchesQuiet(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.quietMode,
        originalText: text,
      );
    }

    if (_matchesSlower(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.slower,
        originalText: text,
      );
    }

    if (_matchesFaster(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.faster,
        originalText: text,
      );
    }

    if (_matchesStop(normalized)) {
      return VoiceIntentResult(
        intent: VoiceIntent.stop,
        originalText: text,
      );
    }

    return VoiceIntentResult(
      intent: VoiceIntent.question,
      originalText: text,
    );
  }

  static bool _matchesNext(String text) {
    final patterns = ['다음', '넥스트', '다음 단계', '다음으로', '계속'];
    return patterns.any((p) => text.contains(p));
  }

  static bool _matchesPrevious(String text) {
    final patterns = ['이전', '전 단계', '뒤로', '돌아가'];
    return patterns.any((p) => text.contains(p));
  }

  static bool _matchesRepeat(String text) {
    final patterns = ['다시', '반복', '다시 한번', '다시 말해', '다시 설명'];
    return patterns.any((p) => text.contains(p));
  }

  static bool _matchesRestart(String text) {
    final patterns = ['처음부터', '처음으로', '시작부터'];
    return patterns.any((p) => text.contains(p));
  }

  static bool _matchesSummary(String text) {
    final patterns = ['현재 단계', '지금 단계', '어디까지', '요약'];
    return patterns.any((p) => text.contains(p));
  }

  static Map<String, dynamic>? _parseTimer(String text) {
    if (text.contains('타이머') || text.contains('알람')) {
      final minutesMatch = RegExp(r'(\d+)\s*분').firstMatch(text);
      final secondsMatch = RegExp(r'(\d+)\s*초').firstMatch(text);
      
      int totalSeconds = 0;
      if (minutesMatch != null) {
        totalSeconds += int.parse(minutesMatch.group(1)!) * 60;
      }
      if (secondsMatch != null) {
        totalSeconds += int.parse(secondsMatch.group(1)!);
      }

      if (text.contains('정지') || text.contains('중지') || text.contains('취소')) {
        return {'intent': VoiceIntent.stopTimer};
      }
      
      if (text.contains('일시정지') || text.contains('멈춰')) {
        return {'intent': VoiceIntent.pauseTimer};
      }
      
      if (text.contains('재개') || text.contains('다시 시작')) {
        return {'intent': VoiceIntent.resumeTimer};
      }
      
      if (text.contains('남은') || text.contains('확인')) {
        return {'intent': VoiceIntent.checkTimer};
      }

      if (totalSeconds > 0) {
        return {
          'intent': VoiceIntent.startTimer,
          'seconds': totalSeconds,
          'label': '타이머',
        };
      }
    }

    return null;
  }

  static bool _matchesQuiet(String text) {
    final patterns = ['조용히', '멈춰', '그만'];
    return patterns.any((p) => text.contains(p));
  }

  static bool _matchesSlower(String text) {
    final patterns = ['느리게', '천천히'];
    return patterns.any((p) => text.contains(p));
  }

  static bool _matchesFaster(String text) {
    final patterns = ['빠르게', '빨리'];
    return patterns.any((p) => text.contains(p));
  }

  static bool _matchesStop(String text) {
    final patterns = ['중지', '정지', '멈춰'];
    return patterns.any((p) => text == p);
  }
}
