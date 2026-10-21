import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../services/accurate_fare_calculator.dart';
import '../../widgets/ui_kit.dart';

class MetroLiveUpdatesScreen extends StatefulWidget {
  final String? initialStation;

  const MetroLiveUpdatesScreen({super.key, this.initialStation});

  @override
  State<MetroLiveUpdatesScreen> createState() => _MetroLiveUpdatesScreenState();
}

class _MetroLiveUpdatesScreenState extends State<MetroLiveUpdatesScreen>
    with TickerProviderStateMixin {
  String _selectedStation = '';
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Major authentic Delhi Metro Stations (no non-stations like "Connaught Place")
  static const List<String> _popularStations = [
    'Rajiv Chowk',
    'Kashmere Gate',
    'Central Secretariat',
    'New Delhi',
    'Hauz Khas',
    'Botanical Garden',
    'Janakpuri West',
    'Lajpat Nagar',
    'Mandi House',
    'Karol Bagh',
    'Dilli Haat - INA',
    'Chandni Chowk',
    'Saket',
    'Dwarka Sector 21',
    'Noida Sector 18',
    'IGI Airport',
    'Netaji Subhash Place',
    'Welcome',
    'Anand Vihar ISBT',
    'Millennium City Centre Gurugram',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.initialStation ?? '';
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
      context.read<MetroProvider>().loadLiveUpdates();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _refreshData() async {
    setState(() => _isRefreshing = true);
    _refreshController.forward().then((_) => _refreshController.reset());
    await context.read<MetroProvider>().loadLiveUpdates();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final metroProvider = context.watch<MetroProvider>();

    // Build merged station list from GTFS provider + popular stations
    final allStationNames = <String>{..._popularStations};
    for (final s in metroProvider.stations) {
      allStationNames.add(s.name);
    }
    final sortedStations = allStationNames.toList()..sort();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildStationSelector(sortedStations),
              _buildTrainTimings(),
              if (_selectedStation.isNotEmpty) _buildPlatformInfo(),
              _buildCrowdDensity(),
              _buildEmergencyInfo(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header with live advisory ─────────────────────────────────────────────

  Widget _buildHeader() {
    return GradientHeader(
      title: 'Service Updates',
      subtitle: 'Typical frequencies, timings & crowds',
      icon: Icons.update_rounded,
      gradient: AppTheme.transitGradient,
      illustration: 'assets/images/illus_metro.svg',
      actions: [
        Tooltip(
          message: 'Refresh',
          child: Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isRefreshing ? null : _refreshData,
              child: SizedBox(
                width: 42,
                height: 42,
                child: AnimatedBuilder(
                  animation: _refreshController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _refreshController.value * 2 * 3.14159,
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: _buildAdvisoryBanner(),
    );
  }

  Widget _buildAdvisoryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.infoColor,
              shape: BoxShape.circle,
              boxShadow: AppTheme.glow(AppTheme.infoColor, alpha: 0.5),
            ),
            child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Typical service information',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  'No live DMRC feed in the app. For disruptions call ${AppConstants.dmrcMetroHelpline} or check DMRC on X (@OfficialDMRC).',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared section card ───────────────────────────────────────────────────

  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    Widget? trailing,
    required List<Widget> children,
  }) {
    final p = context.palette;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: icon, color: color, size: 38, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: p.textTertiary, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStationSelector(List<String> stations) {
    final p = context.palette;
    return _sectionCard(
      icon: Icons.location_on_rounded,
      color: AppTheme.primaryColor,
      title: 'Select metro station',
      subtitle: 'See lines, typical frequency & facilities',
      trailing: _selectedStation.isNotEmpty
          ? TextButton(
              onPressed: () => setState(() => _selectedStation = ''),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Clear', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            )
          : null,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedStation.isEmpty ? null : _selectedStation,
          isExpanded: true,
          dropdownColor: p.card,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.textSecondary),
          decoration: InputDecoration(
            hintText: 'Choose a station',
            hintStyle: TextStyle(fontSize: 13.5, color: p.textTertiary),
            prefixIcon: Icon(Icons.train_rounded, size: 20, color: p.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: p.cardAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: p.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: p.border.withValues(alpha: 0.8)),
            ),
          ),
          items: stations.map((station) {
            return DropdownMenuItem(
              value: station,
              child: Text(
                station,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textPrimary),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStation = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildTrainTimings() {
    final p = context.palette;
    if (_selectedStation.isEmpty) {
      return AppCard(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Column(
            children: [
              IconBubble(icon: Icons.touch_app_rounded, color: p.primary, size: 54, radius: 18),
              const SizedBox(height: 12),
              Text(
                'Pick a station to begin',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a station above to see its lines, directions and typical train frequency',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Compute authentic departures for the selected station
    final departures = _getDeparturesForStation(_selectedStation);

    return _sectionCard(
      icon: Icons.schedule_rounded,
      color: AppTheme.accentColor,
      title: 'Trains from this station',
      subtitle: '$_selectedStation · typical frequency, not live',
      trailing: const TagPill(label: 'TYPICAL', color: AppTheme.infoColor, icon: Icons.schedule_rounded),
      children: departures.map((d) => _buildTrainTimingRow(d)).toList(),
    );
  }

  List<_PlatformDeparture> _getDeparturesForStation(String station) {
    // Lines serving this station: the curated line lists first, then the GTFS
    // station data (covers spelling differences).
    final lower = station.toLowerCase();
    final lines = DelhiMetroNetwork.allLines
        .where((l) => l.stations.any((s) => s.toLowerCase() == lower))
        .toList();
    if (lines.isEmpty) {
      final gtfs = context.read<MetroProvider>().stations.where((s) => s.name.toLowerCase() == lower);
      final names = gtfs.isEmpty ? const <String>[] : gtfs.first.interchangeLines;
      lines.addAll(DelhiMetroNetwork.allLines.where((l) => names.contains(l.name)));
    }

    final departures = <_PlatformDeparture>[];
    for (final line in lines) {
      final firstTerminal = line.stations.first;
      final lastTerminal = line.stations.last;
      final freq = 'Every ${line.typicalHeadway}';
      final hours = 'Runs ${line.operatingHours}';

      if (lower != lastTerminal.toLowerCase()) {
        departures.add(_PlatformDeparture(
          line: line.name,
          destination: 'Towards $lastTerminal',
          time: freq,
          platform: hours,
          color: line.color,
        ));
      }
      if (lower != firstTerminal.toLowerCase()) {
        departures.add(_PlatformDeparture(
          line: line.name,
          destination: 'Towards $firstTerminal',
          time: freq,
          platform: hours,
          color: line.color,
        ));
      }
    }

    return departures;
  }


  Widget _buildTrainTimingRow(_PlatformDeparture d) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: d.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          IconBubble(icon: Icons.directions_subway_rounded, color: d.color, filled: true, size: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.destination,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: d.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.tint(p.textTertiary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d.platform,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              gradient: AppTheme.emeraldGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.glow(AppTheme.successColor, alpha: 0.25),
            ),
            child: Text(
              d.time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformInfo() {
    return _sectionCard(
      icon: Icons.info_outline_rounded,
      color: AppTheme.successColor,
      title: 'Station facilities',
      subtitle: 'Typical at DMRC stations — check signage on site',
      children: [
        _buildInfoRow('Lifts & Escalators', 'At most stations', Icons.elevator_rounded, AppTheme.primaryColor),
        _buildInfoRow('Wheelchair Assistance', 'Ask Customer Care', Icons.accessible_rounded, AppTheme.infoColor),
        _buildInfoRow('Smart Card / QR Tickets', 'Counter, TVM & DMRC app', Icons.credit_card_rounded, AppTheme.brandViolet),
        _buildInfoRow('ATM', 'At many stations', Icons.local_atm_rounded, AppTheme.warningColor),
        _buildInfoRow('Public Restrooms', 'At most stations', Icons.wc_rounded, AppTheme.metroPink),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          IconBubble(icon: icon, color: color, size: 32, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdDensity() {
    // Same peak/off-peak bands DMRC uses for the Smart Card off-peak discount.
    final isPeak = !AccurateFareCalculator.isOffPeakHour(DateTime.now());

    return _sectionCard(
      icon: Icons.people_alt_rounded,
      color: AppTheme.accentColor,
      title: 'Typical crowd patterns',
      subtitle: 'Plan around the rush',
      trailing: TagPill(
        label: isPeak ? 'PEAK NOW' : 'LIGHT NOW',
        color: isPeak ? AppTheme.errorColor : AppTheme.successColor,
      ),
      children: [
        _buildCrowdRow('08:00 AM – 12:00 PM', 'Peak morning commute', 'High', AppTheme.errorColor, 0.9),
        _buildCrowdRow('12:00 PM – 05:00 PM', 'Off-peak (Smart Card 20% off)', 'Light', AppTheme.successColor, 0.35),
        _buildCrowdRow('05:00 PM – 09:00 PM', 'Evening rush hour', 'High', AppTheme.errorColor, 0.95),
        _buildCrowdRow('After 09:00 PM', 'Off-peak (Smart Card 20% off)', 'Light', AppTheme.successColor, 0.3),
      ],
    );
  }

  Widget _buildCrowdRow(String timeRange, String description, String level, Color color, double load) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(timeRange,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.textPrimary)),
                    Text(description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: p.textTertiary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              TagPill(label: level.toUpperCase(), color: color),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: load,
              minHeight: 6,
              backgroundColor: p.tint(color),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInfo() {
    return _sectionCard(
      icon: Icons.shield_rounded,
      color: AppTheme.errorColor,
      title: 'Transit helplines',
      subtitle: 'Available 24/7',
      children: [
        _buildHelplineRow('National Emergency Helpline', AppConstants.nationalEmergencyNumber, Icons.emergency_rounded),
        _buildHelplineRow('Delhi Metro 24/7 Helpline', AppConstants.dmrcMetroHelpline, Icons.train_rounded),
        _buildHelplineRow('Delhi Women Helpline', AppConstants.delhiWomenHelpline, Icons.female_rounded),
      ],
    );
  }

  Widget _buildHelplineRow(String label, String number, IconData icon) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.tint(AppTheme.errorColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.errorColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Text(number,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.errorColor)),
        ],
      ),
    );
  }
}


class _PlatformDeparture {
  final String line;
  final String destination;
  final String time;
  final String platform;
  final Color color;

  const _PlatformDeparture({
    required this.line,
    required this.destination,
    required this.time,
    required this.platform,
    required this.color,
  });
}
