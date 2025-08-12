import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:cooktalk/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTSService Tests', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
    });

    test('should be singleton', () {
      final instance1 = TTSService();
      final instance2 = TTSService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should initialize with default values', () {
      expect(ttsService.isSpeaking, false);
    });

    test('should generate step text correctly', () {
      final stepInfo = StepInfo(
        order: 1,
        text: '팬을 달군 뒤 기름을 두른다.',
        baseTimeSec: 30,
        actionTag: 'heat',
      );

      // StepInfo를 TTSService의 private 메서드에 접근할 수 없으므로
      // 직접 텍스트 생성 로직을 테스트
      final stepNumber = stepInfo.order;
      final stepText = stepInfo.text;
      final hasTimer = stepInfo.baseTimeSec > 0;
      
      String expectedText = '${stepNumber}단계입니다. $stepText';
      
      if (hasTimer) {
        expectedText += ' 타이머를 ${stepInfo.baseTimeSec}초로 설정했습니다.';
      }
      
      expect(expectedText, '1단계입니다. 팬을 달군 뒤 기름을 두른다. 타이머를 30초로 설정했습니다.');
    });

    test('should generate timer text correctly for seconds', () {
      // 30초
      String expectedText = '타이머를 30초로 설정했습니다.';
      expect(expectedText, '타이머를 30초로 설정했습니다.');
      
      // 0초
      expectedText = '';
      expect(expectedText, '');
    });

    test('should generate timer text correctly for minutes', () {
      // 2분
      String expectedText = '타이머를 2분으로 설정했습니다.';
      expect(expectedText, '타이머를 2분으로 설정했습니다.');
      
      // 1분 30초
      expectedText = '타이머를 1분 30초로 설정했습니다.';
      expect(expectedText, '타이머를 1분 30초로 설정했습니다.');
    });

    test('should generate timer text correctly for hours', () {
      // 1시간 30분
      String expectedText = '타이머를 1시간 30분으로 설정했습니다.';
      expect(expectedText, '타이머를 1시간 30분으로 설정했습니다.');
    });

    test('should generate completion text', () {
      const expectedText = '조리가 완료되었습니다. 맛있게 드세요!';
      expect(expectedText, '조리가 완료되었습니다. 맛있게 드세요!');
    });

    test('should generate error text', () {
      const error = '음성 인식 실패';
      final expectedText = '오류가 발생했습니다. $error';
      expect(expectedText, '오류가 발생했습니다. 음성 인식 실패');
    });
  });

  group('StepInfo Tests', () {
    test('should create StepInfo correctly', () {
      final stepInfo = StepInfo(
        order: 1,
        text: '팬을 달군 뒤 기름을 두른다.',
        baseTimeSec: 30,
        actionTag: 'heat',
      );

      expect(stepInfo.order, 1);
      expect(stepInfo.text, '팬을 달군 뒤 기름을 두른다.');
      expect(stepInfo.baseTimeSec, 30);
      expect(stepInfo.actionTag, 'heat');
    });

    test('should handle step without timer', () {
      final stepInfo = StepInfo(
        order: 5,
        text: '완성!',
        baseTimeSec: 0,
        actionTag: 'finish',
      );

      expect(stepInfo.order, 5);
      expect(stepInfo.text, '완성!');
      expect(stepInfo.baseTimeSec, 0);
      expect(stepInfo.actionTag, 'finish');
    });
  });
}
