import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:cooktalk/providers/session_provider.dart';
import 'package:cooktalk/models/recipe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionProvider Tests', () {
    late SessionProvider provider;
    late Recipe testRecipe;

    setUp(() {
      provider = SessionProvider();
      testRecipe = Recipe(
        id: 'test',
        title: 'Test Recipe',
        servingsBase: 2,
        ingredients: [
          Ingredient(name: '재료1', qty: 1, unit: '개'),
          Ingredient(name: '재료2', qty: 2, unit: '개'),
        ],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 30, actionTag: 'heat'),
          RecipeStep(order: 2, text: 'Step 2', baseTimeSec: 60, actionTag: 'stir'),
          RecipeStep(order: 3, text: 'Step 3', baseTimeSec: 0, actionTag: 'finish'),
        ],
      );
    });

    test('should initialize with default values', () {
      expect(provider.currentRecipe, isNull);
      expect(provider.currentStepIndex, 0);
      expect(provider.currentTimerSec, 0);
      expect(provider.isTimerRunning, false);
      expect(provider.speaking, false);
      expect(provider.listening, false);
      expect(provider.servings, 2);
    });

    test('should start session correctly', () {
      provider.startSession(testRecipe);

      expect(provider.currentRecipe, equals(testRecipe));
      expect(provider.currentStepIndex, 0);
      expect(provider.servings, 2);
      expect(provider.currentStep, equals(testRecipe.steps[0]));
      expect(provider.totalSteps, 3);
      expect(provider.isFirstStep, true);
      expect(provider.isLastStep, false);
    });

    test('should start session with custom servings', () {
      provider.startSession(testRecipe, servings: 4);

      expect(provider.servings, 4);
    });

    test('should move to next step', () {
      provider.startSession(testRecipe);
      
      provider.nextStep();

      expect(provider.currentStepIndex, 1);
      expect(provider.currentStep, equals(testRecipe.steps[1]));
      expect(provider.isFirstStep, false);
      expect(provider.isLastStep, false);
    });

    test('should not move to next step when at last step', () {
      provider.startSession(testRecipe);
      provider.nextStep(); // step 1
      provider.nextStep(); // step 2 (last)
      
      provider.nextStep(); // should not move

      expect(provider.currentStepIndex, 2);
      expect(provider.isLastStep, true);
    });

    test('should move to previous step', () {
      provider.startSession(testRecipe);
      provider.nextStep(); // move to step 1
      
      provider.prevStep();

      expect(provider.currentStepIndex, 0);
      expect(provider.currentStep, equals(testRecipe.steps[0]));
      expect(provider.isFirstStep, true);
    });

    test('should not move to previous step when at first step', () {
      provider.startSession(testRecipe);
      
      provider.prevStep(); // should not move

      expect(provider.currentStepIndex, 0);
      expect(provider.isFirstStep, true);
    });

    test('should repeat step', () {
      provider.startSession(testRecipe);
      // 타이머가 있는 단계에서 테스트
      expect(provider.hasTimer, true);
      expect(provider.currentTimerSec, 30); // 첫 단계의 baseTimeSec
      
      provider.repeatStep();

      expect(provider.currentTimerSec, 30);
      expect(provider.isTimerRunning, false);
    });

    test('should start timer', () {
      provider.startTimer(120);

      expect(provider.currentTimerSec, 120);
      expect(provider.isTimerRunning, true);
    });

    test('should pause timer', () {
      provider.startTimer(120);
      provider.pauseTimer();

      expect(provider.isTimerRunning, false);
    });

    test('should resume timer', () {
      provider.startTimer(120);
      provider.pauseTimer();
      provider.resumeTimer();

      expect(provider.isTimerRunning, true);
    });

    test('should cancel timer', () {
      provider.startTimer(120);
      provider.cancelTimer();

      expect(provider.currentTimerSec, 0);
      expect(provider.isTimerRunning, false);
    });

    test('should set speaking state', () {
      provider.setSpeaking(true);
      expect(provider.speaking, true);

      provider.setSpeaking(false);
      expect(provider.speaking, false);
    });

    test('should set listening state', () {
      provider.setListening(true);
      expect(provider.listening, true);

      provider.setListening(false);
      expect(provider.listening, false);
    });

    test('should set servings', () {
      provider.setServings(4);
      expect(provider.servings, 4);

      provider.setServings(1);
      expect(provider.servings, 1);
    });

    test('should not set invalid servings', () {
      provider.setServings(0);
      expect(provider.servings, 2); // 기본값 유지

      provider.setServings(-1);
      expect(provider.servings, 2); // 기본값 유지
    });

    test('should format timer correctly', () {
      provider.startTimer(65); // 1분 5초
      expect(provider.formattedTimer, '1분 5초');

      provider.startTimer(30); // 30초
      expect(provider.formattedTimer, '30초');

      provider.startTimer(0);
      expect(provider.formattedTimer, '');
    });

    test('should calculate step progress correctly', () {
      provider.startSession(testRecipe);
      // 첫 단계: 30초 타이머
      expect(provider.stepProgress, 0.0); // 시작 시점

      provider.startTimer(15); // 15초 남음 (15초 경과)
      expect(provider.stepProgress, 0.5); // 15/30 = 0.5

      provider.startTimer(0); // 완료
      expect(provider.stepProgress, 1.0);
    });

    test('should calculate recipe progress correctly', () {
      provider.startSession(testRecipe);
      expect(provider.recipeProgress, 0.0); // 첫 단계

      provider.nextStep(); // 두 번째 단계
      expect(provider.recipeProgress, 0.5); // 1/2 = 0.5

      provider.nextStep(); // 마지막 단계
      expect(provider.recipeProgress, 1.0); // 2/2 = 1.0
    });

    test('should end session correctly', () {
      provider.startSession(testRecipe);
      provider.nextStep();
      provider.startTimer(60);

      provider.endSession();

      expect(provider.currentRecipe, isNull);
      expect(provider.currentStepIndex, 0);
      expect(provider.currentTimerSec, 0);
      expect(provider.isTimerRunning, false);
      expect(provider.speaking, false);
      expect(provider.listening, false);
    });

    test('should handle step with no timer', () {
      final recipeWithNoTimer = Recipe(
        id: 'no-timer',
        title: 'No Timer Recipe',
        servingsBase: 2,
        ingredients: [],
        steps: [
          RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 0, actionTag: 'finish'),
        ],
      );

      provider.startSession(recipeWithNoTimer);

      expect(provider.hasTimer, false);
      expect(provider.currentTimerSec, 0);
      expect(provider.isTimerRunning, false);
    });
  });
}
