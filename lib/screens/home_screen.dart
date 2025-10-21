import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/feature_card.dart';
import '../widgets/compact_feature_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tablet_navigation.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../providers/weather_provider.dart';

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
    
    // Load weather data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadWeather();
    });
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
                // Enhanced Welcome Section
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
                      // Header with animated greeting
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
                                Text(
                                  _getGreeting(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Welcome to Delhi!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getCurrentTime(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Weather widget
                          _buildWeatherWidget(),
                        ],
                      ),
                      
                      SizedBox(height: ResponsiveHelper.isMobile(context) ? 20 : 24),
                      
                      // Delhi Metro Quick Stats
                      _buildDelhiStats(context),
                      
                      SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),
                      
                      // Daily Tip
                      _buildDailyTip(context),
                      
                      SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),
                      
                      // Quick Actions
                      _buildQuickActions(context),
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

  // New helper methods for enhanced welcome section
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning! 🌅';
    } else if (hour < 17) {
      return 'Good Afternoon! ☀️';
    } else {
      return 'Good Evening! 🌆';
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildWeatherWidget() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }

        if (weatherProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(height: 4),
                Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'No data',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }

        final weather = weatherProvider.currentWeather;
        if (weather == null) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.wb_sunny, color: Colors.white, size: 20),
                SizedBox(height: 4),
                Text(
                  '28°C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sunny',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                _getWeatherIcon(weather.description),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                '${weather.temperature.round()}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                weather.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('sunny') || desc.contains('clear')) {
      return Icons.wb_sunny;
    } else if (desc.contains('cloudy') || desc.contains('overcast')) {
      return Icons.cloud;
    } else if (desc.contains('rainy') || desc.contains('rain')) {
      return Icons.grain;
    } else if (desc.contains('thunderstorm') || desc.contains('storm')) {
      return Icons.flash_on;
    } else if (desc.contains('snow')) {
      return Icons.ac_unit;
    } else if (desc.contains('fog') || desc.contains('mist')) {
      return Icons.foggy;
    } else {
      return Icons.wb_sunny; // Default to sunny
    }
  }

  Widget _buildDelhiStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.train, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Delhi Metro at a Glance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('262', 'Stations', Icons.location_on),
              ),
              Expanded(
                child: _buildStatItem('8', 'Lines', Icons.route),
              ),
              Expanded(
                child: _buildStatItem('390', 'KM', Icons.straighten),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTip(BuildContext context) {
    final tips = [
      '💡 Peak hours: 8-10 AM & 6-8 PM. Plan accordingly!',
      '🚇 Use smart cards for 10% discount on fares',
      '⏰ Trains run every 2-3 minutes during peak hours',
      '🎫 Book tickets online to avoid queues',
      '🚌 Metro connects to bus stops for seamless travel',
      '📱 Check live updates before starting your journey',
    ];
    
    final todayTip = tips[DateTime.now().day % tips.length];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Tip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todayTip,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            'Next Station',
            Icons.near_me,
            () => _findNextStation(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            'Metro Map',
            Icons.map,
            () => _showMetroMap(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            'Calculate Fare',
            Icons.calculate,
            () => context.go('/metro/fare-calculator'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _findNextStation(BuildContext context) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Finding nearest metro station...'),
          ],
        ),
      ),
    );

    // Simulate location finding
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog
      
      // Show nearest station result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.train, color: Colors.green),
              SizedBox(width: 8),
              Text('Nearest Station'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rajiv Chowk',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Distance: 0.8 km'),
              const Text('Walking time: 10 minutes'),
              const Text('Lines: Blue, Yellow'),
              const SizedBox(height: 12),
              const Text(
                'Directions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('1. Walk towards Connaught Place'),
              const Text('2. Turn right at Barakhamba Road'),
              const Text('3. Station entrance on your left'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/metro/route-finder');
              },
              child: const Text('Find Routes'),
            ),
          ],
        ),
      );
    });
  }

  void _showMetroMap(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Delhi Metro Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Map content
              Expanded(
                child: Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Metro Map PDF Viewer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'PDF viewer will be implemented here',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'assets/pdf/metro.pdf',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement PDF download
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Download feature coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
