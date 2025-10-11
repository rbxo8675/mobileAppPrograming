import 'dart:async';
import 'package:cooktalk/providers/session_provider.dart';
import 'package:cooktalk/services/asr_service.dart';
import 'package:cooktalk/services/command_parser.dart';
import 'package:cooktalk/services/analytics_service.dart';
import 'package:cooktalk/services/tts_service.dart';
import 'package:cooktalk/widgets/quick_commands.dart';
import 'package:cooktalk/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CookingSessionScreen extends StatefulWidget {
  const CookingSessionScreen({super.key});

  @override
  State<CookingSessionScreen> createState() => _CookingSessionScreenState();
}

class _CookingSessionScreenState extends State<CookingSessionScreen> {
  final TtsService _ttsService = TtsService();
  final AsrService _asrService = AsrService();
  final CommandParser _commandParser = CommandParser();
  String? _resolvedLocaleId;
  String get _preferredLocaleTag {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    return settings.ttsLanguage; // e.g., ko-KR, en-US, ja-JP
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _asrService.initialize(
      onError: (error) => _showError(error.errorMsg),
      onStatus: (status) {
        // Lightweight status hint
        if (mounted && status.isNotEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(duration: const Duration(milliseconds: 800), content: Text('ASR 상태: $status')),
          );
        }
        if (mounted) {
          final session = Provider.of<SessionProvider>(context, listen: false);
          if (status == 'done' || status == 'notListening') {
            session.setListening(false);
          }
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentStep();
      _maybeStartAutoTimer();
      _logEvent('session_start');
      _resolveLocale();
      _startAutoListeningLoop();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    await AnalyticsService.logEvent(name, parameters: parameters);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _speakCurrentStep() {
    final session = Provider.of<SessionProvider>(context, listen: false);
    if (session.currentStep != null) {
      session.setSpeaking(true);
      _ttsService.speak(
        session.currentStep!.text,
        onComplete: () {
          session.setSpeaking(false);
          _startAutoListeningLoop();
        },
      );
    }
  }

  Future<void> _requestMicrophonePermission() async {
    if (kIsWeb) return; // Web은 브라우저 권한 팝업으로 처리됨
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      _showError('마이크 권한이 거부되었습니다.');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('마이크 권한 필요'),
            content: const Text('음성 명령을 사용하려면 마이크 권한이 필요합니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('설정으로 이동'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _resolveLocale() async {
    try {
      final locales = await _asrService.getLocales();
      final systemLocale = await _asrService.getSystemLocaleId();
      String pref = _preferredLocaleTag; // e.g., ko-KR
      String norm(String s) => s.toLowerCase().replaceAll('_', '-');
      final prefNorm = norm(pref);
      String? match;
      // exact match
      match = locales.map((e) => e.localeId).firstWhere(
            (id) => norm(id) == prefNorm,
            orElse: () => '',
          );
      if ((match ?? '').isEmpty) {
        // startsWith language
        final lang = prefNorm.split('-').first;
        match = locales.map((e) => e.localeId).firstWhere(
              (id) => norm(id).startsWith('$lang-'),
              orElse: () => '',
            );
      }
      if ((match ?? '').isEmpty && systemLocale != null) {
        match = systemLocale;
      }
      setState(() {
        _resolvedLocaleId = (match ?? '').isEmpty ? null : match;
      });
    } catch (_) {
      // leave as null -> plugin default
    }
  }

  // Auto listening loop
  bool _autoListenEnabled = true;
  Timer? _autoListenTimer;

  void _startAutoListeningLoop() {
    _autoListenTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => _autoListenTick());
  }

  void _autoListenTick() {
    if (!_autoListenEnabled || !_asrService.isAvailable || !mounted) return;
    final session = Provider.of<SessionProvider>(context, listen: false);
    if (session.isSpeaking) return;
    if (_asrService.isListening) return;

    final localeId = _resolvedLocaleId;
    _asrService.startListening(
      onResult: _handleVoiceCommand,
      onListening: () => session.setListening(true),
      localeId: localeId,
      partialResults: true,
      listenFor: const Duration(seconds: 8),
    );
  }

  void _handleVoiceCommand(String recognizedWords) {
    if (recognizedWords.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(milliseconds: 1200), content: Text('인식: $recognizedWords')),
      );
    }
    final command = _commandParser.parse(recognizedWords);
    final session = Provider.of<SessionProvider>(context, listen: false);
    _logEvent('asr_intent', parameters: {'intent': command.intent.toString()});

    switch (command.intent) {
      case CommandIntent.nextStep:
        _goToNextStep();
        _logEvent('step_next');
        break;
      case CommandIntent.prevStep:
        _goToPrevStep();
        _logEvent('step_prev');
        break;
      case CommandIntent.repeatStep:
        _speakCurrentStep();
        _logEvent('step_repeat');
        break;
      case CommandIntent.startTimer:
        if (command.durationSec != null) {
          session.startTimer(command.durationSec!);
          _logEvent('timer_start', parameters: {'duration': command.durationSec!});
        }
        break;
      case CommandIntent.pauseTimer:
        session.pauseTimer();
        _logEvent('timer_pause');
        break;
      case CommandIntent.resumeTimer:
        session.resumeTimer();
        _logEvent('timer_resume');
        break;
      case CommandIntent.unknown:
        _showError('알 수 없는 명령입니다.');
        _logEvent('asr_unknown');
        break;
    }

    // Voice interaction finished
    session.setListening(false);
  }

  void _maybeStartAutoTimer() {
    final session = Provider.of<SessionProvider>(context, listen: false);
    final step = session.currentStep;
    if (step != null && step.baseTimeSec > 0) {
      session.startTimer(step.baseTimeSec);
      _logEvent('timer_start', parameters: {'duration': step.baseTimeSec});
    }
  }

  void _goToNextStep() {
    final session = Provider.of<SessionProvider>(context, listen: false);
    session.nextStep();
    _speakCurrentStep();
    _maybeStartAutoTimer();
  }

  void _goToPrevStep() {
    final session = Provider.of<SessionProvider>(context, listen: false);
    session.prevStep();
    _speakCurrentStep();
    _maybeStartAutoTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, child) {
        final currentStep = session.currentStep;
        if (currentStep == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('레시피가 선택되지 않았습니다.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(session.recipe?.title ?? ''),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Center(child: Text('${session.currentStepIndex + 1} / ${session.recipe?.steps.length}')),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 큰 아이콘(이미지 대체)으로 현재 단계의 액션을 직관적으로 표시
                Icon(_iconForAction(session.currentStep?.actionTag), size: 72, color: Colors.blueGrey),
                const SizedBox(height: 12),
                Text(
                  currentStep.text,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (session.currentTimerSec > 0)
                  Text(
                    '${(session.currentTimerSec ~/ 60).toString().padLeft(2, '0')}:${(session.currentTimerSec % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
                // 다음 단계 간략 표시(미니 카드)
                if ((session.currentStepIndex + 1) < (session.recipe?.steps.length ?? 0))
                  Card(
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_forward, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('다음 단계', style: Theme.of(context).textTheme.labelLarge),
                                const SizedBox(height: 4),
                                Text(
                                  session.recipe!.steps[session.currentStepIndex + 1].text,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        _goToPrevStep();
                        _logEvent('step_prev');
                      },
                      iconSize: 48,
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: (session.isSpeaking)
                          ? null
                          : () async {
                              await _requestMicrophonePermission();
                              if (!_asrService.isAvailable) {
                                _showError('이 디바이스에서 음성 인식이 지원되지 않거나 초기화되지 않았습니다.');
                                return;
                              }
                              final localeId = _resolvedLocaleId;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(duration: const Duration(milliseconds: 800), content: Text('음성 인식 시작: ${localeId ?? '기본'}')),
                              );
                              _asrService.startListening(
                                onResult: _handleVoiceCommand,
                                onListening: () {
                                  session.setListening(true);
                                },
                                localeId: localeId,
                                partialResults: true,
                                listenFor: const Duration(seconds: 8),
                              );
                            },
                      iconSize: 64,
                      color: (session.isSpeaking || session.isListening)
                          ? Colors.grey
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        _goToNextStep();
                        _logEvent('step_next');
                      },
                      iconSize: 48,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hearing,
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '자동 듣기 중 · 명령어 예: "다음", "이전", "다시", "타이머 3분", "일시정지", "재개"' +
                            (_resolvedLocaleId != null ? '  · 언어: $_resolvedLocaleId' : ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                QuickCommands(
                  onNext: _goToNextStep,
                  onPrev: _goToPrevStep,
                  onRepeat: _speakCurrentStep,
                  onTimer3Min: () {
                    session.startTimer(180);
                    _logEvent('timer_start', parameters: {'duration': 180});
                  },
                  onPause: session.pauseTimer,
                  onResume: session.resumeTimer,
                  isFirstStep: session.currentStepIndex == 0,
                  isLastStep: session.currentStepIndex == (session.recipe?.steps.length ?? 1) - 1,
                  hasTimer: (session.currentStep?.baseTimeSec ?? 0) > 0,
                  isTimerRunning: session.isTimerRunning,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconForAction(String? tag) {
    switch (tag) {
      case 'chop':
        return Icons.restaurant_menu;
      case 'heat':
        return Icons.local_fire_department;
      case 'stir-fry':
        return Icons.rice_bowl;
      case 'boil':
        return Icons.soup_kitchen;
      case 'season':
        return Icons.restaurant;
      case 'mix':
        return Icons.blender;
      case 'dip':
        return Icons.invert_colors;
      case 'pan-fry':
        return Icons.cookie;
      case 'serve':
        return Icons.emoji_food_beverage;
      default:
        return Icons.menu_book;
    }
  }
}
