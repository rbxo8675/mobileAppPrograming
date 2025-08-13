import 'dart:async';
import 'package:cooktalk/models/recipe.dart';
import 'package:flutter/foundation.dart';

class SessionProvider with ChangeNotifier {
  Recipe? _recipe;
  int _currentStepIndex = 0;
  StreamSubscription<void>? _timer;
  int _currentTimerSec = 0;
  
  bool _isSpeaking = false;
  bool _isListening = false;

  Recipe? get recipe => _recipe;
  int get currentStepIndex => _currentStepIndex;
  RecipeStep? get currentStep => _recipe?.steps[_currentStepIndex];
  int get currentTimerSec => _currentTimerSec;
  bool get isTimerRunning => _timer != null;
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
    _currentTimerSec = seconds;
    
    _timer = (tickStream ?? Stream.periodic(const Duration(seconds: 1))).listen((_) {
      if (_currentTimerSec > 0) {
        _currentTimerSec--;
      } else {
        _timer?.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pauseTimer() {
    if (isTimerRunning) {
      _timer?.pause();

      notifyListeners();
    }
  }

  void resumeTimer() {
    if (!isTimerRunning && _currentTimerSec > 0) {
      _timer?.resume();
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
    
    _currentTimerSec = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}