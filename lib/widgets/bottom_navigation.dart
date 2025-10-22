import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_theme.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                color: AppTheme.primaryColor,
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.train_outlined,
                activeIcon: Icons.train,
                label: 'Metro',
                color: AppTheme.metroBlue,
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.directions_bus_outlined,
                activeIcon: Icons.directions_bus,
                label: 'Bus',
                color: AppTheme.metroGreen,
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.local_taxi_outlined,
                activeIcon: Icons.local_taxi,
                label: 'Transport',
                color: AppTheme.accentColor,
              ),
              _buildNavItem(
                context,
                index: 4,
                icon: Icons.wb_sunny_outlined,
                activeIcon: Icons.wb_sunny,
                label: 'Weather',
                color: AppTheme.warningColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
  }) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/metro');
            break;
          case 2:
            context.go('/bus');
            break;
          case 3:
            context.go('/transport');
            break;
          case 4:
            context.go('/weather');
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}