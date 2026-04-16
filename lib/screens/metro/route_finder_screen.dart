import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../models/metro_route.dart';
import '../../utils/app_theme.dart';
import '../../widgets/searchable_station_dropdown.dart';
import '../../services/recent_routes_service.dart';

class MetroRouteFinderScreen extends StatefulWidget {
  const MetroRouteFinderScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
      _loadRecentRoutes();
    });
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
    setState(() {
      _isSearching = true;
      _searched = true;
    });

    final metroProvider = context.read<MetroProvider>();
    final routes = await metroProvider.findRoute(_fromStation!, _toStation!);

    // Save to recent routes regardless of result (user intended this search)
    await RecentRoutesService.add(_fromStation!, _toStation!);
    await _loadRecentRoutes();

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Route Finder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.metroRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<MetroProvider>(
        builder: (context, metroProvider, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputCard(metroProvider),
                    if (_recentRoutes.isNotEmpty && _routes.isEmpty && !_searched)
                      _buildRecentRoutesSection(),
                  ],
                ),
              ),
              _buildResultsSliver(metroProvider),
            ],
          );
        },
      ),
    );
  }

  // ── Input Card ──────────────────────────────────────────────────────────────

  Widget _buildInputCard(MetroProvider metroProvider) {
    return Container(
      color: AppTheme.metroRed,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status row
              if (metroProvider.isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading ${metroProvider.stations.length} stations…',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else if (metroProvider.stations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        '${metroProvider.stations.length} stations ready',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // From field
              const Text(
                'FROM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              SearchableStationDropdown(
                stations: metroProvider.stations,
                selectedStation: _fromStation,
                hintText: metroProvider.isLoading
                    ? 'Loading stations…'
                    : 'Search starting station',
                prefixIcon: Icons.location_on,
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: _swapStations,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.metroRed.withOpacity(0.4)),
                        shape: BoxShape.circle,
                        color: AppTheme.metroRed.withOpacity(0.05),
                      ),
                      child: const Icon(
                        Icons.swap_vert,
                        size: 22,
                        color: AppTheme.metroRed,
                      ),
                    ),
                  ),
                ),
              ),

              // To field
              const Text(
                'TO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              SearchableStationDropdown(
                stations: metroProvider.stations,
                selectedStation: _toStation,
                hintText: metroProvider.isLoading
                    ? 'Loading stations…'
                    : 'Search destination station',
                prefixIcon: Icons.flag,
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

              const SizedBox(height: 16),

              // Search button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _canSearch() ? _searchRoutes : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.metroRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, size: 20),
                  label: Text(
                    _isSearching ? 'Searching…' : 'Find Route',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recent Routes ────────────────────────────────────────────────────────────

  Widget _buildRecentRoutesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await RecentRoutesService.clear();
                  await _loadRecentRoutes();
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.metroRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._recentRoutes.map((recent) => _buildRecentRouteChip(recent)),
        ],
      ),
    );
  }

  Widget _buildRecentRouteChip(RecentRoute recent) {
    return InkWell(
      onTap: () => _applyRecentRoute(recent),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.metroRed.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_transit,
                  size: 16, color: AppTheme.metroRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recent.from,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward,
                          size: 10, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          recent.to,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ── Results ──────────────────────────────────────────────────────────────────

  Widget _buildResultsSliver(MetroProvider metroProvider) {
    if (_isSearching) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.metroRed),
              SizedBox(height: 16),
              Text(
                'Finding best route…',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.route,
                        size: 18, color: AppTheme.metroRed),
                    const SizedBox(width: 8),
                    Text(
                      '${_routes.length} Route${_routes.length > 1 ? 's' : ''} Found',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }
            final route = _routes[index - 1];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off,
                      size: 36, color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Route Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We couldn\'t find a route between\n${_fromStation ?? ''} and ${_toStation ?? ''}.\nTry different stations.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _searchRoutes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.metroRed,
                    side: const BorderSide(color: AppTheme.metroRed),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Initial empty state — prompt user to select stations
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.metroRed.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_transit,
                    size: 40, color: AppTheme.metroRed),
              ),
              const SizedBox(height: 16),
              const Text(
                'Plan Your Journey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your starting station and\ndestination above to find the\nbest metro route.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Route Card ──────────────────────────────────────────────────────────────

  Widget _buildRouteCard(MetroRoute route, int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            color: AppTheme.metroRed,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${route.fromStation} → ${route.toStation}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      Icons.access_time,
                      '${route.totalTime} min',
                      AppTheme.metroRed,
                    ),
                    _buildStatChip(
                      Icons.currency_rupee,
                      '${route.totalFare.toStringAsFixed(0)}',
                      AppTheme.metroBlue,
                    ),
                    _buildStatChip(
                      Icons.train,
                      '${route.totalStations} stops',
                      Colors.green,
                    ),
                    _buildStatChip(
                      Icons.swap_horiz,
                      '${route.interchangeStations.length} change${route.interchangeStations.length == 1 ? '' : 's'}',
                      Colors.orange,
                    ),
                  ],
                ),

                if (route.interchangeStations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Change at: ${route.interchangeStations.join(' → ')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Text(
                  'Journey Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                ...route.segments.asMap().entries.map(
                      (e) => _buildDetailedSegment(
                          e.value, e.key + 1, route.segments.length),
                    ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Smart card saves 10% on fares. Allow 5 min for interchanges.',
                          style: TextStyle(fontSize: 11, color: Colors.blue),
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

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedSegment(
      RouteSegment segment, int segmentNumber, int totalSegments) {
    Color lineColor;
    try {
      lineColor =
          Color(int.parse(segment.lineColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      lineColor = AppTheme.metroBlue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segment header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: lineColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration:
                      BoxDecoration(color: lineColor, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '$segmentNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    segment.line,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: lineColor,
                    ),
                  ),
                ),
                Text(
                  '${segment.timeMinutes} min · ${segment.stationsCount} stops',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Station list
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildCompleteStationList(segment, lineColor),
          ),
          if (segmentNumber < totalSegments)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.orange.withOpacity(0.06),
              child: const Row(
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: Colors.orange),
                  SizedBox(width: 6),
                  Text(
                    'Change platform here',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteStationList(RouteSegment segment, Color lineColor) {
    final allStations = <String>[
      segment.fromStation,
      ...segment.intermediateStations,
      segment.toStation,
    ];

    return Column(
      children: allStations.asMap().entries.map((entry) {
        final index = entry.key;
        final stationName = entry.value;
        final isFirst = index == 0;
        final isLast = index == allStations.length - 1;

        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isFirst || isLast
                              ? lineColor
                              : lineColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: lineColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isFirst
                              ? const Icon(Icons.play_arrow,
                                  size: 11, color: Colors.white)
                              : isLast
                                  ? const Icon(Icons.flag,
                                      size: 11, color: Colors.white)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: lineColor,
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stationName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isFirst || isLast
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isFirst || isLast ? Colors.black87 : Colors.grey[700],
                    ),
                  ),
                ),
                if (isFirst)
                  _stationBadge('START', Colors.green)
                else if (isLast)
                  _stationBadge('END', AppTheme.metroRed),
              ],
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Container(
                  width: 2,
                  height: 16,
                  color: lineColor.withOpacity(0.25),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _stationBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
