import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/app_drawer.dart';
import '../widgets/ui_kit.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/responsive_helper.dart';
import '../providers/weather_provider.dart';
import '../providers/metro_provider.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen> {
  // Popular destinations in Delhi, with an icon hinting at what they are
  static const _trendingPlaces = [
    ('Rajiv Chowk', Icons.storefront_rounded),
    ('IGI Airport T3', Icons.flight_takeoff_rounded),
    ('India Gate', Icons.account_balance_rounded),
    ('Hauz Khas', Icons.local_cafe_rounded),
    ('Chandni Chowk', Icons.ramen_dining_rounded),
    ('Kashmere Gate', Icons.directions_bus_rounded),
    ('Noida Sec 18', Icons.shopping_bag_rounded),
    ('Gurugram Cyber City', Icons.business_rounded),
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
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
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
              _buildHeroWithSearch(context),
              const SizedBox(height: 22),
              _buildQuickActions(context),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Travel your way',
                subtitle: 'Every mode of transport in Delhi NCR',
              ),
              const SizedBox(height: 12),
              _buildTravelModes(context),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Popular right now',
                subtitle: 'Tap a place to plan your metro route',
              ),
              const SizedBox(height: 12),
              _buildTrendingPlaces(context),
              const SizedBox(height: 26),
              _buildWeatherCard(context),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Metro lines',
                subtitle: 'Frequency & route of every line',
                actionLabel: 'Service info',
                onAction: () => context.push('/metro/live-updates'),
              ),
              const SizedBox(height: 12),
              _buildMetroLines(context),
              const SizedBox(height: 26),
              _buildSmartCardBanner(context),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Delhi Metro in numbers'),
              const SizedBox(height: 12),
              _buildNetworkStats(),
              const SizedBox(height: 26),
              _buildPerks(context),
              const SizedBox(height: 28),
              _buildFooter(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
      ),
    );
  }

  // ── Hero header with skyline + floating search card ──────────────────────

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late night ride?';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildHeroWithSearch(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient hero
        Container(
          // Search card overlaps only the viaduct pillars so the train stays visible
          margin: const EdgeInsets.only(bottom: 100),
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SvgPicture.asset(
                    'assets/images/hero_skyline.svg',
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(context),
                      const SizedBox(height: 22),
                      Text(
                        '$_greeting 👋',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Where are you\nheading today?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.8,
                        ),
                      ),
                      // Space for the skyline to show beneath the headline
                      SizedBox(height: MediaQuery.of(context).size.width * 0.42),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating search card overlapping the hero
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: _buildSearchCard(context),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (ctx) => HeaderIconButton(
            icon: Icons.menu_rounded,
            tooltip: 'Menu',
            onTap: () => Scaffold.maybeOf(ctx)?.openDrawer(),
          ),
        ),
        const SizedBox(width: 12),
        SvgPicture.asset('assets/images/logo.svg', width: 36, height: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Metromate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFFFB547)),
                  const SizedBox(width: 3),
                  Text(
                    'Delhi NCR',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Transit alerts',
          showDot: true,
          onTap: () => _showNotificationsSheet(context),
        ),
      ],
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    final p = context.palette;

    Widget row({
      required Color dot,
      required String label,
      required String value,
      required bool muted,
    }) {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: dot, width: 3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.textTertiary, letterSpacing: 0.4),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: muted ? p.textTertiary : p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandNight.withValues(alpha: p.isDark ? 0.4 : 0.14),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/metro/route-finder'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      row(dot: AppTheme.primaryColor, label: 'FROM', value: 'Your location', muted: false),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 2,
                              height: 20,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: p.border,
                            ),
                            const SizedBox(width: 19),
                            Expanded(child: Divider(color: p.border, height: 1)),
                          ],
                        ),
                      ),
                      row(dot: AppTheme.accentColor, label: 'TO', value: 'Search station or place', muted: true),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.sunsetGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.accentShadow,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick actions grid ───────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction('Route', Icons.alt_route_rounded, AppTheme.primaryColor, '/metro/route-finder'),
      _QuickAction('Fare', Icons.currency_rupee_rounded, AppTheme.successColor, '/metro/fare-calculator'),
      _QuickAction('Live Track', Icons.gps_fixed_rounded, AppTheme.infoColor, '/metro/live-tracker'),
      _QuickAction('Metro Map', Icons.map_rounded, AppTheme.brandViolet, '/metro/map'),
      _QuickAction('Bus Stops', Icons.signpost_rounded, AppTheme.metroGreen, '/bus/stop-locator'),
      _QuickAction('Live Bus', Icons.directions_bus_filled_rounded, AppTheme.metroOrange, '/bus/realtime'),
      _QuickAction('Weather', Icons.wb_sunny_rounded, AppTheme.warningColor, '/weather'),
      _QuickAction('SOS', Icons.emergency_rounded, AppTheme.errorColor, '/emergency'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 4,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, i) {
          final a = actions[i];
          final p = context.palette;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(a.route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.border.withValues(alpha: 0.6)),
                    boxShadow: p.isDark ? null : AppTheme.softShadow,
                  ),
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: p.tint(a.color),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a.icon, color: a.color, size: 21),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  a.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Travel modes with illustrations ──────────────────────────────────────

  Widget _buildTravelModes(BuildContext context) {
    final modes = [
      _TravelMode(
        title: 'Delhi Metro',
        subtitle: '${AppConstants.metroLinesCount} lines · ${AppConstants.metroStationsCount} stations',
        badge: 'FASTEST',
        illustration: 'assets/images/illus_metro.svg',
        colors: const [Color(0xFF4338CA), Color(0xFF6366F1)],
        route: '/metro',
      ),
      _TravelMode(
        title: 'DTC Buses',
        subtitle: '${AppConstants.busRoutesCount} routes · live GPS',
        badge: 'CHEAPEST',
        illustration: 'assets/images/illus_bus.svg',
        colors: const [Color(0xFF047857), Color(0xFF10B981)],
        route: '/bus',
      ),
      _TravelMode(
        title: 'Auto & Cabs',
        subtitle: 'Govt. fares · no surge',
        badge: 'DOORSTEP',
        illustration: 'assets/images/illus_auto.svg',
        colors: const [Color(0xFFC2410C), Color(0xFFFB923C)],
        route: '/transport',
      ),
      _TravelMode(
        title: 'Explore Delhi',
        subtitle: '${AppConstants.touristSpotsCount} must-see places',
        badge: 'GUIDE',
        illustration: 'assets/images/illus_explore.svg',
        colors: const [Color(0xFF6D28D9), Color(0xFFC026D3)],
        route: '/tourist-spots',
      ),
    ];

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final m = modes[i];
          return GestureDetector(
            onTap: () => context.push(m.route),
            child: Container(
              width: 158,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: m.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.glow(m.colors.first, alpha: 0.3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -4,
                      child: SvgPicture.asset(m.illustration, width: 92, height: 92),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TagPill(label: m.badge, color: Colors.white, onDark: true),
                          const SizedBox(height: 12),
                          Text(
                            m.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            m.subtitle,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w500,
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
        },
      ),
    );
  }

  // ── Trending places ──────────────────────────────────────────────────────

  Widget _buildTrendingPlaces(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trendingPlaces.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (name, icon) = _trendingPlaces[i];
          return Material(
            color: p.card,
            borderRadius: BorderRadius.circular(21),
            child: InkWell(
              borderRadius: BorderRadius.circular(21),
              onTap: () {
                final resolved = AppConstants.resolveToMetroStation(name);
                context.push('/metro/route-finder?to=${Uri.encodeComponent(resolved)}');
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: p.tint(AppTheme.accentColor),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 15, color: AppTheme.accentColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Weather & AQI ────────────────────────────────────────────────────────

  Widget _buildWeatherCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<WeatherProvider>(
        builder: (context, wp, _) {
          final w = wp.currentWeather;
          final tempStr = w != null ? '${w.temperature.round()}°' : '--°';
          final desc = w?.description ?? 'Loading weather…';
          final aqi = w?.airQuality.aqi ?? 142;
          final aqiColor = AppConstants.getAqiColor(aqi);
          final aqiLabel = AppConstants.getAqiCategory(aqi);
          final isNight = DateTime.now().hour >= 19 || DateTime.now().hour < 6;

          return GestureDetector(
            onTap: () => context.push('/weather'),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isNight
                      ? const [Color(0xFF1E3A8A), Color(0xFF312E81)]
                      : const [Color(0xFF0284C7), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.glow(isNight ? const Color(0xFF312E81) : const Color(0xFF0284C7), alpha: 0.3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -24,
                      child: Icon(
                        _weatherIcon(desc, isNight),
                        size: 130,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_weatherIcon(desc, isNight), color: const Color(0xFFFDE68A), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'New Delhi · ${DateFormat('EEE, d MMM').format(DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                tempStr,
                                style: const TextStyle(
                                  fontSize: 46,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _capitalize(desc),
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _weatherMetric(
                                    Icons.water_drop_rounded, w != null ? '${w.humidity.round()}%' : '--', 'Humidity'),
                                _weatherMetric(
                                    Icons.air_rounded, w != null ? '${w.windSpeed.round()} km/h' : '--', 'Wind'),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: aqiColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'AQI $aqi',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              aqiLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white.withValues(alpha: 0.75),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }

  Widget _weatherMetric(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Metro lines carousel ─────────────────────────────────────────────────

  Widget _buildMetroLines(BuildContext context) {
    final lines = DelhiMetroNetwork.allLines;
    final p = context.palette;

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: lines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final line = lines[index];
          return Material(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _showLineDetailModal(context, line),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border.withValues(alpha: 0.7)),
                  boxShadow: p.isDark ? null : AppTheme.softShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 6, color: line.color),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: line.color,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.subway_rounded, size: 17, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      line.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                line.route,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: p.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: TagPill(
                                      label: line.typicalHeadway,
                                      color: AppTheme.successColor,
                                      icon: Icons.schedule_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${line.stationCount} stops',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: p.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
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
        },
      ),
    );
  }

  // ── Line station detail sheet ────────────────────────────────────────────

  void _showLineDetailModal(BuildContext context, MetroLineDetails line) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Coloured header for the line
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [line.color, Color.lerp(line.color, Colors.black, 0.25)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 10, 8, 18),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.subway_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  line.route,
                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _sheetStat('${line.stationCount}', 'Stations'),
                          _sheetStat(line.typicalHeadway, 'Frequency'),
                          _sheetStat('${line.interchanges.length}', 'Interchanges'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Stations timeline
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: line.stations.length,
                    itemBuilder: (context, idx) {
                      final station = line.stations[idx];
                      final interchangeLines = line.interchanges[station];
                      final isInterchange = interchangeLines != null;
                      final isFirst = idx == 0;
                      final isLast = idx == line.stations.length - 1;
                      final isEnd = isFirst || isLast;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          final resolved = AppConstants.resolveToMetroStation(station);
                          context.push('/metro/route-finder?to=${Uri.encodeComponent(resolved)}');
                        },
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 22,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 10,
                                      color: isFirst ? Colors.transparent : line.color,
                                    ),
                                    Container(
                                      width: isEnd || isInterchange ? 16 : 12,
                                      height: isEnd || isInterchange ? 16 : 12,
                                      decoration: BoxDecoration(
                                        color: isEnd ? line.color : p.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isInterchange ? AppTheme.warningColor : line.color,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        width: 4,
                                        color: isLast ? Colors.transparent : line.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6, bottom: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              station,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: isEnd || isInterchange ? FontWeight.w800 : FontWeight.w600,
                                                color: p.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (isEnd) TagPill(label: isFirst ? 'START' : 'TERMINAL', color: line.color),
                                        ],
                                      ),
                                      if (isInterchange) ...[
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: interchangeLines
                                              .map((il) => TagPill(
                                                    label: il,
                                                    color: AppTheme.warningColor,
                                                    icon: Icons.swap_horiz_rounded,
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sheetStat(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(label, style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  // ── Smart card promo ─────────────────────────────────────────────────────

  Widget _buildSmartCardBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/metro/fare-calculator'),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.sunsetGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.accentShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative "smart card"
                Positioned(
                  right: -18,
                  top: 18,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      width: 120,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB547),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'METRO CARD',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 120, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TagPill(label: 'SAVE UP TO 20%', color: Colors.white, onDark: true),
                      const SizedBox(height: 10),
                      const Text(
                        'Ride smarter with a Metro Smart Card',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '10% off every ride + extra 10% off-peak',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.88)),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Calculate fare',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFE11D48)),
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
    );
  }

  // ── Network stats ────────────────────────────────────────────────────────

  Widget _buildNetworkStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${AppConstants.metroStationsCount}+',
                  label: 'Metro stations',
                  icon: Icons.location_city_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: '${AppConstants.metroNetworkLengthKm.toInt()} km',
                  label: 'Network length',
                  icon: Icons.timeline_rounded,
                  color: AppTheme.brandViolet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: AppConstants.fareRangeDisplay,
                  label: 'Metro fare range',
                  icon: Icons.currency_rupee_rounded,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: AppConstants.busFleetCount,
                  label: 'DTC buses',
                  icon: Icons.directions_bus_rounded,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Emergency + games ────────────────────────────────────────────────────

  Widget _buildPerks(BuildContext context) {
    final p = context.palette;
    Widget tile({
      required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required String route,
    }) {
      return Expanded(
        child: AppCard(
          onTap: () => context.push(route),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBubble(icon: icon, color: color, size: 42, filled: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: p.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          tile(
            title: 'Emergency',
            subtitle: 'Police 112 · Women 181',
            icon: Icons.sos_rounded,
            color: AppTheme.errorColor,
            route: '/emergency',
          ),
          const SizedBox(width: 12),
          tile(
            title: 'Commute Games',
            subtitle: '5 offline games',
            icon: Icons.sports_esports_rounded,
            color: AppTheme.brandViolet,
            route: '/games',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        children: [
          Opacity(
            opacity: 0.6,
            child: SvgPicture.asset('assets/images/logo.svg', width: 28, height: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Made for Delhi with ❤',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textTertiary),
          ),
          Text(
            'Metromate v${AppConstants.appVersion}',
            style: TextStyle(fontSize: 11, color: p.textTertiary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  IconData _weatherIcon(String desc, bool isNight) {
    final d = desc.toLowerCase();
    if (d.contains('thunder')) return Icons.thunderstorm_rounded;
    if (d.contains('rain') || d.contains('shower') || d.contains('drizzle')) return Icons.water_drop_rounded;
    if (d.contains('snow')) return Icons.ac_unit_rounded;
    if (d.contains('mist') || d.contains('fog') || d.contains('haze') || d.contains('smoke')) {
      return Icons.blur_on_rounded;
    }
    if (d.contains('cloud')) return Icons.cloud_rounded;
    return isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded;
  }

  void _showNotificationsSheet(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final time1 = DateFormat('h:mm a').format(now.subtract(const Duration(minutes: 5)));
    final time2 = DateFormat('h:mm a').format(now.subtract(const Duration(minutes: 15)));

    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const IconBubble(
                    icon: Icons.notifications_active_rounded,
                    color: AppTheme.accentColor,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transit advisories',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close_rounded, color: p.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                context,
                'Yellow Line running normally',
                'Millennium City Centre Gurugram to Samaypur Badli, trains every 2.5 min at peak.',
                time1,
                Icons.check_circle_rounded,
                AppTheme.successColor,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                context,
                'Airport Express frequency',
                'Trains every 10 minutes between New Delhi and IGI Airport Terminal 3.',
                time2,
                Icons.flight_rounded,
                AppTheme.infoColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String desc,
    String time,
    IconData icon,
    Color color,
  ) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: icon, color: color, size: 36, radius: 11),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                      ),
                    ),
                    Text(time, style: TextStyle(fontSize: 10.5, color: p.textTertiary)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}

class _TravelMode {
  final String title;
  final String subtitle;
  final String badge;
  final String illustration;
  final List<Color> colors;
  final String route;
  const _TravelMode({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.illustration,
    required this.colors,
    required this.route,
  });
}
