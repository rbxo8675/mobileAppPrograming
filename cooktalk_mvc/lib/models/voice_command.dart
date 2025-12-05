enum VoiceCommandType {
  next,
  previous,
  startTimer,
  timerWithMinutes,
  stop,
  repeat,
  restart,
  question,
  unknown, // Represents an unclassifiable command
}

class VoiceCommand {
  final VoiceCommandType type;
  final dynamic data;

  VoiceCommand._(this.type, [this.data]);

  static VoiceCommand get next => VoiceCommand._(VoiceCommandType.next);
  static VoiceCommand get previous => VoiceCommand._(VoiceCommandType.previous);
  static VoiceCommand get startTimer => VoiceCommand._(VoiceCommandType.startTimer);
  static VoiceCommand timer(int minutes) =>
      VoiceCommand._(VoiceCommandType.timerWithMinutes, minutes);
  static VoiceCommand get stop => VoiceCommand._(VoiceCommandType.stop);
  static VoiceCommand get repeat => VoiceCommand._(VoiceCommandType.repeat);
  static VoiceCommand get restart => VoiceCommand._(VoiceCommandType.restart);
  static VoiceCommand question(String text) =>
      VoiceCommand._(VoiceCommandType.question, text);
  static VoiceCommand get unknown => VoiceCommand._(VoiceCommandType.unknown);
}
