import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/bus_network.dart';
import '../../services/bus_network_service.dart';
import '../../services/live_bus_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/maps_config.dart';
import '../../utils/user_location.dart';
import '../../widgets/live_bus_widgets.dart';
import '../../widgets/ui_kit.dart';

/// Map of live buses. With a route (`/bus/map?route=764M`) it draws that
/// route's stops and its live buses; without one it shows buses near the user
/// (capped) instead of dropping all ~3,500 markers at once.
///
/// Uses Google Maps when [MapsConfig.googleMapsEnabled], otherwise a built-in
/// schematic map so the screen never crashes on a missing API key.
class BusMapScreen extends StatefulWidget {
  final String? initialRoute;
  final String? focusBusId;

  const BusMapScreen({super.key, this.initialRoute, this.focusBusId});

  @override
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> {
  static const Duration _refreshEvery = Duration(seconds: 30);
  static const double _nearRadiusKm = 3;
  static const int _maxMarkers = 150;
  static const LatLng _delhi = LatLng(28.6139, 77.2090);

  final _live = LiveBusService.instance;
  final _net = BusNetworkService.instance;
  final _search = TextEditingController();
  final _focus = FocusNode();
  final _schematicKey = GlobalKey<_SchematicMapState>();

  LiveBusSnapshot? _snap;
  LiveBusException? _error;
  bool _loading = false;
  bool _networkReady = false;

  String? _route;
  int _direction = 0;
  String? _selectedBusId;
  Position? _me;
  String? _locMessage;
  bool _locating = false;

  GoogleMapController? _gmap;
  LatLngBounds? _visible;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _route = widget.initialRoute?.trim().isEmpty == true ? null : widget.initialRoute?.trim();
    _search.text = _route ?? '';
    _selectedBusId = widget.focusBusId;
    _focus.addListener(() => setState(() {}));
    _snap = _live.lastSnapshot;
    _net.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {
        _networkReady = true;
        _normalizeRoute();
        _pickDirectionOfFocusedBus();
      });
      _fitToContent();
    }).catchError((Object e) {
      debugPrint('BusMap: bus network failed: $e');
      if (mounted) setState(() => _networkReady = false);
    });
    _load();
    _timer = Timer.periodic(_refreshEvery, (_) => _load());
    if (_route == null && widget.focusBusId == null) _locate(silent: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _normalizeRoute() {
    if (_route == null) return;
    final lines = _net.linesByNumber(_route!);
    if (lines.isNotEmpty) _route = lines.first.number;
    if (!_focus.hasFocus) _search.text = _route!;
  }

  void _pickDirectionOfFocusedBus() {
    final bus = _selectedBus;
    if (bus?.line == null || _route == null) return;
    final i = _lines.indexWhere((l) => l.id == bus!.line!.id);
    if (i >= 0) _direction = i;
  }

  Future<void> _load({bool force = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final snap = await _live.snapshot(forceRefresh: force);
      if (!mounted) return;
      final first = _snap == null;
      setState(() {
        _snap = snap;
        _error = null;
        _pickDirectionOfFocusedBus();
      });
      if (first) _fitToContent();
    } on LiveBusException catch (e) {
      if (mounted) setState(() => _error = e);
      if (e.kind == LiveBusErrorKind.unsupportedPlatform) _timer?.cancel();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _locate({bool silent = false}) async {
    setState(() => _locating = true);
    final res = await getUserLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (res.ok) {
        _me = res.position;
        _locMessage = null;
      } else {
        _locMessage = res.message;
      }
    });
    if (res.ok) {
      _centreOnMe();
    } else if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message),
        action: res.needsSettings
            ? SnackBarAction(label: 'Settings', onPressed: () => openLocationSettingsFor(res.issue))
            : null,
      ));
    }
  }

  void _selectRoute(String? number) {
    setState(() {
      _route = number;
      _direction = 0;
      _selectedBusId = null;
      _search.text = number ?? '';
      _normalizeRoute();
    });
    _focus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToContent());
  }

  // ── Derived data ──────────────────────────────────────────────────────────

  List<BusLine> get _lines => (_route == null || !_networkReady) ? const [] : _net.linesByNumber(_route!);
  BusLine? get _line => _lines.isEmpty ? null : _lines[_direction.clamp(0, _lines.length - 1)];
  List<BusStopInfo> get _stops => _line == null ? const [] : _net.stopsOf(_line!);

  LiveBus? get _selectedBus => _selectedBusId == null ? null : _snap?.byId(_selectedBusId!);

  /// Buses worth drawing, capped at [_maxMarkers].
  List<LiveBus> get _buses {
    final snap = _snap;
    if (snap == null) return const [];
    final List<LiveBus> out;
    if (_route != null) {
      out = snap.forRouteNumber(_route!).toList();
    } else if (MapsConfig.googleMapsEnabled && _visible != null) {
      final b = _visible!;
      final c = LatLng((b.northeast.latitude + b.southwest.latitude) / 2, (b.northeast.longitude + b.southwest.longitude) / 2);
      out = snap.buses.where((x) => x.isMatched && b.contains(LatLng(x.latitude, x.longitude))).toList()
        ..sort((a, z) => a.distanceKmTo(c.latitude, c.longitude).compareTo(z.distanceKmTo(c.latitude, c.longitude)));
    } else if (_me != null) {
      out = snap
          .near(_me!.latitude, _me!.longitude, radiusKm: _nearRadiusKm)
          .where((e) => e.$1.isMatched)
          .map((e) => e.$1)
          .toList();
    } else {
      out = [];
    }
    final focus = _selectedBus;
    if (focus != null && !out.contains(focus)) out.insert(0, focus);
    return out.length > _maxMarkers ? out.sublist(0, _maxMarkers) : out;
  }

  /// Points the camera should fit: the route, or the user + nearby buses.
  List<LatLng> _contentPoints() {
    if (_stops.isNotEmpty) return _stops.map((s) => LatLng(s.lat, s.lon)).toList();
    final focus = _selectedBus;
    if (focus != null) {
      return [LatLng(focus.latitude, focus.longitude), if (_me != null) LatLng(_me!.latitude, _me!.longitude)];
    }
    if (_me != null) {
      const d = _nearRadiusKm / 111.0;
      final dLon = d / math.cos(_me!.latitude * math.pi / 180);
      return [
        LatLng(_me!.latitude - d, _me!.longitude - dLon),
        LatLng(_me!.latitude + d, _me!.longitude + dLon),
      ];
    }
    return _buses.map((b) => LatLng(b.latitude, b.longitude)).toList();
  }

  void _fitToContent() {
    if (!mounted) return;
    final pts = _contentPoints();
    if (MapsConfig.googleMapsEnabled) {
      if (_gmap == null || pts.isEmpty) return;
      if (pts.length == 1) {
        _gmap!.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 15));
      } else {
        _gmap!.animateCamera(CameraUpdate.newLatLngBounds(_boundsOf(pts), 56));
      }
    } else {
      _schematicKey.currentState?.resetView();
      setState(() {});
    }
  }

  void _centreOnMe() {
    final me = _me;
    if (me == null) return;
    if (MapsConfig.googleMapsEnabled) {
      _gmap?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(me.latitude, me.longitude), 14.5));
    } else {
      _fitToContent();
    }
  }

  static LatLngBounds _boundsOf(List<LatLng> pts) {
    var s = pts.first.latitude, n = s, w = pts.first.longitude, e = w;
    for (final p in pts) {
      s = math.min(s, p.latitude);
      n = math.max(n, p.latitude);
      w = math.min(w, p.longitude);
      e = math.max(e, p.longitude);
    }
    return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
  }

  void _openBus(LiveBus bus) {
    setState(() => _selectedBusId = bus.id);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final buses = _buses;
    final subtitle = _route != null
        ? '$_route · ${_snap?.countForRouteNumber(_route!) ?? 0} live buses'
        : (_me != null
            ? '${buses.length} buses within ${_nearRadiusKm.toStringAsFixed(0)} km'
            : (_snap == null ? 'Live DTC & cluster buses' : '${_snap!.count} buses live in Delhi'));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(
          children: [
            GradientHeader(
              title: 'Bus Map',
              subtitle: subtitle,
              icon: Icons.map_rounded,
              gradient: AppTheme.emeraldGradient,
              illustration: 'assets/images/illus_bus.svg',
              actions: [
                HeaderIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh buses',
                  onTap: () => _load(force: true),
                ),
              ],
              bottom: _searchField(),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2, color: kBusGreen),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMap(buses)),
                  if (_lines.length > 1)
                    Positioned(top: 12, left: 12, right: 72, child: _directionChips()),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _MapButton(
                          icon: _locating ? Icons.gps_not_fixed_rounded : Icons.my_location_rounded,
                          tooltip: 'My location',
                          onTap: () => _me == null ? _locate() : _centreOnMe(),
                        ),
                        const SizedBox(height: 10),
                        _MapButton(icon: Icons.fit_screen_rounded, tooltip: 'Recentre', onTap: _fitToContent),
                      ],
                    ),
                  ),
                  Positioned(left: 12, right: 12, bottom: 12, child: _bottomCard(buses)),
                  if (_focus.hasFocus && _search.text.trim().isNotEmpty && _search.text.trim() != _route)
                    Positioned.fill(child: _suggestions(_search.text.trim())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
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
          final hits = _networkReady ? _net.searchRoutes(q, limit: 1) : const <BusLine>[];
          _selectRoute(hits.isNotEmpty ? hits.first.number : null);
        },
        decoration: InputDecoration(
          hintText: 'Show a route, e.g. 534',
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

  Widget _suggestions(String q) {
    final p = context.palette;
    final hits = _networkReady ? _net.searchRoutes(q, limit: 10) : const <BusLine>[];
    return Container(
      color: p.background.withValues(alpha: 0.97),
      child: hits.isEmpty
          ? Center(child: EmptyState(title: 'No route "$q"', message: 'Try the number shown on the bus, e.g. 534 or 764M.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                for (final line in hits)
                  AppCard(
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
                        if (_snap != null) ...[
                          const SizedBox(width: 8),
                          TagPill(
                            label: '${_snap!.countForRouteNumber(line.number)} LIVE',
                            color: _snap!.countForRouteNumber(line.number) == 0 ? p.textTertiary : kBusGreen,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _directionChips() {
    final p = context.palette;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _direction = i);
                  _fitToContent();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: i == _direction ? AppTheme.emeraldGradient : null,
                    color: i == _direction ? null : p.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: i == _direction ? Colors.transparent : p.border),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Text(
                    'To ${_net.stopById(_lines[i].stopIds.last)?.name ?? _lines[i].direction}',
                    style: TextStyle(
                      color: i == _direction ? Colors.white : p.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(List<LiveBus> buses) {
    if (MapsConfig.googleMapsEnabled) return _googleMap(buses);
    return _SchematicMap(
      key: _schematicKey,
      stops: _stops,
      otherDirections: [
        for (var i = 0; i < _lines.length; i++)
          if (i != _direction) _net.stopsOf(_lines[i]),
      ],
      buses: buses,
      activeLineId: _line?.id,
      selectedBusId: _selectedBusId,
      me: _me == null ? null : LatLng(_me!.latitude, _me!.longitude),
      fallbackPoints: _contentPoints(),
      onBusTap: _openBus,
      onEmptyTap: () => setState(() => _selectedBusId = null),
    );
  }

  Widget _googleMap(List<LiveBus> buses) {
    final markers = <Marker>{};
    final stops = _stops;
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final terminus = i == 0 || i == stops.length - 1;
      markers.add(Marker(
        markerId: MarkerId('stop_${s.id}'),
        position: LatLng(s.lat, s.lon),
        alpha: terminus ? 1 : 0.6,
        zIndexInt: 1,
        icon: BitmapDescriptor.defaultMarkerWithHue(terminus ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: s.name, snippet: 'Stop ${i + 1} of ${stops.length}'),
      ));
    }
    for (final b in buses) {
      final active = _line == null || b.line?.id == _line!.id;
      markers.add(Marker(
        markerId: MarkerId('bus_${b.id}'),
        position: LatLng(b.latitude, b.longitude),
        zIndexInt: b.id == _selectedBusId ? 4 : 3,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            b.id == _selectedBusId ? BitmapDescriptor.hueRose : (active ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure)),
        infoWindow: InfoWindow(title: 'Bus ${b.routeNumber}', snippet: b.whereText),
        onTap: () => _openBus(b),
      ));
    }
    final polylines = <Polyline>{
      for (var i = 0; i < _lines.length; i++)
        Polyline(
          polylineId: PolylineId('line_${_lines[i].id}'),
          points: _net.stopsOf(_lines[i]).map((s) => LatLng(s.lat, s.lon)).toList(),
          color: i == _direction ? kBusGreen : kBusGreen.withValues(alpha: 0.3),
          width: i == _direction ? 5 : 3,
          zIndex: i == _direction ? 2 : 1,
        ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _contentPoints().isEmpty ? _delhi : _contentPoints().first,
        zoom: 12,
      ),
      onMapCreated: (c) {
        _gmap = c;
        Future.delayed(const Duration(milliseconds: 300), _fitToContent);
      },
      onCameraIdle: () async {
        if (_route != null || _gmap == null) return;
        final b = await _gmap!.getVisibleRegion();
        if (mounted) setState(() => _visible = b);
      },
      onTap: (_) => setState(() => _selectedBusId = null),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: _me != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _bottomCard(List<LiveBus> buses) {
    final p = context.palette;
    final bus = _selectedBus;
    if (bus != null) {
      return AppCard(
        padding: const EdgeInsets.all(14),
        color: p.card,
        onTap: () => showLiveBusSheet(context, bus, userLat: _me?.latitude, userLon: _me?.longitude, showMapButton: false),
        child: Row(
          children: [
            RoutePill(number: bus.routeNumber, known: bus.isMatched),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bus.whereText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary)),
                  const SizedBox(height: 3),
                  Text('${bus.registration} · updated ${formatAge(bus.ageAt(DateTime.now()))}',
                      style: TextStyle(fontSize: 11.5, color: p.textTertiary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textTertiary),
          ],
        ),
      );
    }

    final String title;
    final String message;
    IconData icon = Icons.info_outline_rounded;
    if (_error != null && _snap == null) {
      title = _error!.title;
      message = _error!.message;
      icon = Icons.cloud_off_rounded;
    } else if (_route != null) {
      final n = buses.length;
      title = n == 0 ? 'No $_route buses live right now' : '$n live bus${n == 1 ? '' : 'es'} on $_route';
      message = _line == null ? 'Loading route…' : '${_stops.length} stops · tap a bus for details';
    } else if (_me == null && !MapsConfig.googleMapsEnabled) {
      title = 'Pick a route or use your location';
      message = _locMessage ?? 'Search a route number above, or tap the location button to see buses near you.';
      icon = Icons.travel_explore_rounded;
    } else {
      final n = buses.length;
      title = n == 0 ? 'No buses nearby' : '$n live bus${n == 1 ? '' : 'es'} around you';
      message = n >= _maxMarkers ? 'Showing the closest $_maxMarkers. Search a route to focus.' : 'Tap a bus for details';
    }
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBubble(icon: icon, color: kBusGreen, size: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(fontSize: 12, color: p.textSecondary)),
                if (!MapsConfig.googleMapsEnabled) ...[
                  const SizedBox(height: 4),
                  Text('Schematic view · positions not to street scale',
                      style: TextStyle(fontSize: 10.5, color: p.textTertiary, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.card,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: AppTheme.brandNight.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(11), child: Icon(icon, color: kBusGreen, size: 22)),
        ),
      ),
    );
  }
}

// ── Schematic map (no API key needed) ───────────────────────────────────────

class _SchematicMap extends StatefulWidget {
  final List<BusStopInfo> stops;
  final List<List<BusStopInfo>> otherDirections;
  final List<LiveBus> buses;
  final int? activeLineId;
  final String? selectedBusId;
  final LatLng? me;
  final List<LatLng> fallbackPoints;
  final ValueChanged<LiveBus> onBusTap;
  final VoidCallback onEmptyTap;

  const _SchematicMap({
    super.key,
    required this.stops,
    required this.otherDirections,
    required this.buses,
    required this.activeLineId,
    required this.selectedBusId,
    required this.me,
    required this.fallbackPoints,
    required this.onBusTap,
    required this.onEmptyTap,
  });

  @override
  State<_SchematicMap> createState() => _SchematicMapState();
}

class _SchematicMapState extends State<_SchematicMap> {
  final _tc = TransformationController();

  void resetView() => _tc.value = Matrix4.identity();

  @override
  void initState() {
    super.initState();
    _tc.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  _Projection _projection(Size size) {
    final pts = <LatLng>[
      ...widget.stops.map((s) => LatLng(s.lat, s.lon)),
      if (widget.stops.isEmpty) ...widget.fallbackPoints,
      if (widget.stops.isEmpty) ...widget.buses.map((b) => LatLng(b.latitude, b.longitude)),
      if (widget.stops.isEmpty && widget.me != null) widget.me!,
    ];
    return _Projection.fit(pts.isEmpty ? const [LatLng(28.6139, 77.2090)] : pts, size);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final proj = _projection(size);
      final scale = _tc.value.getMaxScaleOnAxis();
      return ClipRect(
        child: Container(
          color: p.isDark ? const Color(0xFF101433) : const Color(0xFFEAF5EF),
          child: InteractiveViewer(
            transformationController: _tc,
            minScale: 1,
            maxScale: 12,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _handleTap(d.localPosition, proj, scale),
              child: CustomPaint(
                size: size,
                painter: _SchematicPainter(
                  proj: proj,
                  scale: scale,
                  palette: p,
                  stops: widget.stops,
                  otherDirections: widget.otherDirections,
                  buses: widget.buses,
                  activeLineId: widget.activeLineId,
                  selectedBusId: widget.selectedBusId,
                  me: widget.me,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _handleTap(Offset pos, _Projection proj, double scale) {
    LiveBus? best;
    var bestD = 22 / scale;
    for (final b in widget.buses) {
      final d = (proj.toOffset(b.latitude, b.longitude) - pos).distance;
      if (d < bestD) {
        bestD = d;
        best = b;
      }
    }
    if (best != null) {
      widget.onBusTap(best);
    } else {
      widget.onEmptyTap();
    }
  }
}

class _Projection {
  final double midLat, midLon, kx, s;
  final Offset centre;

  const _Projection(this.midLat, this.midLon, this.kx, this.s, this.centre);

  factory _Projection.fit(List<LatLng> pts, Size size) {
    var s = pts.first.latitude, n = s, w = pts.first.longitude, e = w;
    for (final p in pts) {
      s = math.min(s, p.latitude);
      n = math.max(n, p.latitude);
      w = math.min(w, p.longitude);
      e = math.max(e, p.longitude);
    }
    final midLat = (s + n) / 2, midLon = (w + e) / 2;
    final kx = math.cos(midLat * math.pi / 180);
    final spanX = math.max((e - w) * kx, 0.01);
    final spanY = math.max(n - s, 0.01);
    const pad = 56.0;
    final scale = math.min((size.width - pad * 2) / spanX, (size.height - pad * 2 - 90) / spanY);
    // Shift up a little so the bottom card doesn't cover the content.
    return _Projection(midLat, midLon, kx, scale, Offset(size.width / 2, size.height / 2 - 40));
  }

  Offset toOffset(double lat, double lon) =>
      Offset(centre.dx + (lon - midLon) * kx * s, centre.dy - (lat - midLat) * s);
}

class _SchematicPainter extends CustomPainter {
  final _Projection proj;
  final double scale;
  final AppPalette palette;
  final List<BusStopInfo> stops;
  final List<List<BusStopInfo>> otherDirections;
  final List<LiveBus> buses;
  final int? activeLineId;
  final String? selectedBusId;
  final LatLng? me;

  _SchematicPainter({
    required this.proj,
    required this.scale,
    required this.palette,
    required this.stops,
    required this.otherDirections,
    required this.buses,
    required this.activeLineId,
    required this.selectedBusId,
    required this.me,
  });

  static final _busIcon = String.fromCharCode(Icons.directions_bus_rounded.codePoint);

  @override
  void paint(Canvas canvas, Size size) {
    final inv = 1 / scale;

    // Background grid (~1 km).
    final grid = Paint()
      ..color = palette.border.withValues(alpha: 0.5)
      ..strokeWidth = inv;
    final step = proj.s * 0.009;
    if (step * scale > 12) {
      for (var x = proj.centre.dx % step; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (var y = proj.centre.dy % step; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    void route(List<BusStopInfo> s, Color color, double width) {
      if (s.length < 2) return;
      final path = Path()..moveTo(proj.toOffset(s.first.lat, s.first.lon).dx, proj.toOffset(s.first.lat, s.first.lon).dy);
      for (final st in s.skip(1)) {
        final o = proj.toOffset(st.lat, st.lon);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = width * inv
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    }

    for (final o in otherDirections) {
      route(o, kBusGreen.withValues(alpha: 0.25), 3);
    }
    route(stops, kBusGreen, 5);

    // Stops.
    final stopFill = Paint()..color = palette.card;
    final stopRing = Paint()
      ..color = kBusGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * inv;
    for (var i = 0; i < stops.length; i++) {
      final o = proj.toOffset(stops[i].lat, stops[i].lon);
      final terminus = i == 0 || i == stops.length - 1;
      final r = (terminus ? 6.5 : 3.5) * inv;
      canvas.drawCircle(o, r, stopFill);
      canvas.drawCircle(o, r, stopRing);
      if (terminus || scale >= 3.5) {
        _label(canvas, stops[i].name, o + Offset(8 * inv, -6 * inv), terminus ? 12 : 10, terminus ? FontWeight.w800 : FontWeight.w600);
      }
    }

    // User.
    if (me != null) {
      final o = proj.toOffset(me!.latitude, me!.longitude);
      canvas.drawCircle(o, 16 * inv, Paint()..color = AppTheme.infoColor.withValues(alpha: 0.18));
      canvas.drawCircle(o, 7 * inv, Paint()..color = Colors.white);
      canvas.drawCircle(o, 5 * inv, Paint()..color = AppTheme.infoColor);
    }

    // Buses (selected last so it's on top).
    final ordered = [...buses.where((b) => b.id != selectedBusId), ...buses.where((b) => b.id == selectedBusId)];
    for (final b in ordered) {
      final o = proj.toOffset(b.latitude, b.longitude);
      final selected = b.id == selectedBusId;
      final active = activeLineId == null || b.line?.id == activeLineId;
      final color = selected ? AppTheme.brandRose : (active ? const Color(0xFF047857) : AppTheme.infoColor);
      final r = (selected ? 15 : 12) * inv;
      canvas.drawCircle(o + Offset(0, 2 * inv), r, Paint()..color = Colors.black.withValues(alpha: 0.18));
      canvas.drawCircle(o, r + 2 * inv, Paint()..color = Colors.white);
      canvas.drawCircle(o, r, Paint()..color = color);
      final tp = TextPainter(
        text: TextSpan(
          text: _busIcon,
          style: TextStyle(
            fontFamily: Icons.directions_bus_rounded.fontFamily,
            package: Icons.directions_bus_rounded.fontPackage,
            fontSize: r * 1.15,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
      if (activeLineId == null || selected) {
        _label(canvas, b.routeNumber, o + Offset(r + 3 * inv, -r), 11, FontWeight.w800, color: color);
      }
    }
  }

  void _label(Canvas canvas, String text, Offset at, double size, FontWeight weight, {Color? color}) {
    final inv = 1 / scale;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size * inv,
          fontWeight: weight,
          color: color ?? palette.textPrimary,
          fontFamily: AppTheme.fontFamily,
          shadows: [Shadow(color: palette.background, blurRadius: 3 * inv)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 180 * inv);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_SchematicPainter old) => true;
}
