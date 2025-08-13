import 'dart:async';

import 'package:cooktalk/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionProvider sessionProvider;
  late StreamController<void> timerController;

  setUp(() {
    sessionProvider = SessionProvider();
    timerController = StreamController<void>();
  });

  tearDown(() {
    sessionProvider.dispose();
    timerController.close();
  });

  testWidgets('Timer test', (tester) async {
    sessionProvider.startTimer(3, tickStream: timerController.stream);
    expect(sessionProvider.isTimerRunning, true);
    expect(sessionProvider.currentTimerSec, 3);

    timerController.add(null);
    await tester.pump();
    expect(sessionProvider.currentTimerSec, 2);

    timerController.add(null);
    await tester.pump();
    expect(sessionProvider.currentTimerSec, 1);

    timerController.add(null);
    await tester.pump();
    expect(sessionProvider.currentTimerSec, 0);
    expect(sessionProvider.isTimerRunning, false);
  });
}