import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../models/recipe.dart';
import '../controllers/cooking_assistant_controller.dart';
import '../data/services/voice_orchestrator.dart';

/// VoiceOrchestrator를 사용하는 음성 조리 가이드 뷰
class VoiceCookingGuideView extends StatefulWidget {
  final Recipe recipe;

  const VoiceCookingGuideView({super.key, required this.recipe});

  @override
  State<VoiceCookingGuideView> createState() => _VoiceCookingGuideViewState();
}

class _VoiceCookingGuideViewState extends State<VoiceCookingGuideView> {
  String _lastVoiceInput = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 음성 모드로 요리 시작
      context.read<CookingAssistantController>().startCooking(
        widget.recipe,
        withVoice: true,
      );
    });
  }

  @override
  void dispose() {
    context.read<CookingAssistantController>().stopVoiceListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        centerTitle: false,
        actions: [
          // 자동 음성 인식 토글
          Consumer<CookingAssistantController>(
            builder: (context, controller, _) {
              final autoListen = controller.voiceOrchestrator.autoListenAfterTts;
              return IconButton(
                icon: Icon(autoListen ? Icons.hearing : Icons.hearing_disabled),
                tooltip: autoListen ? '자동 인식 켜짐' : '자동 인식 꺼짐',
                onPressed: () {
                  controller.setAutoListen(!autoListen);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !autoListen ? 'TTS 후 자동으로 음성 인식을 시작합니다' : '자동 음성 인식을 껐습니다',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showRecipeInfo(context),
          ),
        ],
      ),
      // Push-to-Talk 버튼 (TTS 중단하고 즉시 인식)
      floatingActionButton: Consumer<CookingAssistantController>(
        builder: (context, controller, _) {
          final isListening = controller.isListening;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 듣고 있는 상태 표시
              if (isListening)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '듣고 있습니다...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // 메인 음성 버튼
              FloatingActionButton.large(
                onPressed: () {
                  if (isListening) {
                    controller.stopVoiceListening();
                  } else {
                    // TTS 중단하고 즉시 인식
                    controller.interruptAndListen();
                  }
                },
                backgroundColor: isListening ? Colors.redAccent : colorScheme.primary,
                child: isListening
                    ? const Icon(Icons.mic, color: Colors.white, size: 36)
                    : const Icon(Icons.mic_none, color: Colors.white, size: 36),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Consumer<CookingAssistantController>(
        builder: (context, controller, _) {
          final orchestrator = controller.voiceOrchestrator;
          final currentStep = orchestrator.currentStep;
          final totalSteps = widget.recipe.steps.length;
          final progress = (currentStep + 1) / totalSteps;
          
          return Column(
            children: [
              // 음성 인식 상태 배너
              if (_lastVoiceInput.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: colorScheme.primaryContainer,
                  child: Text(
                    '🎤 "$_lastVoiceInput"',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // 진행 상태 바
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
              
              // 단계 정보
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: colorScheme.secondaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '단계 ${currentStep + 1} / $totalSteps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.recipe.steps[currentStep].instruction,
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 타이머 정보
              if (orchestrator.activeTimers.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '활성 타이머',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...orchestrator.activeTimers.map((timer) {
                        final minutes = timer.remainingSeconds ~/ 60;
                        final seconds = timer.remainingSeconds % 60;
                        return Text(
                          '${timer.label}: $minutes:${seconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              
              const Spacer(),
              
              // 음성 명령 안내
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 음성 명령 예시',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCommandHint(context, '다음', '다음 단계로 이동'),
                    _buildCommandHint(context, '이전', '이전 단계로 돌아가기'),
                    _buildCommandHint(context, '다시', '현재 단계 다시 읽기'),
                    _buildCommandHint(context, '5분 타이머', '타이머 설정'),
                    _buildCommandHint(context, '느리게/빠르게', '말하기 속도 조절'),
                  ],
                ),
              ),
              
              const SizedBox(height: 80), // FAB 공간 확보
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommandHint(BuildContext context, String command, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              command,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showRecipeInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
            Text('조리시간: ${widget.recipe.durationMinutes}분'),
            if (widget.recipe.servings != null)
              Text('인분: ${widget.recipe.servings}'),
            if (widget.recipe.difficulty != null)
              Text('난이도: ${widget.recipe.difficulty}'),
            const SizedBox(height: 16),
            const Text('재료:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.recipe.ingredients.map((i) => Text('• $i')),
          ],
        ),
      ),
    );
  }
}
