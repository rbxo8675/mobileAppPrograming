import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import 'package:cooktalk/models/recipe.dart';
import 'package:cooktalk/providers/session_provider.dart';
import 'package:cooktalk/widgets/quick_commands.dart';

class CookingSessionScreen extends StatefulWidget {
  final Recipe recipe;

  const CookingSessionScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<CookingSessionScreen> createState() => _CookingSessionScreenState();
}

class _CookingSessionScreenState extends State<CookingSessionScreen> {
  @override
  void initState() {
    super.initState();
    // 세션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().startSession(widget.recipe);
      // 화면 꺼짐 방지
      WakelockPlus.enable();
    });
  }

  @override
  void dispose() {
    // 세션 종료
    context.read<SessionProvider>().endSession();
    // 화면 꺼짐 방지 해제
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<SessionProvider>(
            builder: (context, session, child) {
              return Text(
                '${session.currentStepIndex + 1}/${session.totalSteps}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.currentRecipe == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 상단 정보 영역
              _buildTopSection(session),
              
              // 메인 콘텐츠 영역
              Expanded(
                child: _buildMainContent(session),
              ),
              
              // 하단 퀵 커맨드 영역
              _buildBottomSection(session),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSection(SessionProvider session) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 진행률 표시
          LinearProgressIndicator(
            value: session.recipeProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(session.recipeProgress * 100).toInt()}% 완료',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(SessionProvider session) {
    final currentStep = session.currentStep;
    if (currentStep == null) {
      return const Center(child: Text('단계를 불러올 수 없습니다.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 현재 단계 카드
          Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // 단계 번호
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${currentStep.order}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 단계 설명
                  Text(
                    currentStep.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // 타이머 표시
                  if (session.hasTimer) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: session.isTimerRunning 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: session.isTimerRunning ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            session.isTimerRunning ? Icons.timer : Icons.pause,
                            color: session.isTimerRunning ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            session.formattedTimer,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: session.isTimerRunning ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 타이머 진행률
                    if (session.currentTimerSec > 0) ...[
                      LinearProgressIndicator(
                        value: session.stepProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          session.isTimerRunning ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(session.stepProgress * 100).toInt()}% 완료',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 마이크 버튼
          _buildMicrophoneButton(session),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton(SessionProvider session) {
    final isDisabled = session.speaking || session.listening;
    
    return GestureDetector(
      onTap: isDisabled ? null : () async {
        if (session.listening) {
          await session.stopVoiceRecognition();
        } else {
          await session.startVoiceRecognition();
        }
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: isDisabled 
              ? Colors.grey[300]
              : session.listening 
                  ? Colors.red
                  : Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          session.listening ? Icons.mic : Icons.mic_none,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomSection(SessionProvider session) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: QuickCommands(
        onNext: session.nextStep,
        onPrev: session.prevStep,
        onRepeat: session.repeatStep,
        onTimer3Min: () => session.startTimer(180),
        onPause: session.pauseTimer,
        onResume: session.resumeTimer,
        isFirstStep: session.isFirstStep,
        isLastStep: session.isLastStep,
        hasTimer: session.hasTimer,
        isTimerRunning: session.isTimerRunning,
      ),
    );
  }
}
