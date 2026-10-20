import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/app_drawer.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../providers/weather_provider.dart';
import '../providers/metro_provider.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen> {
  // Quick trending station hubs in Delhi
  static const _trendingStations = [
    'Rajiv Chowk',
    'IGI Airport T3',
    'India Gate',
    'Hauz Khas',
    'Chandni Chowk',
    'Kashmere Gate',
    'Noida Sec 18',
    'Gurugram Cyber City',
  ];

  // Delhi Metro Live Line Radar data
  static const _metroLinesStatus = [
    _LineStatus('Yellow Line', AppTheme.metroYellow, 'Samaypur Badli ↔ Millennium City', 'Normal Service', '3 min'),
    _LineStatus('Blue Line', AppTheme.metroBlue, 'Dwarka Sec 21 ↔ Noida / Vaishali', 'Normal Service', '2.5 min'),
    _LineStatus('Airport Express', AppTheme.metroOrange, 'New Delhi ↔ IGI Airport T3', 'Express Running', '10 min'),
    _LineStatus('Red Line', AppTheme.metroRed, 'Rithala ↔ Shaheed Sthal', 'Normal Service', '4 min'),
    _LineStatus('Violet Line', AppTheme.metroViolet, 'Kashmere Gate ↔ Raja Nahar Singh', 'Normal Service', '4 min'),
    _LineStatus('Pink Line', AppTheme.metroPink, 'Majlis Park ↔ Shiv Vihar (Ring)', 'Normal Service', '4 min'),
    _LineStatus('Magenta Line', AppTheme.metroMagenta, 'Janakpuri West ↔ Botanical Garden', 'Normal Service', '3.5 min'),
    _LineStatus('Green Line', AppTheme.metroGreen, 'Inderlok ↔ Brig. Hoshiyar Singh', 'Normal Service', '6 min'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadWeather();
      context.read<MetroProvider>().loadStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC), // Soft modern slate-grey background
      appBar: _buildConsumerAppBar(context),
      drawer: isTablet
          ? null
          : const AppDrawer(
              title: 'Metromate',
              subtitle: 'Your Delhi Travel Companion',
            ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Search & Quick Transit Chips (Blinkit / Swiggy style)
            _buildSearchPillSection(context),

            // Hero Live Commute Hub (Interactive Plan & Status)
            _buildHeroCommuteHub(context),
            const SizedBox(height: 24),

            // Super-App Service Category Tiles (Zomato / Swiggy style)
            _buildServicesSection(context),
            const SizedBox(height: 24),

            // Metro Lines Live Radar (Horizontal ticker)
            _buildMetroLinesRadar(context),
            const SizedBox(height: 24),

            // Smart Commute Deals & GPS Station Tracker Banner
            _buildSmartCommuteFeatures(context),
            const SizedBox(height: 24),

            // Weather & Air Quality (AQI) Widget
            _buildWeatherAndAqiCard(context),
            const SizedBox(height: 24),

            // Emergency SOS & Offline Commute Games
            _buildCommutePerksSection(context),
            const SizedBox(height: 110),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  // ── Top Consumer App Bar (Zomato / Blinkit style) ──────────────────────────

  PreferredSizeWidget _buildConsumerAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.train_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'DELHI NCR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'Metromate Transit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 19),
          ),
          onPressed: () => _showNotificationsSheet(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Blinkit / Swiggy style Search & Trending Chips ────────────────────────

  Widget _buildSearchPillSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Pill
          InkWell(
            onTap: () => context.push('/metro/route-finder'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D2D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.search_rounded, color: Color(0xFFFF4D2D), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Where to? Search Metro station or route',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'e.g. Rajiv Chowk, IGI Airport, Red Fort',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'PLAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Trending Horizontal Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _trendingStations.map((station) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => context.push('/metro/route-finder'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 13, color: Color(0xFFFF4D2D)),
                          const SizedBox(width: 5),
                          Text(
                            station,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Commute Hub (Interactive Planner & Live Pulse) ────────────────────

  Widget _buildHeroCommuteHub(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1120), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DMRC & DTC LIVE STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    '12 Lines Running',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Headline
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Navigate Delhi Smarter,\nFaster & Cheaper',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.25,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Quick Action Launchers Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickHubButton(
                    context,
                    title: 'Route Finder',
                    subtitle: 'Dijkstra Optimal',
                    icon: Icons.alt_route_rounded,
                    color: const Color(0xFFFF5238),
                    onTap: () => context.push('/metro/route-finder'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.15),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Expanded(
                  child: _buildQuickHubButton(
                    context,
                    title: 'Fare Calculator',
                    subtitle: 'DMRC Smart Card',
                    icon: Icons.calculate_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => context.push('/metro/fare-calculator'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.15),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Expanded(
                  child: _buildQuickHubButton(
                    context,
                    title: 'Live Tracker',
                    subtitle: 'GPS Geofence',
                    icon: Icons.gps_fixed_rounded,
                    color: const Color(0xFF38BDF8),
                    onTap: () => context.push('/metro/live-tracker'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Network Coverage Pill Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBadge('262+ Stations', Icons.domain_rounded),
                _buildStatBadge('390+ KM Network', Icons.timeline_rounded),
                _buildStatBadge('700+ Bus Routes', Icons.directions_bus_filled_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHubButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Super-App Category Tiles (Zomato / Swiggy style 2x2 Grid) ──────────────

  Widget _buildServicesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transit Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Comprehensive Delhi NCR connectivity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/metro/pdf-viewer'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.map_rounded, size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'Metro Map PDF',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Clean Super-App Grid
          Row(
            children: [
              Expanded(
                child: _buildServiceTile(
                  context,
                  title: 'Delhi Metro',
                  subtitle: '12 Lines • Real-time GTFS',
                  badge: 'FASTEST',
                  badgeColor: const Color(0xFF2563EB),
                  icon: Icons.subway_rounded,
                  iconGradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  bgGradient: const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                  onTap: () => context.push('/metro'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceTile(
                  context,
                  title: 'DTC Buses',
                  subtitle: '700+ Routes & Stops',
                  badge: 'LOW FARE',
                  badgeColor: const Color(0xFF16A34A),
                  icon: Icons.directions_bus_rounded,
                  iconGradient: const [Color(0xFF16A34A), Color(0xFF15803D)],
                  bgGradient: const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                  onTap: () => context.push('/bus'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildServiceTile(
                  context,
                  title: 'Cabs & Auto',
                  subtitle: 'Meter Fares & Estimates',
                  badge: 'ZERO SURGE',
                  badgeColor: const Color(0xFFEA580C),
                  icon: Icons.local_taxi_rounded,
                  iconGradient: const [Color(0xFFEA580C), Color(0xFFC2410C)],
                  bgGradient: const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                  onTap: () => context.push('/transport'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceTile(
                  context,
                  title: 'Discover Delhi',
                  subtitle: 'Top 35 Monuments & Spots',
                  badge: 'TOUR GUIDE',
                  badgeColor: const Color(0xFF9333EA),
                  icon: Icons.explore_rounded,
                  iconGradient: const [Color(0xFF9333EA), Color(0xFF7E22CE)],
                  bgGradient: const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                  onTap: () => context.push('/tourist-spots'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<Color> iconGradient,
    required List<Color> bgGradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.first.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Metro Lines Live Radar (Horizontal Scrolling Ticker) ───────────────────

  Widget _buildMetroLinesRadar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metro Lines Live Radar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Real-time frequency & line status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/metro/live-updates'),
                child: const Text(
                  'View All ➔',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF4D2D),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _metroLinesStatus.length,
            itemBuilder: (context, index) {
              final line = _metroLinesStatus[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: line.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            line.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ON TIME',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      line.terminals,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Avg Frequency: ${line.frequency}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Smart Commuter Features (Blinkit style Banners) ───────────────────────

  Widget _buildSmartCommuteFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Smart Card Savings Banner
          InkWell(
            onTap: () => context.push('/metro/fare-calculator'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save 10%–20% on Every Metro Ride',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'DMRC Smart Card offers 10% discount + extra 10% off-peak hours',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'CHECK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // GPS Nearest Station Card
          InkWell(
            onTap: () => context.push('/metro/live-tracker'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Nearest Metro Station',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'GPS walking distance, route navigation & arrival alerts',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weather & Air Quality (AQI) Widget ────────────────────────────────────

  Widget _buildWeatherAndAqiCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => context.push('/weather'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Consumer<WeatherProvider>(
            builder: (context, wp, _) {
              final w = wp.currentWeather;
              final tempStr = w != null ? '${w.temperature.round()}°C' : '--°C';
              final desc = w?.description ?? 'Clear Sky';
              final aqi = w?.airQuality.aqi ?? 142;

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Icon(
                      _weatherIcon(desc),
                      color: const Color(0xFFD97706),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tempStr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Text(' • Delhi NCR', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getAqiColor(aqi).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getAqiColor(aqi).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'AQI $aqi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _getAqiColor(aqi),
                          ),
                        ),
                        Text(
                          _getAqiStatus(aqi),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _getAqiColor(aqi),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Emergency SOS & Commute Games Section ──────────────────────────────────

  Widget _buildCommutePerksSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Emergency Helpline Pill
          Expanded(
            child: InkWell(
              onTap: () => context.push('/emergency'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency SOS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          Text(
                            'Police 112 • Women 1091',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Offline Mini-Games Pill
          Expanded(
            child: InkWell(
              onTap: () => context.push('/games'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sports_esports_rounded, color: Color(0xFF7C3AED), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commute Games',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B21A8),
                            ),
                          ),
                          Text(
                            'Offline 5 Mini-Games',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  IconData _weatherIcon(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('clear')) return Icons.wb_sunny_rounded;
    if (d.contains('cloud')) return Icons.wb_cloudy_rounded;
    if (d.contains('rain') || d.contains('shower')) return Icons.grain_rounded;
    if (d.contains('thunder')) return Icons.flash_on_rounded;
    if (d.contains('snow')) return Icons.ac_unit_rounded;
    if (d.contains('mist') || d.contains('fog')) return Icons.blur_on_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF10B981);
    if (aqi <= 100) return const Color(0xFFF59E0B);
    if (aqi <= 200) return const Color(0xFFEA580C);
    if (aqi <= 300) return const Color(0xFFDC2626);
    return const Color(0xFF7F1D1D);
  }

  String _getAqiStatus(int aqi) {
    if (aqi <= 50) return 'GOOD';
    if (aqi <= 100) return 'MODERATE';
    if (aqi <= 200) return 'UNHEALTHY';
    if (aqi <= 300) return 'VERY POOR';
    return 'SEVERE';
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: Color(0xFFFF4D2D), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Live Transit Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              'Yellow Line Normal Service',
              'Millennium City Centre to Samaypur Badli running smoothly with peak 2.5m headway.',
              '5m ago',
              Icons.check_circle_rounded,
              const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              'Airport Express Frequency',
              'Trains operating every 10 minutes between New Delhi & IGI Airport Terminal 3.',
              '15m ago',
              Icons.speed_rounded,
              const Color(0xFF0284C7),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String desc, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _LineStatus {
  final String name;
  final Color color;
  final String terminals;
  final String status;
  final String frequency;

  const _LineStatus(this.name, this.color, this.terminals, this.status, this.frequency);
}
