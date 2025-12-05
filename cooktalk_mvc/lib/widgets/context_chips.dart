import 'package:flutter/material.dart';

class ContextChips extends StatelessWidget {
  const ContextChips({super.key});

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '아침';
    if (hour < 17) return '점심';
    if (hour < 21) return '저녁';
    return '야식';
  }

  String _getWeatherContext() {
    return '맑음';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeOfDay = _getTimeOfDay();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ContextChip(
          icon: _getTimeIcon(timeOfDay),
          label: timeOfDay,
          color: scheme.primaryContainer,
          textColor: scheme.onPrimaryContainer,
        ),
        _ContextChip(
          icon: Icons.wb_sunny,
          label: _getWeatherContext(),
          color: scheme.secondaryContainer,
          textColor: scheme.onSecondaryContainer,
        ),
        _ContextChip(
          icon: Icons.location_on,
          label: '서울',
          color: scheme.tertiaryContainer,
          textColor: scheme.onTertiaryContainer,
        ),
      ],
    );
  }

  IconData _getTimeIcon(String timeOfDay) {
    switch (timeOfDay) {
      case '아침':
        return Icons.wb_sunny;
      case '점심':
        return Icons.lunch_dining;
      case '저녁':
        return Icons.dinner_dining;
      case '야식':
        return Icons.nightlight_round;
      default:
        return Icons.restaurant;
    }
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
