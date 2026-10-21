import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/responsive_helper.dart';
import 'bus_ui.dart';

class ProfessionalBusHomeScreen extends StatefulWidget {
  const ProfessionalBusHomeScreen({super.key});

  @override
  State<ProfessionalBusHomeScreen> createState() =>
      _ProfessionalBusHomeScreenState();
}

class _ProfessionalBusHomeScreenState extends State<ProfessionalBusHomeScreen> {
  static const _busGreen = busGreen;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _showAllPopular = false;

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().ensureLoaded();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final p = context.palette;
    final bus = context.watch<BusProvider>();

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
              if (_query.isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildSearchResults(bus),
                const SizedBox(height: 100),
              ] else ...[
              const SizedBox(height: 22),
              if (bus.hasError) ...[
                BusNetworkStatusView(bus: bus),
                const SizedBox(height: 10),
              ],
              _buildPlanCard(context),
              const SizedBox(height: 16),
              _buildNetworkStats(bus),
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
                subtitle: 'Busiest by scheduled trips per day',
                actionLabel: bus.isReady ? (_showAllPopular ? 'Show less' : 'Show more') : null,
                onAction: () => setState(() => _showAllPopular = !_showAllPopular),
              ),
              const SizedBox(height: 12),
              _buildPopularRoutes(context, bus),
              const SizedBox(height: 26),
              _buildFareInfo(context),
              const SizedBox(height: 100),
              ],
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
          icon: Icons.near_me_rounded,
          tooltip: 'Bus stops near me',
          onTap: () => context.push('/bus/stop-locator'),
        ),
      ],
      bottom: _buildSearchBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: _onQuery,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        cursorColor: _busGreen,
        decoration: InputDecoration(
          hintText: 'Route number or stop, e.g. 534 or Nehru Place',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          prefixIcon: const Icon(Icons.search_rounded, color: _busGreen),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textTertiary, size: 20),
                  onPressed: _clearSearch,
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ── Search results ────────────────────────────────────────────────────────

  Widget _buildSearchResults(BusProvider bus) {
    final p = context.palette;
    if (!bus.isReady) return BusNetworkStatusView(bus: bus);
    final results = bus.search(_query);
    if (results.isEmpty) {
      return EmptyState(
        title: 'Nothing matches "$_query"',
        message: 'Try a route number like 534 or part of a stop name like "Kashmere".',
      );
    }
    Widget label(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Text(
            text,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (results.routes.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label('ROUTES'),
                  for (final r in results.routes)
                    InkWell(
                      onTap: () => context.push(routePath(r.line)),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                        child: Row(
                          children: [
                            BusNumberBadge(r.number),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                r.termini,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: p.textTertiary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (results.places.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label('STOPS'),
                  for (final place in results.places)
                    BusPlaceTile(place: place, onTap: () => context.push(stopPath(place.stops.first.id))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkStats(BusProvider bus) {
    String v(int Function() f) => bus.isReady ? formatCount(f()) : '…';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: StatTile(value: v(() => bus.routeCount), label: 'Routes', icon: Icons.route_rounded, color: _busGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(value: v(() => bus.stopCount), label: 'Bus stops', icon: Icons.place_rounded, color: AppTheme.metroBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(
                value: v(() => bus.dailyTrips), label: 'Trips / day', icon: Icons.directions_bus_rounded, color: AppTheme.accentColor),
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
                        'Direct & one-change DTC and cluster buses',
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
                child: _actionCard('Live Buses', 'GPS tracking', Icons.radar_rounded,
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
    final bus = context.read<BusProvider>();
    final dtcRoutes = bus.isReady ? '\n• ${bus.routeCountForAgency('DTC')} DTC route numbers in the timetable' : '';
    final clusterRoutes =
        bus.isReady ? '\n• ${bus.routeCountForAgency('DIMTS')} cluster route numbers in the timetable' : '';
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
                        '• Low-floor buses for accessibility\n'
                        '• Passes available monthly & quarterly\n'
                        '• Fare: ₹5–15 non-AC, ₹10–25 AC, by distance\n'
                        '• Women ride free with a pink ticket'
                        '$dtcRoutes', AppTheme.metroBlue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _busTypeCard('Cluster', 'Cluster Bus Services',
                    Icons.directions_bus_filled_rounded, _busGreen,
                    () => _showBusTypeInfo(context, 'Cluster Buses',
                        'Cluster buses are operated by private companies under Delhi government.\n\n'
                        '• Managed by DIMTS, complements DTC routes\n'
                        '• Air conditioned options available\n'
                        '• Fare: ₹5–15 non-AC, ₹10–25 AC, by distance\n'
                        '• Women ride free with a pink ticket'
                        '$clusterRoutes', _busGreen)),
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
                        '• Fare: ₹10 up to 4 km, ₹15 up to 8 km, ₹20 up to 12 km, ₹25 beyond', AppTheme.infoColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _busTypeCard('Electric', 'Zero Emission Bus',
                    Icons.electric_bolt_rounded, AppTheme.metroOrange,
                    () => _showBusTypeInfo(context, 'Electric Buses',
                        'Delhi\'s green initiative — 100% electric fleet.\n\n'
                        '• Zero tailpipe emissions\n'
                        '• Quieter & smoother ride\n'
                        '• Air conditioned — AC fares apply (₹10–25)\n'
                        '• Run by DTC and cluster operators', AppTheme.metroOrange)),
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

  Widget _buildPopularRoutes(BuildContext context, BusProvider bus) {
    if (!bus.isReady) {
      return bus.hasError ? const SizedBox.shrink() : const BusLoadingView(message: 'Loading routes…');
    }
    final routes = bus.popularRoutes(limit: _showAllPopular ? 12 : 5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: routes.map((r) => _routeCard(r, context)).toList(),
      ),
    );
  }

  Widget _routeCard(BusRouteSummary route, BuildContext context) {
    final p = context.palette;
    final freq = route.headwayMinutes == null ? '' : 'Every ~${route.headwayMinutes} min · ';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(routePath(route.line)),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
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
                  route.termini,
                  maxLines: 2,
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
                        '$freq${route.dailyTrips} trips/day',
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
                Expanded(child: _fareChip('Non-AC', '₹5–15', _busGreen)),
                const SizedBox(width: 8),
                Expanded(child: _fareChip('AC / Electric', '₹10–25', AppTheme.infoColor)),
                const SizedBox(width: 8),
                Expanded(child: _fareChip('Women', 'Free', pinkTicket)),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 12),
            _infoRow(Icons.straighten_rounded, 'Non-AC: ₹5 up to 4 km, ₹10 up to 10 km, ₹15 beyond', AppTheme.primaryColor),
            const SizedBox(height: 8),
            _infoRow(Icons.ac_unit_rounded, 'AC: ₹10 up to 4 km, ₹15 up to 8 km, ₹20 up to 12 km, ₹25 beyond',
                AppTheme.infoColor),
            const SizedBox(height: 8),
            _infoRow(Icons.confirmation_number_rounded, 'Women ride free on DTC & cluster buses (pink ticket)', pinkTicket),
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
