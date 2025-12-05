import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../models/voice_command.dart';
import '../data/services/voice_service.dart';
import '../data/services/voice_intent_parser.dart';
import '../data/services/gemini_service.dart';
import '../data/services/notification_service.dart';
import '../core/utils/logger.dart';

/// AI 기반의 스마트 요리 가이드 화면 위젯입니다.
///
/// 단계별 레시피 안내, 타이머, 음성 명령 인식 및 음성 답변(TTS) 기능을 제공하여
/// 사용자가 핸즈프리로 요리를 진행할 수 있도록 돕습니다.
class SmartCookingGuideView extends StatefulWidget {
  final Recipe recipe;

  const SmartCookingGuideView({super.key, required this.recipe});

  @override
  State<SmartCookingGuideView> createState() => _SmartCookingGuideViewState();
}

class _SmartCookingGuideViewState extends State<SmartCookingGuideView> {
  // --- 상태 변수 ---
  int _currentStep = 0; // 현재 진행 중인 요리 단계 인덱스
  int _timerSeconds = 0; // 타이머의 남은 시간(초)
  bool _isTimerActive = false; // 타이머 활성화 여부
  Timer? _timer; // 타이머 객체

  // --- 서비스 클래스 ---
  final VoiceService _voiceService = VoiceService(); // 음성 인식(STT) 서비스
  late final GeminiService _geminiService; // Gemini AI 서비스
  final NotificationService _notificationService = NotificationService(); // 푸시 알림 서비스
  final FlutterTts _flutterTts = FlutterTts(); // 음성 합성(TTS) 서비스

  // --- UI 상태 변수 ---
  bool _isListening = false; // 현재 음성 명령을 듣고 있는지 여부
  String _lastVoiceInput = ''; // 마지막으로 인식된 음성 명령 텍스트

  @override
  void initState() {
    super.initState();
    // Provider를 통해 GeminiService 인스턴스를 가져옵니다.
    _geminiService = context.read<GeminiService>();
    
    // 각종 서비스 초기화
    _initServices();
    _initTts();
    
    // 화면이 로드되면 잠시 후 첫 단계를 음성으로 안내합니다.
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakStepInstruction();
      _checkAutoStartTimer(); // 현재 단계에 자동 시작 타이머가 있는지 확인
    });
  }

  /// 음성 인식, 알림 등 주요 서비스를 초기화합니다.
  Future<void> _initServices() async {
    await _voiceService.initialize();
    await _notificationService.initialize();
  }

  /// TTS(Text-to-Speech) 엔진을 한국어로 설정합니다.
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setSpeechRate(0.5); // 음성 속도 조절
    await _flutterTts.setPitch(1.0); // 음성 톤 조절
    
    // TTS 완료 시 자동으로 음성 인식 시작
    _flutterTts.setCompletionHandler(() {
      if (mounted && !_isListening) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _startAutoListening();
          }
        });
      }
    });
  }

  /// 주어진 텍스트를 음성으로 변환하여 사용자에게 들려줍니다.
  Future<void> _speak(String text) async {
    await _flutterTts.stop(); // 이전 음성이 재생 중이면 중지
    await _flutterTts.speak(text);
  }
  
  /// TTS 완료 후 자동으로 음성 인식 시작
  Future<void> _startAutoListening() async {
    if (_isListening) return;
    
    try {
      Logger.info('Auto-starting voice listening after TTS');
      setState(() => _isListening = true);
      
      await _voiceService.startListening(
        onResult: (recognizedText) {
          Logger.info('Auto-recognized: $recognizedText');
          _handleVoiceCommand(recognizedText);
        },
      );
      
      // 5초 후 자동으로 듣기 중지
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isListening) {
          _stopListening();
        }
      });
    } catch (e) {
      Logger.error('Failed to auto-start listening', e);
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }
  
  /// 음성 인식 중지
  Future<void> _stopListening() async {
    if (!_isListening) return;
    
    try {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
    } catch (e) {
      Logger.error('Failed to stop listening', e);
    }
  }

  /// 현재 단계에 자동 시작 타이머가 설정되어 있으면 타이머를 시작합니다.
  void _checkAutoStartTimer() {
    final currentStepData = widget.recipe.steps[_currentStep];
    if (currentStepData.autoStart && currentStepData.timerMinutes != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _startTimer(currentStepData.timerMinutes!);
      });
    }
  }

  @override
  void dispose() {
    // 위젯이 제거될 때 모든 리소스를 정리합니다.
    _timer?.cancel();
    _voiceService.stopListening();
    _flutterTts.stop();
    super.dispose();
  }

  /// 전체 레시피 단계 중 현재 진행률을 계산합니다.
  double get progress => (_currentStep + 1) / widget.recipe.steps.length;

  /// 음성 인식 시작/중지를 토글합니다.
  void _toggleVoiceListening() async {
    if (_isListening) {
      // 듣고 있는 중이면 중지
      await _stopListening();
    } else {
      // 듣기 시작
      setState(() => _isListening = true);
      await _voiceService.startListening(
        onResult: _handleVoiceCommand, // 음성 인식 결과가 나오면 _handleVoiceCommand 호출
      );
    }
  }

  /// 인식된 음성 명령을 처리하는 핵심 메소드입니다.
  Future<void> _handleVoiceCommand(String text) async {
    // 음성 인식 중지
    await _stopListening();
    
    setState(() {
      _lastVoiceInput = text; // 화면에 마지막 음성 입력 표시
    });

    // VoiceIntentParser를 사용하여 음성 텍스트의 의도를 파악합니다.
    final intentResult = VoiceIntentParser.parse(text);
    Logger.info('Voice command parsed: ${intentResult.intent}, params: ${intentResult.parameters}');

    if (!mounted) return;

    // 파악된 의도(intent)에 따라 적절한 액션을 수행합니다.
    switch (intentResult.intent) {
      case VoiceIntent.next:
        _speak('네, 다음 단계로 이동합니다.');
        _nextStep();
        break;
      case VoiceIntent.previous:
        _speak('이전 단계로 돌아갑니다.');
        _prevStep();
        break;
      case VoiceIntent.startTimer:
        final seconds = intentResult.parameters['seconds'] as int?;
        if (seconds != null) {
          final minutes = seconds ~/ 60;
          final secs = seconds % 60;
          String msg = '';
          if (minutes > 0) msg += '$minutes분 ';
          if (secs > 0) msg += '$secs초 ';
          _speak('${msg}타이머를 설정합니다.');
          _startTimer(minutes + (secs > 0 ? 1 : 0)); // 초 단위를 분으로 올림
        } else {
          final step = widget.recipe.steps[_currentStep];
          if (step.timerMinutes != null) {
            _speak('${step.timerMinutes}분 타이머를 시작합니다.');
            _startTimer(step.timerMinutes!);
          } else {
            _speak('기본 5분 타이머를 시작합니다.');
            _startTimer(5);
          }
        }
        break;
      case VoiceIntent.stopTimer:
        _speak('타이머를 정지합니다.');
        _stopTimer();
        break;
      case VoiceIntent.repeat:
        _speak('현재 단계를 다시 알려드릴게요.');
        _showCurrentStep();
        break;
      case VoiceIntent.restart:
        _speak('네, 처음부터 다시 시작합니다.');
        setState(() => _currentStep = 0);
        _speakStepInstruction();
        _checkAutoStartTimer();
        break;
      case VoiceIntent.slower:
        _speak('말하기 속도를 느리게 합니다.');
        _flutterTts.setSpeechRate(0.4);
        break;
      case VoiceIntent.faster:
        _speak('말하기 속도를 빠르게 합니다.');
        _flutterTts.setSpeechRate(0.8);
        break;
      case VoiceIntent.stop:
        _speak('음성 안내를 중지합니다.');
        _flutterTts.stop();
        break;
      case VoiceIntent.question:
        await _askGemini(text);
        break;
      default:
        _speak('죄송합니다, 잘 이해하지 못했어요.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('죄송합니다, 잘 이해하지 못했어요. 😅')),
        );
        break;
    }
  }

  /// 현재 요리 단계의 설명을 음성으로 안내합니다.
  void _speakStepInstruction() {
    final step = widget.recipe.steps[_currentStep];
    final textToSpeak = '단계 ${_currentStep + 1}. ${step.instruction}';
    _speak(textToSpeak);
  }

  /// 다음 요리 단계로 이동합니다.
  void _nextStep() {
    if (_currentStep < widget.recipe.steps.length - 1) {
      setState(() {
        _currentStep++;
        _isTimerActive = false;
        _timerSeconds = 0;
      });
      _timer?.cancel();
      _speakStepInstruction();
      _checkAutoStartTimer();
    } else {
      // 마지막 단계이면 요리 완료 처리
      _speak('축하합니다! 요리가 완성되었습니다.');
      _showCompletionDialog();
    }
  }

  /// 이전 요리 단계로 이동합니다.
  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isTimerActive = false;
        _timerSeconds = 0;
      });
      _timer?.cancel();
      _speakStepInstruction();
      _checkAutoStartTimer();
    } else {
      _speak('이미 첫 단계입니다.');
    }
  }

  /// 지정된 시간(분)으로 타이머를 시작합니다.
  void _startTimer(int minutes) {
    setState(() {
      _timerSeconds = minutes * 60;
      _isTimerActive = true;
    });
    
    // 타이머 시작 시 푸시 알림 예약
    _notificationService.showTimerStartNotification(
      recipeTitle: widget.recipe.title,
      minutes: minutes,
    );
    
    _timer?.cancel(); // 기존 타이머가 있으면 취소
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
        setState(() => _isTimerActive = false);
        _onTimerComplete(); // 타이머 종료 처리
      }
    });
  }

  /// 현재 타이머를 중지합니다.
  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerActive = false;
      _timerSeconds = 0;
    });
    _notificationService.cancel(1); // 예약된 알림 취소
  }

  /// 타이머가 완료되었을 때 호출됩니다.
  void _onTimerComplete() {
    final message = '타이머가 완료되었습니다!';
    _speak(message);
    _notificationService.showTimerCompleteNotification(
      recipeTitle: widget.recipe.title,
      stepNumber: _currentStep + 1,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ $message'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 초 단위를 '분:초' 형식의 문자열로 변환합니다.
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// '다시 말해줘' 명령 처리: 현재 단계 설명을 다시 음성으로 안내합니다.
  void _showCurrentStep() {
    final step = widget.recipe.steps[_currentStep];
    _speak('${_currentStep + 1}단계는, ${step.instruction} 입니다.');
  }

  /// 요리 관련 질문을 Gemini에게 물어보고 답변을 음성으로 안내합니다.
  Future<void> _askGemini(String question) async {
    _speak('네, 질문에 대해 알아보고 있어요. 잠시만 기다려주세요.');
    try {
      final answer = await _geminiService.getCookingAssistance(
        recipeTitle: widget.recipe.title,
        ingredients: widget.recipe.ingredients,
        steps: widget.recipe.steps.map((s) => s.instruction).toList(),
        userQuestion: question,
      );
      _speak(answer);
    } catch (e) {
      Logger.error('Failed to get answer from Gemini', e);
      final errorMessage = '죄송합니다, 답변을 찾는 중 오류가 발생했어요.';
      _speak(errorMessage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  /// 요리 완료 시 다이얼로그를 표시합니다.
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('요리 완성! 🎉'),
        content: const Text('멋진 요리가 완성되었습니다!\n완성된 요리 사진을 찍어서 기록해보세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('완료'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📸 사진이 저장되었습니다!')),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('사진 촬영'),
          ),
        ],
      ),
    );
  }

  // --- 위젯 빌드 메소드 ---

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentStepData = widget.recipe.steps[_currentStep];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showRecipeInfo(context),
          ),
        ],
      ),
      // 음성 명령을 위한 중앙 플로팅 액션 버튼
      floatingActionButton: FloatingActionButton.large(
        onPressed: _toggleVoiceListening,
        backgroundColor: _isListening ? Colors.redAccent : scheme.primary,
        child: _isListening
            ? const Icon(Icons.mic, color: Colors.white, size: 36) // 듣는 중
            : const Icon(Icons.mic_none, color: Colors.white, size: 36), // 대기 중
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: [
          // 마지막 음성 입력 내용을 보여주는 배너
          if (_lastVoiceInput.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: scheme.primaryContainer,
              child: Text(
                '🎤 "$_lastVoiceInput"',
                style: TextStyle(color: scheme.onPrimaryContainer),
                textAlign: TextAlign.center,
              ),
            ),
          // 진행 상태 바
          _buildProgressBar(scheme),
          // 메인 콘텐츠 (스크롤 가능)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStepCard(scheme, currentStepData), // 현재 단계 카드
                  const SizedBox(height: 16),
                  _buildTimerCard(scheme, currentStepData), // 타이머 카드
                  const SizedBox(height: 16),
                  _buildVoiceCommandsCard(scheme), // 사용 가능한 음성 명령 예시 카드
                  const SizedBox(height: 16),
                  _buildIngredientsCard(scheme), // 레시피 재료 카드
                ],
              ),
            ),
          ),
          // 하단 네비게이션 바 (이전/다음 버튼)
          _buildBottomAppBar(scheme),
        ],
      ),
    );
  }

  /// 진행 상태를 보여주는 프로그레스 바 위젯을 빌드합니다.
  Widget _buildProgressBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '단계 ${_currentStep + 1} / ${widget.recipe.steps.length}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).round()}% 완료',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// 현재 요리 단계의 상세 내용을 보여주는 카드 위젯을 빌드합니다.
  Widget _buildCurrentStepCard(ColorScheme scheme, RecipeStep stepData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_currentStep + 1}',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '단계 ${_currentStep + 1}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // 해당 단계에 타이머 정보가 있으면 표시
                if (stepData.timerMinutes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: scheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stepData.timerMinutes}분',
                          style: TextStyle(
                            color: scheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              stepData.instruction,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 타이머 시간과 컨트롤 버튼을 보여주는 카드 위젯을 빌드합니다.
  Widget _buildTimerCard(ColorScheme scheme, RecipeStep stepData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _formatTime(_timerSeconds),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: _isTimerActive ? scheme.primary : scheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (stepData.timerMinutes != null && !_isTimerActive)
                  FilledButton.icon(
                    onPressed: () => _startTimer(stepData.timerMinutes!),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('${stepData.timerMinutes}분 시작'),
                  ),
                if (!_isTimerActive) ...[
                  FilledButton.tonalIcon(
                    onPressed: () => _startTimer(5),
                    icon: const Icon(Icons.timer),
                    label: const Text('5분'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _startTimer(10),
                    icon: const Icon(Icons.timer),
                    label: const Text('10분'),
                  ),
                ],
                if (_isTimerActive)
                  OutlinedButton.icon(
                    onPressed: _stopTimer,
                    icon: const Icon(Icons.stop),
                    label: const Text('정지'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 사용 가능한 음성 명령어 예시를 보여주는 카드 위젯을 빌드합니다.
  Widget _buildVoiceCommandsCard(ColorScheme scheme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '음성 명령어',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CommandChip(text: '"다음 단계"', scheme: scheme),
                _CommandChip(text: '"이전 단계"', scheme: scheme),
                _CommandChip(text: '"타이머 5분"', scheme: scheme),
                _CommandChip(text: '"정지"', scheme: scheme),
                _CommandChip(text: '"처음부터"', scheme: scheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 현재 레시피에 필요한 재료 목록을 보여주는 카드 위젯을 빌드합니다.
  Widget _buildIngredientsCard(ColorScheme scheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '필요한 재료',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.recipe.ingredients.map((ingredient) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, 
                      size: 20, 
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 이전/다음 단계로 이동하는 버튼이 있는 하단 앱 바를 빌드합니다.
  Widget _buildBottomAppBar(ColorScheme scheme) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(), // 중앙 FAB를 위한 노치
      notchMargin: 8.0,
      color: scheme.surface,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: _currentStep > 0 ? _prevStep : null,
            icon: const Icon(Icons.skip_previous),
            iconSize: 32,
            tooltip: '이전 단계',
            disabledColor: scheme.onSurface.withOpacity(0.3),
            color: scheme.onSurface,
          ),
          const SizedBox(width: 80), // 중앙 FAB를 위한 공간
          IconButton(
            onPressed: _nextStep,
            icon: Icon(
              _currentStep == widget.recipe.steps.length - 1
                  ? Icons.check_circle // 마지막 단계이면 체크 아이콘
                  : Icons.skip_next,
            ),
            iconSize: 32,
            tooltip: '다음 단계',
            color: scheme.primary,
          ),
        ],
      ),
    );
  }

  /// 레시피의 기본 정보(조리 시간, 인분, 난이도)를 보여주는 바텀 시트를 표시합니다.
  void _showRecipeInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipe.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.schedule,
              label: '조리시간',
              value: '${widget.recipe.durationMinutes}분',
            ),
            if (widget.recipe.servings != null)
              _InfoRow(
                icon: Icons.people_alt,
                label: '인분',
                value: '${widget.recipe.servings}인분',
              ),
            if (widget.recipe.difficulty != null)
              _InfoRow(
                icon: Icons.signal_cellular_alt,
                label: '난이도',
                value: widget.recipe.difficulty!,
              ),
          ],
        ),
      ),
    );
  }
}

/// 음성 명령어 예시를 보여주는 작은 칩 위젯
class _CommandChip extends StatelessWidget {
  final String text;
  final ColorScheme scheme;

  const _CommandChip({required this.text, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 레시피 정보 행을 표시하는 작은 위젯 (예: 아이콘 - 라벨 - 값)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}
