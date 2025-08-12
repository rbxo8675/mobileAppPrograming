import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cooktalk/models/recipe.dart';
import 'package:cooktalk/services/tts_service.dart';
import 'package:cooktalk/services/asr_service.dart';
import 'package:cooktalk/services/command_parser.dart';

class SessionProvider extends ChangeNotifier {
  Recipe? _currentRecipe;
  int _currentStepIndex = 0;
  int _currentTimerSec = 0;
  bool _isTimerRunning = false;
  bool _speaking = false;
  bool _listening = false;
  int _servings = 2;
  Timer? _timer;
  final TTSService _ttsService = TTSService();
  final ASRService _asrService = ASRService();
  final CommandParser _commandParser = CommandParser();
  StreamSubscription<String>? _asrSubscription;

  // Getters
  Recipe? get currentRecipe => _currentRecipe;
  int get currentStepIndex => _currentStepIndex;
  int get currentTimerSec => _currentTimerSec;
  bool get isTimerRunning => _isTimerRunning;
  bool get speaking => _speaking;
  bool get listening => _listening;
  int get servings => _servings;
  TTSService get ttsService => _ttsService;
  ASRService get asrService => _asrService;
  CommandParser get commandParser => _commandParser;
  
  RecipeStep? get currentStep {
    if (_currentRecipe == null || _currentStepIndex >= _currentRecipe!.steps.length) {
      return null;
    }
    return _currentRecipe!.steps[_currentStepIndex];
  }
  
  int get totalSteps => _currentRecipe?.steps.length ?? 0;
  bool get isFirstStep => _currentStepIndex == 0;
  bool get isLastStep => _currentStepIndex >= totalSteps - 1;
  bool get hasTimer => currentStep?.baseTimeSec != null && currentStep!.baseTimeSec > 0;

  /// 조리 세션을 시작합니다.
  Future<void> startSession(Recipe recipe, {int? servings}) async {
    _currentRecipe = recipe;
    _currentStepIndex = 0;
    _currentTimerSec = 0;
    _isTimerRunning = false;
    _speaking = false;
    _listening = false;
    _servings = servings ?? recipe.servingsBase;
    
    // 첫 번째 단계에 타이머가 있으면 자동 시작
    _startStepTimer();
    
    // 첫 번째 단계 안내 음성 재생
    await _speakCurrentStep();
    
    notifyListeners();
  }

  /// 세션을 종료합니다.
  void endSession() {
    _stopTimer();
    _currentRecipe = null;
    _currentStepIndex = 0;
    _currentTimerSec = 0;
    _isTimerRunning = false;
    _speaking = false;
    _listening = false;
    notifyListeners();
  }

  /// 다음 단계로 이동합니다.
  Future<void> nextStep() async {
    if (isLastStep) return;
    
    _stopTimer();
    _currentStepIndex++;
    _currentTimerSec = 0;
    _isTimerRunning = false;
    
    // 새 단계에 타이머가 있으면 자동 시작
    _startStepTimer();
    
    // 새 단계 안내 음성 재생
    await _speakCurrentStep();
    
    notifyListeners();
  }

  /// 이전 단계로 이동합니다.
  Future<void> prevStep() async {
    if (isFirstStep) return;
    
    _stopTimer();
    _currentStepIndex--;
    _currentTimerSec = 0;
    _isTimerRunning = false;
    
    // 새 단계에 타이머가 있으면 자동 시작
    _startStepTimer();
    
    // 새 단계 안내 음성 재생
    await _speakCurrentStep();
    
    notifyListeners();
  }

  /// 현재 단계를 반복합니다.
  Future<void> repeatStep() async {
    // 타이머가 있으면 리셋
    if (hasTimer) {
      _currentTimerSec = currentStep!.baseTimeSec;
      _isTimerRunning = false;
    }
    
    // 현재 단계 안내 음성 재생
    await _speakCurrentStep();
    
    notifyListeners();
  }

  /// 타이머를 시작합니다.
  void startTimer(int durationSec) {
    _currentTimerSec = durationSec;
    _isTimerRunning = true;
    _startTimer();
    notifyListeners();
  }

  /// 타이머를 일시정지합니다.
  void pauseTimer() {
    if (!_isTimerRunning) return;
    
    _isTimerRunning = false;
    _stopTimer();
    notifyListeners();
  }

  /// 타이머를 재개합니다.
  void resumeTimer() {
    if (_isTimerRunning || _currentTimerSec <= 0) return;
    
    _isTimerRunning = true;
    _startTimer();
    notifyListeners();
  }

  /// 타이머를 취소합니다.
  void cancelTimer() {
    _stopTimer();
    _currentTimerSec = 0;
    _isTimerRunning = false;
    notifyListeners();
  }

  /// TTS 상태를 설정합니다.
  void setSpeaking(bool speaking) {
    _speaking = speaking;
    notifyListeners();
  }

  /// 현재 단계를 음성으로 안내합니다.
  Future<void> _speakCurrentStep() async {
    if (currentStep == null) return;
    
    _speaking = true;
    notifyListeners();
    
    try {
      final stepInfo = StepInfo(
        order: currentStep!.order,
        text: currentStep!.text,
        baseTimeSec: currentStep!.baseTimeSec,
        actionTag: currentStep!.actionTag,
      );
      
      await _ttsService.speakStep(stepInfo);
    } catch (e) {
      print('TTS speak error: $e');
    } finally {
      _speaking = false;
      notifyListeners();
    }
  }

  /// 타이머 완료 시 음성 안내
  Future<void> _speakTimerComplete() async {
    _speaking = true;
    notifyListeners();
    
    try {
      await _ttsService.speak('타이머가 완료되었습니다.');
    } catch (e) {
      print('TTS timer complete error: $e');
    } finally {
      _speaking = false;
      notifyListeners();
    }
  }

  /// 조리 완료 시 음성 안내
  Future<void> speakCompletion() async {
    _speaking = true;
    notifyListeners();
    
    try {
      await _ttsService.speakCompletion();
    } catch (e) {
      print('TTS completion error: $e');
    } finally {
      _speaking = false;
      notifyListeners();
    }
  }

  /// ASR 상태를 설정합니다.
  void setListening(bool listening) {
    _listening = listening;
    notifyListeners();
  }

  /// 음성 인식을 시작합니다.
  Future<void> startVoiceRecognition() async {
    if (_speaking || _listening) return;
    
    try {
      _listening = true;
      notifyListeners();
      
      // ASR 결과 스트림 구독
      _asrSubscription = _asrService.resultStream.listen(
        (text) => _handleVoiceCommand(text),
        onError: (error) {
          print('ASR Error: $error');
          _listening = false;
          notifyListeners();
        },
      );
      
      await _asrService.startListening();
    } catch (e) {
      print('음성 인식 시작 실패: $e');
      _listening = false;
      notifyListeners();
    }
  }

  /// 음성 인식을 정지합니다.
  Future<void> stopVoiceRecognition() async {
    try {
      await _asrService.stopListening();
      await _asrSubscription?.cancel();
      _asrSubscription = null;
      _listening = false;
      notifyListeners();
    } catch (e) {
      print('음성 인식 정지 실패: $e');
    }
  }

  /// 음성 명령을 처리합니다.
  void _handleVoiceCommand(String text) async {
    print('음성 명령 인식: $text');
    
    final command = _commandParser.parse(text);
    print('파싱된 명령: ${command.intent}');
    
    switch (command.intent) {
      case VoiceIntent.nextStep:
        await nextStep();
        break;
      case VoiceIntent.prevStep:
        await prevStep();
        break;
      case VoiceIntent.repeatStep:
        await repeatStep();
        break;
      case VoiceIntent.startTimer:
        if (command.durationSeconds != null) {
          startTimer(command.durationSeconds!);
        } else {
          // 기본 3분 타이머
          startTimer(180);
        }
        break;
      case VoiceIntent.pauseTimer:
        pauseTimer();
        break;
      case VoiceIntent.resumeTimer:
        resumeTimer();
        break;
      case VoiceIntent.unknown:
        // 알 수 없는 명령에 대한 피드백
        await _ttsService.speak('알 수 없는 명령입니다. 다시 말씀해 주세요.');
        break;
    }
    
    // 명령 처리 후 음성 인식 정지
    await stopVoiceRecognition();
  }

  /// 인분 수를 변경합니다.
  void setServings(int servings) {
    if (servings < 1) return;
    _servings = servings;
    notifyListeners();
  }

  /// 현재 단계의 타이머를 자동 시작합니다.
  void _startStepTimer() {
    if (hasTimer) {
      _currentTimerSec = currentStep!.baseTimeSec;
      _isTimerRunning = true;
      _startTimer();
    }
  }

  /// 타이머를 시작합니다.
  void _startTimer() {
    _stopTimer(); // 기존 타이머 정리
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTimerSec > 0) {
        _currentTimerSec--;
        notifyListeners();
      } else {
        _isTimerRunning = false;
        timer.cancel();
        // 타이머 완료 시 음성 안내
        _speakTimerComplete();
        notifyListeners();
      }
    });
  }

  /// 타이머를 정지합니다.
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 현재 단계의 남은 시간을 포맷된 문자열로 반환합니다.
  String get formattedTimer {
    if (_currentTimerSec <= 0) return '';
    
    final minutes = _currentTimerSec ~/ 60;
    final seconds = _currentTimerSec % 60;
    
    if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
  }

  /// 현재 단계의 진행률을 반환합니다 (0.0 ~ 1.0).
  double get stepProgress {
    if (currentStep == null || currentStep!.baseTimeSec <= 0) return 0.0;
    
    final totalTime = currentStep!.baseTimeSec;
    final remainingTime = _currentTimerSec;
    final elapsedTime = totalTime - remainingTime;
    
    return (elapsedTime / totalTime).clamp(0.0, 1.0);
  }

  /// 전체 레시피의 진행률을 반환합니다 (0.0 ~ 1.0).
  double get recipeProgress {
    if (totalSteps == 0) return 0.0;
    return (_currentStepIndex / (totalSteps - 1)).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _stopTimer();
    _asrSubscription?.cancel();
    _asrService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}


