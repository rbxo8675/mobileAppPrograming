import 'dart:math';
import 'package:flutter/material.dart';

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key, required this.userName, required this.todayCount});
  final String userName;
  final int todayCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final greetings = <String>[
      '오늘도 맛있게 요리해볼까요?',
      '레시피 탐험을 시작해요!',
      '함께 요리하며 즐거운 시간 보내요!',
      '오늘의 요리 여정을 시작해봐요!',
    ];
    final greet = greetings[Random().nextInt(greetings.length)];

    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primary,
            child: Text(
              userName.isNotEmpty ? userName.characters.first.toUpperCase() : 'C',
              style: TextStyle(color: scheme.onPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, $userName 님',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  greet,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (todayCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '오늘 추천 레시피 $todayCount개가 준비됐어요! ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
