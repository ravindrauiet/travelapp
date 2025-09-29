import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;

  const AppDrawer({
    super.key,
    required this.title,
    required this.subtitle,
    this.primaryColor = AppTheme.primaryColor,
    this.secondaryColor = AppTheme.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
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
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: AppTheme.primaryColor),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.train, color: AppTheme.metroBlue),
            title: const Text('Metro Services'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate, color: AppTheme.metroBlue),
            title: const Text('Fare Calculator'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/fare-calculator');
            },
          ),
          ListTile(
            leading: const Icon(Icons.route, color: AppTheme.metroRed),
            title: const Text('Route Finder'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/route-finder');
            },
          ),
          ListTile(
            leading: const Icon(Icons.update, color: AppTheme.metroGreen),
            title: const Text('Live Updates'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/live-updates');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.directions_bus, color: AppTheme.infoColor),
            title: const Text('Bus Services'),
            onTap: () {
              Navigator.pop(context);
              context.go('/bus');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_taxi, color: AppTheme.accentColor),
            title: const Text('Other Transport'),
            onTap: () {
              Navigator.pop(context);
              context.go('/transport');
            },
          ),
          ListTile(
            leading: const Icon(Icons.place, color: AppTheme.metroMagenta),
            title: const Text('Tourist Spots'),
            onTap: () {
              Navigator.pop(context);
              context.go('/tourist-spots');
            },
          ),
          ListTile(
            leading: const Icon(Icons.emergency, color: AppTheme.errorColor),
            title: const Text('Emergency'),
            onTap: () {
              Navigator.pop(context);
              context.go('/emergency');
            },
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny, color: AppTheme.warningColor),
            title: const Text('Weather'),
            onTap: () {
              Navigator.pop(context);
              context.go('/weather');
            },
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
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
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.grey),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Delhi Travel Guide',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.train,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'A comprehensive travel and navigation app for Delhi with metro, bus, and other transport features.',
        ),
      ],
    );
  }
}




