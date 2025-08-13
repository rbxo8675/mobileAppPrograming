enum CommandIntent {
  nextStep,
  prevStep,
  repeatStep,
  startTimer,
  pauseTimer,
  resumeTimer,
  unknown,
}

class Command {
  final CommandIntent intent;
  final int? durationSec;

  Command(this.intent, {this.durationSec});
}

class CommandParser {
  Command parse(String text) {
    final normalizedText = text.toLowerCase().trim();

    if (_isMatch(normalizedText, ['다음', '넘겨', '다음 단계'])) {
      return Command(CommandIntent.nextStep);
    } else if (_isMatch(normalizedText, ['이전', '뒤로', '전 단계'])) {
      return Command(CommandIntent.prevStep);
    } else if (_isMatch(normalizedText, ['다시', '한번 더', '다시 말해줘'])) {
      return Command(CommandIntent.repeatStep);
    } else if (_isMatch(normalizedText, ['멈춰', '일시정지'])) {
      return Command(CommandIntent.pauseTimer);
    } else if (_isMatch(normalizedText, ['계속', '재개'])) {
      return Command(CommandIntent.resumeTimer);
    } else if (normalizedText.contains('타이머')) {
      final duration = _parseDuration(normalizedText);
      return Command(CommandIntent.startTimer, durationSec: duration);
    }

    return Command(CommandIntent.unknown);
  }

  bool _isMatch(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  int _parseDuration(String text) {
    final minMatch = RegExp(r'(\d+)\s*분').firstMatch(text);
    final secMatch = RegExp(r'(\d+)\s*초').firstMatch(text);

    int minutes = 0;
    int seconds = 0;

    if (minMatch != null) {
      minutes = int.tryParse(minMatch.group(1)!) ?? 0;
    }

    if (secMatch != null) {
      seconds = int.tryParse(secMatch.group(1)!) ?? 0;
    }

    return (minutes * 60) + seconds;
  }
}