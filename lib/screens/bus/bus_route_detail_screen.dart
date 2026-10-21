import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/bus_network.dart';
import '../../providers/bus_provider.dart';
import '../../services/live_bus_service.dart' show LiveBusService;
import '../../utils/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'bus_ui.dart';

/// One bus route (`/bus/route/:id`, id = [BusLine.id]): both directions,
/// timetable summary, live-bus count and the full stop list.
class BusRouteDetailScreen extends StatefulWidget {
  const BusRouteDetailScreen({super.key, required this.lineId});

  final String lineId;

  @override
  State<BusRouteDetailScreen> createState() => _BusRouteDetailScreenState();
}

class _BusRouteDetailScreenState extends State<BusRouteDetailScreen> {
  BusLine? _line;
  Future<int?>? _live;
  String? _liveFor;

  @override
  void initState() {
    super.initState();
    final bus = context.read<BusProvider>();
    bus.ensureLoaded().then((_) {
      if (!mounted || !bus.isReady) return;
      setState(() => _line = bus.network.lineByIdString(widget.lineId));
    });
  }

  void _loadLive(BusProvider bus, String number) {
    if (_liveFor == number && _live != null) return;
    _liveFor = number;
    _live = bus.liveBusCount(number);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bus = context.watch<BusProvider>();
    final line = _line ?? (bus.isReady ? bus.network.lineByIdString(widget.lineId) : null);

    Widget body;
    if (!bus.isReady) {
      body = SliverFillRemaining(hasScrollBody: false, child: Center(child: BusNetworkStatusView(bus: bus)));
    } else if (line == null) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: EmptyState(
            title: 'Route not found',
            message: 'This bus route isn\'t in the current timetable.',
            action: GradientButton(
              label: 'Find a bus',
              icon: Icons.search_rounded,
              gradient: AppTheme.emeraldGradient,
              expand: false,
              onPressed: () => context.go('/bus/route-finder'),
            ),
          ),
        ),
      );
    } else {
      _loadLive(bus, line.number);
      body = _buildContent(bus, line);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: line == null ? 'Bus route' : 'Bus ${line.number}',
                subtitle: line == null ? null : bus.network.terminiOf(line),
                icon: Icons.route_rounded,
                gradient: AppTheme.emeraldGradient,
                illustration: 'assets/images/illus_bus.svg',
                onBack: () => context.canPop() ? context.pop() : context.go('/bus'),
              ),
            ),
            body,
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BusProvider bus, BusLine line) {
    final p = context.palette;
    final net = bus.network;
    final directions = bus.directionsOf(line);
    final stops = net.stopsOf(line);
    final now = DateTime.now();
    final next = net.nextArrivals(line, 0, now, count: 3);
    final headway = line.headwayMinutes;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (directions.length > 1) ...[
            Text(
              'DIRECTION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in directions)
                  ChoiceChip(
                    label: Text(directionLabel(d), overflow: TextOverflow.ellipsis),
                    selected: d.id == line.id,
                    showCheckmark: false,
                    selectedColor: p.tint(busGreen),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: d.id == line.id ? busGreen : p.textSecondary,
                    ),
                    side: BorderSide(color: d.id == line.id ? busGreen : p.border),
                    onSelected: (_) => setState(() => _line = d),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          AppCard(
            radius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BusNumberBadge(line.number, large: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.operatorName,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                          ),
                          Text(
                            '${stops.length} stops · ${formatDistance(lineDistanceKm(line))} · ~${formatDuration(line.durationMinutes)} end to end',
                            style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    TagPill(label: line.isDtc ? 'DTC' : 'CLUSTER', color: line.isDtc ? AppTheme.metroBlue : busGreen),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _fact('First bus', line.firstDeparture == null ? '—' : formatMinutesOfDay(line.firstDeparture!))),
                    Expanded(child: _fact('Last bus', line.lastDeparture == null ? '—' : formatMinutesOfDay(line.lastDeparture!))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _fact('Frequency', headway == null ? 'Few trips' : 'Every ~$headway min')),
                    Expanded(child: _fact('Trips / day', '${line.tripCount}')),
                  ],
                ),
                const SizedBox(height: 12),
                const ScheduledNote(text: 'First/last bus are departures from the starting stop. Timetable estimates.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildLiveCard(line),
          if (next.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppCard(
              radius: 22,
              child: Row(
                children: [
                  const IconBubble(icon: Icons.schedule_rounded, color: AppTheme.primaryColor, size: 40, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next scheduled from ${stops.first.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.textTertiary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          next.map((a) => '~${formatClock(a.time)}').join('  ·  '),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SectionHeader(
            title: 'All stops',
            subtitle: 'Minutes from ${stops.first.name}',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          AppCard(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
            child: Column(
              children: [
                for (var i = 0; i < stops.length; i++)
                  BusStopTimelineRow(
                    name: stops[i].name,
                    isFirst: i == 0,
                    isLast: i == stops.length - 1,
                    highlight: i == 0 || i == stops.length - 1,
                    trailing: i == 0 ? 'Start' : '${line.offsets[i]} min',
                    onTap: () => context.push(stopPath(stops[i].id)),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _fact(String label, String value) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.6)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary)),
      ],
    );
  }

  Widget _buildLiveCard(BusLine line) {
    final p = context.palette;
    return AppCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.radar_rounded, color: busGreen, size: 40, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<int?>(
                  future: _live,
                  builder: (context, snap) {
                    final String title;
                    final String sub;
                    if (!LiveBusService.instance.isSupported) {
                      // e.g. web: the feed has no CORS, so a 0 count would be misleading.
                      title = 'Live tracking is in the app';
                      sub = "The live bus feed can't be opened in a web browser";
                    } else if (snap.connectionState != ConnectionState.done) {
                      title = 'Checking live buses…';
                      sub = 'From the Delhi OTD realtime feed';
                    } else if (snap.data == null) {
                      title = 'Live positions unavailable';
                      sub = 'Realtime feed couldn\'t be reached right now';
                    } else if (snap.data == 0) {
                      title = 'No buses reporting live';
                      sub = 'None of route ${line.number}\'s buses are sending GPS now';
                    } else {
                      title = '${snap.data} bus${snap.data == 1 ? '' : 'es'} live now';
                      sub = 'GPS-tracked on route ${line.number} (all directions)';
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.textPrimary)),
                        Text(sub, style: TextStyle(fontSize: 11.5, color: p.textTertiary)),
                      ],
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: Icon(Icons.refresh_rounded, color: p.textTertiary),
                onPressed: () => setState(() {
                  _live = context.read<BusProvider>().liveBusCount(line.number);
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Track ${line.number} live',
            icon: Icons.my_location_rounded,
            gradient: AppTheme.emeraldGradient,
            onPressed: () => context.push(liveTrackerPath(line.number)),
          ),
        ],
      ),
    );
  }
}
