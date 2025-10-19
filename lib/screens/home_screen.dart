import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/feature_card.dart';
import '../widgets/compact_feature_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tablet_navigation.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    if (isTablet || isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            TabletNavigation(currentIndex: 0),
            Expanded(
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Delhi Travel Guide'),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          // Handle notifications
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: _buildBody(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delhi Travel Guide'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      drawer: const AppDrawer(
        title: 'Delhi Travel Guide',
        subtitle: 'Your travel companion',
      ),
      body: _buildBody(context),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
            padding: ResponsiveHelper.getScreenPadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.getMaxContentWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveHelper.getCardPadding(context)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.location_city,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome to Delhi!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Navigate the city with ease using our comprehensive travel guide',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.isMobile(context) ? 20 : 24),
                      _buildResponsiveStats(context),
                    ],
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                
                // Metro Features
                _buildSectionHeader(
                  '🚇 Metro Services',
                  'Plan your metro journey',
                  () => context.go('/metro'),
                ),
                SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4, // More compact grid
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0, // Square boxes
                  children: [
                    CompactFeatureCard(
                      title: 'Fare Calculator',
                      subtitle: '',
                      icon: Icons.calculate,
                      color: AppTheme.metroBlue,
                      onTap: () => context.go('/metro/fare-calculator'),
                    ),
                    CompactFeatureCard(
                      title: 'Route Finder',
                      subtitle: '',
                      icon: Icons.route,
                      color: AppTheme.metroRed,
                      onTap: () => context.go('/metro/route-finder'),
                    ),
                    CompactFeatureCard(
                      title: 'Live Updates',
                      subtitle: '',
                      icon: Icons.update,
                      color: AppTheme.metroGreen,
                      onTap: () => context.go('/metro/live-updates'),
                    ),
                    CompactFeatureCard(
                      title: 'Metro Map',
                      subtitle: '',
                      icon: Icons.map,
                      color: AppTheme.metroViolet,
                      onTap: () => context.go('/metro/map'),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                
                // Bus Features
                _buildSectionHeader(
                  '🚌 Bus Services',
                  'Explore bus routes',
                  () => context.go('/bus'),
                ),
                SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4, // More compact grid
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0, // Square boxes
                  children: [
                    CompactFeatureCard(
                      title: 'Route Finder',
                      subtitle: '',
                      icon: Icons.directions_bus,
                      color: AppTheme.infoColor,
                      onTap: () => context.go('/bus/route-finder'),
                    ),
                    CompactFeatureCard(
                      title: 'Stop Locator',
                      subtitle: '',
                      icon: Icons.bus_alert,
                      color: AppTheme.warningColor,
                      onTap: () => context.go('/bus/stop-locator'),
                    ),
                    CompactFeatureCard(
                      title: 'Live Timing',
                      subtitle: '',
                      icon: Icons.schedule,
                      color: AppTheme.metroOrange,
                      onTap: () => context.go('/bus'),
                    ),
                    CompactFeatureCard(
                      title: 'Bus Map',
                      subtitle: '',
                      icon: Icons.map,
                      color: AppTheme.metroPink,
                      onTap: () => context.go('/bus/map'),
                    ),
                    CompactFeatureCard(
                      title: 'Live Bus Tracker',
                      subtitle: 'Real-time tracking',
                      icon: Icons.gps_fixed,
                      color: AppTheme.metroOrange,
                      onTap: () => context.go('/bus/realtime'),
                    ),
                    CompactFeatureCard(
                      title: 'API Test',
                      subtitle: 'Debug API calls',
                      icon: Icons.bug_report,
                      color: AppTheme.metroRed,
                      onTap: () => context.go('/bus/api-test'),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                
                // Other Transport
                _buildSectionHeader(
                  '🚖 Other Transport',
                  'Alternative transport options',
                  () => context.go('/transport'),
                ),
                SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4, // More compact grid
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0, // Square boxes
                  children: [
                    CompactFeatureCard(
                      title: 'Auto & Cab',
                      subtitle: 'Book rides',
                      icon: Icons.local_taxi,
                      color: AppTheme.accentColor,
                      onTap: () => context.go('/transport'),
                    ),
                    CompactFeatureCard(
                      title: 'Cycle Rentals',
                      subtitle: 'Eco-friendly',
                      icon: Icons.pedal_bike,
                      color: AppTheme.metroGreen,
                      onTap: () => context.go('/transport'),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                
                // City Assistance
                _buildSectionHeader(
                  '📍 City Assistance',
                  'Explore Delhi',
                  () => context.go('/tourist-spots'),
                ),
                SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4, // More compact grid
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0, // Square boxes
                  children: [
                    CompactFeatureCard(
                      title: 'Tourist Spots',
                      subtitle: 'Discover places',
                      icon: Icons.place,
                      color: AppTheme.metroMagenta,
                      onTap: () => context.go('/tourist-spots'),
                    ),
                    CompactFeatureCard(
                      title: 'Emergency',
                      subtitle: 'Emergency help',
                      icon: Icons.emergency,
                      color: AppTheme.errorColor,
                      onTap: () => context.go('/emergency'),
                    ),
                    CompactFeatureCard(
                      title: 'Weather',
                      subtitle: 'Weather info',
                      icon: Icons.wb_sunny,
                      color: AppTheme.warningColor,
                      onTap: () => context.go('/weather'),
                    ),
                    CompactFeatureCard(
                      title: 'More Services',
                      subtitle: 'Additional help',
                      icon: Icons.more_horiz,
                      color: AppTheme.metroGrey,
                      onTap: () => context.go('/transport'),
                    ),
                  ],
                ),
                
                // Games Section
                const SizedBox(height: 24),
                _buildSectionHeader(
                  '🎮 Games & Entertainment',
                  'Have fun while waiting',
                  () => context.go('/games'),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4, // More games in a row
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0, // Square boxes
                  children: [
                    CompactFeatureCard(
                      title: 'Snake',
                      subtitle: '', // Remove subtitle
                      icon: Icons.games,
                      color: AppTheme.metroGreen,
                      onTap: () => context.go('/games/snake'),
                    ),
                    CompactFeatureCard(
                      title: 'Tetris',
                      subtitle: '', // Remove subtitle
                      icon: Icons.extension,
                      color: AppTheme.metroBlue,
                      onTap: () => context.go('/games/tetris'),
                    ),
                    CompactFeatureCard(
                      title: 'More',
                      subtitle: '', // Remove subtitle
                      icon: Icons.more_horiz,
                      color: AppTheme.metroMagenta,
                      onTap: () => context.go('/games'),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getSectionSpacing(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildResponsiveStats(BuildContext context) {
    final stats = [
      {'label': 'Metro Lines', 'value': '8', 'icon': Icons.train},
      {'label': 'Bus Routes', 'value': '150+', 'icon': Icons.directions_bus},
      {'label': 'Stations', 'value': '300+', 'icon': Icons.location_on},
      {'label': 'Daily Users', 'value': '2.8M', 'icon': Icons.people},
      {'label': 'Coverage', 'value': '95%', 'icon': Icons.map},
    ];

    final visibleStats = stats.take(ResponsiveHelper.getWelcomeStatsCount(context)).toList();
    
    if (ResponsiveHelper.isMobile(context)) {
      return Row(
        children: visibleStats.map((stat) => 
          Expanded(
            child: _buildQuickStat(
              stat['label'] as String,
              stat['value'] as String,
              stat['icon'] as IconData,
              Colors.white,
            ),
          ),
        ).toList(),
      );
    } else {
      return Wrap(
        spacing: ResponsiveHelper.getGridSpacing(context),
        runSpacing: ResponsiveHelper.getGridSpacing(context),
        children: visibleStats.map((stat) => 
          SizedBox(
            width: (MediaQuery.of(context).size.width - ResponsiveHelper.getScreenPadding(context).horizontal - ResponsiveHelper.getGridSpacing(context) * (visibleStats.length - 1)) / visibleStats.length,
            child: _buildQuickStat(
              stat['label'] as String,
              stat['value'] as String,
              stat['icon'] as IconData,
              Colors.white,
            ),
          ),
        ).toList(),
      );
    }
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text('View All'),
        ),
      ],
    );
  }
}
