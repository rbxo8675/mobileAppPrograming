import 'package:cooktalk/providers/session_provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Timer test', () {
    fakeAsync((async) {
      final sessionProvider = SessionProvider();
      sessionProvider.startTimer(5);
      expect(sessionProvider.isTimerRunning, true);
      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(sessionProvider.isTimerRunning, false);
      sessionProvider.dispose();
    });
  });
}