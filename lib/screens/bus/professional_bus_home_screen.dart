import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/responsive_helper.dart';

class ProfessionalBusHomeScreen extends StatefulWidget {
  const ProfessionalBusHomeScreen({super.key});

  @override
  State<ProfessionalBusHomeScreen> createState() =>
      _ProfessionalBusHomeScreenState();
}

class _ProfessionalBusHomeScreenState extends State<ProfessionalBusHomeScreen> {
  static const _popularRoutes = [
    _BusRoute('Connaught Place', 'India Gate', '505', '~12 min'),
    _BusRoute('Rajiv Chowk', 'Karol Bagh', '522', '~18 min'),
    _BusRoute('Lajpat Nagar', 'South Extension', '534', '~10 min'),
    _BusRoute('AIIMS', 'Saket', '544', '~15 min'),
    _BusRoute('Nehru Place', 'Noida Sec-15', '543', '~25 min'),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      drawer: isTablet
          ? null
          : const AppDrawer(
              title: 'Delhi Bus',
              subtitle: 'Affordable & Convenient',
            ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildBusTypes(context),
            const SizedBox(height: 20),
            _buildPopularRoutes(context),
            const SizedBox(height: 20),
            _buildFareInfo(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
              color: AppTheme.metroGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Delhi Bus',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          tooltip: 'Find Bus Route',
          onPressed: () => context.push('/bus/route-finder'),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.metroGreen, AppTheme.metroGreen.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.metroGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delhi Bus Services',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'DTC · Cluster · Electric',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat('Routes', '650+', Icons.route),
              const SizedBox(width: 20),
              _headerStat('Buses', '6,500+', Icons.directions_bus),
              const SizedBox(width: 20),
              _headerStat('Daily', '4.2M', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard('Find Route', Icons.directions,
                    AppTheme.metroBlue, () => context.push('/bus/route-finder')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard('Live Tracking', Icons.location_on,
                    AppTheme.metroGreen, () => context.push('/bus/realtime')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard('Bus Stops', Icons.place,
                    AppTheme.metroOrange, () => context.push('/bus/stop-locator')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard('Bus Map', Icons.map,
                    AppTheme.metroRed, () => context.push('/bus/map')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBusTypes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bus Types',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _busTypeCard('DTC', 'Delhi Transport Corporation',
                    Icons.directions_bus, AppTheme.metroBlue,
                    () => _showBusTypeInfo(context, 'DTC Buses',
                        'Delhi Transport Corporation is the primary public bus operator in Delhi.\n\n'
                        '• Fleet: 3,500+ buses\n'
                        '• Routes: 400+\n'
                        '• Low-floor buses for accessibility\n'
                        '• Passes available monthly & quarterly\n'
                        '• Fare: ₹5 to ₹25 based on distance')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _busTypeCard('Cluster', 'Cluster Bus Services',
                    Icons.directions_bus_filled, AppTheme.metroGreen,
                    () => _showBusTypeInfo(context, 'Cluster Buses',
                        'Cluster buses are operated by private companies under Delhi government.\n\n'
                        '• Fleet: 3,000+ buses\n'
                        '• Complements DTC routes\n'
                        '• Air conditioned options available\n'
                        '• Electronic ticketing system\n'
                        '• Fare: ₹5 to ₹25')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _busTypeCard('AC Bus', 'Air Conditioned', Icons.ac_unit,
                    AppTheme.metroOrange,
                    () => _showBusTypeInfo(context, 'AC Buses',
                        'Air conditioned buses for a comfortable journey.\n\n'
                        '• Comfortable seating\n'
                        '• GPS tracked\n'
                        '• Electronic display inside\n'
                        '• Available on major routes\n'
                        '• Fare: ₹10 to ₹50')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _busTypeCard('Electric', 'Zero Emission Bus',
                    Icons.electric_car, AppTheme.metroRed,
                    () => _showBusTypeInfo(context, 'Electric Buses',
                        'Delhi\'s green initiative — 100% electric fleet.\n\n'
                        '• Zero emissions\n'
                        '• 300+ e-buses operational\n'
                        '• Quieter & smoother ride\n'
                        '• Same fare as regular DTC\n'
                        '• Expanding across all routes')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _busTypeCard(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            Text(subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRoutes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Popular Routes',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/bus/route-finder'),
                child: const Text('See all →',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.metroGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._popularRoutes.map((r) => _routeCard(r, context)),
        ],
      ),
    );
  }

  Widget _routeCard(_BusRoute route, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/bus/route-finder'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.metroGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  route.number,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.metroGreen),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${route.from} → ${route.to}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('Route ${route.number} · ${route.time}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildFareInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fare Information',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              children: [
                _fareChip('Regular', '₹5–25', Colors.green),
                const SizedBox(width: 20),
                _fareChip('AC Bus', '₹10–50', Colors.blue),
                const SizedBox(width: 20),
                _fareChip('Electric', '₹5–25', AppTheme.metroGreen),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _infoRow(Icons.info_outline, 'Day pass: ₹50 (unlimited travel)', Colors.blue),
            const SizedBox(height: 6),
            _infoRow(Icons.people, 'Women & seniors: concessional fares', Colors.purple),
            const SizedBox(height: 6),
            _infoRow(Icons.school, 'Student pass: ₹200/month', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _fareChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ),
      ],
    );
  }

  void _showBusTypeInfo(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.metroGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.directions_bus,
                      color: AppTheme.metroGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(body,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black87, height: 1.6)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BusRoute {
  final String from;
  final String to;
  final String number;
  final String time;
  const _BusRoute(this.from, this.to, this.number, this.time);
}
