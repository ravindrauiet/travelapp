import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'ui_kit.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  static const _items = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      color: Color(0xFF4F46E5),
      route: '/',
    ),
    _NavItem(
      label: 'Metro',
      icon: Icons.train_outlined,
      activeIcon: Icons.train_rounded,
      color: Color(0xFF2563EB),
      route: '/metro',
    ),
    _NavItem(
      label: 'Bus',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus_rounded,
      color: Color(0xFF16A34A),
      route: '/bus',
    ),
    _NavItem(
      label: 'Transport',
      icon: Icons.local_taxi_outlined,
      activeIcon: Icons.local_taxi_rounded,
      color: Color(0xFFEA580C),
      route: '/transport',
    ),
    _NavItem(
      label: 'Weather',
      icon: Icons.wb_sunny_outlined,
      activeIcon: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
      route: '/weather',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final navBg = context.palette.surface;
    final borderColor = context.palette.border;

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? Border.all(color: borderColor) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x1A1E1B4B),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              return Expanded(
                child: _NavButton(
                  item: _items[i],
                  isSelected: currentIndex == i,
                  onTap: () {
                    if (currentIndex != i) context.go(_items[i].route);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Single nav button ─────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon pill — highlighted when active
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isSelected ? 52 : 36,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? item.color.withValues(alpha: context.isDark ? 0.22 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? item.color : context.palette.textTertiary,
                    size: 22,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 3),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? item.color : context.palette.textTertiary,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              // Clamp scaling so large accessibility text cannot overflow the 64px bar.
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
    required this.route,
  });
}
