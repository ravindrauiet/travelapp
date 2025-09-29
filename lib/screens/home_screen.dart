import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/feature_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/app_drawer.dart';
import '../utils/app_theme.dart';

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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickStat(
                              'Metro Lines',
                              '8',
                              Icons.train,
                              Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickStat(
                              'Bus Routes',
                              '150+',
                              Icons.directions_bus,
                              Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickStat(
                              'Stations',
                              '300+',
                              Icons.location_on,
                              Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Metro Features
                _buildSectionHeader(
                  '🚇 Metro Services',
                  'Plan your metro journey',
                  () => context.go('/metro'),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    FeatureCard(
                      title: 'Fare Calculator',
                      subtitle: 'Calculate fare',
                      icon: Icons.calculate,
                      color: AppTheme.metroBlue,
                      onTap: () => context.go('/metro/fare-calculator'),
                    ),
                    FeatureCard(
                      title: 'Route Finder',
                      subtitle: 'Find best route',
                      icon: Icons.route,
                      color: AppTheme.metroRed,
                      onTap: () => context.go('/metro/route-finder'),
                    ),
                    FeatureCard(
                      title: 'Live Updates',
                      subtitle: 'Real-time info',
                      icon: Icons.update,
                      color: AppTheme.metroGreen,
                      onTap: () => context.go('/metro/live-updates'),
                    ),
                    FeatureCard(
                      title: 'Nearest Station',
                      subtitle: 'Find nearby',
                      icon: Icons.location_on,
                      color: AppTheme.metroViolet,
                      onTap: () => context.go('/metro'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Bus Features
                _buildSectionHeader(
                  '🚌 Bus Services',
                  'Explore bus routes',
                  () => context.go('/bus'),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    FeatureCard(
                      title: 'Route Finder',
                      subtitle: 'Find bus routes',
                      icon: Icons.directions_bus,
                      color: AppTheme.infoColor,
                      onTap: () => context.go('/bus/route-finder'),
                    ),
                    FeatureCard(
                      title: 'Stop Locator',
                      subtitle: 'Find bus stops',
                      icon: Icons.bus_alert,
                      color: AppTheme.warningColor,
                      onTap: () => context.go('/bus/stop-locator'),
                    ),
                    FeatureCard(
                      title: 'Live Timing',
                      subtitle: 'Real-time schedule',
                      icon: Icons.schedule,
                      color: AppTheme.metroOrange,
                      onTap: () => context.go('/bus'),
                    ),
                    FeatureCard(
                      title: 'Bus Services',
                      subtitle: 'All bus info',
                      icon: Icons.directions_transit,
                      color: AppTheme.metroPink,
                      onTap: () => context.go('/bus'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Other Transport
                _buildSectionHeader(
                  '🚖 Other Transport',
                  'Alternative transport options',
                  () => context.go('/transport'),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    FeatureCard(
                      title: 'Auto & Cab',
                      subtitle: 'Book rides',
                      icon: Icons.local_taxi,
                      color: AppTheme.accentColor,
                      onTap: () => context.go('/transport'),
                    ),
                    FeatureCard(
                      title: 'Cycle Rentals',
                      subtitle: 'Eco-friendly',
                      icon: Icons.pedal_bike,
                      color: AppTheme.metroGreen,
                      onTap: () => context.go('/transport'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // City Assistance
                _buildSectionHeader(
                  '📍 City Assistance',
                  'Explore Delhi',
                  () => context.go('/tourist-spots'),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    FeatureCard(
                      title: 'Tourist Spots',
                      subtitle: 'Discover places',
                      icon: Icons.place,
                      color: AppTheme.metroMagenta,
                      onTap: () => context.go('/tourist-spots'),
                    ),
                    FeatureCard(
                      title: 'Emergency',
                      subtitle: 'Emergency help',
                      icon: Icons.emergency,
                      color: AppTheme.errorColor,
                      onTap: () => context.go('/emergency'),
                    ),
                    FeatureCard(
                      title: 'Weather',
                      subtitle: 'Weather info',
                      icon: Icons.wb_sunny,
                      color: AppTheme.warningColor,
                      onTap: () => context.go('/weather'),
                    ),
                    FeatureCard(
                      title: 'More Services',
                      subtitle: 'Additional help',
                      icon: Icons.more_horiz,
                      color: AppTheme.metroGrey,
                      onTap: () => context.go('/transport'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
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
