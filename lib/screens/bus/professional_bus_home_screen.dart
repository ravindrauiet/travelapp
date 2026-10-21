import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/responsive_helper.dart';

class ProfessionalBusHomeScreen extends StatefulWidget {
  const ProfessionalBusHomeScreen({super.key});

  @override
  State<ProfessionalBusHomeScreen> createState() =>
      _ProfessionalBusHomeScreenState();
}

class _ProfessionalBusHomeScreenState extends State<ProfessionalBusHomeScreen> {
  static const _busGreen = Color(0xFF059669);

  static const _popularRoutes = [
    _BusRoute('Connaught Place', 'India Gate', '505', '~12 min'),
    _BusRoute('Rajiv Chowk', 'Karol Bagh', '522', '~18 min'),
    _BusRoute('Lajpat Nagar', 'South Extension', '534', '~10 min'),
    _BusRoute('AIIMS', 'Saket', '544', '~15 min'),
    _BusRoute('Nehru Place', 'Noida Sec-15', '543', '~25 min'),
  ];

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
                title: 'Delhi Bus',
                subtitle: 'Affordable & Convenient',
              ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isTablet),
              const SizedBox(height: 22),
              _buildPlanCard(context),
              const SizedBox(height: 16),
              _buildNetworkStats(),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Quick actions',
                subtitle: 'Plan, track and find your bus',
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Bus types',
                subtitle: 'Tap a fleet to learn more',
              ),
              const SizedBox(height: 12),
              _buildBusTypes(context),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Popular routes',
                subtitle: 'Most travelled DTC corridors',
                actionLabel: 'See all',
                onAction: () => context.push('/bus/route-finder'),
              ),
              const SizedBox(height: 12),
              _buildPopularRoutes(context),
              const SizedBox(height: 26),
              _buildFareInfo(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return GradientHeader(
      title: 'Delhi Bus',
      subtitle: 'DTC · Cluster · Electric',
      icon: Icons.directions_bus_rounded,
      gradient: AppTheme.emeraldGradient,
      illustration: 'assets/images/illus_bus.svg',
      leading: isTablet
          ? null
          : Builder(
              builder: (ctx) => HeaderIconButton(
                icon: Icons.menu_rounded,
                tooltip: 'Menu',
                onTap: () => Scaffold.maybeOf(ctx)?.openDrawer(),
              ),
            ),
      actions: [
        HeaderIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Find Bus Route',
          onTap: () => context.push('/bus/route-finder'),
        ),
      ],
    );
  }

  Widget _buildNetworkStats() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: StatTile(value: '650+', label: 'Routes', icon: Icons.route_rounded, color: _busGreen),
          ),
          SizedBox(width: 10),
          Expanded(
            child: StatTile(value: '6,500+', label: 'Buses', icon: Icons.directions_bus_rounded, color: AppTheme.metroBlue),
          ),
          SizedBox(width: 10),
          Expanded(
            child: StatTile(value: '4.2M', label: 'Daily riders', icon: Icons.people_alt_rounded, color: AppTheme.accentColor),
          ),
        ],
      ),
    );
  }

  // ── Plan trip card ────────────────────────────────────────────────────────

  Widget _buildPlanCard(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        onTap: () => context.push('/bus/route-finder'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBubble(icon: Icons.alt_route_rounded, color: _busGreen, filled: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where to by bus?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find direct DTC & cluster routes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: p.textTertiary),
                      ),
                    ],
                  ),
                ),
                const TagPill(label: 'DTC', color: _busGreen),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Plan a bus trip',
              icon: Icons.search_rounded,
              gradient: AppTheme.emeraldGradient,
              onPressed: () => context.push('/bus/route-finder'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _actionCard('Find Route', 'Stop to stop', Icons.directions_rounded,
                    AppTheme.metroBlue, () => context.push('/bus/route-finder')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard('Live Tracking', 'Buses on map', Icons.radar_rounded,
                    _busGreen, () => context.push('/bus/realtime')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard('Bus Stops', 'Near you', Icons.place_rounded,
                    AppTheme.metroOrange, () => context.push('/bus/stop-locator')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard('Bus Map', 'All routes', Icons.map_rounded,
                    AppTheme.brandRose, () => context.push('/bus/map')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
      String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBubble(icon: icon, color: color, size: 42, radius: 13),
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
                  style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bus types ─────────────────────────────────────────────────────────────

  Widget _buildBusTypes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _busTypeCard('DTC', 'Delhi Transport Corporation',
                    Icons.directions_bus_rounded, AppTheme.metroBlue,
                    () => _showBusTypeInfo(context, 'DTC Buses',
                        'Delhi Transport Corporation is the primary public bus operator in Delhi.\n\n'
                        '• Fleet: 3,500+ buses\n'
                        '• Routes: 400+\n'
                        '• Low-floor buses for accessibility\n'
                        '• Passes available monthly & quarterly\n'
                        '• Fare: ₹5 to ₹25 based on distance', AppTheme.metroBlue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _busTypeCard('Cluster', 'Cluster Bus Services',
                    Icons.directions_bus_filled_rounded, _busGreen,
                    () => _showBusTypeInfo(context, 'Cluster Buses',
                        'Cluster buses are operated by private companies under Delhi government.\n\n'
                        '• Fleet: 3,000+ buses\n'
                        '• Complements DTC routes\n'
                        '• Air conditioned options available\n'
                        '• Electronic ticketing system\n'
                        '• Fare: ₹5 to ₹25', _busGreen)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _busTypeCard('AC Bus', 'Air Conditioned', Icons.ac_unit_rounded,
                    AppTheme.infoColor,
                    () => _showBusTypeInfo(context, 'AC Buses',
                        'Air conditioned buses for a comfortable journey.\n\n'
                        '• Comfortable seating\n'
                        '• GPS tracked\n'
                        '• Electronic display inside\n'
                        '• Available on major routes\n'
                        '• Fare: ₹10 to ₹50', AppTheme.infoColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _busTypeCard('Electric', 'Zero Emission Bus',
                    Icons.electric_bolt_rounded, AppTheme.metroOrange,
                    () => _showBusTypeInfo(context, 'Electric Buses',
                        'Delhi\'s green initiative — 100% electric fleet.\n\n'
                        '• Zero emissions\n'
                        '• 300+ e-buses operational\n'
                        '• Quieter & smoother ride\n'
                        '• Same fare as regular DTC\n'
                        '• Expanding across all routes', AppTheme.metroOrange)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _busTypeCard(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: icon, color: color, size: 38, radius: 12, filled: true),
              const Spacer(),
              Icon(Icons.info_outline_rounded, size: 16, color: p.textTertiary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: p.textTertiary),
          ),
        ],
      ),
    );
  }

  // ── Popular routes ────────────────────────────────────────────────────────

  Widget _buildPopularRoutes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _popularRoutes.map((r) => _routeCard(r, context)).toList(),
      ),
    );
  }

  Widget _routeCard(_BusRoute route, BuildContext context) {
    final p = context.palette;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/bus/route-finder'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.emeraldGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.glow(_busGreen, alpha: 0.25),
            ),
            child: Center(
              child: Text(
                route.number,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.from} → ${route.to}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: p.textTertiary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Route ${route.number} · ${route.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: p.tint(_busGreen), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: _busGreen, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Fare info ─────────────────────────────────────────────────────────────

  Widget _buildFareInfo(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBubble(icon: Icons.confirmation_number_rounded, color: AppTheme.accentColor, size: 38, radius: 12),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fare information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _fareChip('Regular', '₹5–25', _busGreen)),
                const SizedBox(width: 8),
                Expanded(child: _fareChip('AC Bus', '₹10–50', AppTheme.infoColor)),
                const SizedBox(width: 8),
                Expanded(child: _fareChip('Electric', '₹5–25', AppTheme.metroOrange)),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today_rounded, 'Day pass: ₹50 (unlimited travel)', AppTheme.primaryColor),
            const SizedBox(height: 8),
            _infoRow(Icons.people_alt_rounded, 'Women & seniors: concessional fares', AppTheme.brandViolet),
            const SizedBox(height: 8),
            _infoRow(Icons.school_rounded, 'Student pass: ₹200/month', AppTheme.accentColor),
          ],
        ),
      ),
    );
  }

  Widget _fareChip(String label, String value, Color color) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: p.tint(color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: p.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    final p = context.palette;
    return Row(
      children: [
        IconBubble(icon: icon, color: color, size: 28, radius: 9),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12.5, color: p.textSecondary, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  void _showBusTypeInfo(BuildContext context, String title, String body, [Color color = _busGreen]) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final p = sheetContext.palette;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    IconBubble(icon: Icons.directions_bus_rounded, color: color, filled: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.cardAlt,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    body,
                    style: TextStyle(fontSize: 14, color: p.textSecondary, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BusRoute {
  final String from;
  final String to;
  final String number;
  final String time;
  const _BusRoute(this.from, this.to, this.number, this.time);
}
