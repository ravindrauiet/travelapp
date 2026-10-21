import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/live_bus_service.dart';
import '../utils/app_theme.dart';
import 'ui_kit.dart';

/// Building blocks shared by the live tracker and the bus map.

const Color kBusGreen = Color(0xFF059669);

/// Emerald pill with the passenger-facing route number.
class RoutePill extends StatelessWidget {
  final String number;
  final bool known;
  final double fontSize;

  const RoutePill({super.key, required this.number, this.known = true, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.7, vertical: fontSize * 0.35),
      decoration: BoxDecoration(
        gradient: known ? AppTheme.emeraldGradient : null,
        color: known ? null : p.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: known ? null : Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_bus_rounded, size: fontSize, color: known ? Colors.white : p.textTertiary),
          SizedBox(width: fontSize * 0.3),
          Text(
            known ? number : 'Route ?',
            style: TextStyle(
              color: known ? Colors.white : p.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pulsing "LIVE" dot.
class LiveDot extends StatefulWidget {
  final Color color;
  final double size;
  const LiveDot({super.key, this.color = AppTheme.successColor, this.size = 8});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.2,
      height: widget.size * 2.2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * (1 + _c.value * 1.2),
              height: widget.size * (1 + _c.value * 1.2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

/// List card for one live bus.
class LiveBusCard extends StatelessWidget {
  final LiveBus bus;
  final DateTime now;
  final double? distanceKm;
  final VoidCallback? onTap;

  const LiveBusCard({super.key, required this.bus, required this.now, this.distanceKm, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final age = bus.ageAt(now);
    final old = age.inMinutes >= 3;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RoutePill(number: bus.routeNumber, known: bus.isMatched),
              const SizedBox(width: 8),
              if (bus.direction.isNotEmpty) ...[
                TagPill(label: bus.direction, color: AppTheme.infoColor),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  bus.registration,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.textTertiary, letterSpacing: 0.4),
                ),
              ),
              if (distanceKm != null)
                Text(
                  formatDistance(distanceKm!),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kBusGreen),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bus.termini ?? 'Route details not in the timetable yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.place_rounded, size: 14, color: p.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  bus.whereText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              LiveDot(color: old ? AppTheme.warningColor : AppTheme.successColor, size: 6),
              const SizedBox(width: 4),
              Text(
                'Updated ${formatAge(age)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: old ? AppTheme.warningColor : p.textTertiary,
                ),
              ),
              const Spacer(),
              if (bus.speedKmh != null)
                TagPill(
                  label: bus.isMoving == true ? '${bus.speedKmh!.round()} km/h' : 'Stopped',
                  color: bus.isMoving == true ? kBusGreen : p.textTertiary,
                  icon: bus.isMoving == true ? Icons.speed_rounded : Icons.pause_circle_outline_rounded,
                ),
              const SizedBox(width: 6),
              TagPill(label: bus.line?.isDtc == false ? 'CLUSTER' : (bus.isMatched ? 'DTC' : 'BUS'), color: AppTheme.brandIndigo),
            ],
          ),
        ],
      ),
    );
  }
}

/// Error / unsupported state for the live feed.
class LiveFeedErrorState extends StatelessWidget {
  final LiveBusException error;
  final VoidCallback? onRetry;

  const LiveFeedErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final web = error.kind == LiveBusErrorKind.unsupportedPlatform;
    return EmptyState(
      title: error.title,
      message: error.message,
      illustration: web ? 'assets/images/illus_bus.svg' : 'assets/images/empty_route.svg',
      action: web
          ? GradientButton(
              label: 'Plan a bus trip instead',
              icon: Icons.alt_route_rounded,
              gradient: AppTheme.emeraldGradient,
              expand: false,
              onPressed: () => context.push('/bus/route-finder'),
            )
          : (error.isRetryable && onRetry != null)
              ? GradientButton(
                  label: 'Try again',
                  icon: Icons.refresh_rounded,
                  gradient: AppTheme.emeraldGradient,
                  expand: false,
                  onPressed: onRetry,
                )
              : null,
    );
  }
}

/// Bottom sheet with full details of a live bus.
Future<void> showLiveBusSheet(
  BuildContext context,
  LiveBus bus, {
  double? userLat,
  double? userLon,
  bool showMapButton = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _LiveBusSheet(
      bus: bus,
      userLat: userLat,
      userLon: userLon,
      showMapButton: showMapButton,
      parentContext: context,
    ),
  );
}

class _LiveBusSheet extends StatelessWidget {
  final LiveBus bus;
  final double? userLat;
  final double? userLon;
  final bool showMapButton;
  final BuildContext parentContext;

  const _LiveBusSheet({
    required this.bus,
    required this.userLat,
    required this.userLon,
    required this.showMapButton,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final ahead = LiveBusService.instance.stopsAhead(bus, count: 8);
    final dist = userLat == null || userLon == null ? null : bus.distanceKmTo(userLat!, userLon!);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.66,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(16, 10, 16, 24 + MediaQuery.of(context).padding.bottom),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              gradient: AppTheme.emeraldGradient,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        bus.isMatched ? bus.routeNumber : 'Live bus',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8),
                      ),
                      const SizedBox(width: 10),
                      if (bus.direction.isNotEmpty) TagPill(label: bus.direction, color: Colors.white, onDark: true),
                      const Spacer(),
                      const LiveDot(color: Colors.white),
                      const SizedBox(width: 2),
                      const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bus.termini ?? 'This route isn\'t in the published timetable yet',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TagPill(label: bus.registration, color: Colors.white, onDark: true, icon: Icons.badge_rounded),
                      TagPill(label: bus.operatorName, color: Colors.white, onDark: true, icon: Icons.business_rounded),
                      TagPill(label: 'Updated ${formatAge(bus.ageAt(now))}', color: Colors.white, onDark: true, icon: Icons.schedule_rounded),
                      if (bus.speedKmh != null)
                        TagPill(
                          label: bus.isMoving == true
                              ? '${bus.speedEstimated ? '~' : ''}${bus.speedKmh!.round()} km/h'
                              : 'Stopped',
                          color: Colors.white,
                          onDark: true,
                          icon: Icons.speed_rounded,
                        ),
                      if (dist != null)
                        TagPill(label: '${formatDistance(dist)} away', color: Colors.white, onDark: true, icon: Icons.near_me_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const IconBubble(icon: Icons.place_rounded, color: kBusGreen, size: 38, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bus.whereText,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            if (ahead.isNotEmpty) ...[
              const SectionHeader(
                title: 'Stops ahead',
                subtitle: 'Approximate, from scheduled run times',
                padding: EdgeInsets.fromLTRB(2, 20, 2, 10),
              ),
              AppCard(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Column(
                  children: [
                    for (var i = 0; i < ahead.length; i++)
                      _StopRow(eta: ahead[i], first: i == 0, last: i == ahead.length - 1),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                if (showMapButton)
                  Expanded(
                    child: GradientButton(
                      label: 'Show on map',
                      icon: Icons.map_rounded,
                      gradient: AppTheme.emeraldGradient,
                      onPressed: () {
                        Navigator.of(context).pop();
                        final q = bus.isMatched ? 'route=${Uri.encodeQueryComponent(bus.routeNumber)}&' : '';
                        parentContext.push('/bus/map?${q}bus=${Uri.encodeQueryComponent(bus.id)}');
                      },
                    ),
                  ),
                if (showMapButton && bus.isMatched) const SizedBox(width: 10),
                if (bus.isMatched)
                  Expanded(
                    child: GradientButton(
                      label: 'Open route',
                      icon: Icons.route_rounded,
                      gradient: AppTheme.heroGradient,
                      onPressed: () {
                        Navigator.of(context).pop();
                        parentContext.push('/bus/route/${bus.line!.id}');
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final LiveStopEta eta;
  final bool first;
  final bool last;

  const _StopRow({required this.eta, required this.first, required this.last});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Expanded(child: Container(width: 3, color: first ? Colors.transparent : kBusGreen.withValues(alpha: 0.35))),
                Container(
                  width: first ? 14 : 10,
                  height: first ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: first ? kBusGreen : p.card,
                    border: Border.all(color: kBusGreen, width: 2.5),
                  ),
                ),
                Expanded(child: Container(width: 3, color: last ? Colors.transparent : kBusGreen.withValues(alpha: 0.35))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                eta.stop.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: first ? FontWeight.w800 : FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              eta.minutes <= 1 ? '~1 min' : '~${eta.minutes} min',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: first ? kBusGreen : p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
