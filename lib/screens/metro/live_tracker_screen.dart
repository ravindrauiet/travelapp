import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/station_tracker_service.dart';
import '../../providers/metro_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/searchable_station_dropdown.dart';
import '../../widgets/ui_kit.dart';

Color _parseHex(String hex, [Color fallback = AppTheme.metroBlue]) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return fallback;
  }
}

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
    final p = context.palette;
    return Consumer<StationTrackerService>(
      builder: (context, tracker, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
          child: Scaffold(
            backgroundColor: p.background,
            body: Column(
              children: [
                GradientHeader(
                  title: 'Live Tracker',
                  subtitle: 'GPS station proximity & route follow',
                  icon: Icons.my_location_rounded,
                  gradient: AppTheme.oceanGradient,
                  actions: [_TrackingToggleButton(tracker: tracker)],
                  bottom: Column(
                    children: [
                      _buildGpsStatusBar(tracker),
                      const SizedBox(height: 12),
                      _buildPillTabBar(),
                    ],
                  ),
                ),
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
          ),
        );
      },
    );
  }

  // ── GPS Status Bar ──────────────────────────────────────────────────────────

  Widget _buildGpsStatusBar(StationTrackerService tracker) {
    Color dot;
    String label;
    IconData icon;

    switch (tracker.state) {
      case TrackerState.idle:
        dot = Colors.white.withValues(alpha: 0.6);
        label = tracker.journeyComplete && tracker.trackedStops.isNotEmpty
            ? 'Arrived at ${tracker.trackedStops.last.name} — GPS turned off'
            : 'Tracking stopped — tap Start to begin';
        icon = tracker.journeyComplete ? Icons.flag_rounded : Icons.gps_off_rounded;
      case TrackerState.loading:
        dot = const Color(0xFFFFB547);
        label = 'Loading station data…';
        icon = Icons.sync_rounded;
      case TrackerState.active:
        final pos = tracker.position;
        label = pos != null
            ? 'GPS active  ·  ±${pos.accuracy.round()} m accuracy'
            : 'Acquiring GPS signal…';
        dot = const Color(0xFF4ADE80);
        icon = Icons.signal_cellular_alt_rounded;
      case TrackerState.error:
        dot = const Color(0xFFFCA5A5);
        label = tracker.error ?? 'Unknown error';
        icon = Icons.warning_amber_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tracker.state == TrackerState.error
            ? AppTheme.errorColor.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          tracker.state == TrackerState.loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: dot.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 13, color: dot),
                ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          if (tracker.state == TrackerState.error && tracker.canFixInSettings)
            GestureDetector(
              onTap: tracker.openSettings,
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Settings',
                  style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          if (tracker.state == TrackerState.error)
            GestureDetector(
              onTap: tracker.clearError,
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ── Segmented Tab Bar ──────────────────────────────────────────────────

  Widget _buildPillTabBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _SegmentedTab(
            label: 'Nearby Stations',
            icon: Icons.near_me_rounded,
            selected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          _SegmentedTab(
            label: 'Follow Route',
            icon: Icons.route_rounded,
            selected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ],
      ),
    );
  }
}

// ── Segmented Tab Item ───────────────────────────────────────────────────

class _SegmentedTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentedTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF0369A1);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.brandNight.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? selectedColor : Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? selectedColor : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDistance(double metres) =>
    metres < 1000 ? '${metres.round()} m' : '${(metres / 1000).toStringAsFixed(1)} km';

// ── Tracking Toggle Button ────────────────────────────────────────────────────

class _TrackingToggleButton extends StatelessWidget {
  final StationTrackerService tracker;
  const _TrackingToggleButton({required this.tracker});

  @override
  Widget build(BuildContext context) {
    if (tracker.state == TrackerState.loading) {
      return Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    final active = tracker.isTracking;
    return GestureDetector(
      onTap: active ? tracker.stopTracking : tracker.startTracking,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.sunsetGradient : AppTheme.emeraldGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: AppTheme.glow(active ? AppTheme.brandRose : AppTheme.successColor, alpha: 0.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 5),
            Text(
              active ? 'Stop' : 'Start',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
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
    final p = context.palette;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metro map section
          _MetroMapWidget(tracker: tracker),

          const SizedBox(height: 20),

          // Arriving soon
          if (!tracker.isTracking && tracker.state != TrackerState.active)
            const _IdlePrompt(
              illustration: 'assets/images/illus_explore.svg',
              title: 'Discover Nearby Stations',
              subtitle: 'Tap Start to turn on GPS.\nStations will appear sorted by distance.',
            )
          else if (tracker.nearby.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: p.primary),
                    const SizedBox(height: 14),
                    Text(
                      'Calculating distances…',
                      style: TextStyle(color: p.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SectionHeader(
              title: 'Arriving soon',
              subtitle: '${tracker.nearby.length} stations near you',
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

// ── Metro Map Widget ──────────────────────────────────────────────

class _MetroMapWidget extends StatelessWidget {
  final StationTrackerService tracker;
  const _MetroMapWidget({required this.tracker});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final currentStation = tracker.nearby.isNotEmpty
        ? tracker.nearby.first.station.name
        : (tracker.isTracking ? 'Detecting Location…' : 'Location Off');

    final Color lineColor = tracker.nearby.isNotEmpty
        ? _parseHex(tracker.nearby.first.station.lineColor)
        : (tracker.isTracking ? p.primary : p.textTertiary);

    return Container(
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: p.cardAlt,
        border: Border.all(color: p.border.withValues(alpha: p.isDark ? 1 : 0.7)),
        boxShadow: p.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Custom SVG-style Metro Map Background
          Positioned.fill(
            child: CustomPaint(painter: _MetroMapPainter(isDark: p.isDark)),
          ),

          // ── LIVE FEED badge (top-left) ──────────────────────────────
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: tracker.isTracking ? AppTheme.emeraldGradient : AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tracker.isTracking ? Colors.white : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tracker.isTracking ? 'GPS ON' : 'GPS OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Timer card (top-right) ──────────────────────────────────
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandNight.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.directions_walk_rounded, size: 16, color: AppTheme.accentColor),
                  const SizedBox(width: 4),
                  Text(
                    tracker.isTracking && tracker.nearby.isNotEmpty
                        ? tracker.nearby.first.walkMinutes
                            .toString()
                            .padLeft(2, '0')
                        : '--',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'min',
                    style: TextStyle(
                      color: p.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Station name + line (bottom-left) ───────────────────────
          Positioned(
            bottom: 14,
            left: 14,
            right: 64,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.card.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: lineColor, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentStation,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tracker.nearby.isNotEmpty
                        ? '${tracker.nearby.first.station.line} · ${_formatDistance(tracker.nearby.first.distanceMetres)} away'
                        : (tracker.isTracking
                            ? 'Searching for nearest metro station…'
                            : 'GPS off — Tap Start to detect nearest station'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tracker.nearby.isNotEmpty ? lineColor : p.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Location button (bottom-right) ──────────────────────────
          Positioned(
            bottom: 18,
            right: 14,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.oceanGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.glow(AppTheme.infoColor, alpha: 0.35),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metro Map Painter ─────────────────────────────────────────────────────────

class _MetroMapPainter extends CustomPainter {
  final bool isDark;
  _MetroMapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = isDark ? 0.55 : 0.4;

    Paint linePaint(Color c, double w) => Paint()
      ..color = c.withValues(alpha: alpha)
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bluePaint = linePaint(AppTheme.metroBlue, 4);
    final greenPaint = linePaint(AppTheme.metroGreen, 4);
    final yellowPaint = linePaint(AppTheme.metroYellow, 3.5);
    final violetPaint = linePaint(AppTheme.metroViolet, 3);

    final dotPaint = Paint()
      ..color = isDark ? AppTheme.darkCard : Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppTheme.metroBlue.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final w = size.width;
    final h = size.height;

    // Subtle grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : AppTheme.brandIndigo).withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Blue line (horizontal with curves)
    final path1 = Path();
    path1.moveTo(0, h * 0.4);
    path1.quadraticBezierTo(w * 0.25, h * 0.2, w * 0.5, h * 0.45);
    path1.quadraticBezierTo(w * 0.75, h * 0.65, w, h * 0.5);
    canvas.drawPath(path1, bluePaint);

    // Blue line branch
    final path1b = Path();
    path1b.moveTo(w * 0.5, h * 0.45);
    path1b.quadraticBezierTo(w * 0.55, h * 0.1, w * 0.8, 0);
    canvas.drawPath(path1b, violetPaint);

    // Green line (diagonal)
    final path2 = Path();
    path2.moveTo(0, h * 0.7);
    path2.quadraticBezierTo(w * 0.35, h * 0.5, w * 0.65, h * 0.35);
    path2.lineTo(w, h * 0.2);
    canvas.drawPath(path2, greenPaint);

    // Yellow line (short curve)
    final path3 = Path();
    path3.moveTo(0, h * 0.85);
    path3.quadraticBezierTo(w * 0.3, h * 0.75, w * 0.55, h * 0.65);
    canvas.drawPath(path3, yellowPaint);

    // Station dots
    final stations = [
      Offset(w * 0.0, h * 0.4),
      Offset(w * 0.25, h * 0.32),
      Offset(w * 0.5, h * 0.45),
      Offset(w * 0.75, h * 0.58),
      Offset(w * 1.0, h * 0.5),
      Offset(w * 0.35, h * 0.53),
      Offset(w * 0.65, h * 0.38),
    ];

    for (final s in stations) {
      canvas.drawCircle(s, 5, dotPaint);
      canvas.drawCircle(s, 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MetroMapPainter oldDelegate) => oldDelegate.isDark != isDark;
}

// ── Arriving Soon Station Card ────────────────────────────────────────────────

class _StationArrivingCard extends StatelessWidget {
  final NearbyStation item;
  final int rank;
  const _StationArrivingCard({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lineColor = _parseHex(item.station.lineColor);

    Color statusColor;
    String statusLabel;

    if (item.isArrived) {
      statusColor = AppTheme.successColor;
      statusLabel = 'YOU ARE HERE';
    } else if (item.isApproaching) {
      statusColor = AppTheme.warningColor;
      statusLabel = '${item.walkMinutes} MIN WALK';
    } else {
      statusColor = p.textTertiary;
      statusLabel = '${item.walkMinutes} MIN WALK';
    }

    final distText = item.distanceMetres < 1000
        ? '${item.distanceMetres.round()} m'
        : '${(item.distanceMetres / 1000).toStringAsFixed(1)} km';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: item.isArrived ? p.tint(AppTheme.successColor) : p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isArrived
              ? AppTheme.successColor.withValues(alpha: 0.6)
              : p.border.withValues(alpha: p.isDark ? 1 : 0.7),
          width: item.isArrived ? 1.5 : 1,
        ),
        boxShadow: p.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left coloured border line
            Container(width: 5, color: lineColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    // Rank bubble
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: item.isArrived ? AppTheme.emeraldGradient : null,
                        color: item.isArrived ? null : p.tint(lineColor),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Text(
                          (rank + 1).toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: item.isArrived ? Colors.white : lineColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Station name & status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.station.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Distance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: p.tint(item.isArrived || item.isApproaching ? statusColor : p.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        distText,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: item.isArrived || item.isApproaching ? statusColor : p.primary,
                        ),
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
    final lineColors = <String>[];
    for (final s in stops) {
      if (!lineColors.contains(s.lineColor)) lineColors.add(s.lineColor);
    }
    final status = tracker.journeyComplete
        ? 'Arrived'
        : (tracker.isTracking ? '$remaining stop${remaining == 1 ? '' : 's'} left' : 'GPS off');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.glow(AppTheme.brandViolet, alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TagPill(label: 'CURRENT TRIP', color: Colors.white, icon: Icons.train_rounded, onDark: true),
          const SizedBox(height: 10),
          Text(
            to.isNotEmpty ? to : 'No destination',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          if (from.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'from $from',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Line colour bubbles (one per line on the route)
              for (final c in lineColors.take(3)) _LineBubble(color: _parseHex(c)),
              if (remaining > 0 && !tracker.journeyComplete)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              // Trip status (no live train data — progress comes from GPS)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.sunsetGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tracker.journeyComplete ? Icons.flag_rounded : Icons.my_location_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
      ),
      child: const Icon(Icons.train_rounded, size: 14, color: Colors.white),
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
    final p = context.palette;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
          const SizedBox(height: 18),
          if (tracker.loadingRoute)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: p.primary),
                    const SizedBox(height: 14),
                    Text(
                      'Building route…',
                      style: TextStyle(color: p.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            )
          else if (tracker.routeError != null && !tracker.hasRoute)
            _IdlePrompt(
              title: 'Couldn\'t load route',
              subtitle: tracker.routeError!,
            )
          else if (tracker.hasRoute)
            _RouteTimeline(tracker: tracker)
          else if (!tracker.isTracking)
            const _IdlePrompt(
              title: 'Follow Your Metro Journey',
              subtitle:
                  'Start tracking, then select your from/to stations.\nThe app will tick off each station as you pass through it.',
            )
          else
            const _IdlePrompt(
              title: 'Select a Route',
              subtitle: 'Pick your departure and destination, then tap Load Route.',
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
    final p = context.palette;

    Widget label(String text, Color dot) {
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

    return Consumer<MetroProvider>(
      builder: (context, metroProvider, _) {
        return AppCard(
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBubble(icon: Icons.route_rounded, color: AppTheme.infoColor, size: 38, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route to follow',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                        ),
                        Text(
                          'We tick off stations as you pass them',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: p.textTertiary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // FROM
              label('FROM', AppTheme.successColor),
              SearchableStationDropdown(
                stations: metroProvider.stations,
                selectedStation: routeFrom,
                hintText: 'Starting station',
                prefixIcon: Icons.trip_origin_rounded,
                accentColor: AppTheme.successColor,
                onChanged: onFromChanged,
              ),
              const SizedBox(height: 14),

              // TO
              label('TO', AppTheme.accentColor),
              SearchableStationDropdown(
                stations: metroProvider.stations,
                selectedStation: routeTo,
                hintText: 'Destination station',
                prefixIcon: Icons.flag_rounded,
                accentColor: AppTheme.accentColor,
                onChanged: onToChanged,
              ),
              const SizedBox(height: 18),

              // Buttons
              Row(
                children: [
                  if (tracker.hasRoute) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: tracker.clearRoute,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.6), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      label: tracker.hasRoute ? 'Reload Route' : 'Load Route',
                      icon: Icons.play_arrow_rounded,
                      gradient: AppTheme.oceanGradient,
                      onPressed: (routeFrom != null && routeTo != null)
                          ? () => tracker.loadRoute(routeFrom!, routeTo!)
                          : null,
                    ),
                  ),
                ],
              ),

              // GPS warning
              if (!tracker.isTracking) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.tint(AppTheme.warningColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Start GPS tracking first (tap Start in the top-right)',
                          style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w600),
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
    final p = context.palette;
    final stops = tracker.trackedStops;
    final passed = tracker.passedCount;
    final remaining = tracker.remainingStops;
    final progress = stops.isEmpty ? 0.0 : (passed / stops.length).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tracker.journeyComplete || !tracker.isTracking) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.tint(tracker.journeyComplete ? AppTheme.successColor : AppTheme.warningColor),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  tracker.journeyComplete ? Icons.flag_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: tracker.journeyComplete ? AppTheme.successColor : AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tracker.journeyComplete
                        ? 'You have arrived at ${stops.last.name}. GPS tracking was turned off automatically.'
                        : 'GPS is off — tap Start (top-right) so stations are ticked off as you travel. '
                            'Alerts keep working in the background.',
                    style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Progress summary
        AppCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _ProgressStat(label: 'Total', value: '${stops.length}', icon: Icons.train_rounded, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  _ProgressStat(label: 'Passed', value: '$passed', icon: Icons.check_circle_rounded, color: AppTheme.successColor),
                  const SizedBox(width: 10),
                  _ProgressStat(label: 'Remaining', value: '$remaining', icon: Icons.directions_rounded, color: AppTheme.accentColor),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: p.tint(AppTheme.successColor),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.successColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Stations',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.textPrimary),
        ),
        const SizedBox(height: 10),
        AppCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
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
  final Color color;
  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: p.tint(color),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: p.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
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
    final p = context.palette;
    final lineColor = _parseHex(stop.lineColor);
    final passedColor = p.border;

    Color dotColor;
    Widget dotContent;
    Color textColor;

    if (stop.passed && !stop.isCurrent) {
      dotColor = passedColor;
      dotContent = Icon(Icons.check_rounded, size: 12, color: p.textTertiary);
      textColor = p.textTertiary;
    } else if (stop.isCurrent) {
      dotColor = AppTheme.successColor;
      dotContent = const Icon(Icons.person_pin_circle_rounded, size: 14, color: Colors.white);
      textColor = AppTheme.successColor;
    } else if (isFirst) {
      dotColor = lineColor;
      dotContent = const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white);
      textColor = p.textPrimary;
    } else if (isLast) {
      dotColor = lineColor;
      dotContent = const Icon(Icons.flag_rounded, size: 12, color: Colors.white);
      textColor = p.textPrimary;
    } else {
      dotColor = lineColor;
      dotContent = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
      );
      textColor = p.textPrimary;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  color: isFirst
                      ? Colors.transparent
                      : (stop.passed ? passedColor : lineColor),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: stop.isCurrent ? AppTheme.glow(AppTheme.successColor, alpha: 0.45) : null,
                  ),
                  child: Center(child: dotContent),
                ),
                Expanded(
                  child: Container(
                    width: 3,
                    color: showConnector
                        ? (stop.passed ? passedColor : lineColor)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 3, bottom: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: stop.isCurrent
                    ? BoxDecoration(
                        color: p.tint(AppTheme.successColor),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.4)),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: stop.isCurrent || isFirst || isLast ? FontWeight.w800 : FontWeight.w600,
                              color: textColor,
                              decoration: stop.passed && !stop.isCurrent ? TextDecoration.lineThrough : null,
                              decorationColor: p.textTertiary,
                            ),
                          ),
                          Text(
                            stop.line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: stop.passed && !stop.isCurrent ? p.textTertiary : lineColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (stop.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppTheme.emeraldGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'YOU ARE HERE',
                          style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      )
                    else if (isFirst && !stop.passed)
                      const TagPill(label: 'START', color: AppTheme.primaryColor)
                    else if (isLast)
                      const TagPill(label: 'DEST', color: AppTheme.accentColor)
                    else if (stop.passed)
                      Icon(Icons.check_circle_rounded, size: 16, color: p.textTertiary),
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

// ── Shared Idle Prompt ────────────────────────────────────────────────────────

class _IdlePrompt extends StatelessWidget {
  final String illustration;
  final String title;
  final String subtitle;

  const _IdlePrompt({
    this.illustration = 'assets/images/empty_route.svg',
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        title: title,
        message: subtitle,
        illustration: illustration,
      ),
    );
  }
}
