import 'package:cooktalk/providers/session_provider.dart';
import 'package:cooktalk/services/asr_service.dart';
import 'package:cooktalk/services/command_parser.dart';
import 'package:cooktalk/services/tts_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
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
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _asrService.initialize(onError: (error) => _showError(error));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentStep();
      _logEvent('session_start');
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _speakCurrentStep() {
    final session = Provider.of<SessionProvider>(context, listen: false);
    if (session.currentStep != null) {
      _ttsService.speak(session.currentStep!.text);
    }
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      _showError('마이크 권한이 거부되었습니다.');
      // Show a dialog to the user
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

  void _handleVoiceCommand(String recognizedWords) {
    final command = _commandParser.parse(recognizedWords);
    final session = Provider.of<SessionProvider>(context, listen: false);
    _logEvent('asr_intent', parameters: {'intent': command.intent.toString()});

    switch (command.intent) {
      case CommandIntent.nextStep:
        session.nextStep();
        _logEvent('step_next');
        break;
      case CommandIntent.prevStep:
        session.prevStep();
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
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        session.prevStep();
                        _logEvent('step_prev');
                      },
                      iconSize: 48,
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: () async {
                        await _requestMicrophonePermission();
                        _asrService.startListening(onResult: _handleVoiceCommand);
                      },
                      iconSize: 64,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        session.nextStep();
                        _logEvent('step_next');
                      },
                      iconSize: 48,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
