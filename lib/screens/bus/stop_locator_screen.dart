import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/bus_network.dart';
import '../../providers/bus_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/ui_kit.dart';
import 'bus_ui.dart';

/// Nearest bus stops from GPS, or find one by name.
class BusStopLocatorScreen extends StatefulWidget {
  const BusStopLocatorScreen({super.key});

  @override
  State<BusStopLocatorScreen> createState() => _BusStopLocatorScreenState();
}

class _BusStopLocatorScreenState extends State<BusStopLocatorScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  bool _locating = false;
  Position? _position;
  LocationIssue? _issue;

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().ensureLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _issue = null;
    });
    final (pos, issue) = await locateUser(context);
    if (!mounted) return;
    setState(() {
      _locating = false;
      _position = pos;
      _issue = issue;
    });
  }

  void _onQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bus = context.watch<BusProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: 'Nearby Bus Stops',
                subtitle: 'DTC & cluster stops around you',
                icon: Icons.place_rounded,
                gradient: AppTheme.emeraldGradient,
                illustration: 'assets/images/illus_bus.svg',
                actions: [
                  HeaderIconButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Refresh location',
                    onTap: _locate,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onQuery,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary),
                  decoration: busFieldDecoration(
                    context,
                    hint: 'Search a bus stop by name',
                    icon: Icons.search_rounded,
                    suffix: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: Icon(Icons.close_rounded, color: p.textTertiary, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
            ),
            ..._buildBody(bus),
          ],
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
      ),
    );
  }

  List<Widget> _buildBody(BusProvider bus) {
    if (!bus.isReady) {
      return [SliverFillRemaining(hasScrollBody: false, child: Center(child: BusNetworkStatusView(bus: bus)))];
    }
    if (_query.isNotEmpty) return _buildSearchResults(bus);
    if (_locating && _position == null) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: Center(child: BusLoadingView(message: 'Finding your location…'))),
      ];
    }
    if (_position == null) {
      final issue = _issue ?? LocationIssue.unavailable;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              title: issue.title,
              message: '${issue.message}\nYou can also search for a stop by name above.',
              action: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (issue.settingsLabel != null)
                    GradientButton(
                      label: issue.settingsLabel!,
                      icon: Icons.settings_rounded,
                      gradient: AppTheme.emeraldGradient,
                      expand: false,
                      onPressed: issue.openSettings,
                    ),
                  OutlinedButton.icon(
                    onPressed: _locate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(issue == LocationIssue.denied ? 'Allow location' : 'Try again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: busGreen,
                      side: const BorderSide(color: busGreen),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    final pos = _position!;
    final near = bus.nearbyStops(pos.latitude, pos.longitude, limit: 15, maxKm: 2);
    final p = context.palette;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Closest to you',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.textPrimary, letterSpacing: -0.3),
                ),
              ),
              if (_locating)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: busGreen))
              else
                TagPill(label: '${near.length} STOPS', color: busGreen, icon: Icons.directions_bus_rounded),
            ],
          ),
        ),
      ),
      if (near.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              title: 'No bus stops within 2 km',
              message: 'You seem to be outside the Delhi bus network. Search for a stop by name above.',
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _NearbyCard(stop: near[i]),
              childCount: near.length,
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildSearchResults(BusProvider bus) {
    final hits = bus.suggestPlaces(_query, limit: 25);
    if (hits.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              title: 'No stop matches "$_query"',
              message: 'Check the spelling or try part of the name, like "Kashmere" or "Nehru".',
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverToBoxAdapter(
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                for (final place in hits)
                  BusPlaceTile(
                    place: place,
                    trailing: _distanceTo(place),
                    onTap: () => context.push(stopPath(place.stops.first.id)),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget? _distanceTo(BusPlace place) {
    final pos = _position;
    if (pos == null) return null;
    final km = Geolocator.distanceBetween(pos.latitude, pos.longitude, place.lat, place.lon) / 1000;
    return Text(formatDistance(km), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.palette.textTertiary));
  }
}


class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.stop});

  final NearbyBusStop stop;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bus = context.read<BusProvider>();
    final numbers = bus.routeNumbersAt(stop.place);
    const maxChips = 10;
    final lineFor = <String, BusLine>{};
    for (final l in bus.network.linesAtPlace(stop.place)) {
      lineFor.putIfAbsent(l.number, () => l);
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 20,
      onTap: () => context.push(stopPath(stop.stop.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.directions_bus_rounded, color: busGreen, size: 42, radius: 13),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${numbers.length} route${numbers.length == 1 ? '' : 's'} · ${stop.walkMinutes} min walk',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: p.tint(AppTheme.primaryColor), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_walk_rounded, size: 13, color: p.primary),
                    const SizedBox(width: 3),
                    Text(
                      formatDistance(stop.distanceKm),
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: p.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (numbers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final n in numbers.take(maxChips))
                  BusNumberChip(n, onTap: () => context.push(routePath(lineFor[n]!))),
                if (numbers.length > maxChips)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      '+${numbers.length - maxChips} more',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.textTertiary),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
