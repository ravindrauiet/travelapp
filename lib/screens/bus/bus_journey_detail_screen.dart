import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/bus_network.dart';
import '../../services/bus_network_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'bus_ui.dart';

/// Step-by-step view of one [BusJourney]: each ride with its stops, where to
/// board, change and get off.
class BusJourneyDetailScreen extends StatelessWidget {
  const BusJourneyDetailScreen({super.key, required this.journey});

  final BusJourney journey;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final numbers = journey.legs.map((l) => l.line.number).join(' → ');
    final now = DateTime.now();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: 'Bus $numbers',
                subtitle: '${journey.legs.first.boardStop.name} → ${journey.legs.last.alightStop.name}',
                icon: Icons.directions_bus_rounded,
                gradient: AppTheme.emeraldGradient,
                illustration: 'assets/images/illus_bus.svg',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: '~${formatDuration(journey.totalMinutes)}',
                          label: 'Total time',
                          icon: Icons.schedule_rounded,
                          color: busGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          value: formatDistance(journey.distanceKm),
                          label: 'Distance',
                          icon: Icons.straighten_rounded,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          value: '₹${journey.fareNonAc}',
                          label: 'AC ₹${journey.fareAc}',
                          icon: Icons.confirmation_number_rounded,
                          color: AppTheme.metroBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Align(alignment: Alignment.centerLeft, child: PinkTicketNote()),
                  const SizedBox(height: 10),
                  ScheduledNote(
                    text: journey.isDirect
                        ? 'Total time includes an average wait for the bus. Times are approximate, from the timetable.'
                        : 'Total time includes average waits and a few minutes to change buses. '
                            'Fares are per ticket — you buy a new ticket on the second bus.',
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < journey.legs.length; i++) ...[
                    if (i > 0) _TransferCard(journey: journey),
                    _LegCard(leg: journey.legs[i], index: i, count: journey.legs.length, now: now),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.journey});

  final BusJourney journey;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final walk = journey.transferWalkMeters;
    final at = journey.legs.first.alightStop.name;
    final text = walk > 0
        ? 'Get off at $at and walk about $walk m (~${(walk / 80).ceil()} min) to the next stop'
        : 'Change buses at $at — same stop';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.tint(AppTheme.warningColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_walk_rounded, color: AppTheme.warningColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegCard extends StatefulWidget {
  const _LegCard({required this.leg, required this.index, required this.count, required this.now});

  final BusLeg leg;
  final int index;
  final int count;
  final DateTime now;

  @override
  State<_LegCard> createState() => _LegCardState();
}

class _LegCardState extends State<_LegCard> {
  static const _collapsedMiddle = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final leg = widget.leg;
    final net = BusNetworkService.instance;
    final towards = net.stopById(leg.line.stopIds.last)?.name ?? '';
    final next = net.nextArrivals(leg.line, leg.fromIndex, widget.now, count: 3);
    final stops = leg.stops;
    final middle = stops.length - 2;
    final collapse = !_expanded && middle > _collapsedMiddle;
    final baseOffset = leg.line.offsets[leg.fromIndex];

    Widget row(int i) {
      final stop = stops[i];
      final isBoard = i == 0;
      final isAlight = i == stops.length - 1;
      final mins = leg.line.offsets[leg.fromIndex + i] - baseOffset;
      return BusStopTimelineRow(
        name: stop.name,
        isFirst: isBoard,
        isLast: isAlight,
        highlight: isBoard || isAlight,
        color: isAlight && widget.index == widget.count - 1 ? AppTheme.brandRose : busGreen,
        subtitle: isBoard ? 'Board here' : (isAlight ? 'Get off here' : null),
        trailing: isBoard ? null : '+$mins min',
        onTap: () => context.push(stopPath(stop.id)),
      );
    }

    return AppCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BusNumberBadge(leg.line.number, large: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.count > 1 ? 'Bus ${widget.index + 1} of ${widget.count}' : 'Your bus',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Towards $towards',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                  ],
                ),
              ),
              TagPill(label: leg.line.isDtc ? 'DTC' : 'CLUSTER', color: leg.line.isDtc ? AppTheme.metroBlue : busGreen),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BusInfoPill(Icons.timer_outlined, '~${formatDuration(leg.rideMinutes)} ride', busGreen),
              BusInfoPill(Icons.place_rounded, '${leg.stopCount} stops', AppTheme.brandViolet),
              BusInfoPill(Icons.straighten_rounded, formatDistance(leg.distanceKm), AppTheme.accentColor),
              if (leg.line.headwayMinutes != null)
                BusInfoPill(Icons.repeat_rounded, 'Every ~${leg.line.headwayMinutes} min', AppTheme.primaryColor),
            ],
          ),
          if (next.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'SCHEDULED AT ${stops.first.name.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.6),
            ),
            const SizedBox(height: 6),
            Text(
              next.map((a) => '~${formatClock(a.time)}').join('   ·   '),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.textPrimary),
            ),
            Text(
              'Next one ${relativeTime(next.first.time, widget.now)} (approx.)',
              style: TextStyle(fontSize: 11.5, color: p.textTertiary),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: p.border),
          const SizedBox(height: 8),
          if (collapse) ...[
            row(0),
            for (var i = 1; i <= 2; i++) row(i),
            _ShowAll(count: middle - 3, onTap: () => setState(() => _expanded = true)),
            row(stops.length - 2),
            row(stops.length - 1),
          ] else
            for (var i = 0; i < stops.length; i++) row(i),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push(routePath(leg.line)),
              style: TextButton.styleFrom(foregroundColor: busGreen),
              icon: const Icon(Icons.route_rounded, size: 18),
              label: Text('View route ${leg.line.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowAll extends StatelessWidget {
  const _ShowAll({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(child: Icon(Icons.more_vert_rounded, size: 18, color: busGreen.withValues(alpha: 0.7))),
            ),
            const SizedBox(width: 10),
            Text(
              'Show $count more stop${count == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: busGreen),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 18, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}
