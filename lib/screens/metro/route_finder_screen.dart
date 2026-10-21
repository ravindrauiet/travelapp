import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../models/metro_route.dart';
import '../../utils/app_theme.dart';
import '../../widgets/searchable_station_dropdown.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/bottom_navigation.dart';
import '../../services/recent_routes_service.dart';
import '../../services/gtfs_graph_service.dart';
import '../../services/accurate_fare_calculator.dart';
import '../../utils/user_location.dart';

class MetroRouteFinderScreen extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;

  const MetroRouteFinderScreen({
    super.key,
    this.initialFrom,
    this.initialTo,
  });

  @override
  State<MetroRouteFinderScreen> createState() => _MetroRouteFinderScreenState();
}

class _MetroRouteFinderScreenState extends State<MetroRouteFinderScreen> {
  String? _fromStation;
  String? _toStation;
  List<MetroRoute> _routes = [];
  bool _isSearching = false;
  bool _searched = false; // true once user has pressed Find Route at least once
  List<RecentRoute> _recentRoutes = [];
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _fromStation = _nonEmpty(widget.initialFrom);
    _toStation = _nonEmpty(widget.initialTo);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadRecentRoutes();
      await context.read<MetroProvider>().loadStations();
      if (!mounted) return;
      // Deep links may carry landmark-ish or old spellings ("Noida Sec 18",
      // "IGI Airport T3") — map them to the station names in the picker.
      final unknown = <String>[];
      Future<String?> resolve(String? name) async {
        if (name == null) return null;
        String? r;
        try {
          r = await GTFSGraphService.resolveStationName(name);
        } catch (_) {
          r = null;
        }
        if (r == null) unknown.add(name);
        return r;
      }

      final from = await resolve(_fromStation);
      final to = await resolve(_toStation);
      if (!mounted) return;
      setState(() {
        _fromStation = from;
        _toStation = to;
      });
      if (unknown.isNotEmpty) {
        _showMessage('Couldn\'t find "${unknown.join('", "')}" — please pick the station from the list.');
      }
      if (_fromStation != null && _toStation != null) {
        _searchRoutes();
      }
    });
  }

  static String? _nonEmpty(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

  void _showMessage(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  /// Fills the FROM field with the metro station nearest to the user.
  Future<void> _useNearestStation() async {
    if (_locating) return;
    final metroProvider = context.read<MetroProvider>();
    setState(() => _locating = true);
    final result = await getUserLocation();
    if (!mounted) return;
    setState(() => _locating = false);

    if (!result.ok) {
      final msg = switch (result.issue) {
        LocationIssue.serviceOff => 'Location (GPS) is turned off. Turn it on to find your nearest station.',
        LocationIssue.denied => 'Location permission denied. You can still pick a station from the list.',
        LocationIssue.deniedForever => 'Location access is blocked for Metromate. Enable it in Settings.',
        _ => 'Couldn\'t get your location right now. Please pick a station from the list.',
      };
      _showMessage(
        msg,
        action: result.needsSettings
            ? SnackBarAction(label: 'Settings', onPressed: () => openLocationSettingsFor(result.issue))
            : null,
      );
      return;
    }

    final pos = result.position!;
    final nearest = metroProvider.findNearestStations(pos.latitude, pos.longitude, limit: 1);
    if (nearest.isEmpty) {
      _showMessage('Stations are still loading — try again in a moment.');
      return;
    }
    final station = nearest.first;
    final km = AccurateFareCalculator.calculateDistance(
        pos.latitude, pos.longitude, station.latitude, station.longitude);
    setState(() {
      _fromStation = station.name;
      _routes = [];
      _searched = false;
    });
    final away = km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
    _showMessage(km > 15
        ? 'Nearest metro station is ${station.name}, $away away — you seem to be outside the metro area.'
        : 'Nearest station: ${station.name} ($away away)');
  }

  Future<void> _loadRecentRoutes() async {
    final routes = await RecentRoutesService.getAll();
    if (mounted) {
      setState(() => _recentRoutes = routes);
    }
  }

  void _swapStations() {
    setState(() {
      final temp = _fromStation;
      _fromStation = _toStation;
      _toStation = temp;
      _routes = [];
      _searched = false;
    });
  }

  bool _canSearch() =>
      _fromStation != null && _toStation != null && !_isSearching;

  Future<void> _searchRoutes() async {
    if (!_canSearch()) return;
    if (_fromStation!.toLowerCase() == _toStation!.toLowerCase()) {
      _showMessage('Starting point and destination are the same station. Pick a different destination.');
      return;
    }
    setState(() {
      _isSearching = true;
      _searched = true;
    });

    final metroProvider = context.read<MetroProvider>();
    final routes = await metroProvider.findRoute(_fromStation!, _toStation!);

    // Remember successful searches only (with the canonical station names).
    if (routes.isNotEmpty) {
      await RecentRoutesService.add(routes.first.fromStation, routes.first.toStation);
      await _loadRecentRoutes();
    }

    if (mounted) {
      setState(() {
        _routes = routes;
        _isSearching = false;
      });
    }
  }

  void _applyRecentRoute(RecentRoute recent) {
    setState(() {
      _fromStation = recent.from;
      _toStation = recent.to;
      _routes = [];
      _searched = false;
    });
    _searchRoutes();
  }

  // Segments whose full station list the user has expanded (UI-only state).
  final Set<String> _expandedSegments = {};

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Consumer<MetroProvider>(
          builder: (context, metroProvider, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(metroProvider),
                      Transform.translate(
                        offset: const Offset(0, -34),
                        child: _buildInputCard(metroProvider),
                      ),
                      if (_recentRoutes.isNotEmpty && _routes.isEmpty && !_searched)
                        Transform.translate(
                          offset: const Offset(0, -22),
                          child: _buildRecentRoutesSection(),
                        ),
                    ],
                  ),
                ),
                _buildResultsSliver(metroProvider),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(MetroProvider metroProvider) {
    return GradientHeader(
      title: 'Route Finder',
      subtitle: 'Fastest metro route across Delhi NCR',
      icon: Icons.alt_route_rounded,
      illustration: 'assets/images/illus_metro.svg',
      bottom: Padding(
        padding: const EdgeInsets.only(bottom: 34),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (metroProvider.isLoading)
              const TagPill(label: 'LOADING STATIONS…', color: Colors.white, icon: Icons.sync_rounded, onDark: true)
            else
              TagPill(
                label: '${metroProvider.stations.length} STATIONS READY',
                color: Colors.white,
                icon: Icons.check_circle_rounded,
                onDark: true,
              ),
            const TagPill(label: 'SMART FARES', color: Colors.white, icon: Icons.currency_rupee_rounded, onDark: true),
            const TagPill(label: 'INTERCHANGES', color: Colors.white, icon: Icons.swap_horiz_rounded, onDark: true),
          ],
        ),
      ),
    );
  }

  // ── Input Card ──────────────────────────────────────────────────────────────

  Widget _buildInputCard(MetroProvider metroProvider) {
    final p = context.palette;

    Widget fieldLabel(String text, Color dot) {
      return Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: dot, width: 2.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: p.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.route_rounded, color: AppTheme.primaryColor, size: 38, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan your journey',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                    Text(
                      'Pick two stations — we do the rest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.textTertiary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (metroProvider.isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // From field
          Row(
            children: [
              Expanded(child: fieldLabel('FROM', AppTheme.successColor)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: TextButton.icon(
                  onPressed: _locating || metroProvider.stations.isEmpty ? null : _useNearestStation,
                  icon: _locating
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(_locating ? 'Locating…' : 'Nearest station'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily),
                  ),
                ),
              ),
            ],
          ),
          SearchableStationDropdown(
            stations: metroProvider.stations,
            selectedStation: _fromStation,
            hintText: metroProvider.isLoading ? 'Loading stations…' : 'Search starting station',
            prefixIcon: Icons.trip_origin_rounded,
            accentColor: AppTheme.successColor,
            onChanged: (value) {
              if (metroProvider.stations.isNotEmpty) {
                setState(() {
                  _fromStation = value;
                  _routes = [];
                  _searched = false;
                });
              }
            },
          ),

          // Swap button row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider(color: p.border, height: 1)),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Swap stations',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _swapStations,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.glow(AppTheme.brandViolet, alpha: 0.3),
                        ),
                        child: const Icon(Icons.swap_vert_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Divider(color: p.border, height: 1)),
              ],
            ),
          ),

          // To field
          fieldLabel('TO', AppTheme.accentColor),
          SearchableStationDropdown(
            stations: metroProvider.stations,
            selectedStation: _toStation,
            hintText: metroProvider.isLoading ? 'Loading stations…' : 'Search destination station',
            prefixIcon: Icons.flag_rounded,
            accentColor: AppTheme.accentColor,
            onChanged: (value) {
              if (metroProvider.stations.isNotEmpty) {
                setState(() {
                  _toStation = value;
                  _routes = [];
                  _searched = false;
                });
              }
            },
          ),

          const SizedBox(height: 20),

          // Search button
          GradientButton(
            label: _isSearching ? 'Finding best route…' : 'Find Best Route',
            icon: _isSearching ? Icons.hourglass_top_rounded : Icons.search_rounded,
            onPressed: _canSearch() ? _searchRoutes : null,
          ),
        ],
      ),
    );
  }

  // ── Recent Routes ────────────────────────────────────────────────────────────

  Widget _buildRecentRoutesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent searches',
            subtitle: 'Tap to fill in the stations',
            actionLabel: 'Clear',
            onAction: () async {
              await RecentRoutesService.clear();
              await _loadRecentRoutes();
            },
          ),
          const SizedBox(height: 12),
          ..._recentRoutes.map((recent) => _buildRecentRouteChip(recent)),
        ],
      ),
    );
  }

  Widget _buildRecentRouteChip(RecentRoute recent) {
    final p = context.palette;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 20,
      onTap: () => _applyRecentRoute(recent),
      child: Row(
        children: [
          const IconBubble(icon: Icons.history_rounded, color: AppTheme.brandViolet, size: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recent.from,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: AppTheme.accentColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        recent.to,
                        style: TextStyle(fontSize: 12.5, color: p.textSecondary, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: p.textTertiary),
        ],
      ),
    );
  }

  // ── Results ──────────────────────────────────────────────────────────────────

  Widget _buildResultsSliver(MetroProvider metroProvider) {
    final p = context.palette;

    if (_isSearching) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: p.tint(p.primary),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(strokeWidth: 3, color: p.primary),
                ),
                const SizedBox(height: 18),
                Text(
                  'Finding the best route…',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Checking lines, interchanges and fares',
                  style: TextStyle(fontSize: 13, color: p.textTertiary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_routes.isNotEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionHeader(
                  title: '${_routes.length} route${_routes.length > 1 ? 's' : ''} found',
                  subtitle: '${_fromStation ?? ''} → ${_toStation ?? ''}',
                ),
              );
            }
            final route = _routes[index - 1];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: _buildRouteCard(route, index - 1),
            );
          },
          childCount: _routes.length + 1,
        ),
      );
    }

    if (_searched && !_isSearching) {
      // No routes found after a real search
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: EmptyState(
            title: 'No route found',
            message: metroProvider.error ??
                'We couldn\'t find a route between ${_fromStation ?? ''} and ${_toStation ?? ''}. Try different stations.',
            action: GradientButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: _searchRoutes,
            ),
          ),
        ),
      );
    }

    // Initial empty state — prompt user to select stations
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: EmptyState(
          title: 'Plan your journey',
          message: 'Select your starting station and destination above to find the best metro route.',
          illustration: 'assets/images/illus_metro.svg',
        ),
      ),
    );
  }

  // ── Route Card ──────────────────────────────────────────────────────────────

  Color _parseLineColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.metroBlue;
    }
  }

  Widget _buildRouteCard(MetroRoute route, int index) {
    final p = context.palette;
    final changes = route.interchangeStations.length;
    final isBest = index == 0;

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border.withValues(alpha: p.isDark ? 1 : 0.7)),
        boxShadow: p.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRouteSummary(route, index, isBest, changes),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (route.interchangeStations.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.tint(AppTheme.warningColor),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.warningColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Change line at ',
                                  style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: route.interchangeStations.join(', '),
                                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Text(
                      'Journey details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '${route.segments.length} leg${route.segments.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...route.segments.asMap().entries.map(
                      (e) => e.value.line == GTFSGraphService.walkLine
                          ? _buildWalkLeg(e.value)
                          : _buildDetailedSegment(
                              e.value,
                              e.key + 1,
                              route.segments.length,
                              segmentKey: '${route.id}-$index-${e.key}',
                              nextSegment: e.key + 1 < route.segments.length ? route.segments[e.key + 1] : null,
                            ),
                    ),

                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.tint(AppTheme.successColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded, size: 18, color: AppTheme.successColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fareNote(route),
                          style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w600),
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
    );
  }

  /// Gradient summary block: label, big travel time, from → to, stats and a
  /// proportional line strip showing each leg in its line colour.
  Widget _buildRouteSummary(MetroRoute route, int index, bool isBest, int changes) {
    final totalStops = route.segments.fold<int>(0, (sum, s) => sum + (s.stationsCount <= 0 ? 1 : s.stationsCount));

    Widget stat(IconData icon, String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TagPill(
                label: isBest ? 'BEST ROUTE' : 'OPTION ${index + 1}',
                color: Colors.white,
                icon: isBest ? Icons.bolt_rounded : Icons.alt_route_rounded,
                onDark: true,
              ),
              const Spacer(),
              Text(
                '${route.totalTime}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'min',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Text(
                  route.fromStation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFFFFB547)),
              ),
              Flexible(
                child: Text(
                  route.toStation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Proportional line strip
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (var i = 0; i < route.segments.length; i++) ...[
                    if (i > 0) Container(width: 3, color: Colors.white),
                    Expanded(
                      flex: totalStops == 0
                          ? 1
                          : (route.segments[i].stationsCount <= 0 ? 1 : route.segments[i].stationsCount),
                      child: Container(color: _parseLineColor(route.segments[i].lineColor)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: route.segments.where((s) => s.line != GTFSGraphService.walkLine).map((s) {
              final c = _parseLineColor(s.lineColor);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        s.line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              stat(Icons.currency_rupee_rounded, '₹${route.totalFare.toStringAsFixed(0)}',
                  route.fareLegs.length > 1 ? '${route.fareLegs.length} tickets' : 'Token fare'),
              const SizedBox(width: 8),
              stat(Icons.train_rounded, '${route.totalStations}', 'Stops'),
              const SizedBox(width: 8),
              stat(Icons.swap_horiz_rounded, '$changes', changes == 1 ? 'Change' : 'Changes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSegment(
    RouteSegment segment,
    int segmentNumber,
    int totalSegments, {
    required String segmentKey,
    RouteSegment? nextSegment,
  }) {
    final p = context.palette;
    final lineColor = _parseLineColor(segment.lineColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: p.cardAlt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: lineColor.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segment header
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(color: p.tint(lineColor)),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: AppTheme.glow(lineColor, alpha: 0.3),
                      ),
                      child: const Icon(Icons.directions_subway_rounded, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            segment.line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                          ),
                          Text(
                            'Leg $segmentNumber of $totalSegments',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${segment.timeMinutes} min',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: lineColor),
                        ),
                        Text(
                          '${segment.stationsCount} stops',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Station timeline
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: _buildCompleteStationList(segment, lineColor, segmentKey),
              ),
            ],
          ),
        ),
        if (segmentNumber < totalSegments && nextSegment?.line != GTFSGraphService.walkLine)
          _buildInterchangeConnector(segment, lineColor, nextSegment)
        else
          const SizedBox(height: 12),
      ],
    );
  }

  String _fareNote(MetroRoute route) {
    final card = route.smartCardFare?.round();
    final parts = <String>[];
    if (route.fareLegs.length > 1) {
      parts.add('Separate tickets: ${route.fareLegs.map((l) => '${l.system.label} ₹${l.tokenFare}').join(' + ')}.');
    }
    if (card != null && card < route.totalFare.round()) {
      parts.add('Smart Card now: ₹$card (10% off, 20% off-peak).');
    }
    if (route.distanceKm > 0) parts.add('${route.distanceKm.toStringAsFixed(1)} km.');
    if (route.fareIsApproximate) parts.add('Non-DMRC fares are approximate.');
    parts.add('Time is typical from the timetable, excl. waiting.');
    return parts.join(' ');
  }

  Widget _buildWalkLeg(RouteSegment walk) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.tint(AppTheme.warningColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_walk_rounded, size: 18, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Walk to ${walk.toStation}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                  ),
                  Text(
                    'From ${walk.fromStation} via the linked walkway · ~${walk.timeMinutes} min',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterchangeConnector(RouteSegment segment, Color fromColor, RouteSegment? next) {
    final p = context.palette;
    final toColor = next != null ? _parseLineColor(next.lineColor) : AppTheme.warningColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Container(
            width: 4,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [fromColor, toColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: p.tint(AppTheme.warningColor),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.transfer_within_a_station_rounded, size: 18, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change at ${segment.toStation}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                        ),
                        Text(
                          next == null
                              ? 'Change platform here'
                              : next.line == segment.line
                                  ? 'Change trains here (branch line)'
                                  : GTFSGraphService.fareSystemFor(next.line) !=
                                          GTFSGraphService.fareSystemFor(segment.line)
                                      ? 'Exit & buy a separate ${next.line} ticket'
                                      : 'Walk to ${next.line} platform',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStationList(RouteSegment segment, Color lineColor, String segmentKey) {
    final p = context.palette;
    final allStations = <String>[
      segment.fromStation,
      ...segment.intermediateStations,
      segment.toStation,
    ];

    // Long legs collapse their middle stops until the user expands them.
    const collapseThreshold = 6;
    final canCollapse = segment.intermediateStations.length > collapseThreshold;
    final expanded = !canCollapse || _expandedSegments.contains(segmentKey);

    Widget stationRow(String stationName, {required bool isFirst, required bool isLast}) {
      final isEnd = isFirst || isLast;
      final rowHeight = isEnd ? 40.0 : 32.0;
      return SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: isFirst ? rowHeight / 2 : 0,
                    bottom: isLast ? rowHeight / 2 : 0,
                    child: Container(width: 4, color: lineColor.withValues(alpha: 0.85)),
                  ),
                  Container(
                    width: isEnd ? 18 : 10,
                    height: isEnd ? 18 : 10,
                    decoration: BoxDecoration(
                      color: isEnd ? lineColor : p.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: isEnd ? p.card : lineColor, width: isEnd ? 3 : 2.5),
                      boxShadow: isEnd ? AppTheme.glow(lineColor, alpha: 0.35) : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isEnd ? 13.5 : 12.5,
                  fontWeight: isEnd ? FontWeight.w800 : FontWeight.w500,
                  color: isEnd ? p.textPrimary : p.textSecondary,
                ),
              ),
            ),
            if (isFirst)
              _stationBadge('BOARD', AppTheme.successColor)
            else if (isLast)
              _stationBadge('ALIGHT', AppTheme.accentColor),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < allStations.length; i++) {
      final isFirst = i == 0;
      final isLast = i == allStations.length - 1;
      if (!expanded && !isFirst && !isLast) {
        if (i == 1) {
          rows.add(_buildCollapsedStops(segment.intermediateStations.length, lineColor, segmentKey));
        }
        continue;
      }
      rows.add(stationRow(allStations[i], isFirst: isFirst, isLast: isLast));
    }
    if (canCollapse && expanded) {
      rows.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _expandedSegments.remove(segmentKey)),
            icon: const Icon(Icons.unfold_less_rounded, size: 16),
            label: const Text('Hide stops'),
            style: TextButton.styleFrom(
              foregroundColor: lineColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily),
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildCollapsedStops(int count, Color lineColor, String segmentKey) {
    final p = context.palette;
    return InkWell(
      onTap: () => setState(() => _expandedSegments.add(segmentKey)),
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(
                child: Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        lineColor.withValues(alpha: 0.85),
                        lineColor.withValues(alpha: 0.3),
                        lineColor.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.tint(lineColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.unfold_more_rounded, size: 14, color: lineColor),
                  const SizedBox(width: 4),
                  Text(
                    'Show $count intermediate stops',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: lineColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.palette.tint(color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
