import 'package:flutter/material.dart';

class HomeStats extends StatelessWidget {
  final int completedCount;
  final int weeklyGoal;
  final bool cookedToday;

  const HomeStats({
    super.key,
    required this.completedCount,
    this.weeklyGoal = 7,
    this.cookedToday = false,
  });

  double get goalProgress => 
      (completedCount / weeklyGoal * 100).clamp(0.0, 100.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTodayStatus(context),
        const SizedBox(height: 12),
        _buildWeeklyGoal(context),
      ],
    );
  }

  Widget _buildTodayStatus(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '오늘의 요리',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (cookedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '완료!',
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '🎉',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (cookedToday)
              Text(
                '오늘도 멋진 요리를 완성하셨네요! 👨‍🍳',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘 어떤 요리를 만들어볼까요?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '💡',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '"오늘의 추천 레시피"를 확인해보세요!',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoal(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isGoalComplete = goalProgress >= 100;

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
                Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '이번 주 목표',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '주 $weeklyGoal회 요리 목표',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$completedCount / $weeklyGoal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goalProgress / 100,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalComplete ? const Color(0xFF166534) : scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isGoalComplete)
              Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '이번 주 목표를 달성했어요!',
                    style: TextStyle(
                      color: const Color(0xFF166534),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Text(
                '목표까지 ${weeklyGoal - completedCount}번 더 요리하면 됩니다!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
