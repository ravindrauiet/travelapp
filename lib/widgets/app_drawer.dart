import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.train,
                color: AppTheme.primaryColor,
                size: 32,
              ),
              const SizedBox(width: 8),
              const Text('Metromate'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Smart Travel Companion for Delhi. Navigate the city with ease using metro, bus, and other transport options.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Important Disclaimer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This app is not affiliated with, endorsed by, or connected to any government entity including Delhi Metro Rail Corporation (DMRC) or Delhi Transport Corporation (DTC). Metromate is an independent third-party application.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Official Government Sources:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildSourceLink(
                  context,
                  'Delhi Metro',
                  'https://www.delhimetrorail.com',
                ),
                const SizedBox(height: 4),
                _buildSourceLink(
                  context,
                  'DTC (Delhi Transport Corporation)',
                  'https://www.dtc.nic.in',
                ),
                const SizedBox(height: 4),
                _buildSourceLink(
                  context,
                  'Delhi Transport Department',
                  'http://www.delhi.gov.in/transport/',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSourceLink(BuildContext context, String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.link, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}