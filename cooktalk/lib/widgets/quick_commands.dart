import 'package:flutter/material.dart';

class QuickCommands extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onRepeat;
  final VoidCallback onTimer3Min;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final bool isFirstStep;
  final bool isLastStep;
  final bool hasTimer;
  final bool isTimerRunning;

  const QuickCommands({
    super.key,
    required this.onNext,
    required this.onPrev,
    required this.onRepeat,
    required this.onTimer3Min,
    required this.onPause,
    required this.onResume,
    required this.isFirstStep,
    required this.isLastStep,
    required this.hasTimer,
    required this.isTimerRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 첫 번째 행: 다음/이전/다시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCommandButton(
              context,
              icon: Icons.skip_previous,
              label: '이전',
              onPressed: isFirstStep ? null : onPrev,
              color: Colors.blue,
            ),
            _buildCommandButton(
              context,
              icon: Icons.replay,
              label: '다시',
              onPressed: onRepeat,
              color: Colors.orange,
            ),
            _buildCommandButton(
              context,
              icon: Icons.skip_next,
              label: '다음',
              onPressed: isLastStep ? null : onNext,
              color: Colors.green,
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 두 번째 행: 타이머/일시정지/재개
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCommandButton(
              context,
              icon: Icons.timer,
              label: '3분',
              onPressed: onTimer3Min,
              color: Colors.purple,
            ),
            _buildCommandButton(
              context,
              icon: Icons.pause,
              label: '일시정지',
              onPressed: (hasTimer && isTimerRunning) ? onPause : null,
              color: Colors.red,
            ),
            _buildCommandButton(
              context,
              icon: Icons.play_arrow,
              label: '재개',
              onPressed: (hasTimer && !isTimerRunning && isTimerRunning != null) ? onResume : null,
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommandButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    final isDisabled = onPressed == null;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? Colors.grey[300] : color,
            foregroundColor: isDisabled ? Colors.grey[600] : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isDisabled ? 0 : 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
