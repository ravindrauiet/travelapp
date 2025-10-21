import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../providers/theme_provider.dart';

class TabletNavigation extends StatelessWidget {
  final int currentIndex;

  const TabletNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.train,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Metromate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Your travel companion',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  index: 0,
                  onTap: () => context.go('/'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.train,
                  title: 'Metro Services',
                  index: 1,
                  onTap: () => context.go('/metro'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.directions_bus,
                  title: 'Bus Services',
                  index: 2,
                  onTap: () => context.go('/bus'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.local_taxi,
                  title: 'Other Transport',
                  index: 3,
                  onTap: () => context.go('/transport'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.wb_sunny,
                  title: 'Weather',
                  index: 4,
                  onTap: () => context.go('/weather'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.map,
                  title: 'Metro Map',
                  index: 5,
                  onTap: () => context.go('/metro/map'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.directions_bus,
                  title: 'Bus Map',
                  index: 6,
                  onTap: () => context.go('/bus/map'),
                ),
                const Divider(height: 32),
                _buildNavItem(
                  context,
                  icon: Icons.place,
                  title: 'Tourist Spots',
                  index: 7,
                  onTap: () => context.go('/tourist-spots'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.emergency,
                  title: 'Emergency',
                  index: 8,
                  onTap: () => context.go('/emergency'),
                ),
              ],
            ),
          ),
          
          // Theme Toggle
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      themeProvider.themeIcon,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text('Theme: ${themeProvider.themeModeName}'),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    onTap: () {
                      themeProvider.toggleTheme();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : Theme.of(context).iconTheme.color,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }
}
