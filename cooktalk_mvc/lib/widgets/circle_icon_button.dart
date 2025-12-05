import 'package:flutter/material.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.size = 40,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double size; // diameter
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final btn = Material(
      color: active ? scheme.primaryContainer : Colors.white70,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: active ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

