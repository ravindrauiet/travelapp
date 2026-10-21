import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/bus_network.dart';
import '../../providers/bus_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'bus_ui.dart';

/// A bus stop (`/bus/stop/:id`, id = stop id). Shows every bay sharing the
/// stop's name nearby, the routes serving it and upcoming scheduled buses.
class BusStopDetailScreen extends StatefulWidget {
  const BusStopDetailScreen({super.key, required this.stopId});

  final String stopId;

  @override
  State<BusStopDetailScreen> createState() => _BusStopDetailScreenState();
}

class _BusStopDetailScreenState extends State<BusStopDetailScreen> {
  static const _departureLimit = 12;
  Timer? _ticker;
  DateTime _now = DateTime.now();
  bool _showAllDepartures = false;

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().ensureLoaded();
    // Keep "in N min" fresh while the screen is open.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bus = context.watch<BusProvider>();
    final id = int.tryParse(widget.stopId);
    final stop = bus.isReady && id != null ? bus.network.stopById(id) : null;
    final place = stop == null ? null : bus.network.placeOfStop(stop.id);

    Widget body;
    if (!bus.isReady) {
      body = SliverFillRemaining(hasScrollBody: false, child: Center(child: BusNetworkStatusView(bus: bus)));
    } else if (stop == null || place == null) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: EmptyState(
            title: 'Stop not found',
            message: 'This bus stop isn\'t served by any route in the current timetable.',
            action: GradientButton(
              label: 'Find stops near me',
              icon: Icons.place_rounded,
              gradient: AppTheme.emeraldGradient,
              expand: false,
              onPressed: () => context.go('/bus/stop-locator'),
            ),
          ),
        ),
      );
    } else {
      body = _buildContent(bus, stop, place);
    }

    final numbers = place == null ? const <String>[] : bus.routeNumbersAt(place);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: place?.name ?? 'Bus stop',
                subtitle: place == null
                    ? null
                    : '${numbers.length} route${numbers.length == 1 ? '' : 's'} · Stop code ${stop!.code}',
                icon: Icons.place_rounded,
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

  Widget _buildContent(BusProvider bus, BusStopInfo stop, BusPlace place) {
    final p = context.palette;
    final net = bus.network;
    final all = net.departuresAt(place, _now, limit: 40);
    final departures = _showAllDepartures ? all : all.take(_departureLimit).toList();

    // One line per route number serving here, to open its detail page.
    final lineFor = <String, BusLine>{};
    for (final l in net.linesAtPlace(place)) {
      lineFor.putIfAbsent(l.number, () => l);
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            children: [
              Expanded(
                child: _action(Icons.trip_origin_rounded, 'Plan from here', busGreen,
                    () => context.push(plannerPath(from: place.name))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _action(Icons.location_on_rounded, 'Plan to here', AppTheme.brandRose,
                    () => context.push(plannerPath(to: place.name))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _action(Icons.map_rounded, 'Open in Maps', AppTheme.metroBlue,
                    () => openInMaps(context, stop.lat, stop.lon)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            place.stops.length > 1
                ? '${place.stops.length} bus stops share this name nearby (e.g. both sides of the road). '
                    'Coordinates: ${stop.lat.toStringAsFixed(5)}, ${stop.lon.toStringAsFixed(5)}'
                : 'Coordinates: ${stop.lat.toStringAsFixed(5)}, ${stop.lon.toStringAsFixed(5)}',
            style: TextStyle(fontSize: 11.5, color: p.textTertiary, height: 1.4),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Upcoming buses',
            subtitle: 'Scheduled, approx. — ${formatClock(_now)}',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          if (departures.isEmpty)
            AppCard(
              child: Text(
                'No scheduled departures found for this stop.',
                style: TextStyle(fontSize: 13, color: p.textSecondary),
              ),
            )
          else
            AppCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final a in departures) _departureRow(bus, a),
                  if (!_showAllDepartures && all.length > _departureLimit)
                    TextButton(
                      onPressed: () => setState(() => _showAllDepartures = true),
                      style: TextButton.styleFrom(foregroundColor: busGreen),
                      child: Text('Show ${all.length - _departureLimit} more',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          const ScheduledNote(),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Routes from this stop',
            subtitle: 'Tap a number for its stops & timings',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in lineFor.entries)
                BusNumberChip(e.key, onTap: () => context.push(routePath(e.value))),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _departureRow(BusProvider bus, BusArrival a) {
    final p = context.palette;
    final towards = bus.network.stopById(a.line.stopIds.last)?.name ?? '';
    return InkWell(
      onTap: () => context.push(routePath(a.line)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            BusNumberBadge(a.line.number),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'to $towards',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '~${formatClock(a.time)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                  ),
                  Text(
                    relativeTime(a.time, _now),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: busGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          IconBubble(icon: icon, color: color, size: 38, radius: 12),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.textPrimary),
          ),
        ],
      ),
    );
  }
}
