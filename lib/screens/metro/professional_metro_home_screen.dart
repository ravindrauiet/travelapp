import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/responsive_helper.dart';

class ProfessionalMetroHomeScreen extends StatefulWidget {
  const ProfessionalMetroHomeScreen({super.key});

  @override
  State<ProfessionalMetroHomeScreen> createState() =>
      _ProfessionalMetroHomeScreenState();
}

class _ProfessionalMetroHomeScreenState
    extends State<ProfessionalMetroHomeScreen> {

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        drawer: isTablet
            ? null
            : const AppDrawer(
                title: 'Delhi Metro',
                subtitle: 'Fast, Safe & Reliable',
              ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isTablet),
              const SizedBox(height: 22),
              _buildQuickActions(context),
              const SizedBox(height: 26),
              _buildMetroLines(context),
              const SizedBox(height: 26),
              _buildServices(context),
              const SizedBox(height: 26),
              _buildFareInfo(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return GradientHeader(
      title: 'Delhi Metro',
      subtitle: 'Fast, safe & eco-friendly rapid transit',
      icon: Icons.train_rounded,
      illustration: 'assets/images/illus_metro.svg',
      leading: isTablet
          ? null
          : Builder(
              builder: (ctx) => HeaderIconButton(
                icon: Icons.menu_rounded,
                tooltip: 'Navigation Menu',
                onTap: () => Scaffold.maybeOf(ctx)?.openDrawer(),
              ),
            ),
      actions: [
        HeaderIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Find Metro Route',
          onTap: () => context.push('/metro/route-finder'),
        ),
      ],
      bottom: Row(
        children: [
          _buildHeaderStat('Lines', '${AppConstants.metroLinesCount}', Icons.alt_route_rounded),
          const SizedBox(width: 10),
          _buildHeaderStat('Stations', '${AppConstants.metroStationsCount}', Icons.location_on_rounded),
          const SizedBox(width: 10),
          _buildHeaderStat('Network', '${AppConstants.metroNetworkLengthKm.toInt()} km', Icons.timeline_rounded),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFB547), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick actions', subtitle: 'Everything you need for your ride'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      'Route Finder',
                      'Fastest path',
                      Icons.directions_rounded,
                      AppTheme.accentColor,
                      () => context.push('/metro/route-finder'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      'Fare Calculator',
                      'Token & card',
                      Icons.calculate_rounded,
                      AppTheme.successColor,
                      () => context.push('/metro/fare-calculator'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      'Service Updates',
                      'Frequency & crowds',
                      Icons.update_rounded,
                      AppTheme.warningColor,
                      () => context.push('/metro/live-updates'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      'Metro Map',
                      'Official DMRC map',
                      Icons.map_rounded,
                      AppTheme.primaryColor,
                      () => context.push('/metro/map'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                gradient: AppTheme.oceanGradient,
                radius: 22,
                padding: const EdgeInsets.all(16),
                onTap: () => context.push('/metro/live-tracker'),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Station Proximity Tracker',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Get alerted before your stop arrives',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: icon, color: color, filled: true, size: 42, radius: 13),
              const Spacer(),
              Icon(Icons.north_east_rounded, size: 16, color: p.textTertiary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: p.textTertiary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Metro lines ───────────────────────────────────────────────────────────

  Widget _buildMetroLines(BuildContext context) {
    const lines = DelhiMetroNetwork.allLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Metro corridors',
          subtitle: '${lines.length} lines • Tap for stations',
        ),
        const SizedBox(height: 12),
        ...lines.map((line) => _lineCard(line, context)),
      ],
    );
  }

  Widget _lineCard(MetroLineDetails line, BuildContext context) {
    final p = context.palette;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: EdgeInsets.zero,
      radius: 20,
      onTap: () => _showLineDetailModal(context, line),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colour indicator bar
              Container(width: 5, color: line.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      IconBubble(icon: Icons.train_rounded, color: line.color, filled: true, size: 40, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              line.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              line.route,
                              style: TextStyle(fontSize: 11.5, color: p.textTertiary, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TagPill(label: '${line.stationCount} STN', color: line.color),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 20, color: p.textTertiary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLineDetailModal(BuildContext context, MetroLineDetails line) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [line.color, Color.lerp(line.color, AppTheme.brandNight, 0.45)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.glow(line.color, alpha: 0.3),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.train_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${line.stationCount} Stations • Typical Headway: ${line.typicalHeadway}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.82)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: p.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tap a station to plan a route there',
                          style: TextStyle(fontSize: 12, color: p.textTertiary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: line.stations.length,
                    itemBuilder: (context, idx) {
                      final station = line.stations[idx];
                      final isInterchange = line.interchanges.containsKey(station);
                      final interchangeLines = line.interchanges[station];
                      final isFirst = idx == 0;
                      final isLast = idx == line.stations.length - 1;
                      final isEnd = isFirst || isLast;
                      final dotSize = isEnd ? 16.0 : (isInterchange ? 14.0 : 10.0);

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(ctx);
                          final resolved = AppConstants.resolveToMetroStation(station);
                          context.push('/metro/route-finder?to=${Uri.encodeComponent(resolved)}');
                        },
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 28,
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Positioned(
                                      top: isFirst ? 14 : 0,
                                      bottom: isLast ? null : 0,
                                      height: isLast ? 14 : null,
                                      child: Container(width: 4, color: line.color.withValues(alpha: 0.55)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 14 - dotSize / 2),
                                      child: Container(
                                        width: dotSize,
                                        height: dotSize,
                                        decoration: BoxDecoration(
                                          color: isEnd
                                              ? line.color
                                              : (isInterchange ? AppTheme.warningColor : p.surface),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isEnd || isInterchange ? p.surface : line.color,
                                            width: isEnd || isInterchange ? 3 : 2.5,
                                          ),
                                          boxShadow: isEnd || isInterchange
                                              ? AppTheme.glow(isEnd ? line.color : AppTheme.warningColor, alpha: 0.35)
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        child: Row(
                                          children: [
                                            Text(
                                              '${idx + 1}. ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: p.textTertiary,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                station,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isEnd || isInterchange ? FontWeight.w800 : FontWeight.w600,
                                                  color: isEnd || isInterchange ? p.textPrimary : p.textSecondary,
                                                ),
                                              ),
                                            ),
                                            if (isEnd)
                                              TagPill(label: isFirst ? 'START' : 'TERMINAL', color: line.color),
                                          ],
                                        ),
                                      ),
                                      if (isInterchange && interchangeLines != null) ...[
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: interchangeLines
                                              .map((il) => TagPill(
                                                    label: 'Interchange: $il',
                                                    color: AppTheme.warningColor,
                                                    icon: Icons.swap_horiz_rounded,
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Amenities ─────────────────────────────────────────────────────────────

  Widget _buildServices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Station amenities', subtitle: 'Tap a card for the details'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _serviceCard(
                  'Smart Card',
                  '10% Ride Off',
                  Icons.credit_card_rounded,
                  AppTheme.primaryColor,
                  () => _showInfoSheet(
                    context,
                    'DMRC Smart Card Benefits',
                    Icons.credit_card_rounded,
                    AppTheme.primaryColor,
                    '• Flat 10% discount on every metro journey\n'
                        '• Extra 10% off in off-peak hours: before 8 AM, 12–5 PM and after 9 PM\n'
                        '• Minimum purchase & recharge: ₹100\n'
                        '• Valid on all DMRC lines incl. Airport Express (separate AEL fare)\n'
                        '• Top up online via DMRC Momentum 2.0 app or station TVMs',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _serviceCard(
                  'Parking',
                  'Station Lots',
                  Icons.local_parking_rounded,
                  AppTheme.successColor,
                  () => _showInfoSheet(
                    context,
                    'Metro Station Parking',
                    Icons.local_parking_rounded,
                    AppTheme.successColor,
                    '• Available at 100+ major DMRC stations\n'
                        '• 2-Wheeler: typically ₹10–₹25 per day\n'
                        '• 4-Wheeler: typically ₹30–₹60 per day (varies by station)\n'
                        '• Overnight parking available at designated stations\n'
                        '• Fastag payment supported at major interchange hubs',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _serviceCard(
                  'Wi-Fi',
                  'High Speed',
                  Icons.wifi_rounded,
                  AppTheme.brandViolet,
                  () => _showInfoSheet(
                    context,
                    'Free Metro Wi-Fi',
                    Icons.wifi_rounded,
                    AppTheme.brandViolet,
                    '• Available at all Airport Express Line stations & trains\n'
                        '• Select interchange stations offer "Free Wi-Fi DMRC"\n'
                        '• OTP authentication required for Indian mobile numbers',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _serviceCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        children: [
          IconBubble(icon: icon, color: color, size: 42, radius: 13),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Fares ─────────────────────────────────────────────────────────────────

  Widget _buildFareInfo(BuildContext context) {
    final p = context.palette;
    const slabs = [
      ('0–2 km', 11),
      ('2–5 km', 21),
      ('5–12 km', 32),
      ('12–21 km', 43),
      ('21–32 km', 54),
      ('32+ km', 64),
    ];
    const slabColors = [
      AppTheme.successColor,
      AppTheme.metroAqua,
      AppTheme.primaryColor,
      AppTheme.brandViolet,
      AppTheme.metroPink,
      AppTheme.accentColor,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Standard fare slabs',
          subtitle: 'Distance-based DMRC token fares',
          actionLabel: 'Calculator',
          onAction: () => context.push('/metro/fare-calculator'),
        ),
        const SizedBox(height: 12),
        AppCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          radius: 24,
          padding: const EdgeInsets.all(16),
          onTap: () => context.push('/metro/fare-calculator'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _fareChip('Minimum', '₹${AppConstants.metroMinFare}', AppTheme.successColor),
                  const SizedBox(width: 8),
                  _fareChip('Maximum', '₹${AppConstants.metroMaxFare}', AppTheme.accentColor),
                  const SizedBox(width: 8),
                  _fareChip('Smart Card', '10% Off', AppTheme.primaryColor),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < slabs.length; i++)
                _fareRow(slabs[i].$1, slabs[i].$2, slabColors[i]),
              const SizedBox(height: 4),
              Divider(height: 20, color: p.border),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: p.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tap to calculate the exact fare between two stations',
                      style: TextStyle(fontSize: 11.5, color: p.textTertiary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fareChip(String label, String value, Color color) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: p.tint(color),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: p.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fareRow(String distance, int fare, Color color) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              distance,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textSecondary),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 8, color: p.tint(color)),
                  FractionallySizedBox(
                    widthFactor: fare / 64,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '₹$fare',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String body,
  ) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  IconBubble(icon: icon, color: color, filled: true, size: 44, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close_rounded, color: p.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.tint(color),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  body,
                  style: TextStyle(fontSize: 13, height: 1.7, color: p.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
