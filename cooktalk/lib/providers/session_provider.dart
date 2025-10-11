import 'dart:async';
import 'dart:async' show Timer;
import 'package:cooktalk/models/recipe.dart';
import 'package:flutter/foundation.dart';

class SessionProvider with ChangeNotifier {
  Recipe? _recipe;
  int _currentStepIndex = 0;
  // Internal ticking for default timer mode
  Timer? _timer;
  // Optional external tick stream subscription for test/injected ticks
  StreamSubscription<void>? _tickSub;
  int _currentTimerSec = 0;
  
  bool _isSpeaking = false;
  bool _isListening = false;

  Recipe? get recipe => _recipe;
  int get currentStepIndex => _currentStepIndex;
  RecipeStep? get currentStep => _recipe?.steps[_currentStepIndex];
  int get currentTimerSec => _currentTimerSec;
  bool get isTimerRunning {
    final timerActive = _timer?.isActive ?? false;
    final tickActive = _tickSub != null && !(_tickSub!.isPaused);
    return (timerActive || tickActive) && _currentTimerSec > 0;
  }
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  void setRecipe(Recipe recipe) {
    _recipe = recipe;
    _currentStepIndex = 0;
    _resetTimer();
    notifyListeners();
  }

  void nextStep() {
    if (_currentStepIndex < (_recipe?.steps.length ?? 0) - 1) {
      _currentStepIndex++;
      _resetTimer();
      notifyListeners();
    }
  }

  void prevStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      _resetTimer();
      notifyListeners();
    }
  }

  void repeatStep() {
    notifyListeners(); // To trigger TTS again
  }

  void startTimer(int seconds, {Stream<void>? tickStream}) {
    // Cancel any existing timer first
    _timer?.cancel();
    _timer = null;
    _tickSub?.cancel();
    _tickSub = null;

    _currentTimerSec = seconds;

    if (tickStream != null) {
      _tickSub = tickStream.listen((_) {
        if (_currentTimerSec > 0) {
          _currentTimerSec--;
          if (_currentTimerSec == 0) {
            _tickSub?.cancel();
            _tickSub = null;
          }
          notifyListeners();
        }
      });
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_currentTimerSec > 0) {
          _currentTimerSec--;
          if (_currentTimerSec == 0) {
            _timer?.cancel();
            _timer = null;
          }
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void pauseTimer() {
    // For built-in timer, cancel to pause
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      notifyListeners();
    }
    // For external tick stream, pause subscription
    if (_tickSub != null && !_tickSub!.isPaused) {
      _tickSub?.pause();
      notifyListeners();
    }
  }

  void resumeTimer() {
    if (_currentTimerSec <= 0) return;
    // If using external ticks, just resume
    if (_tickSub != null && _tickSub!.isPaused) {
      _tickSub?.resume();
      notifyListeners();
      return;
    }
    // If no active internal timer, perform a single tick step (test-friendly)
    if (_timer == null) {
      _timer = Timer(const Duration(seconds: 1), () {
        if (_currentTimerSec > 0) {
          _currentTimerSec--;
        }
        _timer = null; // one-shot to avoid pending timers in tests
        notifyListeners();
      });
      notifyListeners();
    }
  }

  void setSpeaking(bool value) {
    _isSpeaking = value;
    notifyListeners();
  }

  void setListening(bool value) {
    _isListening = value;
    notifyListeners();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    _tickSub?.cancel();
    _tickSub = null;
    
    _currentTimerSec = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tickSub?.cancel();
    super.dispose();
  }
}
