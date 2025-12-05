import 'package:flutter/material.dart';

Future<void> showFabMenu(
  BuildContext context, {
  required VoidCallback onAddManual,
  required VoidCallback onExtractYoutube,
  VoidCallback? onScanRecipe,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'fab-menu',
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (_, __, ___) {
      final scheme = Theme.of(context).colorScheme;
      return Stack(
        children: [
          // Close area
          Positioned.fill(
            child: GestureDetector(onTap: () => Navigator.pop(context)),
          ),
          // Menu cluster near bottom-right, above the FAB position
          Positioned(
            right: 24,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (onScanRecipe != null) ...[
                  _MenuPill(
                    icon: Icons.document_scanner,
                    label: '레시피북 스캔',
                    onTap: () {
                      Navigator.pop(context);
                      onScanRecipe();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _MenuPill(
                  icon: Icons.ondemand_video,
                  label: '유튜브 추출',
                  onTap: () {
                    Navigator.pop(context);
                    onExtractYoutube();
                  },
                ),
                const SizedBox(height: 12),
                _MenuPill(
                  icon: Icons.add,
                  label: '레시피 추가',
                  onTap: () {
                    Navigator.pop(context);
                    onAddManual();
                  },
                ),
                const SizedBox(height: 12),
                Material(
                  color: scheme.tertiaryContainer,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(Icons.close, color: scheme.onTertiaryContainer),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
    transitionBuilder: (_, anim, __, child) {
      final slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOut))
          .animate(anim);
      return FadeTransition(opacity: anim, child: SlideTransition(position: slide, child: child));
    },
  );
}

class _MenuPill extends StatelessWidget {
  const _MenuPill({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

