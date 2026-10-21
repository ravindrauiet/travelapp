import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/bus_network.dart';
import '../../providers/bus_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/bus_network_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_kit.dart';

/// Shared pieces for the bus screens (formatting, badges, loading/error views).

const Color busGreen = Color(0xFF059669);
const Color pinkTicket = Color(0xFFDB2777);

// ── Formatting ──────────────────────────────────────────────────────────────

String formatClock(DateTime t) => DateFormat('h:mm a').format(t).toLowerCase();

/// Minutes after midnight (may exceed 24 h for after-midnight trips) → "6:00 am".
String formatMinutesOfDay(int minutes) {
  final m = minutes % (24 * 60);
  return formatClock(DateTime(2000, 1, 1, m ~/ 60, m % 60));
}

String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')} min';
}

String formatDistance(double km) => km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

String formatCount(int n) {
  if (n >= 100000) return '${(n / 1000).round()}k';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
  return NumberFormat.decimalPattern('en_IN').format(n);
}

/// "now", "in 7 min", "in 1 h 20 min", or "tomorrow 6:10 am".
String relativeTime(DateTime t, DateTime now) {
  final mins = t.difference(now).inMinutes;
  if (t.day != now.day && mins > 12 * 60) return 'tomorrow ${formatClock(t)}';
  if (mins <= 0) return 'now';
  return 'in ${formatDuration(mins)}';
}

String directionLabel(BusLine line) {
  final d = line.direction.isEmpty ? 'Route' : line.direction;
  final last = BusNetworkService.instance.stopById(line.stopIds.last)?.name ?? '';
  return '$d · to $last';
}

double lineDistanceKm(BusLine line) {
  final stops = BusNetworkService.instance.stopsOf(line);
  var km = 0.0;
  for (var i = 1; i < stops.length; i++) {
    km += BusNetworkService.distanceKm(stops[i - 1].lat, stops[i - 1].lon, stops[i].lat, stops[i].lon);
  }
  return km;
}

String routePath(BusLine line) => '/bus/route/${line.id}';
String stopPath(int stopId) => '/bus/stop/$stopId';
String plannerPath({String? from, String? to}) {
  final q = <String, String>{
    if (from != null) 'from': from,
    if (to != null) 'to': to,
  };
  return Uri(path: '/bus/route-finder', queryParameters: q.isEmpty ? null : q).toString();
}

String liveTrackerPath(String number) =>
    Uri(path: '/bus/realtime', queryParameters: {'route': number}).toString();

Future<void> openInMaps(BuildContext context, double lat, double lon) async {
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Maps on this device')),
    );
  }
}

// ── Location ────────────────────────────────────────────────────────────────

enum LocationIssue { serviceOff, denied, deniedForever, unavailable }

extension LocationIssueText on LocationIssue {
  String get title => switch (this) {
        LocationIssue.serviceOff => 'Location is turned off',
        LocationIssue.denied => 'Location permission needed',
        LocationIssue.deniedForever => 'Location permission blocked',
        LocationIssue.unavailable => 'Couldn\'t find your location',
      };

  String get message => switch (this) {
        LocationIssue.serviceOff => 'Turn on location services to see bus stops around you.',
        LocationIssue.denied => 'Allow location access to see bus stops around you.',
        LocationIssue.deniedForever => 'Location access is blocked for Metromate. Enable it in app settings.',
        LocationIssue.unavailable => 'Your device didn\'t return a GPS fix. Try again outdoors, or search by name.',
      };

  /// Label of the settings button, or null when retrying is the only fix.
  String? get settingsLabel => switch (this) {
        LocationIssue.serviceOff => 'Location settings',
        LocationIssue.deniedForever => 'App settings',
        _ => null,
      };

  Future<void> openSettings() async {
    try {
      if (this == LocationIssue.serviceOff) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (_) {
      // Not supported on this platform (e.g. web)
    }
  }
}

/// Gets a real GPS fix via [LocationProvider], or the reason it failed.
Future<(Position?, LocationIssue?)> locateUser(BuildContext context) async {
  final loc = context.read<LocationProvider>();
  await loc.getCurrentLocation();
  final err = loc.error?.toLowerCase();
  if (err != null) {
    if (err.contains('disabled')) return (null, LocationIssue.serviceOff);
    if (err.contains('permanently')) return (null, LocationIssue.deniedForever);
    if (err.contains('denied')) return (null, LocationIssue.denied);
    return (null, LocationIssue.unavailable);
  }
  final pos = loc.currentPosition;
  if (pos == null || BusProvider.isFallbackPosition(pos)) return (null, LocationIssue.unavailable);
  return (pos, null);
}

// ── Widgets ─────────────────────────────────────────────────────────────────

/// Green gradient pill with a route number, e.g. "534".
class BusNumberBadge extends StatelessWidget {
  const BusNumberBadge(this.number, {super.key, this.large = false, this.onTap});

  final String number;
  final bool large;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      constraints: BoxConstraints(minWidth: large ? 52 : 40),
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 9, vertical: large ? 9 : 5),
      decoration: BoxDecoration(
        gradient: AppTheme.emeraldGradient,
        borderRadius: BorderRadius.circular(large ? 14 : 10),
        boxShadow: AppTheme.glow(busGreen, alpha: 0.22),
      ),
      child: Text(
        number,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(color: Colors.white, fontSize: large ? 15 : 12, fontWeight: FontWeight.w800),
      ),
    );
    if (onTap == null) return badge;
    return Semantics(
      button: true,
      label: 'Route $number',
      child: GestureDetector(onTap: onTap, child: badge),
    );
  }
}

/// Outlined, tinted route chip for dense lists of route numbers.
class BusNumberChip extends StatelessWidget {
  const BusNumberChip(this.number, {super.key, this.onTap});

  final String number;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.tint(busGreen),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: busGreen.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(number, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: busGreen)),
        ),
      ),
    );
  }
}

class BusInfoPill extends StatelessWidget {
  const BusInfoPill(this.icon, this.text, this.color, {super.key});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: p.tint(color), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small disclaimer that timetable times are estimates, not live data.
class ScheduledNote extends StatelessWidget {
  const ScheduledNote({super.key, this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: p.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text ?? 'Times are approximate, from the DTC/DIMTS timetable — not live tracking.',
            style: TextStyle(fontSize: 11.5, color: p.textTertiary, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class PinkTicketNote extends StatelessWidget {
  const PinkTicketNote({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: p.tint(pinkTicket), borderRadius: BorderRadius.circular(10)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.confirmation_number_rounded, size: 14, color: pinkTicket),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Women ride free (pink ticket)',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: pinkTicket),
            ),
          ),
        ],
      ),
    );
  }
}

class BusLoadingView extends StatelessWidget {
  const BusLoadingView({super.key, this.message = 'Loading Delhi bus network…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3, color: busGreen),
            ),
            const SizedBox(height: 14),
            Text(message, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Loading or error view for when [BusProvider] isn't ready yet.
class BusNetworkStatusView extends StatelessWidget {
  const BusNetworkStatusView({super.key, required this.bus});

  final BusProvider bus;

  @override
  Widget build(BuildContext context) {
    if (!bus.hasError) return const BusLoadingView();
    return EmptyState(
      title: 'Bus data didn\'t load',
      message: bus.error ?? 'Something went wrong.',
      action: GradientButton(
        label: 'Try again',
        icon: Icons.refresh_rounded,
        gradient: AppTheme.emeraldGradient,
        expand: false,
        onPressed: bus.ensureLoaded,
      ),
    );
  }
}

/// Vertical timeline row used for stop lists.
class BusStopTimelineRow extends StatelessWidget {
  const BusStopTimelineRow({
    super.key,
    required this.name,
    this.trailing,
    this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.highlight = false,
    this.color = busGreen,
    this.onTap,
  });

  final String name;
  final String? trailing;
  final String? subtitle;
  final bool isFirst;
  final bool isLast;
  final bool highlight;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dot = highlight ? 14.0 : 9.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Expanded(child: Container(width: 3, color: isFirst ? Colors.transparent : color.withValues(alpha: 0.35))),
                  Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: highlight ? color : p.card,
                      border: Border.all(color: color, width: highlight ? 3 : 2),
                    ),
                  ),
                  Expanded(child: Container(width: 3, color: isLast ? Colors.transparent : color.withValues(alpha: 0.35))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: highlight ? 14 : 13,
                        fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                        color: highlight ? p.textPrimary : p.textSecondary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Center(
                  child: Text(trailing!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.textTertiary)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Search-style text field used on the bus screens.
InputDecoration busFieldDecoration(
  BuildContext context, {
  String? label,
  required String hint,
  required IconData icon,
  Color iconColor = busGreen,
  Widget? suffix,
  EdgeInsetsGeometry? contentPadding,
}) {
  final p = context.palette;
  final radius = BorderRadius.circular(16);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: label == null ? null : FloatingLabelBehavior.always,
    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textTertiary),
    hintStyle: TextStyle(fontSize: 13, color: p.textTertiary),
    prefixIcon: Icon(icon, color: iconColor, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: p.cardAlt,
    contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(14, 14, 14, 14),
    border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.border)),
    enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.border)),
    focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: busGreen, width: 1.6)),
  );
}

/// One stop-name search result row: name + number of routes serving it.
class BusPlaceTile extends StatelessWidget {
  const BusPlaceTile({super.key, required this.place, required this.onTap, this.trailing});

  final BusPlace place;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bus = context.read<BusProvider>();
    final numbers = bus.routeNumbersAt(place);
    final preview = numbers.take(4).join(', ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Row(
          children: [
            const IconBubble(icon: Icons.place_rounded, color: busGreen, size: 36, radius: 11),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    numbers.isEmpty
                        ? 'Bus stop'
                        : '${numbers.length} route${numbers.length == 1 ? '' : 's'} · $preview${numbers.length > 4 ? '…' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}
