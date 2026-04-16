import 'package:flutter/material.dart';
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
  late TabController _tabs;

  // Route follower inputs
  String? _routeFrom;
  String? _routeTo;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    // Pre-load station list for dropdowns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StationTrackerService>(
      builder: (context, tracker, _) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context, tracker),
          body: Column(
            children: [
              _buildStatusBar(tracker),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
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

  PreferredSizeWidget _buildAppBar(
      BuildContext context, StationTrackerService tracker) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.black87),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tracker.isTracking ? Colors.green : AppTheme.metroBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tracker.isTracking ? Icons.my_location : Icons.location_off,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Live Tracker',
            style: TextStyle(
                color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        _TrackingToggleButton(tracker: tracker),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Status bar ──────────────────────────────────────────────────────────────

  Widget _buildStatusBar(StationTrackerService tracker) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (tracker.state) {
      case TrackerState.idle:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
        label = 'Tracking stopped — tap ▶ to start';
        icon = Icons.gps_off;
      case TrackerState.loading:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'Loading station data…';
        icon = Icons.sync;
      case TrackerState.active:
        final pos = tracker.position;
        if (pos != null) {
          label =
              'GPS active · ±${pos.accuracy.round()} m accuracy';
        } else {
          label = 'Acquiring GPS signal…';
        }
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.gps_fixed;
      case TrackerState.error:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = tracker.error ?? 'Unknown error';
        icon = Icons.warning_amber;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          tracker.state == TrackerState.loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: fg))
              : Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
          ),
          if (tracker.state == TrackerState.error)
            GestureDetector(
              onTap: tracker.clearError,
              child: Icon(Icons.close, size: 16, color: fg),
            ),
        ],
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabs,
        indicatorColor: AppTheme.metroBlue,
        labelColor: AppTheme.metroBlue,
        unselectedLabelColor: Colors.grey,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.near_me, size: 18), text: 'Nearby Stations'),
          Tab(icon: Icon(Icons.route, size: 18), text: 'Follow Route'),
        ],
      ),
    );
  }
}

// ── Tracking toggle button ────────────────────────────────────────────────────

class _TrackingToggleButton extends StatelessWidget {
  final StationTrackerService tracker;
  const _TrackingToggleButton({required this.tracker});

  @override
  Widget build(BuildContext context) {
    final loading = tracker.state == TrackerState.loading;

    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final active = tracker.isTracking;
    return TextButton.icon(
      onPressed: active ? tracker.stopTracking : tracker.startTracking,
      icon: Icon(active ? Icons.stop_circle : Icons.play_circle,
          color: active ? Colors.red : Colors.green),
      label: Text(
        active ? 'Stop' : 'Start',
        style: TextStyle(
            color: active ? Colors.red : Colors.green,
            fontWeight: FontWeight.w700),
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
    if (!tracker.isTracking && tracker.state != TrackerState.active) {
      return _IdlePrompt(
        icon: Icons.near_me,
        title: 'Discover Nearby Stations',
        subtitle:
            'Tap ▶ Start to turn on GPS tracking.\nThe app will show all metro stations sorted by distance and alert you when you get close.',
      );
    }

    if (tracker.nearby.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.metroBlue),
            SizedBox(height: 16),
            Text('Calculating distances…',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: tracker.nearby.length,
      itemBuilder: (_, i) => _NearbyStationCard(
        item: tracker.nearby[i],
        rank: i,
      ),
    );
  }
}

class _NearbyStationCard extends StatelessWidget {
  final NearbyStation item;
  final int rank;
  const _NearbyStationCard({required this.item, required this.rank});

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
    IconData statusIcon;

    if (item.isArrived) {
      statusColor = Colors.green;
      statusLabel = 'You are here';
      statusIcon = Icons.check_circle;
    } else if (item.isApproaching) {
      statusColor = Colors.orange;
      statusLabel = 'Nearby';
      statusIcon = Icons.directions_walk;
    } else {
      statusColor = Colors.grey.shade400;
      statusLabel = '${item.walkMinutes} min walk';
      statusIcon = Icons.directions_walk;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: item.isArrived
            ? Border.all(color: Colors.green, width: 1.5)
            : item.isApproaching
                ? Border.all(color: Colors.orange.shade300, width: 1)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: rank == 0
                    ? AppTheme.metroBlue.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${rank + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rank == 0 ? AppTheme.metroBlue : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Line colour dot
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: lineColor, shape: BoxShape.circle),
            ),

            const SizedBox(width: 10),

            // Station name + line
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.station.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.station.line,
                    style: TextStyle(fontSize: 11, color: lineColor),
                  ),
                ],
              ),
            ),

            // Distance column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDistance(item.distanceMetres),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 11, color: statusColor),
                    const SizedBox(width: 2),
                    Text(statusLabel,
                        style:
                            TextStyle(fontSize: 10, color: statusColor)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2 — Route Follower
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Route picker card ──────────────────────────────────────
          _RoutePickerCard(
            tracker: tracker,
            routeFrom: routeFrom,
            routeTo: routeTo,
            onFromChanged: onFromChanged,
            onToChanged: onToChanged,
          ),

          const SizedBox(height: 20),

          // ── Route timeline ─────────────────────────────────────────
          if (tracker.loadingRoute)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.metroBlue),
                    SizedBox(height: 12),
                    Text('Building route…',
                        style: TextStyle(color: Colors.grey)),
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
                  'Start tracking, then select your from/to stations.\nThe app will tick off each station as you pass through it and notify you at every stop.',
            )
          else
            _IdlePrompt(
              icon: Icons.route,
              title: 'Select a Route',
              subtitle:
                  'Pick your departure and destination above, then tap "Load Route" to begin following.',
            ),
        ],
      ),
    );
  }
}

// ── Route picker card ─────────────────────────────────────────────────────────

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
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.route, color: AppTheme.metroBlue, size: 20),
                    SizedBox(width: 8),
                    Text('Route to Follow',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),

                // FROM
                const Text('FROM',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                SearchableStationDropdown(
                  stations: metroProvider.stations,
                  selectedStation: routeFrom,
                  hintText: 'Starting station',
                  prefixIcon: Icons.location_on,
                  onChanged: onFromChanged,
                ),

                const SizedBox(height: 12),

                // TO
                const Text('TO',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                SearchableStationDropdown(
                  stations: metroProvider.stations,
                  selectedStation: routeTo,
                  hintText: 'Destination station',
                  prefixIcon: Icons.flag,
                  onChanged: onToChanged,
                ),

                const SizedBox(height: 16),

                // Buttons row
                Row(
                  children: [
                    if (tracker.hasRoute)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: tracker.clearRoute,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    if (tracker.hasRoute) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: (routeFrom != null && routeTo != null)
                            ? () => tracker.loadRoute(routeFrom!, routeTo!)
                            : null,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(
                          tracker.hasRoute ? 'Reload Route' : 'Load Route',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.metroBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                // Warning if tracking not started
                if (!tracker.isTracking) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Start GPS tracking first (tap ▶ in the top-right)',
                            style: TextStyle(
                                fontSize: 11, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Route timeline ────────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.metroBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _progressStat('Total', '${stops.length}', Icons.train),
              _progressStat('Passed', '$passed', Icons.check_circle,
                  color: Colors.green),
              _progressStat('Remaining', '$remaining', Icons.directions,
                  color: AppTheme.metroBlue),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text('Stations',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),

        // Station list
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stops.length,
              itemBuilder: (_, i) => _TimelineStop(
                stop: stops[i],
                isFirst: i == 0,
                isLast: i == stops.length - 1,
                showConnector: i < stops.length - 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressStat(String label, String value, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

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

    // Visual state
    Color dotColor;
    Widget dotContent;
    Color textColor;
    FontWeight textWeight;

    if (stop.passed && !stop.isCurrent) {
      dotColor = Colors.grey.shade300;
      dotContent = const Icon(Icons.check, size: 12, color: Colors.grey);
      textColor = Colors.grey;
      textWeight = FontWeight.normal;
    } else if (stop.isCurrent) {
      dotColor = Colors.green;
      dotContent = const Icon(Icons.person_pin_circle,
          size: 14, color: Colors.white);
      textColor = Colors.green.shade700;
      textWeight = FontWeight.bold;
    } else if (isFirst) {
      dotColor = lineColor;
      dotContent = const Icon(Icons.play_arrow, size: 12, color: Colors.white);
      textColor = Colors.black87;
      textWeight = FontWeight.w600;
    } else if (isLast) {
      dotColor = lineColor;
      dotContent =
          const Icon(Icons.flag, size: 12, color: Colors.white);
      textColor = Colors.black87;
      textWeight = FontWeight.w600;
    } else {
      dotColor = lineColor;
      dotContent = Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle));
      textColor = Colors.black87;
      textWeight = FontWeight.normal;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connector + dot column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Top connector
                Container(
                  width: 2,
                  height: 14,
                  color: isFirst
                      ? Colors.transparent
                      : (stop.passed ? Colors.grey.shade300 : lineColor),
                ),
                // Dot
                Container(
                  width: 24,
                  height: 24,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  child: Center(child: dotContent),
                ),
                // Bottom connector
                Expanded(
                  child: Container(
                    width: 2,
                    color: showConnector
                        ? (stop.passed ? Colors.grey.shade300 : lineColor)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),

          // Station info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 2, bottom: 2),
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: stop.isCurrent
                    ? BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.shade300, width: 1),
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
                              fontSize: 13,
                              fontWeight: textWeight,
                              color: textColor,
                            ),
                          ),
                          Text(
                            stop.line,
                            style: TextStyle(
                              fontSize: 10,
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
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('YOU ARE HERE',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      )
                    else if (isFirst && !stop.passed)
                      _stationBadge('START', Colors.blue)
                    else if (isLast)
                      _stationBadge('DEST', AppTheme.metroRed)
                    else if (stop.passed)
                      const Icon(Icons.check_circle,
                          size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}

// ── Shared idle prompt ────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.metroBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 36, color: AppTheme.metroBlue),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
