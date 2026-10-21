import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
import '../../models/bus_route.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/ui_kit.dart';

class BusRouteFinderScreen extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;

  const BusRouteFinderScreen({
    super.key,
    this.initialFrom,
    this.initialTo,
  });

  @override
  State<BusRouteFinderScreen> createState() => _BusRouteFinderScreenState();
}

class _BusRouteFinderScreenState extends State<BusRouteFinderScreen> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  List<BusRoute> _routes = [];
  bool _isSearching = false;
  bool _searched = false;

  static const _busGreen = Color(0xFF059669);

  // Quick popular DTC bus hubs
  static const _popularBusStops = [
    'ISBT Kashmere Gate',
    'Connaught Place',
    'India Gate',
    'Red Fort (Lal Qila)',
    'Chandni Chowk',
    'AIIMS / Safdarjung Hospital',
    'Nehru Place Terminal',
    'Karol Bagh',
    'Lajpat Nagar',
    'Saket',
  ];

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialFrom ?? '');
    _toController = TextEditingController(text: widget.initialTo ?? '');

    _fromController.addListener(_onTextChanged);
    _toController.addListener(_onTextChanged);

    if (_canSearch()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchRoutes());
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _fromController.removeListener(_onTextChanged);
    _toController.removeListener(_onTextChanged);
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
      _routes = [];
      _searched = false;
    });
  }

  bool _canSearch() {
    return _fromController.text.trim().isNotEmpty &&
        _toController.text.trim().isNotEmpty &&
        !_isSearching;
  }

  void _searchRoutes() async {
    if (!_canSearch()) return;

    setState(() {
      _isSearching = true;
      _searched = true;
    });

    final busProvider = context.read<BusProvider>();
    final routes = await busProvider.findRoute(
      _fromController.text.trim(),
      _toController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _routes = routes;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Consumer<BusProvider>(
          builder: (context, busProvider, child) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: GradientHeader(
                    title: 'Bus Route Finder',
                    subtitle: 'Direct DTC & cluster routes across Delhi',
                    icon: Icons.alt_route_rounded,
                    gradient: AppTheme.emeraldGradient,
                    illustration: 'assets/images/illus_bus.svg',
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Input Selection Card
                        _buildInputCard(),
                        const SizedBox(height: 20),

                        // Popular Destination Chips
                        _buildPopularChips(),
                        const SizedBox(height: 20),

                        if (_isSearching) _buildLoading(),

                        if (_searched && !_isSearching && _routes.isEmpty)
                          _buildEmptyResults(),

                        if (_routes.isNotEmpty)
                          Row(
                            children: [
                              const IconBubble(
                                icon: Icons.directions_bus_rounded,
                                color: _busGreen,
                                size: 34,
                                radius: 10,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_routes.length} Available Bus Routes',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // Routes Sliver List
                if (_routes.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildRouteCard(_routes[index]),
                        childCount: _routes.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
      ),
    );
  }

  // ── Input Card ─────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    final p = context.palette;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textTertiary),
      hintStyle: TextStyle(fontSize: 13, color: p.textTertiary),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      filled: true,
      fillColor: p.cardAlt,
      contentPadding: const EdgeInsets.fromLTRB(14, 14, 56, 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _busGreen, width: 1.6),
      ),
    );
  }

  Widget _buildInputCard() {
    final p = context.palette;
    final fieldStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary);

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.commute_rounded, color: _busGreen, size: 36, radius: 11),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Plan Bus Trip',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
              const TagPill(label: 'DTC & CLUSTER', color: _busGreen),
            ],
          ),
          const SizedBox(height: 20),

          // Origin + destination fields with a floating swap button between them
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  TextField(
                    controller: _fromController,
                    style: fieldStyle,
                    decoration: _fieldDecoration(
                      label: 'FROM',
                      hint: 'Enter origin bus stop or area',
                      icon: Icons.trip_origin_rounded,
                      iconColor: _busGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _toController,
                    style: fieldStyle,
                    decoration: _fieldDecoration(
                      label: 'TO',
                      hint: 'Enter destination bus stop or landmark',
                      icon: Icons.location_on_rounded,
                      iconColor: AppTheme.brandRose,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.glow(_busGreen, alpha: 0.22),
                    ),
                    child: Material(
                      color: p.card,
                      shape: CircleBorder(side: BorderSide(color: p.border)),
                      child: InkWell(
                        onTap: _swapLocations,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.swap_vert_rounded, size: 20, color: _busGreen),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search Button (Disabled until both stops are specified)
          GradientButton(
            label: 'Search Bus Routes',
            icon: Icons.search_rounded,
            gradient: AppTheme.emeraldGradient,
            onPressed: _canSearch() ? _searchRoutes : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularChips() {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POPULAR BUS STOPS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: p.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            children: _popularBusStops.map((stop) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: p.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: p.border),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (_fromController.text.isEmpty) {
                        _fromController.text = stop;
                      } else {
                        _toController.text = stop;
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: p.tint(_busGreen),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_bus_filled_rounded, size: 11, color: _busGreen),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stop,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3, color: _busGreen),
            ),
            const SizedBox(height: 14),
            Text(
              'Finding the best bus routes…',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
    return const Center(
      child: EmptyState(
        title: 'No direct bus routes found',
        message: 'Try searching nearby landmark stops like Connaught Place or Kashmere Gate.',
      ),
    );
  }

  Widget _buildRouteCard(BusRoute route) {
    final p = context.palette;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.tint(_busGreen),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppTheme.emeraldGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppTheme.glow(_busGreen, alpha: 0.25),
                  ),
                  child: Text(
                    'BUS ${route.busNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.schedule_rounded, size: 14, color: _busGreen),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '~${route.totalTime} min',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _busGreen,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _busGreen.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '₹${route.fare.toStringAsFixed(0)} Fare',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _busGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Journey details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildEndpoint('FROM', route.fromLocation, _busGreen),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: p.cardAlt, shape: BoxShape.circle),
                        child: Icon(Icons.arrow_forward_rounded, color: p.textTertiary, size: 16),
                      ),
                    ),
                    Expanded(
                      child: _buildEndpoint('TO', route.toLocation, AppTheme.brandRose),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatPill(Icons.schedule_rounded, route.frequency, AppTheme.primaryColor),
                    _buildStatPill(Icons.straighten_rounded,
                        '${route.totalDistance.toStringAsFixed(1)} km', AppTheme.accentColor),
                    _buildStatPill(Icons.place_rounded, '${route.stops.length} stops', AppTheme.brandViolet),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpoint(String label, String value, Color dot) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: p.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(IconData icon, String text, Color color) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.tint(color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
