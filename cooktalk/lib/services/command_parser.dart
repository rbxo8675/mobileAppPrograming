import 'dart:core';

/// 음성 명령 Intent
enum VoiceIntent {
  nextStep,
  prevStep,
  repeatStep,
  startTimer,
  pauseTimer,
  resumeTimer,
  unknown,
}

/// 파싱된 명령 결과
class ParsedCommand {
  final VoiceIntent intent;
  final int? durationSeconds;
  final String originalText;

  ParsedCommand({
    required this.intent,
    this.durationSeconds,
    required this.originalText,
  });

  @override
  String toString() {
    return 'ParsedCommand(intent: $intent, durationSeconds: $durationSeconds, originalText: "$originalText")';
  }
}

/// 규칙 기반 음성 명령 파서
class CommandParser {
  static final CommandParser _instance = CommandParser._internal();
  factory CommandParser() => _instance;
  CommandParser._internal();

  // 다음 단계 키워드
  static const List<String> _nextKeywords = [
    '다음', '넘겨', '다음 단계', '다음단계', '다음으로', '다음 단계로',
    '넘어가', '진행', '계속', '다음 단계로 가', '다음단계로 가',
  ];

  // 이전 단계 키워드
  static const List<String> _prevKeywords = [
    '이전', '뒤로', '전 단계', '전단계', '이전 단계', '이전단계',
    '뒤로 가', '이전으로', '이전 단계로', '이전단계로',
  ];

  // 반복 키워드
  static const List<String> _repeatKeywords = [
    '다시', '한번 더', '다시 말해줘', '다시 말해', '반복', '다시 해',
    '다시 말해줘', '다시 말해줘요', '다시 말해요',
  ];

  // 타이머 시작 키워드
  static const List<String> _timerKeywords = [
    '타이머', '타이머 설정', '타이머 시작', '타이머로', '타이머를',
  ];

  // 일시정지 키워드
  static const List<String> _pauseKeywords = [
    '멈춰', '일시정지', '정지', '멈춰줘', '일시정지해', '정지해',
    '멈춰요', '일시정지해요', '정지해요',
  ];

  // 재개 키워드
  static const List<String> _resumeKeywords = [
    '재개', '다시 시작', '재개해', '다시 시작해',
    '재개해요', '다시 시작해요',
  ];

  /// 음성 텍스트를 파싱하여 명령으로 변환
  ParsedCommand parse(String text) {
    final normalizedText = _normalizeText(text);
    
    // 재개 확인 (다음 단계보다 우선)
    if (_containsAny(normalizedText, _resumeKeywords)) {
      return ParsedCommand(
        intent: VoiceIntent.resumeTimer,
        originalText: text,
      );
    }

    // 다음 단계 확인
    if (_containsAny(normalizedText, _nextKeywords)) {
      return ParsedCommand(
        intent: VoiceIntent.nextStep,
        originalText: text,
      );
    }

    // 이전 단계 확인
    if (_containsAny(normalizedText, _prevKeywords)) {
      return ParsedCommand(
        intent: VoiceIntent.prevStep,
        originalText: text,
      );
    }

    // 반복 확인
    if (_containsAny(normalizedText, _repeatKeywords)) {
      return ParsedCommand(
        intent: VoiceIntent.repeatStep,
        originalText: text,
      );
    }

    // 타이머 시작 확인
    if (_containsAny(normalizedText, _timerKeywords)) {
      final duration = _extractDuration(normalizedText);
      return ParsedCommand(
        intent: VoiceIntent.startTimer,
        durationSeconds: duration,
        originalText: text,
      );
    }

    // 일시정지 확인
    if (_containsAny(normalizedText, _pauseKeywords)) {
      return ParsedCommand(
        intent: VoiceIntent.pauseTimer,
        originalText: text,
      );
    }

    // 인식할 수 없는 명령
    return ParsedCommand(
      intent: VoiceIntent.unknown,
      originalText: text,
    );
  }

  /// 텍스트 정규화 (소문자 변환, 공백 정리)
  String _normalizeText(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 텍스트에 키워드가 포함되어 있는지 확인
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// 텍스트에서 시간 정보 추출
  int? _extractDuration(String text) {
    // 시간 추출: "1시간", "1시간 30분"
    final hourPattern = RegExp(r'(\d+)\s*시간');
    final hourMatch = hourPattern.firstMatch(text);
    
    // 분 추출: "3분", "1분 30초", "1분30초"
    final minutePattern = RegExp(r'(\d+)\s*분');
    final minuteMatch = minutePattern.firstMatch(text);
    
    // 초 추출: "30초", "1분 30초", "1분30초"
    final secondPattern = RegExp(r'(\d+)\s*초');
    final secondMatch = secondPattern.firstMatch(text);
    
    int totalSeconds = 0;
    
    if (hourMatch != null) {
      final hours = int.tryParse(hourMatch.group(1) ?? '0') ?? 0;
      totalSeconds += hours * 3600;
    }
    
    if (minuteMatch != null) {
      final minutes = int.tryParse(minuteMatch.group(1) ?? '0') ?? 0;
      totalSeconds += minutes * 60;
    }
    
    if (secondMatch != null) {
      final seconds = int.tryParse(secondMatch.group(1) ?? '0') ?? 0;
      totalSeconds += seconds;
    }
    
    // 시간이 추출되지 않았지만 타이머 키워드가 있으면 기본값 반환
    if (totalSeconds == 0 && _containsAny(text, _timerKeywords)) {
      // "타이머"만 말했을 때 기본값 (3분)
      if (text.contains('타이머') && !text.contains('분') && !text.contains('초') && !text.contains('시간')) {
        return 180; // 3분
      }
    }
    
    return totalSeconds >= 0 ? totalSeconds : null;
  }

  /// 지원하는 명령 예시 반환
  List<String> get supportedCommands {
    return [
      '다음',
      '이전',
      '다시',
      '타이머 3분',
      '타이머 1분 30초',
      '일시정지',
      '재개',
    ];
  }

  /// Intent를 한국어로 변환
  String intentToKorean(VoiceIntent intent) {
    switch (intent) {
      case VoiceIntent.nextStep:
        return '다음 단계';
      case VoiceIntent.prevStep:
        return '이전 단계';
      case VoiceIntent.repeatStep:
        return '단계 반복';
      case VoiceIntent.startTimer:
        return '타이머 시작';
      case VoiceIntent.pauseTimer:
        return '타이머 일시정지';
      case VoiceIntent.resumeTimer:
        return '타이머 재개';
      case VoiceIntent.unknown:
        return '알 수 없는 명령';
    }
  }
}
