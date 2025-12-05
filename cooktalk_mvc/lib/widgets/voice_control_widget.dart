import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cooking_assistant_controller.dart';

class VoiceControlWidget extends StatelessWidget {
  const VoiceControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CookingAssistantController>();
    final scheme = Theme.of(context).colorScheme;

    if (!controller.voiceMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: controller.isListening ? scheme.primary : scheme.onSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isListening ? '듣는 중...' : '음성 명령 대기',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: controller.isListening ? scheme.primary : null,
                        ),
                      ),
                      Text(
                        '다음, 이전, 타이머, 다시 등',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (controller.isListening)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(scheme.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _QuickCommandChip(
                  label: '다음',
                  icon: Icons.skip_next,
                  onTap: () async {
                    await controller.voiceOrchestrator.nextStep();
                  },
                ),
                _QuickCommandChip(
                  label: '이전',
                  icon: Icons.skip_previous,
                  onTap: () async {
                    await controller.voiceOrchestrator.previousStep();
                  },
                ),
                _QuickCommandChip(
                  label: '다시',
                  icon: Icons.replay,
                  onTap: () async {
                    await controller.voiceOrchestrator.readCurrentStep();
                  },
                ),
                _QuickCommandChip(
                  label: '3분 타이머',
                  icon: Icons.timer,
                  onTap: () async {
                    await controller.voiceOrchestrator.startTimer(180, label: '3분');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCommandChip extends StatelessWidget {
  const _QuickCommandChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: scheme.secondaryContainer,
      labelStyle: TextStyle(
        color: scheme.onSecondaryContainer,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
