import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../models/bus_network.dart';
import '../../services/bus_network_service.dart';
import '../../services/live_bus_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/user_location.dart';
import '../../widgets/live_bus_widgets.dart';
import '../../widgets/ui_kit.dart';

/// Live positions of Delhi DTC & cluster buses from the OTD realtime feed.
/// Open with `/bus/realtime?route=764M` to start filtered to one route number.
class RealtimeBusTracker extends StatefulWidget {
  final String? initialRoute;

  const RealtimeBusTracker({super.key, this.initialRoute});

  @override
  State<RealtimeBusTracker> createState() => _RealtimeBusTrackerState();
}

class _RealtimeBusTrackerState extends State<RealtimeBusTracker> with WidgetsBindingObserver {
  static const Duration _refreshEvery = Duration(seconds: 30);
  static const double _nearRadiusKm = 2;

  final _live = LiveBusService.instance;
  final _net = BusNetworkService.instance;
  final _search = TextEditingController();
  final _focus = FocusNode();

  LiveBusSnapshot? _snap;
  LiveBusException? _error;
  bool _loading = false;

  String? _route; // selected route number
  bool _nearMe = false;
  Position? _me;
  UserLocationResult? _locFailure;
  bool _locating = false;

  bool _autoRefresh = true;
  Timer? _refreshTimer;
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final r = widget.initialRoute?.trim();
    if (r != null && r.isNotEmpty) {
      _route = r;
      _search.text = r;
    }
    _focus.addListener(() => setState(() {}));
    _snap = _live.lastSnapshot;
    _net.ensureLoaded().then((_) {
      if (mounted) setState(() => _normalizeRoute());
    }, onError: (Object e) => debugPrint('Tracker: bus network failed: $e'));
    _load();
    _startTimers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _clock?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_autoRefresh) {
        _load();
        _startTimers();
      }
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
      _clock?.cancel();
    }
  }

  void _startTimers() {
    _refreshTimer?.cancel();
    _clock?.cancel();
    if (_autoRefresh) _refreshTimer = Timer.periodic(_refreshEvery, (_) => _load());
    _clock = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  /// Use the network's spelling of a typed route number ("764m" → "764M").
  void _normalizeRoute() {
    final r = _route;
    if (r == null || !_net.isLoaded) return;
    final lines = _net.linesByNumber(r);
    if (lines.isNotEmpty) {
      _route = lines.first.number;
      if (!_focus.hasFocus) _search.text = _route!;
    }
  }

  Future<void> _load({bool force = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final snap = await _live.snapshot(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _snap = snap;
        _error = null;
      });
    } on LiveBusException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.kind == LiveBusErrorKind.unsupportedPlatform || e.kind == LiveBusErrorKind.badKey) {
        _refreshTimer?.cancel();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _now = DateTime.now();
        });
      }
    }
  }

  Future<void> _toggleNearMe() async {
    if (_nearMe) {
      setState(() => _nearMe = false);
      return;
    }
    setState(() {
      _nearMe = true;
      _locating = true;
      _locFailure = null;
    });
    final res = await getUserLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (res.ok) {
        _me = res.position;
      } else {
        _locFailure = res;
      }
    });
  }

  void _selectRoute(String? number) {
    setState(() {
      _route = number;
      _search.text = number ?? '';
    });
    _focus.unfocus();
  }

  void _toggleAuto() {
    setState(() => _autoRefresh = !_autoRefresh);
    if (_autoRefresh) _load();
    _startTimers();
  }

  // ── Derived data ──────────────────────────────────────────────────────────

  List<(LiveBus, double?)> _visibleBuses() {
    final snap = _snap;
    if (snap == null) return const [];
    Iterable<LiveBus> buses = _route != null ? snap.forRouteNumber(_route!) : snap.buses.where((b) => b.isMatched);

    final me = _me;
    if (me == null) {
      final list = buses.map((b) => (b, null as double?)).toList()
        ..sort((a, b) {
          final c = _compareNumbers(a.$1.routeNumber, b.$1.routeNumber);
          return c != 0 ? c : a.$1.registration.compareTo(b.$1.registration);
        });
      return _nearMe ? const [] : list;
    }
    final list = buses.map((b) => (b, b.distanceKmTo(me.latitude, me.longitude) as double?)).toList()
      ..sort((a, b) => a.$2!.compareTo(b.$2!));
    return _nearMe ? list.where((e) => e.$2! <= _nearRadiusKm).toList() : list;
  }

  static int _compareNumbers(String a, String b) {
    final na = int.tryParse(RegExp(r'^\d+').stringMatch(a) ?? '');
    final nb = int.tryParse(RegExp(r'^\d+').stringMatch(b) ?? '');
    if (na != null && nb != null && na != nb) return na.compareTo(nb);
    if (na != null && nb == null) return -1;
    if (na == null && nb != null) return 1;
    return a.compareTo(b);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final snap = _snap;
    final subtitle = snap == null
        ? (_error != null ? 'Live feed unavailable' : 'Connecting to Delhi\'s live feed…')
        : '${snap.count} buses live · updated ${formatAge(_now.difference(snap.fetchedAt))}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(
          children: [
            GradientHeader(
              title: 'Live Bus Tracker',
              subtitle: subtitle,
              icon: Icons.radar_rounded,
              gradient: AppTheme.emeraldGradient,
              illustration: 'assets/images/illus_bus.svg',
              actions: [
                HeaderIconButton(
                  icon: _autoRefresh ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onTap: _toggleAuto,
                  tooltip: _autoRefresh ? 'Pause auto refresh' : 'Resume auto refresh',
                ),
                const SizedBox(width: 8),
                HeaderIconButton(
                  icon: Icons.map_rounded,
                  tooltip: 'Bus map',
                  onTap: () => context.push(
                      _route == null ? '/bus/map' : '/bus/map?route=${Uri.encodeQueryComponent(_route!)}'),
                ),
                const SizedBox(width: 8),
                HeaderIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: () => _load(force: true),
                  tooltip: 'Refresh now',
                ),
              ],
              bottom: _buildSearchField(),
            ),
            if (_loading && snap != null) const LinearProgressIndicator(minHeight: 2, color: kBusGreen),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: TextField(
        controller: _search,
        focusNode: _focus,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        onChanged: (_) => setState(() {}),
        onSubmitted: (q) {
          final hits = _net.isLoaded ? _net.searchRoutes(q, limit: 1) : const <BusLine>[];
          if (hits.isNotEmpty) {
            _selectRoute(hits.first.number);
          } else if (q.trim().isEmpty) {
            _selectRoute(null);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search a route number, e.g. 764M',
          hintStyle: const TextStyle(color: AppTheme.textTertiary, fontWeight: FontWeight.w500, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: kBusGreen),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textTertiary),
                  tooltip: 'Clear',
                  onPressed: () => _selectRoute(null),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final snap = _snap;
    final query = _search.text.trim();
    if (_focus.hasFocus && query.isNotEmpty && query != _route) return _buildSuggestions(query);

    if (snap == null) {
      if (_error != null) {
        return Center(
          child: SingleChildScrollView(child: LiveFeedErrorState(error: _error!, onRetry: () => _load(force: true))),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: kBusGreen)),
            const SizedBox(height: 14),
            Text(
              'Finding live buses…',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.palette.textSecondary),
            ),
          ],
        ),
      );
    }

    final buses = _visibleBuses();
    final header = <Widget>[
      _buildStats(snap),
      const SizedBox(height: 14),
      _buildModeChips(),
      if (_error != null) ...[const SizedBox(height: 12), _buildStaleBanner(snap)],
      if (_route != null) ...[const SizedBox(height: 14), _buildRouteCard(_route!, snap)],
      if (_nearMe && (_locating || _locFailure != null)) ...[const SizedBox(height: 14), _buildLocationCard()],
      if (buses.isNotEmpty)
        SectionHeader(
          title: _listTitle(buses.length),
          subtitle: _me != null ? 'Closest first' : null,
          padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
        ),
    ];
    final empty = buses.isEmpty ? _buildEmpty(snap) : null;
    final unmatched = _route == null ? snap.count - snap.matchedCount : 0;

    return RefreshIndicator(
      color: kBusGreen,
      onRefresh: () => _load(force: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: header.length + (empty != null ? 1 : buses.length) + 1,
        itemBuilder: (context, i) {
          if (i < header.length) return header[i];
          i -= header.length;
          if (empty != null) {
            if (i == 0) return empty;
          } else if (i < buses.length) {
            final (bus, dist) = buses[i];
            return LiveBusCard(
              bus: bus,
              now: _now,
              distanceKm: dist,
              onTap: () => showLiveBusSheet(context, bus, userLat: _me?.latitude, userLon: _me?.longitude),
            );
          }
          return _buildFootnote(unmatched);
        },
      ),
    );
  }

  String _listTitle(int n) {
    if (_nearMe) return '$n bus${n == 1 ? '' : 'es'} within ${_nearRadiusKm.toStringAsFixed(0)} km';
    if (_route != null) return '$n live on $_route';
    return '$n buses on known routes';
  }

  Widget _buildStats(LiveBusSnapshot snap) {
    final onRoute = _route == null ? null : snap.countForRouteNumber(_route!);
    return Row(
      children: [
        Expanded(
          child: StatTile(
            value: '${onRoute ?? snap.count}',
            label: onRoute == null ? 'Buses live' : 'On $_route',
            icon: Icons.directions_bus_filled_rounded,
            color: kBusGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            value: '${snap.routeCount}',
            label: 'Routes running',
            icon: Icons.route_rounded,
            color: AppTheme.brandIndigo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            value: formatAge(_now.difference(snap.fetchedAt)),
            label: _autoRefresh ? 'Auto every 30 s' : 'Auto paused',
            icon: _autoRefresh ? Icons.sync_rounded : Icons.sync_disabled_rounded,
            color: _autoRefresh ? AppTheme.infoColor : AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: _route == null ? 'All buses' : 'All $_route',
          icon: Icons.directions_bus_rounded,
          selected: !_nearMe,
          onTap: () => setState(() => _nearMe = false),
        ),
        _Chip(
          label: 'Near me',
          icon: _locating ? Icons.gps_not_fixed_rounded : Icons.near_me_rounded,
          selected: _nearMe,
          onTap: _toggleNearMe,
        ),
        if (_route != null)
          _Chip(
            label: 'Route $_route',
            icon: Icons.close_rounded,
            selected: false,
            onTap: () => _selectRoute(null),
          ),
      ],
    );
  }

  Widget _buildSuggestions(String query) {
    final p = context.palette;
    if (!_net.isLoaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3, color: kBusGreen));
    }
    final hits = _net.searchRoutes(query, limit: 12);
    if (hits.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyState(title: 'No route "$query"', message: 'Check the number painted on the bus, e.g. 534, 764M or 47BCL.'),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final line = hits[i];
        final live = _snap?.countForRouteNumber(line.number);
        return AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => _selectRoute(line.number),
          child: Row(
            children: [
              RoutePill(number: line.number),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _net.terminiOf(line),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              if (live != null)
                TagPill(
                  label: live == 0 ? 'NONE LIVE' : '$live LIVE',
                  color: live == 0 ? p.textTertiary : kBusGreen,
                  icon: live == 0 ? null : Icons.sensors_rounded,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteCard(String number, LiveBusSnapshot snap) {
    final p = context.palette;
    final lines = _net.isLoaded ? _net.linesByNumber(number) : const <BusLine>[];
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RoutePill(number: number, fontSize: 18),
              const Spacer(),
              if (lines.isNotEmpty) TagPill(label: lines.first.operatorName.toUpperCase(), color: AppTheme.brandIndigo),
            ],
          ),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            Text('Route $number isn\'t in our timetable.', style: TextStyle(color: p.textSecondary, fontSize: 13)),
          for (final line in lines.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.swap_vert_rounded, size: 16, color: p.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _net.terminiOf(line),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${snap.forLineId('${line.id}').length} live',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kBusGreen),
                  ),
                ],
              ),
            ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    label: 'Map',
                    icon: Icons.map_rounded,
                    gradient: AppTheme.emeraldGradient,
                    onPressed: () => context.push('/bus/map?route=${Uri.encodeQueryComponent(number)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(
                    label: 'Stops',
                    icon: Icons.format_list_bulleted_rounded,
                    gradient: AppTheme.heroGradient,
                    onPressed: () => context.push('/bus/route/${lines.first.id}'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final p = context.palette;
    if (_locating) {
      return AppCard(
        child: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: kBusGreen)),
            const SizedBox(width: 12),
            Text('Finding your location…', style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
          ],
        ),
      );
    }
    final f = _locFailure!;
    return AppCard(
      child: Row(
        children: [
          const IconBubble(icon: Icons.location_off_rounded, color: AppTheme.warningColor, size: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Text(f.message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textPrimary)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              if (f.needsSettings) {
                await openLocationSettingsFor(f.issue);
              } else {
                setState(() => _nearMe = false);
                await _toggleNearMe();
              }
            },
            child: Text(f.needsSettings ? 'Settings' : 'Retry',
                style: const TextStyle(color: kBusGreen, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildStaleBanner(LiveBusSnapshot snap) {
    final p = context.palette;
    return AppCard(
      color: p.tint(AppTheme.warningColor),
      showBorder: false,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_error!.title}. Showing positions from ${formatAge(_now.difference(snap.fetchedAt))}.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => _load(force: true),
            child: const Text('Retry', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(LiveBusSnapshot snap) {
    if (_nearMe && (_locating || _locFailure != null)) return const SizedBox.shrink();
    if (_nearMe) {
      return EmptyState(
        title: _route == null ? 'No buses within 2 km' : 'No $_route buses near you',
        message: _route == null
            ? 'No bus on a known route is within 2 km right now. Pull down to refresh.'
            : 'Switch to "All $_route" to see where they are.',
      );
    }
    if (_route != null) {
      final lines = _net.isLoaded ? _net.linesByNumber(_route!) : const <BusLine>[];
      final hours = lines.isEmpty ? null : _serviceHours(lines.first);
      return EmptyState(
        title: 'No $_route buses live right now',
        message: hours != null
            ? 'Scheduled service runs $hours. Buses appear here once they start their trip.'
            : 'Buses appear here as soon as they start broadcasting their position.',
        action: lines.isEmpty
            ? null
            : GradientButton(
                label: 'See route & timings',
                icon: Icons.route_rounded,
                gradient: AppTheme.emeraldGradient,
                expand: false,
                onPressed: () => context.push('/bus/route/${lines.first.id}'),
              ),
      );
    }
    return const EmptyState(
      title: 'No buses broadcasting',
      message: 'Delhi\'s live feed has no buses right now — this is normal late at night. Pull down to refresh.',
    );
  }

  static String? _serviceHours(BusLine line) {
    if (line.firstDeparture == null || line.lastDeparture == null) return null;
    String hm(int m) => '${(m ~/ 60 % 24).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
    return '${hm(line.firstDeparture!)}–${hm(line.lastDeparture!)}';
  }

  Widget _buildFootnote(int unmatched) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Text(
        [
          'Live data: Delhi Open Transit Data (DTC & cluster buses). Stop times ahead are estimates.',
          if (unmatched > 0) '$unmatched more buses are on routes not yet in the published timetable.',
        ].join(' '),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.5, color: p.textTertiary, height: 1.4),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.emeraldGradient : null,
          color: selected ? null : p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : p.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : p.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
