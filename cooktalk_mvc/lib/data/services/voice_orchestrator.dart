import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/recipe.dart';
import '../../models/timer.dart';
import 'tts_service.dart';
import 'voice_service.dart';
import 'voice_intent_parser.dart';
import '../../core/utils/logger.dart';

enum OrchestratorState {
  idle,
  readingStep,
  listening,
  executingIntent,
}

class VoiceOrchestrator extends ChangeNotifier {
  final TtsService _tts = TtsService();
  final VoiceService _voice = VoiceService();
  
  OrchestratorState _state = OrchestratorState.idle;
  Recipe? _currentRecipe;
  int _currentStep = 0;
  bool _isListening = false;
  double _speechRate = 0.5;
  final List<CookingTimer> _activeTimers = [];
  
  // 자동 음성 인식 설정
  bool _autoListenAfterTts = true;
  Timer? _listenTimeoutTimer;
  final Duration _listenTimeout = const Duration(seconds: 5);
  Function(String)? _onVoiceCommand;
  
  OrchestratorState get state => _state;
  bool get isListening => _isListening;
  double get speechRate => _speechRate;
  int get currentStep => _currentStep;
  List<CookingTimer> get activeTimers => List.unmodifiable(_activeTimers);
  bool get autoListenAfterTts => _autoListenAfterTts;
  
  /// 자동 음성 인식 활성화/비활성화
  void setAutoListenAfterTts(bool value) {
    _autoListenAfterTts = value;
    notifyListeners();
  }

  Future<void> initialize() async {
    await _tts.initialize();
    Logger.info('Voice Orchestrator initialized');
  }

  Future<void> startCookingSession(
    Recipe recipe, {
    int startStep = 0,
    Function(String)? onVoiceCommand,
  }) async {
    try {
      _currentRecipe = recipe;
      _currentStep = startStep;
      _state = OrchestratorState.idle;
      _onVoiceCommand = onVoiceCommand;
      
      await readCurrentStep();
      
      Logger.info('Started cooking session for: ${recipe.title}');
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to start cooking session', e);
    }
  }
  
  /// 음성 명령 콜백 설정
  void setOnVoiceCommand(Function(String)? callback) {
    _onVoiceCommand = callback;
  }

  Future<void> readCurrentStep() async {
    if (_currentRecipe == null) return;
    
    try {
      _state = OrchestratorState.readingStep;
      notifyListeners();
      
      final step = _currentRecipe!.steps[_currentStep];
      final stepNumber = _currentStep + 1;
      final totalSteps = _currentRecipe!.steps.length;
      
      final text = '$stepNumber번째 단계입니다. 총 $totalSteps단계 중 $stepNumber입니다. ${step.instruction}';
      
      // TTS 완료 후 자동으로 음성 인식 시작
      await _tts.speak(text, onComplete: () {
        if (_autoListenAfterTts && _onVoiceCommand != null) {
          _startAutoListening();
        }
      });
      
      _state = OrchestratorState.idle;
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to read current step', e);
      _state = OrchestratorState.idle;
      notifyListeners();
    }
  }
  
  /// TTS 완료 후 자동으로 음성 인식 시작
  Future<void> _startAutoListening() async {
    if (_isListening) return;
    
    try {
      Logger.info('Auto-starting voice listening after TTS');
      
      // 짧은 딜레이 후 인식 시작 (TTS 종료 음향 방지)
      await Future.delayed(const Duration(milliseconds: 300));
      
      _isListening = true;
      _state = OrchestratorState.listening;
      notifyListeners();
      
      await _voice.startListening(
        onResult: (recognizedText) {
          Logger.info('Auto-recognized: $recognizedText');
          _onVoiceCommand?.call(recognizedText);
          _stopListeningWithTimeout();
        },
      );
      
      // 타임아웃 설정 (5초 후 자동 종료)
      _listenTimeoutTimer?.cancel();
      _listenTimeoutTimer = Timer(_listenTimeout, () {
        Logger.info('Voice listening timeout');
        _stopListeningWithTimeout();
      });
      
    } catch (e) {
      Logger.error('Failed to auto-start listening', e);
      _isListening = false;
      _state = OrchestratorState.idle;
      notifyListeners();
    }
  }
  
  /// 타임아웃과 함께 인식 중단
  Future<void> _stopListeningWithTimeout() async {
    _listenTimeoutTimer?.cancel();
    await stopListening();
  }

  Future<void> startListening(Function(String) onResult) async {
    if (_isListening) return;
    
    try {
      _isListening = true;
      _state = OrchestratorState.listening;
      notifyListeners();
      
      await _voice.startListening(
        onResult: (recognizedText) {
          onResult(recognizedText);
        },
      );
      
      Logger.info('Started listening for voice commands');
    } catch (e) {
      Logger.error('Failed to start listening', e);
      _isListening = false;
      _state = OrchestratorState.idle;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _voice.stopListening();
      _isListening = false;
      _state = OrchestratorState.idle;
      notifyListeners();
      
      Logger.info('Stopped listening');
    } catch (e) {
      Logger.error('Failed to stop listening', e);
    }
  }

  Future<VoiceIntentResult> processCommand(String command) async {
    try {
      _state = OrchestratorState.executingIntent;
      notifyListeners();
      
      final result = VoiceIntentParser.parse(command);
      
      await _executeIntent(result);
      
      _state = OrchestratorState.idle;
      notifyListeners();
      
      return result;
    } catch (e) {
      Logger.error('Failed to process command', e);
      _state = OrchestratorState.idle;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _executeIntent(VoiceIntentResult result) async {
    Logger.info('Executing intent: ${result.intent}');
    
    switch (result.intent) {
      case VoiceIntent.next:
        await nextStep();
        break;
      case VoiceIntent.previous:
        await previousStep();
        break;
      case VoiceIntent.repeat:
        await readCurrentStep();
        break;
      case VoiceIntent.restart:
        await goToStep(0);
        break;
      case VoiceIntent.summary:
        await readStepSummary();
        break;
      case VoiceIntent.slower:
        await setSpeechRateSlower();
        break;
      case VoiceIntent.faster:
        await setSpeechRateFaster();
        break;
      case VoiceIntent.stop:
        await _tts.stop();
        break;
      case VoiceIntent.startTimer:
        await startTimer(
          result.parameters['seconds'] as int,
          label: result.parameters['label'] as String? ?? '타이머',
        );
        break;
      case VoiceIntent.stopTimer:
        await stopAllTimers();
        break;
      case VoiceIntent.pauseTimer:
        await pauseAllTimers();
        break;
      case VoiceIntent.resumeTimer:
        await resumeAllTimers();
        break;
      case VoiceIntent.checkTimer:
        await announceTimers();
        break;
      default:
        Logger.info('Unhandled intent: ${result.intent}');
    }
  }

  Future<void> startTimer(int seconds, {String label = '타이머'}) async {
    final timer = CookingTimer(
      id: 'timer_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      status: TimerStatus.running,
      startedAt: DateTime.now(),
    );
    
    _activeTimers.add(timer);
    
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    String announcement = '$label';
    if (minutes > 0) announcement += ' $minutes분';
    if (secs > 0) announcement += ' $secs초';
    announcement += ' 타이머를 시작합니다.';
    
    await _tts.speak(announcement);
    notifyListeners();
    Logger.info('Started timer: $label for $seconds seconds');
  }

  Future<void> stopAllTimers() async {
    if (_activeTimers.isEmpty) {
      await _tts.speak('실행 중인 타이머가 없습니다.');
      return;
    }
    
    _activeTimers.clear();
    await _tts.speak('모든 타이머를 중지했습니다.');
    notifyListeners();
    Logger.info('Stopped all timers');
  }

  Future<void> pauseAllTimers() async {
    if (_activeTimers.isEmpty) {
      await _tts.speak('실행 중인 타이머가 없습니다.');
      return;
    }
    
    for (int i = 0; i < _activeTimers.length; i++) {
      if (_activeTimers[i].isActive) {
        _activeTimers[i] = _activeTimers[i].copyWith(
          status: TimerStatus.paused,
          pausedAt: DateTime.now(),
        );
      }
    }
    
    await _tts.speak('타이머를 일시정지했습니다.');
    notifyListeners();
    Logger.info('Paused all timers');
  }

  Future<void> resumeAllTimers() async {
    if (_activeTimers.isEmpty) {
      await _tts.speak('일시정지된 타이머가 없습니다.');
      return;
    }
    
    for (int i = 0; i < _activeTimers.length; i++) {
      if (_activeTimers[i].isPaused) {
        _activeTimers[i] = _activeTimers[i].copyWith(
          status: TimerStatus.running,
          pausedAt: null,
        );
      }
    }
    
    await _tts.speak('타이머를 재개합니다.');
    notifyListeners();
    Logger.info('Resumed all timers');
  }

  Future<void> announceTimers() async {
    if (_activeTimers.isEmpty) {
      await _tts.speak('실행 중인 타이머가 없습니다.');
      return;
    }
    
    String announcement = '';
    for (final timer in _activeTimers) {
      if (timer.isActive || timer.isPaused) {
        final minutes = timer.remainingSeconds ~/ 60;
        final seconds = timer.remainingSeconds % 60;
        announcement += '${timer.label} ';
        if (minutes > 0) announcement += '$minutes분 ';
        if (seconds > 0) announcement += '$seconds초 ';
        announcement += '남았습니다. ';
      }
    }
    
    await _tts.speak(announcement);
  }

  Future<void> nextStep() async {
    if (_currentRecipe == null) return;
    
    if (_currentStep < _currentRecipe!.steps.length - 1) {
      _currentStep++;
      await readCurrentStep();
      Logger.info('Moved to next step: $_currentStep');
    } else {
      await _tts.speak('마지막 단계입니다. 요리가 완료되었습니다!');
    }
  }

  Future<void> previousStep() async {
    if (_currentStep > 0) {
      _currentStep--;
      await readCurrentStep();
      Logger.info('Moved to previous step: $_currentStep');
    } else {
      await _tts.speak('첫 번째 단계입니다.');
    }
  }

  Future<void> goToStep(int step) async {
    if (_currentRecipe == null) return;
    
    if (step >= 0 && step < _currentRecipe!.steps.length) {
      _currentStep = step;
      await readCurrentStep();
      Logger.info('Moved to step: $_currentStep');
    }
  }

  Future<void> readStepSummary() async {
    if (_currentRecipe == null) return;
    
    final stepNumber = _currentStep + 1;
    final totalSteps = _currentRecipe!.steps.length;
    final text = '현재 $totalSteps단계 중 $stepNumber번째 단계입니다.';
    
    await _tts.speak(text);
  }

  Future<void> setSpeechRateSlower() async {
    _speechRate = (_speechRate - 0.1).clamp(0.3, 1.0);
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak('말하기 속도를 느리게 했습니다.');
    notifyListeners();
  }

  Future<void> setSpeechRateFaster() async {
    _speechRate = (_speechRate + 0.1).clamp(0.3, 1.0);
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak('말하기 속도를 빠르게 했습니다.');
    notifyListeners();
  }

  Future<void> stopSession() async {
    _listenTimeoutTimer?.cancel();
    await _tts.stop();
    await stopListening();
    _currentRecipe = null;
    _currentStep = 0;
    _onVoiceCommand = null;
    _state = OrchestratorState.idle;
    notifyListeners();
    Logger.info('Stopped cooking session');
  }
  
  /// TTS를 즉시 중단하고 음성 인식 시작 (Push-to-Talk)
  Future<void> interruptAndListen(Function(String) onResult) async {
    try {
      Logger.info('Interrupting TTS and starting voice recognition');
      
      // TTS 즉시 중단
      await _tts.stop();
      _listenTimeoutTimer?.cancel();
      
      // 음성 인식 시작
      if (!_isListening) {
        _isListening = true;
        _state = OrchestratorState.listening;
        notifyListeners();
        
        await _voice.startListening(
          onResult: (recognizedText) {
            Logger.info('Interrupt-recognized: $recognizedText');
            onResult(recognizedText);
            _stopListeningWithTimeout();
          },
        );
        
        // 타임아웃 설정
        _listenTimeoutTimer = Timer(_listenTimeout, () {
          Logger.info('Interrupt voice listening timeout');
          _stopListeningWithTimeout();
        });
      }
    } catch (e) {
      Logger.error('Failed to interrupt and listen', e);
      _isListening = false;
      _state = OrchestratorState.idle;
      notifyListeners();
    }
  }
  
  /// 수동으로 음성 인식 시작 (버튼 클릭)
  Future<void> startManualListening(Function(String) onResult) async {
    if (_isListening) return;
    
    try {
      Logger.info('Starting manual voice listening');
      
      _isListening = true;
      _state = OrchestratorState.listening;
      notifyListeners();
      
      await _voice.startListening(
        onResult: (recognizedText) {
          Logger.info('Manual-recognized: $recognizedText');
          onResult(recognizedText);
          _stopListeningWithTimeout();
        },
      );
      
      // 타임아웃 설정
      _listenTimeoutTimer?.cancel();
      _listenTimeoutTimer = Timer(_listenTimeout, () {
        Logger.info('Manual voice listening timeout');
        _stopListeningWithTimeout();
      });
      
    } catch (e) {
      Logger.error('Failed to start manual listening', e);
      _isListening = false;
      _state = OrchestratorState.idle;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _listenTimeoutTimer?.cancel();
    _tts.dispose();
    super.dispose();
  }
}
