import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/app_drawer.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../providers/weather_provider.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context),
      drawer: isTablet ? null : const AppDrawer(
        title: 'Metromate',
        subtitle: 'Your Delhi Travel Companion',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(context),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildServicesSection(context),
            const SizedBox(height: 20),
            _buildWeatherSection(context),
            const SizedBox(height: 20),
            _buildMetroStats(),
            const SizedBox(height: 20),
            _buildQuickAccess(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.black87),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.metroBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.train, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Metromate',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
          onPressed: () => _showNotificationsSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => context.push('/metro/route-finder'),
        ),
      ],
    );
  }

  // ── Hero / Welcome Section ─────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.metroBlue,
            AppTheme.metroBlue.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.metroBlue.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_city, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Welcome to Delhi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Text(
                      'Your Complete Travel Companion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int itemsPerRow = width < 300 ? 1 : 3;
              final double spacing = 12.0;
              final double itemWidth = (width - ((itemsPerRow - 1) * spacing)) / itemsPerRow;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildHeroStat('Routes', '156', Icons.route, itemWidth),
                  _buildHeroStat('Stations', '262', Icons.train, itemWidth),
                  _buildHeroStat('Lines', '12', Icons.linear_scale, itemWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, IconData icon, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int itemsPerRow = width < 360 ? 2 : 4;
              final double spacing = 12.0;
              final double itemWidth = (width - ((itemsPerRow - 1) * spacing)) / itemsPerRow;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildActionCard(
                    'Find Route',
                    Icons.directions,
                    AppTheme.metroBlue,
                    () => context.push('/metro/route-finder'),
                    itemWidth,
                  ),
                  _buildActionCard(
                    'Fare Check',
                    Icons.calculate,
                    AppTheme.metroGreen,
                    () => context.push('/metro/fare-calculator'),
                    itemWidth,
                  ),
                  _buildActionCard(
                    'Live Updates',
                    Icons.update,
                    AppTheme.metroOrange,
                    () => context.push('/metro/live-updates'),
                    itemWidth,
                  ),
                  _buildActionCard(
                    'Metro Map',
                    Icons.map,
                    AppTheme.metroRed,
                    () => context.push('/metro/pdf-viewer'),
                    itemWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap, double width) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Services Section ───────────────────────────────────────────────────────

  Widget _buildServicesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transport Services',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int itemsPerRow = width < 320 ? 1 : 3;
              final double spacing = 12.0;
              final double itemWidth = (width - ((itemsPerRow - 1) * spacing)) / itemsPerRow;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildServiceCard(
                    'Metro',
                    'DMRC Rail',
                    Icons.train,
                    AppTheme.metroBlue,
                    '12 lines',
                    () => context.push('/metro'),
                    itemWidth,
                  ),
                  _buildServiceCard(
                    'Bus',
                    'DTC & Cluster',
                    Icons.directions_bus,
                    AppTheme.metroGreen,
                    '700+ routes',
                    () => context.push('/bus'),
                    itemWidth,
                  ),
                  _buildServiceCard(
                    'Transport',
                    'Taxi & Auto',
                    Icons.local_taxi,
                    AppTheme.metroOrange,
                    'On demand',
                    () => context.push('/transport'),
                    itemWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String badge,
    VoidCallback onTap,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Weather Section ────────────────────────────────────────────────────────

  Widget _buildWeatherSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/weather'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Consumer<WeatherProvider>(
            builder: (context, wp, _) {
              if (wp.isLoading) {
                return const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading weather…',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                );
              }
              if (wp.error != null) {
                return const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Weather unavailable',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                );
              }
              final w = wp.currentWeather;
              return Row(
                children: [
                  Icon(_weatherIcon(w?.description ?? ''),
                      color: Colors.blue, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${w?.temperature?.round() ?? '--'}°C  •  Delhi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          w?.description ?? 'Tap for full forecast',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Metro Stats ────────────────────────────────────────────────────────────

  Widget _buildMetroStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delhi Metro at a Glance',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int itemsPerRow = width < 320 ? 1 : 3;
              final double spacing = 12.0;
              final double itemWidth = (width - ((itemsPerRow - 1) * spacing)) / itemsPerRow;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildStatCard('Lines', '12', Icons.linear_scale, Colors.blue, itemWidth),
                  _buildStatCard('Stations', '262', Icons.location_on, Colors.green, itemWidth),
                  _buildStatCard('Daily Riders', '2.8M', Icons.people, Colors.orange, itemWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Access ───────────────────────────────────────────────────────────

  Widget _buildQuickAccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More Services',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int itemsPerRow = width < 360 ? 2 : 4;
              final double spacing = 12.0;
              final double itemWidth = (width - ((itemsPerRow - 1) * spacing)) / itemsPerRow;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildAccessCard('Tourist\nSpots', Icons.place, AppTheme.metroPink,
                      () => context.push('/tourist-spots'), itemWidth),
                  _buildAccessCard('Emergency', Icons.emergency, AppTheme.metroRed,
                      () => context.push('/emergency'), itemWidth),
                  _buildAccessCard('Weather', Icons.wb_sunny, AppTheme.metroYellow,
                      () => context.push('/weather'), itemWidth),
                  _buildAccessCard('Games', Icons.games, AppTheme.metroPurple,
                      () => context.push('/games'), itemWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard(
      String title, IconData icon, Color color, VoidCallback onTap, double width) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  IconData _weatherIcon(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('clear')) return Icons.wb_sunny;
    if (d.contains('cloud')) return Icons.wb_cloudy;
    if (d.contains('rain') || d.contains('shower')) return Icons.grain;
    if (d.contains('thunder')) return Icons.flash_on;
    if (d.contains('snow')) return Icons.ac_unit;
    if (d.contains('mist') || d.contains('fog')) return Icons.blur_on;
    return Icons.wb_sunny;
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _notifTile(
              Icons.train,
              AppTheme.metroBlue,
              'Blue Line — Normal service',
              'All stations operating on schedule',
            ),
            _notifTile(
              Icons.warning_amber,
              Colors.orange,
              'Yellow Line — Minor delay',
              'Trains running 3–5 min late due to maintenance',
            ),
            _notifTile(
              Icons.info_outline,
              AppTheme.metroGreen,
              'Tip: Use smart card',
              'Save 10% on every journey',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(
      IconData icon, Color color, String title, String subtitle) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle:
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
