import 'package:flutter/material.dart';

class CookTalkWelcome extends StatelessWidget {
  final String userName;
  final int todayRecipeCount;

  const CookTalkWelcome({
    super.key,
    this.userName = '요리사',
    this.todayRecipeCount = 0,
  });

  static const List<String> _greetings = [
    '오늘도 맛있는 요리 해볼까요?',
    '새로운 레시피에 도전해보세요!',
    '함께 요리하며 즐거운 시간 보내요!',
    '오늘의 요리 여행을 시작해봐요!',
  ];

  String get _randomGreeting {
    final index = DateTime.now().hour % _greetings.length;
    return _greetings[index];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: scheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, $userName님! 👋',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _randomGreeting,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (todayRecipeCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '오늘 $todayRecipeCount개의 새 레시피',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
