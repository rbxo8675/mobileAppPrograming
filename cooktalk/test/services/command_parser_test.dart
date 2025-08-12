import 'package:flutter_test/flutter_test.dart';
import 'package:cooktalk/services/command_parser.dart';

void main() {
  group('CommandParser Tests', () {
    late CommandParser parser;

    setUp(() {
      parser = CommandParser();
    });

    group('Next Step Commands', () {
      test('should parse "다음" as nextStep', () {
        final result = parser.parse('다음');
        expect(result.intent, VoiceIntent.nextStep);
        expect(result.durationSeconds, isNull);
      });

      test('should parse "다음 단계" as nextStep', () {
        final result = parser.parse('다음 단계');
        expect(result.intent, VoiceIntent.nextStep);
      });

      test('should parse "넘어가" as nextStep', () {
        final result = parser.parse('넘어가');
        expect(result.intent, VoiceIntent.nextStep);
      });

      test('should parse "진행" as nextStep', () {
        final result = parser.parse('진행');
        expect(result.intent, VoiceIntent.nextStep);
      });
    });

    group('Previous Step Commands', () {
      test('should parse "이전" as prevStep', () {
        final result = parser.parse('이전');
        expect(result.intent, VoiceIntent.prevStep);
      });

      test('should parse "이전 단계" as prevStep', () {
        final result = parser.parse('이전 단계');
        expect(result.intent, VoiceIntent.prevStep);
      });

      test('should parse "뒤로" as prevStep', () {
        final result = parser.parse('뒤로');
        expect(result.intent, VoiceIntent.prevStep);
      });

      test('should parse "전 단계" as prevStep', () {
        final result = parser.parse('전 단계');
        expect(result.intent, VoiceIntent.prevStep);
      });
    });

    group('Repeat Commands', () {
      test('should parse "다시" as repeatStep', () {
        final result = parser.parse('다시');
        expect(result.intent, VoiceIntent.repeatStep);
      });

      test('should parse "다시 말해줘" as repeatStep', () {
        final result = parser.parse('다시 말해줘');
        expect(result.intent, VoiceIntent.repeatStep);
      });

      test('should parse "반복" as repeatStep', () {
        final result = parser.parse('반복');
        expect(result.intent, VoiceIntent.repeatStep);
      });

      test('should parse "한번 더" as repeatStep', () {
        final result = parser.parse('한번 더');
        expect(result.intent, VoiceIntent.repeatStep);
      });
    });

    group('Timer Commands', () {
      test('should parse "타이머 3분" as startTimer with 180 seconds', () {
        final result = parser.parse('타이머 3분');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 180);
      });

      test('should parse "타이머 1분 30초" as startTimer with 90 seconds', () {
        final result = parser.parse('타이머 1분 30초');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 90);
      });

      test('should parse "타이머 30초" as startTimer with 30 seconds', () {
        final result = parser.parse('타이머 30초');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 30);
      });

      test('should parse "타이머" as startTimer with default 180 seconds', () {
        final result = parser.parse('타이머');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 180);
      });

      test('should parse "타이머 2분 15초" as startTimer with 135 seconds', () {
        final result = parser.parse('타이머 2분 15초');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 135);
      });

      test('should parse "타이머 1시간 30분" as startTimer with 5400 seconds', () {
        final result = parser.parse('타이머 1시간 30분');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 5400);
      });
    });

    group('Pause Commands', () {
      test('should parse "일시정지" as pauseTimer', () {
        final result = parser.parse('일시정지');
        expect(result.intent, VoiceIntent.pauseTimer);
      });

      test('should parse "멈춰" as pauseTimer', () {
        final result = parser.parse('멈춰');
        expect(result.intent, VoiceIntent.pauseTimer);
      });

      test('should parse "정지" as pauseTimer', () {
        final result = parser.parse('정지');
        expect(result.intent, VoiceIntent.pauseTimer);
      });

      test('should parse "멈춰줘" as pauseTimer', () {
        final result = parser.parse('멈춰줘');
        expect(result.intent, VoiceIntent.pauseTimer);
      });
    });

    group('Resume Commands', () {
      test('should parse "재개" as resumeTimer', () {
        final result = parser.parse('재개');
        expect(result.intent, VoiceIntent.resumeTimer);
      });

      test('should parse "다시 시작" as resumeTimer', () {
        final result = parser.parse('다시 시작');
        expect(result.intent, VoiceIntent.resumeTimer);
      });

      test('should parse "재개해" as resumeTimer', () {
        final result = parser.parse('재개해');
        expect(result.intent, VoiceIntent.resumeTimer);
      });
    });

    group('Unknown Commands', () {
      test('should parse unknown text as unknown intent', () {
        final result = parser.parse('안녕하세요');
        expect(result.intent, VoiceIntent.unknown);
      });

      test('should parse empty text as unknown intent', () {
        final result = parser.parse('');
        expect(result.intent, VoiceIntent.unknown);
      });

      test('should parse mixed text as unknown intent', () {
        final result = parser.parse('오늘 날씨가 좋네요');
        expect(result.intent, VoiceIntent.unknown);
      });
    });

    group('Text Normalization', () {
      test('should handle uppercase text', () {
        final result = parser.parse('다음');
        expect(result.intent, VoiceIntent.nextStep);
      });

      test('should handle extra spaces', () {
        final result = parser.parse('  다음  ');
        expect(result.intent, VoiceIntent.nextStep);
      });

      test('should handle multiple spaces', () {
        final result = parser.parse('다음    단계');
        expect(result.intent, VoiceIntent.nextStep);
      });
    });

    group('Intent to Korean', () {
      test('should convert nextStep to Korean', () {
        expect(parser.intentToKorean(VoiceIntent.nextStep), '다음 단계');
      });

      test('should convert prevStep to Korean', () {
        expect(parser.intentToKorean(VoiceIntent.prevStep), '이전 단계');
      });

      test('should convert repeatStep to Korean', () {
        expect(parser.intentToKorean(VoiceIntent.repeatStep), '단계 반복');
      });

      test('should convert startTimer to Korean', () {
        expect(parser.intentToKorean(VoiceIntent.startTimer), '타이머 시작');
      });

      test('should convert pauseTimer to Korean', () {
        expect(parser.intentToKorean(VoiceIntent.pauseTimer), '타이머 일시정지');
      });

      test('should convert resumeTimer to Korean', () {
        expect(parser.intentToKorean(VoiceIntent.resumeTimer), '타이머 재개');
      });

      test('should convert unknown to Korean', () {
        expect(parser.intentToKorean(VoiceIntent.unknown), '알 수 없는 명령');
      });
    });

    group('Supported Commands', () {
      test('should return list of supported commands', () {
        final commands = parser.supportedCommands;
        expect(commands, isA<List<String>>());
        expect(commands.length, greaterThan(0));
        expect(commands, contains('다음'));
        expect(commands, contains('타이머 3분'));
      });
    });

    group('Edge Cases', () {
      test('should handle timer with only minutes', () {
        final result = parser.parse('타이머 5분');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 300);
      });

      test('should handle timer with only seconds', () {
        final result = parser.parse('타이머 45초');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 45);
      });

      test('should handle timer with zero duration', () {
        final result = parser.parse('타이머 0분');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 0);
      });

      test('should handle mixed case in timer command', () {
        final result = parser.parse('타이머 2분 30초');
        expect(result.intent, VoiceIntent.startTimer);
        expect(result.durationSeconds, 150);
      });
    });
  });
}
