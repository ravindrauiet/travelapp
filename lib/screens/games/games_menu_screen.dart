import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../widgets/game_bottom_navigation.dart';
import '../../widgets/ui_kit.dart';
import 'game_chrome.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.background,
        drawer: _buildDrawer(context),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) => GradientHeader(
                  title: 'Games & Fun',
                  subtitle: 'Have fun while waiting for your metro or during your journey!',
                  gradient: AppTheme.royalGradient,
                  illustration: 'assets/images/illus_explore.svg',
                  leading: HeaderIconButton(
                    icon: Icons.menu_rounded,
                    tooltip: 'Menu',
                    onTap: () => Scaffold.of(context).openDrawer(),
                  ),
                  bottom: const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TagPill(label: '5 GAMES', color: Colors.white, icon: Icons.sports_esports_rounded, onDark: true),
                      TagPill(label: 'OFFLINE', color: Colors.white, icon: Icons.wifi_off_rounded, onDark: true),
                      TagPill(
                          label: 'HIGH SCORES', color: Colors.white, icon: Icons.emoji_events_rounded, onDark: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(
                title: 'Available Games',
                subtitle: 'Pick one and beat your best',
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _FeaturedGameCard(
                      title: 'Snake Game',
                      subtitle: 'Classic arcade game',
                      icon: Icons.gesture_rounded,
                      gradient: AppTheme.emeraldGradient,
                      onTap: () => context.push('/games/snake'),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.98,
                      children: [
                        _GameCard(
                          title: 'Block Drop',
                          subtitle: 'Block puzzle game',
                          icon: Icons.extension_rounded,
                          gradient: AppTheme.transitGradient,
                          onTap: () => context.push('/games/tetris'),
                        ),
                        _GameCard(
                          title: '2048',
                          subtitle: 'Number puzzle game',
                          icon: Icons.grid_view_rounded,
                          gradient: GamesPalette.amber,
                          onTap: () => context.push('/games/2048'),
                        ),
                        _GameCard(
                          title: 'Sky Hopper',
                          subtitle: 'Tap to fly game',
                          icon: Icons.flight_rounded,
                          gradient: AppTheme.oceanGradient,
                          onTap: () => context.push('/games/flappy-bird'),
                        ),
                        _GameCard(
                          title: 'Memory Game',
                          subtitle: 'Find matching pairs',
                          icon: Icons.psychology_rounded,
                          gradient: AppTheme.sunsetGradient,
                          onTap: () => context.push('/games/memory'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Game Features'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        context,
                        Icons.emoji_events_rounded,
                        'High Score Tracking',
                        'Keep track of your best scores',
                        AppTheme.metroOrange,
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureItem(
                        context,
                        Icons.pause_circle_rounded,
                        'Pause & Resume',
                        'Pause anytime and resume later',
                        AppTheme.metroBlue,
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureItem(
                        context,
                        Icons.keyboard_rounded,
                        'Keyboard Controls',
                        'Use arrow keys for precise control',
                        AppTheme.brandRose,
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureItem(
                        context,
                        Icons.touch_app_rounded,
                        'Touch Controls',
                        'Tap buttons for easy mobile play',
                        AppTheme.metroGreen,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Game Tips'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  color: p.cardAlt,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildTipItem(context, '🎮', 'Use touch controls for mobile gaming'),
                      _buildTipItem(context, '🏆', 'Try to beat your high scores'),
                      _buildTipItem(context, '⏸️', 'Pause games when needed'),
                      _buildTipItem(context, '🔄', 'Restart anytime to try again'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
        bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    final p = context.palette;
    return Row(
      children: [
        IconBubble(icon: icon, color: color, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(BuildContext context, String emoji, String tip) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: p.shadow,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final p = context.palette;
    Widget tile(IconData icon, Color color, String label, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: IconBubble(icon: icon, color: color, size: 38, radius: 12),
          title: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary, fontSize: 14.5),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: p.textTertiary, size: 18),
          onTap: onTap,
        ),
      );
    }

    return Drawer(
      backgroundColor: p.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 22, 20, 24),
            decoration: const BoxDecoration(gradient: AppTheme.royalGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: SvgPicture.asset('assets/images/logo.svg', width: 40, height: 40),
                    ),
                    const Spacer(),
                    const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 30),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Games & Entertainment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Have fun while traveling',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          tile(Icons.home_rounded, AppTheme.accentColor, 'Home', () {
            Navigator.pop(context);
            context.go('/');
          }),
          tile(Icons.train_rounded, AppTheme.metroBlue, 'Metro Services', () {
            Navigator.pop(context);
            context.go('/metro');
          }),
          tile(Icons.directions_bus_rounded, AppTheme.metroGreen, 'Bus Services', () {
            Navigator.pop(context);
            context.go('/bus');
          }),
          tile(Icons.local_taxi_rounded, AppTheme.metroOrange, 'Other Transport', () {
            Navigator.pop(context);
            context.go('/transport');
          }),
          tile(Icons.sports_esports_rounded, AppTheme.brandViolet, 'Games', () {
            Navigator.pop(context);
            context.go('/games');
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Divider(color: p.border),
          ),
          tile(Icons.info_rounded, AppTheme.metroGrey, 'About', () {
            Navigator.pop(context);
            _showAboutDialog(context);
          }),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final p = context.palette;
        TextStyle heading() => TextStyle(fontWeight: FontWeight.w800, color: p.textPrimary);
        TextStyle body() => TextStyle(color: p.textSecondary, height: 1.5);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              IconBubble(
                icon: Icons.sports_esports_rounded,
                color: AppTheme.brandViolet,
                filled: true,
                size: 40,
                radius: 12,
              ),
              SizedBox(width: 10),
              Expanded(child: Text('Metromate Games')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TagPill(label: 'VERSION 1.0.0', color: AppTheme.brandViolet),
                const SizedBox(height: 16),
                Text('Enjoy classic games while traveling in Delhi!', style: body()),
                const SizedBox(height: 16),
                Text('Available Games:', style: heading()),
                const SizedBox(height: 8),
                Text('• Snake Game - Classic arcade fun', style: body()),
                Text('• Tetris - Block puzzle challenge', style: body()),
                Text('• 2048 - Number puzzle game', style: body()),
                Text('• Flappy Bird - Tap to fly game', style: body()),
                Text('• Memory Game - Find matching pairs', style: body()),
                const SizedBox(height: 16),
                Text('Features:', style: heading()),
                const SizedBox(height: 8),
                Text('• Touch controls for mobile', style: body()),
                Text('• High score tracking', style: body()),
                Text('• Pause and resume functionality', style: body()),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.tint(AppTheme.warningColor),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Important Disclaimer',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This app is not affiliated with, endorsed by, or connected to any government entity including Delhi Metro Rail Corporation (DMRC) or Delhi Transport Corporation (DTC). Metromate is an independent third-party application.',
                        style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Official Government Sources:', style: heading()),
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
    final linkColor = context.palette.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
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
            Icon(Icons.link_rounded, size: 16, color: linkColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: linkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: linkColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide hero card for the featured game.
class _FeaturedGameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeaturedGameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        boxShadow: AppTheme.glow(gradient.colors.last, alpha: 0.3),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -24,
                  child: Icon(icon, size: 140, color: Colors.white.withValues(alpha: 0.12)),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Icon(icon, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TagPill(
                                label: 'FEATURED', color: Colors.white, icon: Icons.star_rounded, onDark: true),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.play_arrow_rounded, color: gradient.colors.first, size: 28),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Colourful gradient tile for a game in the grid.
class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        boxShadow: AppTheme.glow(gradient.colors.last, alpha: 0.28),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: Icon(icon, size: 96, color: Colors.white.withValues(alpha: 0.13)),
                ),
                // Fixed-size tile: cap text scaling so large accessibility text fits.
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.1,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const Spacer(),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const TagPill(label: 'PLAY', color: Colors.white, icon: Icons.play_arrow_rounded, onDark: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
