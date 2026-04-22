import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/station_tracker_service.dart';
import '../../providers/metro_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/searchable_station_dropdown.dart';

class LiveTrackerScreen extends StatefulWidget {
  const LiveTrackerScreen({super.key});

  @override
  State<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends State<LiveTrackerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  String? _routeFrom;
  String? _routeTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StationTrackerService>(
      builder: (context, tracker, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: _buildAppBar(tracker),
          body: Column(
            children: [
              _buildGpsStatusBar(tracker),
              _buildPillTabBar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _NearbyTab(tracker: tracker),
                    _RouteFollowerTab(
                      tracker: tracker,
                      routeFrom: _routeFrom,
                      routeTo: _routeTo,
                      onFromChanged: (v) => setState(() => _routeFrom = v),
                      onToChanged: (v) => setState(() => _routeTo = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
        );
      },
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(StationTrackerService tracker) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.black87),
      leadingWidth: 44,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.metroBlue,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.route, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE TRACKER',
            style: TextStyle(
              color: Color(0xFF0D1B3E),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        _TrackingToggleButton(tracker: tracker),
        const SizedBox(width: 12),
      ],
    );
  }

  // ── GPS Status Bar ──────────────────────────────────────────────────────────

  Widget _buildGpsStatusBar(StationTrackerService tracker) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (tracker.state) {
      case TrackerState.idle:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
        label = 'Tracking stopped — tap Start to begin';
        icon = Icons.gps_off;
      case TrackerState.loading:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'Loading station data…';
        icon = Icons.sync;
      case TrackerState.active:
        final pos = tracker.position;
        label = pos != null
            ? 'GPS active  ·  ±${pos.accuracy.round()} m accuracy'
            : 'Acquiring GPS signal…';
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.signal_cellular_alt;
      case TrackerState.error:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = tracker.error ?? 'Unknown error';
        icon = Icons.warning_amber;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          tracker.state == TrackerState.loading
              ? SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 10, color: fg, fontWeight: FontWeight.w500),
            ),
          ),
          if (tracker.state == TrackerState.error)
            GestureDetector(
              onTap: tracker.clearError,
              child: Icon(Icons.close, size: 13, color: fg),
            ),
        ],
      ),
    );
  }

  // ── Pill Tab Bar ────────────────────────────────────────────────────────────

  Widget _buildPillTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            _PillTabItem(
              label: 'Nearby Stations',
              icon: Icons.near_me,
              selected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            _PillTabItem(
              label: 'Follow Route',
              icon: Icons.route,
              selected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pill Tab Item ─────────────────────────────────────────────────────────────

class _PillTabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PillTabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: selected ? AppTheme.metroBlue : Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.metroBlue : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tracking Toggle Button ────────────────────────────────────────────────────

class _TrackingToggleButton extends StatelessWidget {
  final StationTrackerService tracker;
  const _TrackingToggleButton({required this.tracker});

  @override
  Widget build(BuildContext context) {
    if (tracker.state == TrackerState.loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final active = tracker.isTracking;
    return GestureDetector(
      onTap: active ? tracker.stopTracking : tracker.startTracking,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.red.shade600 : const Color(0xFF1DB954),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              active ? 'Stop' : 'Start',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 1 — Nearby Stations
// ═══════════════════════════════════════════════════════════════════════════════

class _NearbyTab extends StatelessWidget {
  final StationTrackerService tracker;
  const _NearbyTab({required this.tracker});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metro map section
          _MetroMapWidget(tracker: tracker),

          const SizedBox(height: 14),

          // Arriving soon
          if (!tracker.isTracking && tracker.state != TrackerState.active)
            _IdlePrompt(
              icon: Icons.near_me,
              title: 'Discover Nearby Stations',
              subtitle:
                  'Tap Start to turn on GPS.\nStations will appear sorted by distance.',
            )
          else if (tracker.nearby.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.metroBlue),
                    SizedBox(height: 12),
                    Text('Calculating distances…',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'ARRIVING SOON',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: tracker.nearby.length,
              itemBuilder: (_, i) => _StationArrivingCard(
                item: tracker.nearby[i],
                rank: i,
              ),
            ),
            const SizedBox(height: 14),
            // Current Trip Card (always shown when tracking)
            if (tracker.hasRoute)
              _CurrentTripCard(tracker: tracker),
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }
}

// ── Metro Map Widget (Real Google Map) ────────────────────────────────────────

class _MetroMapWidget extends StatefulWidget {
  final StationTrackerService tracker;
  const _MetroMapWidget({required this.tracker});

  @override
  State<_MetroMapWidget> createState() => _MetroMapWidgetState();
}

class _MetroMapWidgetState extends State<_MetroMapWidget> {
  GoogleMapController? _mapController;

  // Delhi center as fallback
  static const LatLng _delhiCenter = LatLng(28.6139, 77.2090);

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (int i = 0; i < widget.tracker.nearby.length; i++) {
      final item = widget.tracker.nearby[i];
      final station = item.station;

      markers.add(
        Marker(
          markerId: MarkerId('station_${station.id}'),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: station.line,
          ),
          icon: item.isArrived
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen)
              : item.isApproaching
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange)
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
        ),
      );
    }
    return markers;
  }

  LatLng get _mapCenter {
    final pos = widget.tracker.position;
    if (pos != null) return LatLng(pos.latitude, pos.longitude);
    if (widget.tracker.nearby.isNotEmpty) {
      return LatLng(
        widget.tracker.nearby.first.station.latitude,
        widget.tracker.nearby.first.station.longitude,
      );
    }
    return _delhiCenter;
  }

  @override
  void didUpdateWidget(covariant _MetroMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pan camera when GPS position changes
    final pos = widget.tracker.position;
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStation = widget.tracker.nearby.isNotEmpty
        ? widget.tracker.nearby.first.station.name
        : 'Rajiv Chowk';

    Color lineColor;
    try {
      lineColor = widget.tracker.nearby.isNotEmpty
          ? Color(int.parse(widget.tracker.nearby.first.station.lineColor
              .replaceFirst('#', '0xFF')))
          : AppTheme.metroBlue;
    } catch (_) {
      lineColor = AppTheme.metroBlue;
    }

    return Container(
      height: 210,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: const Color(0xFFECF1F8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // ── Real Google Map ──────────────────────────────────────────
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _mapCenter,
              zoom: 14.5,
            ),
            markers: _buildMarkers(),
            myLocationEnabled: widget.tracker.isTracking,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            mapType: MapType.normal,
            liteModeEnabled: false,
          ),

          // ── LIVE FEED badge (top-left) ──────────────────────────────
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A5E).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.tracker.isTracking
                          ? const Color(0xFF1DB954)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.tracker.isTracking ? 'LIVE FEED' : 'GPS OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Timer card (top-right) ──────────────────────────────────
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.tracker.isTracking &&
                            widget.tracker.nearby.isNotEmpty
                        ? widget.tracker.nearby.first.walkMinutes
                            .toString()
                            .padLeft(2, '0')
                        : '--',
                    style: const TextStyle(
                      color: Color(0xFF0D1B3E),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'min',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Station info bar (bottom) ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.93),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStation,
                          style: TextStyle(
                            color: lineColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.tracker.nearby.isNotEmpty
                              ? 'Next: ${widget.tracker.nearby.first.station.line}'
                              : 'Start GPS to see nearby stations',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Re-center button
                  GestureDetector(
                    onTap: () {
                      final pos = widget.tracker.position;
                      if (pos != null && _mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target:
                                  LatLng(pos.latitude, pos.longitude),
                              zoom: 15,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B3E),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        size: 15,
                        color: Colors.white,
                      ),
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
}

// ── Arriving Soon Station Card ────────────────────────────────────────────────

class _StationArrivingCard extends StatelessWidget {
  final NearbyStation item;
  final int rank;
  const _StationArrivingCard({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    Color lineColor;
    try {
      lineColor = Color(
          int.parse(item.station.lineColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      lineColor = AppTheme.metroBlue;
    }

    Color statusColor;
    String statusLabel;

    if (item.isArrived) {
      statusColor = const Color(0xFF1DB954);
      statusLabel = 'YOU ARE HERE';
    } else if (item.isApproaching) {
      statusColor = Colors.orange;
      statusLabel = '${item.walkMinutes} MIN WALK';
    } else {
      statusColor = Colors.grey.shade500;
      statusLabel = '${item.walkMinutes} MIN WALK';
    }

    final distText = item.distanceMetres < 1000
        ? '${item.distanceMetres.round()} m'
        : '${(item.distanceMetres / 1000).toStringAsFixed(1)} km';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: item.isArrived
            ? Border.all(color: const Color(0xFF1DB954), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left coloured border line
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    // Rank circle
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: item.isArrived
                            ? const Color(0xFF1DB954)
                            : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text(
                          '${(rank + 1).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.isArrived
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Line color dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: lineColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Station name & status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.station.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0D1B3E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Distance
                    Text(
                      distText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Current Trip Card ─────────────────────────────────────────────────────────

class _CurrentTripCard extends StatelessWidget {
  final StationTrackerService tracker;
  const _CurrentTripCard({required this.tracker});

  @override
  Widget build(BuildContext context) {
    final stops = tracker.trackedStops;
    final from = stops.isNotEmpty ? stops.first.name : '';
    final to = stops.isNotEmpty ? stops.last.name : '';
    final remaining = tracker.remainingStops;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A5E),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT TRIP',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            to.isNotEmpty ? to : 'No destination',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
          if (from.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'from $from',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Line color bubbles
              Row(
                children: [
                  _LineBubble(color: const Color(0xFF1DB954)),
                  _LineBubble(color: AppTheme.metroBlue.withValues(alpha: 0.7)),
                  if (remaining > 0)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '+$remaining',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // On Time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.metroBlue,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'On Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineBubble extends StatelessWidget {
  final Color color;
  const _LineBubble({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2 — Follow Route
// ═══════════════════════════════════════════════════════════════════════════════

class _RouteFollowerTab extends StatelessWidget {
  final StationTrackerService tracker;
  final String? routeFrom;
  final String? routeTo;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;

  const _RouteFollowerTab({
    required this.tracker,
    required this.routeFrom,
    required this.routeTo,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoutePickerCard(
            tracker: tracker,
            routeFrom: routeFrom,
            routeTo: routeTo,
            onFromChanged: onFromChanged,
            onToChanged: onToChanged,
          ),
          const SizedBox(height: 16),
          if (tracker.loadingRoute)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.metroBlue),
                    SizedBox(height: 10),
                    Text('Building route…',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            )
          else if (tracker.hasRoute)
            _RouteTimeline(tracker: tracker)
          else if (!tracker.isTracking)
            _IdlePrompt(
              icon: Icons.route,
              title: 'Follow Your Metro Journey',
              subtitle:
                  'Start tracking, then select your from/to stations.\nThe app will tick off each station as you pass through it.',
            )
          else
            _IdlePrompt(
              icon: Icons.route,
              title: 'Select a Route',
              subtitle:
                  'Pick your departure and destination, then tap Load Route.',
            ),
        ],
      ),
    );
  }
}

// ── Route Picker Card ─────────────────────────────────────────────────────────

class _RoutePickerCard extends StatelessWidget {
  final StationTrackerService tracker;
  final String? routeFrom;
  final String? routeTo;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;

  const _RoutePickerCard({
    required this.tracker,
    required this.routeFrom,
    required this.routeTo,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MetroProvider>(
      builder: (context, metroProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, color: AppTheme.metroBlue, size: 15),
                  const SizedBox(width: 6),
                  const Text(
                    'Route to Follow',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // FROM
              Text(
                'FROM',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              SearchableStationDropdown(
                stations: metroProvider.stations,
                selectedStation: routeFrom,
                hintText: 'Starting station',
                prefixIcon: Icons.location_on,
                onChanged: onFromChanged,
              ),
              const SizedBox(height: 10),

              // TO
              Text(
                'TO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              SearchableStationDropdown(
                stations: metroProvider.stations,
                selectedStation: routeTo,
                hintText: 'Destination station',
                prefixIcon: Icons.flag,
                onChanged: onToChanged,
              ),
              const SizedBox(height: 14),

              // Buttons
              Row(
                children: [
                  if (tracker.hasRoute) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: tracker.clearRoute,
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text('Clear',
                            style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (routeFrom != null && routeTo != null)
                          ? () => tracker.loadRoute(routeFrom!, routeTo!)
                          : null,
                      icon: const Icon(Icons.play_arrow, size: 14),
                      label: Text(
                        tracker.hasRoute ? 'Reload Route' : 'Load Route',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.metroBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),

              // GPS warning
              if (!tracker.isTracking) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 13, color: Colors.orange),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Start GPS tracking first (tap Start in the top-right)',
                          style:
                              TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Route Timeline ────────────────────────────────────────────────────────────

class _RouteTimeline extends StatelessWidget {
  final StationTrackerService tracker;
  const _RouteTimeline({required this.tracker});

  @override
  Widget build(BuildContext context) {
    final stops = tracker.trackedStops;
    final passed = tracker.passedCount;
    final remaining = tracker.remainingStops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.metroBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProgressStat(
                  label: 'Total',
                  value: '${stops.length}',
                  icon: Icons.train),
              _ProgressStat(
                  label: 'Passed',
                  value: '$passed',
                  icon: Icons.check_circle,
                  color: const Color(0xFF1DB954)),
              _ProgressStat(
                  label: 'Remaining',
                  value: '$remaining',
                  icon: Icons.directions,
                  color: AppTheme.metroBlue),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Stations',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D1B3E)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: stops.length,
            itemBuilder: (_, i) => _TimelineStop(
              stop: stops[i],
              isFirst: i == 0,
              isLast: i == stops.length - 1,
              showConnector: i < stops.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _ProgressStat(
      {required this.label,
      required this.value,
      required this.icon,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color ?? Colors.black87)),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}

// ── Timeline Stop ─────────────────────────────────────────────────────────────

class _TimelineStop extends StatelessWidget {
  final TrackedStop stop;
  final bool isFirst;
  final bool isLast;
  final bool showConnector;

  const _TimelineStop({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    Color lineColor;
    try {
      lineColor =
          Color(int.parse(stop.lineColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      lineColor = AppTheme.metroBlue;
    }

    Color dotColor;
    Widget dotContent;
    Color textColor;

    if (stop.passed && !stop.isCurrent) {
      dotColor = Colors.grey.shade300;
      dotContent = const Icon(Icons.check, size: 10, color: Colors.grey);
      textColor = Colors.grey;
    } else if (stop.isCurrent) {
      dotColor = const Color(0xFF1DB954);
      dotContent = const Icon(Icons.person_pin_circle,
          size: 12, color: Colors.white);
      textColor = const Color(0xFF1DB954);
    } else if (isFirst) {
      dotColor = lineColor;
      dotContent =
          const Icon(Icons.play_arrow, size: 10, color: Colors.white);
      textColor = const Color(0xFF0D1B3E);
    } else if (isLast) {
      dotColor = lineColor;
      dotContent =
          const Icon(Icons.flag, size: 10, color: Colors.white);
      textColor = const Color(0xFF0D1B3E);
    } else {
      dotColor = lineColor;
      dotContent = Container(
          width: 5,
          height: 5,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle));
      textColor = const Color(0xFF0D1B3E);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 14,
                  color: isFirst
                      ? Colors.transparent
                      : (stop.passed ? Colors.grey.shade200 : lineColor),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: dotContent),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: showConnector
                        ? (stop.passed ? Colors.grey.shade200 : lineColor)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 7),
                decoration: stop.isCurrent
                    ? BoxDecoration(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                            width: 1),
                      )
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stop.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: textColor,
                            ),
                          ),
                          Text(
                            stop.line,
                            style: TextStyle(
                              fontSize: 9,
                              color: stop.passed && !stop.isCurrent
                                  ? Colors.grey
                                  : lineColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stop.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text('YOU ARE HERE',
                            style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      )
                    else if (isFirst && !stop.passed)
                      _StationBadge('START', AppTheme.metroBlue)
                    else if (isLast)
                      _StationBadge('DEST', AppTheme.metroRed)
                    else if (stop.passed)
                      const Icon(Icons.check_circle,
                          size: 13, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StationBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: color)),
    );
  }
}

// ── Shared Idle Prompt ────────────────────────────────────────────────────────

class _IdlePrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _IdlePrompt({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.metroBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppTheme.metroBlue),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0D1B3E))),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.5,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
