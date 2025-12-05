import 'package:flutter/material.dart';

class MaterialBottomNav extends StatelessWidget {
  const MaterialBottomNav({
    super.key,
    required this.activeIndex,
    required this.onChanged,
    this.showActiveBadge = true,
  });

  final int activeIndex;
  final ValueChanged<int> onChanged;
  final bool showActiveBadge; // show a small red dot on the active tab

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.home_outlined, label: '홈'),
    (icon: Icons.trending_up, label: '인기'),
    (icon: Icons.people_alt_outlined, label: '피드'),
    (icon: Icons.menu_book_outlined, label: '레시피'),
    (icon: Icons.person_outline, label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: const [
              BoxShadow(blurRadius: 8, color: Color(0x1F000000)),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                Expanded(
                  child: _NavItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    active: i == activeIndex,
                    showBadge: showActiveBadge && i == activeIndex,
                    onTap: () => onChanged(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.showBadge = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final circleBg = active ? scheme.secondaryContainer : Colors.transparent;
    final fg = active ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: fg, size: 22),
                  ),
                  if (showBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: scheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
