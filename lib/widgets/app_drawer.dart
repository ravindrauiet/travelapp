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
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
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
            title: const Text('Metro'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro');
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus, color: AppTheme.metroGreen),
            title: const Text('Bus'),
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
            leading: const Icon(Icons.location_city, color: AppTheme.metroPurple),
            title: const Text('Tourist Spots'),
            onTap: () {
              Navigator.pop(context);
              context.go('/tourist-spots');
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
          ListTile(
            leading: const Icon(Icons.emergency, color: Colors.red),
            title: const Text('Emergency'),
            onTap: () {
              Navigator.pop(context);
              context.go('/emergency');
            },
          ),
          ListTile(
            leading: const Icon(Icons.games, color: AppTheme.metroOrange),
            title: const Text('Games'),
            onTap: () {
              Navigator.pop(context);
              context.go('/games');
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
      applicationName: 'Metromate',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.train,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'Your Smart Travel Companion for Delhi. Navigate the city with ease using metro, bus, and other transport options.',
        ),
      ],
    );
  }
}