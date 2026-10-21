import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/responsive_helper.dart';

class ProfessionalTransportHomeScreen extends StatefulWidget {
  const ProfessionalTransportHomeScreen({super.key});

  @override
  State<ProfessionalTransportHomeScreen> createState() =>
      _ProfessionalTransportHomeScreenState();
}

class _ProfessionalTransportHomeScreenState
    extends State<ProfessionalTransportHomeScreen> {
  static const LinearGradient _autoGradient = LinearGradient(
    colors: [Color(0xFF9A3412), Color(0xFFEA580C), AppTheme.brandSaffron],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color _saffron = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final p = context.palette;
    final isDark = context.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        drawer: isTablet
            ? null
            : const AppDrawer(
                title: 'Other Transport',
                subtitle: 'Auto, Cabs & Last-Mile',
              ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark),
              const SizedBox(height: 16),
              _buildQuickStats(),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Modes of transport',
                subtitle: 'Tap a mode for fares, tips & providers',
              ),
              const SizedBox(height: 12),
              _buildTransportTypes(isDark),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Trusted providers',
                subtitle: 'Official meters & popular ride apps',
              ),
              const SizedBox(height: 12),
              _buildPopularServices(isDark),
              const SizedBox(height: 26),
              _buildFareInfo(isDark),
              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    return GradientHeader(
      title: 'Delhi NCR Transport',
      subtitle: 'Last-mile autos, app cabs & bike taxis',
      gradient: _autoGradient,
      illustration: 'assets/images/illus_auto.svg',
      leading: Builder(
        builder: (ctx) => HeaderIconButton(
          tooltip: 'Navigation Menu',
          icon: Icons.menu_rounded,
          onTap: () => Scaffold.maybeOf(ctx)?.openDrawer(),
        ),
      ),
      actions: [
        HeaderIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Search transport options',
          onTap: () {
            showSearch(
              context: context,
              delegate: _TransportSearchDelegate(isDark),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: StatTile(
              value: '1 Lakh+',
              label: 'Auto Rickshaws',
              icon: Icons.electric_rickshaw_rounded,
              color: _saffron,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: StatTile(
              value: '1.5 Lakh+',
              label: 'App Cabs',
              icon: Icons.local_taxi_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: StatTile(
              value: 'Active',
              label: 'E-Bikes / Taxis',
              icon: Icons.electric_bike_rounded,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Modes grid ───────────────────────────────────────────────────────────

  Widget _buildTransportTypes(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTransportCard(
                  'Auto Rickshaw',
                  'Metered CNG 3-wheeler',
                  '₹30 base + ₹11/km',
                  Icons.electric_rickshaw_rounded,
                  _saffron,
                  () => _showAutoOptions(context, isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTransportCard(
                  'Cab Services',
                  'Uber, Ola, InDrive',
                  '₹12–₹18/km',
                  Icons.local_taxi_rounded,
                  AppTheme.primaryColor,
                  () => _showCabOptions(context, isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTransportCard(
                  'Bike Taxis',
                  'Rapido & Uber Moto',
                  '₹5–₹8/km',
                  Icons.two_wheeler_rounded,
                  AppTheme.successColor,
                  () => _showBikeTaxiOptions(context, isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTransportCard(
                  'Yulu EV Micro',
                  'Station-based Miracle',
                  '₹2.5/min',
                  Icons.electric_bike_rounded,
                  AppTheme.infoColor,
                  () => _showYuluOptions(context, isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(
    String title,
    String subtitle,
    String price,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      radius: 22,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Soft colour wash in the corner
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: p.isDark ? 0.16 : 0.09),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBubble(icon: icon, color: color, size: 46, filled: true),
                      const Spacer(),
                      Icon(Icons.arrow_outward_rounded, size: 18, color: p.textTertiary),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.tint(color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Providers ────────────────────────────────────────────────────────────

  Widget _buildPopularServices(bool isDark) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildServiceCard(
            'Delhi Auto Rickshaw (Meter)',
            'Official Delhi Transport Dept notified fare meter',
            '₹30 base (1.5 km), ₹11/km after',
            'Flag down anywhere · Pay by Cash / UPI',
            Icons.electric_rickshaw_rounded,
            _saffron,
          ),
          _buildServiceCard(
            'Uber India',
            'Uber Auto, Premier & Go Sedan',
            'App-based fare with upfront estimate',
            '24/7 Available across Delhi NCR',
            Icons.local_taxi_rounded,
            p.textPrimary,
          ),
          _buildServiceCard(
            'Rapido (Bike Taxi & Auto)',
            'Fastest commute through Delhi peak traffic',
            '₹25 base + ₹5/km',
            'App booking · Helmet provided',
            Icons.two_wheeler_rounded,
            const Color(0xFFEAB308),
          ),
          _buildServiceCard(
            'Yulu Miracle (Metro EV)',
            'Low-speed green EV docked at metro stations',
            '₹10 unlock + ₹2.5/min',
            'Yulu Zone pickup · No driving license required',
            Icons.electric_bike_rounded,
            AppTheme.infoColor,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    String title,
    String description,
    String price,
    String availability,
    IconData icon,
    Color color,
  ) {
    return _OptionCard(
      title: title,
      description: description,
      price: price,
      availability: availability,
      icon: icon,
      color: color,
      margin: const EdgeInsets.only(bottom: 10),
    );
  }

  // ── Fare chart ───────────────────────────────────────────────────────────

  Widget _buildFareInfo(bool isDark) {
    final p = context.palette;
    const rows = [
      ('Base Fare', '₹30 for first 1.5 km', 'Meter down', Icons.flag_rounded),
      ('Subsequent Distance', '₹11 per km', 'Every 100 meters = ₹1.10', Icons.straighten_rounded),
      ('Night Charges (23:00 - 05:00)', '+25% on meter', 'Legally applicable', Icons.nightlight_round),
      ('Waiting Charges', '₹0.75 / minute', 'Free for first 15 mins', Icons.hourglass_bottom_rounded),
      ('Luggage Charges', '₹7.50 / piece', 'Small bags/briefcases free', Icons.luggage_rounded),
    ];

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.zero,
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: const BoxDecoration(
              gradient: _autoGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notified Auto Meter Rates',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        'Delhi Govt · Transport Department',
                        style: TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  _buildFareRow(rows[i].$1, rows[i].$2, rows[i].$3, rows[i].$4),
                  if (i != rows.length - 1) Divider(height: 1, color: p.border),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String title, String fare, String note, IconData icon) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconBubble(icon: icon, color: _saffron, size: 36, radius: 11),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
                ),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fare,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _saffron),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheets ────────────────────────────────────────────────────────

  void _showAutoOptions(BuildContext context, bool isDark) {
    _showTransportModal(context, 'Delhi Auto Rickshaw Guidelines', [
      {
        'title': 'Meter Fare Mandate',
        'description': 'By law, auto drivers in Delhi must go by meter. Complaint helpline: 1095 / 011-25844444.',
        'price': '₹30 base / ₹11 km',
        'availability': 'Enforced by Delhi Traffic Police',
        'icon': Icons.electric_rickshaw_rounded,
        'color': _saffron,
      },
      {
        'title': 'Prepaid Auto Booths',
        'description': 'Available at New Delhi Railway Station, Old Delhi Station, Nizamuddin & ISBTs.',
        'price': 'Fixed Receipt Fare',
        'availability': 'Official Traffic Police Booth',
        'icon': Icons.confirmation_number_rounded,
        'color': AppTheme.successColor,
      },
    ], isDark);
  }

  void _showCabOptions(BuildContext context, bool isDark) {
    _showTransportModal(context, 'Delhi NCR Cab Services', [
      {
        'title': 'Uber India',
        'description': 'Uber Go, Auto, Moto & Premier across Delhi, Gurugram, Noida, Ghaziabad.',
        'price': 'Upfront pricing',
        'availability': 'Instant app dispatch',
        'icon': Icons.local_taxi_rounded,
        'color': context.palette.textPrimary,
      },
      {
        'title': 'Ola Cabs',
        'description': 'Ola Auto, Mini & Prime. Available 24x7 with OTP safety.',
        'price': 'Meter & dynamic',
        'availability': 'App-based',
        'icon': Icons.local_taxi_rounded,
        'color': AppTheme.warningColor,
      },
      {
        'title': 'InDrive',
        'description': 'Peer-to-peer fare negotiation cab platform.',
        'price': 'User negotiated',
        'availability': 'Popular for longer intercity trips',
        'icon': Icons.handshake_rounded,
        'color': AppTheme.successColor,
      },
    ], isDark);
  }

  void _showBikeTaxiOptions(BuildContext context, bool isDark) {
    _showTransportModal(context, 'Bike Taxi Options', [
      {
        'title': 'Rapido Bike Taxi',
        'description': 'Single passenger motorcycle pillion ride. Fast and low-cost.',
        'price': '₹25 base + ₹5/km',
        'availability': 'App booking · Helmet provided',
        'icon': Icons.two_wheeler_rounded,
        'color': const Color(0xFFEAB308),
      },
      {
        'title': 'Uber Moto',
        'description': 'Two-wheeler hailing inside the standard Uber app.',
        'price': '₹20 base + ₹6/km',
        'availability': 'Available across NCR',
        'icon': Icons.motorcycle_rounded,
        'color': context.palette.textPrimary,
      },
    ], isDark);
  }

  void _showYuluOptions(BuildContext context, bool isDark) {
    _showTransportModal(context, 'Yulu Micro-Mobility EV', [
      {
        'title': 'Yulu Miracle',
        'description': 'Speed capped at 25 km/h. Great for 1–3 km metro station to home/office rides.',
        'price': '₹10 unlock + ₹2.5/min',
        'availability': 'Docked at 150+ metro stations',
        'icon': Icons.electric_bike_rounded,
        'color': AppTheme.infoColor,
      },
    ], isDark);
  }

  void _showTransportModal(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> options,
    bool isDark,
  ) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const IconBubble(icon: Icons.info_rounded, color: _saffron, size: 40, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: options
                      .map((option) => _OptionCard(
                            title: option['title'] as String,
                            description: option['description'] as String,
                            price: option['price'] as String,
                            availability: option['availability'] as String,
                            icon: option['icon'] as IconData,
                            color: option['color'] as Color,
                            background: p.cardAlt,
                            margin: const EdgeInsets.only(bottom: 12),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider / option card shared by the providers list and the bottom sheets.
class _OptionCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String availability;
  final IconData icon;
  final Color color;
  final Color? background;
  final EdgeInsetsGeometry? margin;

  const _OptionCard({
    required this.title,
    required this.description,
    required this.price,
    required this.availability,
    required this.icon,
    required this.color,
    this.background,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      margin: margin,
      color: background,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: icon, color: color, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.tint(color),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        price,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 13, color: p.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            availability,
                            style: TextStyle(fontSize: 11, color: p.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportSearchDelegate extends SearchDelegate<String> {
  final bool isDark;

  _TransportSearchDelegate(this.isDark);

  static const _suggestions = [
    'Auto Rickshaw (Meter)',
    'Uber Auto',
    'Uber Premier',
    'Ola Auto',
    'Rapido Bike Taxi',
    'Yulu Miracle EV',
    'InDrive Cabs',
    'Prepaid Auto Booth',
  ];

  @override
  String get searchFieldLabel => 'Search transport mode…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final p = context.palette;
    final lower = query.toLowerCase();
    final filtered = _suggestions
        .where((s) => s.toLowerCase().contains(lower))
        .toList();

    if (filtered.isEmpty) {
      return Container(
        color: p.background,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: EmptyState(
            title: 'No matching options',
            message: 'No options matching "$query". Try "auto", "cab" or "bike".',
          ),
        ),
      );
    }

    return Container(
      color: p.background,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => close(ctx, filtered[i]),
          child: Row(
            children: [
              const IconBubble(
                icon: Icons.directions_car_filled_rounded,
                color: Color(0xFFEA580C),
                size: 40,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  filtered[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
              Icon(Icons.north_west_rounded, size: 18, color: p.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
