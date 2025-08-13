import 'package:cooktalk/services/command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CommandParser commandParser;

  setUp(() {
    commandParser = CommandParser();
  });

  group('CommandParser Tests', () {
    test('should parse "다음" as nextStep', () {
      final command = commandParser.parse('다음');
      expect(command.intent, CommandIntent.nextStep);
    });

    test('should parse "이전" as prevStep', () {
      final command = commandParser.parse('이전');
      expect(command.intent, CommandIntent.prevStep);
    });

    test('should parse "다시" as repeatStep', () {
      final command = commandParser.parse('다시');
      expect(command.intent, CommandIntent.repeatStep);
    });

    test('should parse "일시정지" as pauseTimer', () {
      final command = commandParser.parse('일시정지');
      expect(command.intent, CommandIntent.pauseTimer);
    });

    test('should parse "재개" as resumeTimer', () {
      final command = commandParser.parse('재개');
      expect(command.intent, CommandIntent.resumeTimer);
    });

    test('should parse "타이머 3분" as startTimer with 180 seconds', () {
      final command = commandParser.parse('타이머 3분');
      expect(command.intent, CommandIntent.startTimer);
      expect(command.durationSec, 180);
    });

    test('should parse "타이머 1분 30초" as startTimer with 90 seconds', () {
      final command = commandParser.parse('타이머 1분 30초');
      expect(command.intent, CommandIntent.startTimer);
      expect(command.durationSec, 90);
    });

    test('should parse unknown text as unknown intent', () {
      final command = commandParser.parse('안녕하세요');
      expect(command.intent, CommandIntent.unknown);
    });
  });
}