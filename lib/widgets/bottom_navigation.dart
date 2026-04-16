import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      color: Color(0xFF1976D2),
      route: '/',
    ),
    _NavItem(
      label: 'Metro',
      icon: Icons.train_outlined,
      activeIcon: Icons.train_rounded,
      color: Color(0xFF1565C0),
      route: '/metro',
    ),
    _NavItem(
      label: 'Bus',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus_rounded,
      color: Color(0xFF2E7D32),
      route: '/bus',
    ),
    _NavItem(
      label: 'Transport',
      icon: Icons.local_taxi_outlined,
      activeIcon: Icons.local_taxi_rounded,
      color: Color(0xFFE65100),
      route: '/transport',
    ),
    _NavItem(
      label: 'Weather',
      icon: Icons.wb_sunny_outlined,
      activeIcon: Icons.wb_sunny_rounded,
      color: Color(0xFFF57F17),
      route: '/weather',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
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
                    ? item.color.withValues(alpha: 0.13)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? item.color : const Color(0xFF9E9E9E),
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
                color: isSelected ? item.color : const Color(0xFF9E9E9E),
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              child: Text(item.label),
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
