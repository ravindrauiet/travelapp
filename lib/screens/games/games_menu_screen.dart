import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../widgets/game_bottom_navigation.dart';
import '../../widgets/compact_feature_card.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games & Entertainment'),
        backgroundColor: AppTheme.metroGreen,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.metroGreen.withOpacity(0.1),
              AppTheme.metroBlue.withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.games,
                        size: 64,
                        color: AppTheme.metroGreen,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Games & Entertainment',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.metroGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Have fun while waiting for your metro or during your journey!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Available Games
              const Text(
                'Available Games',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  CompactFeatureCard(
                    title: 'Snake Game',
                    subtitle: 'Classic arcade game',
                    icon: Icons.games,
                    color: AppTheme.metroGreen,
                    onTap: () => context.go('/games/snake'),
                  ),
                  CompactFeatureCard(
                    title: 'Tetris',
                    subtitle: 'Block puzzle game',
                    icon: Icons.extension,
                    color: AppTheme.metroBlue,
                    onTap: () => context.go('/games/tetris'),
                  ),
                  CompactFeatureCard(
                    title: '2048',
                    subtitle: 'Number puzzle game',
                    icon: Icons.calculate,
                    color: AppTheme.metroOrange,
                    onTap: () => context.go('/games/2048'),
                  ),
                  CompactFeatureCard(
                    title: 'Flappy Bird',
                    subtitle: 'Tap to fly game',
                    icon: Icons.flight,
                    color: AppTheme.metroRed,
                    onTap: () => context.go('/games/flappy-bird'),
                  ),
                  CompactFeatureCard(
                    title: 'Memory Game',
                    subtitle: 'Find matching pairs',
                    icon: Icons.psychology,
                    color: AppTheme.metroPurple,
                    onTap: () => context.go('/games/memory'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Game Features
              const Text(
                'Game Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        Icons.score,
                        'High Score Tracking',
                        'Keep track of your best scores',
                        AppTheme.metroOrange,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        Icons.pause,
                        'Pause & Resume',
                        'Pause anytime and resume later',
                        AppTheme.metroBlue,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        Icons.keyboard,
                        'Keyboard Controls',
                        'Use arrow keys for precise control',
                        AppTheme.metroRed,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        Icons.touch_app,
                        'Touch Controls',
                        'Tap buttons for easy mobile play',
                        AppTheme.metroGreen,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Game Tips
              const Text(
                'Game Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTipItem('🎮', 'Use touch controls for mobile gaming'),
                      _buildTipItem('🏆', 'Try to beat your high scores'),
                      _buildTipItem('⏸️', 'Pause games when needed'),
                      _buildTipItem('🔄', 'Restart anytime to try again'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.metroGreen, AppTheme.metroBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.games,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Games & Entertainment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Have fun while traveling',
                  style: TextStyle(
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
            leading: const Icon(Icons.games, color: AppTheme.metroGreen),
            title: const Text('Games'),
            onTap: () {
              Navigator.pop(context);
              context.go('/games');
            },
          ),
          const Divider(),
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
                Icons.games,
                color: AppTheme.metroGreen,
                size: 32,
              ),
              const SizedBox(width: 8),
              const Text('Metromate Games'),
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
                const Text('Enjoy classic games while traveling in Delhi!'),
                const SizedBox(height: 16),
                const Text(
                  'Available Games:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Snake Game - Classic arcade fun'),
                const Text('• Tetris - Block puzzle challenge'),
                const Text('• 2048 - Number puzzle game'),
                const Text('• Flappy Bird - Tap to fly game'),
                const Text('• Memory Game - Find matching pairs'),
                const SizedBox(height: 16),
                const Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Touch controls for mobile'),
                const Text('• High score tracking'),
                const Text('• Pause and resume functionality'),
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
