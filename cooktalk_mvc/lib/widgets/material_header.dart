import 'package:flutter/material.dart';

class MaterialHeader extends StatelessWidget {
  const MaterialHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.elevation = 2,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = MediaQuery.of(context).padding.top;
    return AnimatedPhysicalModel(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      color: scheme.surface.withValues(alpha: 0.95),
      elevation: elevation,
      shadowColor: Colors.black,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (actions != null) ...actions! else const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
