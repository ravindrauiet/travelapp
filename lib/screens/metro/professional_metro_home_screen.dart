import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/responsive_helper.dart';

class ProfessionalMetroHomeScreen extends StatefulWidget {
  const ProfessionalMetroHomeScreen({super.key});

  @override
  State<ProfessionalMetroHomeScreen> createState() =>
      _ProfessionalMetroHomeScreenState();
}

class _ProfessionalMetroHomeScreenState
    extends State<ProfessionalMetroHomeScreen> {
  // All Delhi Metro lines with accurate data
  static const _lines = [
    _MetroLine('Red Line',      Color(0xFFE53935), 'Rithala – New Bus Adda',               '29'),
    _MetroLine('Yellow Line',   Color(0xFFFDD835), 'Samaypur Badli – HUDA City Centre',    '37'),
    _MetroLine('Blue Line',     Color(0xFF1E88E5), 'Dwarka Sec 21 – Vaishali / Noida',     '52'),
    _MetroLine('Green Line',    Color(0xFF43A047), 'Inderlok – Brigadier Hoshiyar Singh',  '24'),
    _MetroLine('Violet Line',   Color(0xFF8E24AA), 'Kashmere Gate – Raja Nahar Singh',     '34'),
    _MetroLine('Pink Line',     Color(0xFFE91E63), 'Majlis Park – Shiv Vihar',             '38'),
    _MetroLine('Magenta Line',  Color(0xFF6A1B9A), 'Janakpuri West – Botanical Garden',    '25'),
    _MetroLine('Orange Line',   Color(0xFFFF6F00), 'New Delhi – Dwarka Sec 21 (Airport)',  '6' ),
    _MetroLine('Aqua Line',     Color(0xFF00ACC1), 'Noida Sector 51 – Depot Station',      '21'),
    _MetroLine('Grey Line',     Color(0xFF757575), 'Dwarka – Najafgarh',                   '3' ),
    _MetroLine('Rapid Metro',   Color(0xFF0097A7), 'Sector 55-56 – Sector 53-54',          '6' ),
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
              title: 'Delhi Metro',
              subtitle: 'Fast, Safe & Reliable',
            ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildMetroLines(context),
            const SizedBox(height: 20),
            _buildServices(context),
            const SizedBox(height: 20),
            _buildFareInfo(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
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
              color: AppTheme.metroBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.train, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Delhi Metro',
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
          tooltip: 'Find Route',
          onPressed: () => context.push('/metro/route-finder'),
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
          colors: [AppTheme.metroBlue, AppTheme.metroBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.metroBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delhi Metro Rail',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fast, Safe & Reliable',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderStat('Lines', '${_lines.length}', Icons.train),
              const SizedBox(width: 20),
              _buildHeaderStat('Stations', '262', Icons.location_on),
              const SizedBox(width: 20),
              _buildHeaderStat('Daily', '2.8M', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard('Find Route', Icons.directions,
                    AppTheme.metroBlue, () => context.push('/metro/route-finder')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard('Fare Calculator', Icons.calculate,
                    AppTheme.metroGreen,
                    () => context.push('/metro/fare-calculator')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard('Live Updates', Icons.update,
                    AppTheme.metroOrange,
                    () => context.push('/metro/live-updates')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard('Metro Map', Icons.map, AppTheme.metroRed,
                    () => context.push('/metro/pdf-viewer')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => context.push('/metro/live-tracker'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.metroBlue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.my_location, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Live Station Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMetroLines(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Metro Lines',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const Spacer(),
              Text('${_lines.length} lines',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          ..._lines.map((line) => _lineCard(line, context)),
        ],
      ),
    );
  }

  Widget _lineCard(_MetroLine line, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/metro/route-finder'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            // Colour bar
            Container(
              width: 5,
              height: 44,
              decoration: BoxDecoration(
                color: line.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            // Colour circle + name
            Container(
              width: 32,
              height: 32,
              decoration:
                  BoxDecoration(color: line.color, shape: BoxShape.circle),
              child: const Icon(Icons.train, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(line.route,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: line.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${line.stationCount} stn',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: line.color),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Station Services',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _serviceCard(
                  'Smart Card',
                  'Recharge & Balance',
                  Icons.credit_card,
                  AppTheme.metroBlue,
                  () => _showInfoSheet(
                    context,
                    'Smart Card',
                    Icons.credit_card,
                    AppTheme.metroBlue,
                    'Delhi Metro Smart Card gives 10% discount on every journey.\n\n'
                        '• Minimum balance: ₹20\n'
                        '• Auto top-up available\n'
                        '• Valid for 10 years\n'
                        '• Recharge at any metro station or online via DMRC app.',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _serviceCard(
                  'Parking',
                  'Station Parking',
                  Icons.local_parking,
                  AppTheme.metroGreen,
                  () => _showInfoSheet(
                    context,
                    'Station Parking',
                    Icons.local_parking,
                    AppTheme.metroGreen,
                    'Parking facilities available at select metro stations.\n\n'
                        '• 2-wheeler: ₹10-20/day\n'
                        '• 4-wheeler: ₹40-80/day\n'
                        '• Monthly passes available\n'
                        '• CCTV monitored 24/7',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _serviceCard(
                  'Wi-Fi',
                  'Free Internet',
                  Icons.wifi,
                  AppTheme.metroOrange,
                  () => _showInfoSheet(
                    context,
                    'Free Wi-Fi',
                    Icons.wifi,
                    AppTheme.metroOrange,
                    'Free high-speed Wi-Fi is available at all Delhi Metro stations.\n\n'
                        '• Speed: up to 100 Mbps\n'
                        '• Connect to "Metro Free WiFi" network\n'
                        '• No registration required\n'
                        '• Available inside trains on select lines',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                textAlign: TextAlign.center),
            Text(subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Icon(Icons.info_outline, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildFareInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/metro/fare-calculator'),
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
              Row(
                children: [
                  const Text('Fare Information',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.metroBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Calculate →',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.metroBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _fareChip('Minimum', '₹10', Colors.green),
                  const SizedBox(width: 20),
                  _fareChip('Maximum', '₹60', Colors.orange),
                  const SizedBox(width: 20),
                  _fareChip('Smart Card', '10% Off', AppTheme.metroBlue),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Fare slabs
              _fareRow('0–2 km', '₹10'),
              _fareRow('2–5 km', '₹20'),
              _fareRow('5–12 km', '₹30'),
              _fareRow('12–21 km', '₹40'),
              _fareRow('21–32 km', '₹50'),
              _fareRow('32+ km', '₹60'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fareChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _fareRow(String distance, String fare) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(distance,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text(fare,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.metroBlue)),
        ],
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String title, IconData icon,
      Color color, String body) {
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
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

class _MetroLine {
  final String name;
  final Color color;
  final String route;
  final String stationCount;
  const _MetroLine(this.name, this.color, this.route, this.stationCount);
}
