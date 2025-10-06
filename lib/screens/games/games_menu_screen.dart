import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
              
              // Coming Soon
              const Text(
                'Coming Soon',
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
                      _buildComingSoonItem('Pac-Man', 'Classic maze game'),
                      _buildComingSoonItem('2048', 'Number puzzle game'),
                      _buildComingSoonItem('Sudoku', 'Logic puzzle game'),
                      _buildComingSoonItem('Memory Game', 'Test your memory'),
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

  Widget _buildComingSoonItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.grey,
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
                    color: Colors.grey,
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
          const Text(
            'Soon',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.metroOrange,
              fontWeight: FontWeight.bold,
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
    showAboutDialog(
      context: context,
      applicationName: 'DelhiGo Games',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.games,
        size: 48,
        color: AppTheme.metroGreen,
      ),
      children: [
        const Text('Enjoy classic games while traveling in Delhi!'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Snake Game - Classic arcade fun'),
        const Text('• Tetris - Block puzzle challenge'),
        const Text('• High score tracking'),
        const Text('• Pause and resume functionality'),
      ],
    );
  }
}
