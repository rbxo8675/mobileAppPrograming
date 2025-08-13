import 'package:cooktalk/models/recipe.dart';
import 'package:cooktalk/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionProvider sessionProvider;
  late Recipe recipe;

  setUp(() {
    sessionProvider = SessionProvider();
    recipe = const Recipe(
      id: 'r1',
      title: 'Test Recipe',
      servingsBase: 2,
      ingredients: [],
      steps: [
        RecipeStep(order: 1, text: 'Step 1', baseTimeSec: 10, actionTag: 'tag1'),
        RecipeStep(order: 2, text: 'Step 2', baseTimeSec: 20, actionTag: 'tag2'),
      ],
    );
    sessionProvider.setRecipe(recipe);
  });

  tearDown(() {
    sessionProvider.dispose();
  });

  test('Initial values are correct', () {
    expect(sessionProvider.recipe, recipe);
    expect(sessionProvider.currentStepIndex, 0);
    expect(sessionProvider.currentStep, recipe.steps[0]);
    expect(sessionProvider.isTimerRunning, false);
    expect(sessionProvider.currentTimerSec, 0);
  });

  test('nextStep moves to the next step and resets timer', () {
    sessionProvider.startTimer(5);
    sessionProvider.nextStep();

    expect(sessionProvider.currentStepIndex, 1);
    expect(sessionProvider.currentStep, recipe.steps[1]);
    expect(sessionProvider.isTimerRunning, false);
    expect(sessionProvider.currentTimerSec, 0);
  });

  test('prevStep moves to the previous step and resets timer', () {
    sessionProvider.nextStep();
    sessionProvider.startTimer(5);
    sessionProvider.prevStep();

    expect(sessionProvider.currentStepIndex, 0);
    expect(sessionProvider.currentStep, recipe.steps[0]);
    expect(sessionProvider.isTimerRunning, false);
    expect(sessionProvider.currentTimerSec, 0);
  });

  testWidgets('startTimer starts the timer and stops when it reaches 0', (tester) async {
    sessionProvider.startTimer(1);

    expect(sessionProvider.isTimerRunning, true);
    expect(sessionProvider.currentTimerSec, 1);

    await tester.pump(const Duration(seconds: 1));

    expect(sessionProvider.currentTimerSec, 0);
    await tester.pumpAndSettle();
    expect(sessionProvider.isTimerRunning, false);
  });

  testWidgets('pauseTimer pauses the timer', (tester) async {
    sessionProvider.startTimer(5);
    await tester.pump(const Duration(seconds: 1));
    sessionProvider.pauseTimer();

    expect(sessionProvider.isTimerRunning, false);
    expect(sessionProvider.currentTimerSec, 4);

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(sessionProvider.currentTimerSec, 4); // Timer should not have changed
  });

  testWidgets('resumeTimer resumes the timer', (tester) async {
    sessionProvider.startTimer(5);
    await tester.pump(const Duration(seconds: 1));
    sessionProvider.pauseTimer();

    expect(sessionProvider.isTimerRunning, false);
    expect(sessionProvider.currentTimerSec, 4);

    sessionProvider.resumeTimer();
    await tester.pump();

    expect(sessionProvider.isTimerRunning, true);
    expect(sessionProvider.currentTimerSec, 4);

    await tester.pump(const Duration(seconds: 1));
    expect(sessionProvider.currentTimerSec, 3);
  });
}
