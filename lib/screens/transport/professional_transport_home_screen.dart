import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/responsive_helper.dart';

class ProfessionalTransportHomeScreen extends StatefulWidget {
  const ProfessionalTransportHomeScreen({super.key});

  @override
  State<ProfessionalTransportHomeScreen> createState() => _ProfessionalTransportHomeScreenState();
}

class _ProfessionalTransportHomeScreenState extends State<ProfessionalTransportHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      drawer: isTablet ? null : const AppDrawer(
        title: 'Other Transport',
        subtitle: 'Auto, Cabs & Rentals',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTransportTypes(),
            const SizedBox(height: 20),
            _buildPopularServices(),
            const SizedBox(height: 20),
            _buildFareInfo(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_taxi,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Other Transport',
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
          onPressed: () {},
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
          colors: [
            AppTheme.accentColor,
            AppTheme.accentColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.local_taxi,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Other Transport Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Auto, Cabs & Rentals',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickStat('Auto Rickshaws', '500+', Icons.auto_awesome, Colors.white),
              const SizedBox(width: 16),
              _buildQuickStat('Cab Services', '50+', Icons.local_taxi, Colors.white),
              const SizedBox(width: 16),
              _buildQuickStat('Bike Rentals', '20+', Icons.pedal_bike, Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportTypes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transport Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTransportCard(
                  'Auto Rickshaw',
                  'Traditional three-wheeler',
                  '₹10-15/km',
                  Icons.auto_awesome,
                  AppTheme.accentColor,
                  () => _showAutoOptions(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTransportCard(
                  'Cab Services',
                  'Uber, Ola & more',
                  '₹8-12/km',
                  Icons.local_taxi,
                  AppTheme.metroBlue,
                  () => _showCabOptions(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTransportCard(
                  'Bike Rentals',
                  'Yulu, Rapido & more',
                  '₹2-5/km',
                  Icons.pedal_bike,
                  AppTheme.metroGreen,
                  () => _showBikeOptions(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTransportCard(
                  'Scooter Rentals',
                  'Bounce, Vogo & more',
                  '₹2-4/km',
                  Icons.motorcycle,
                  AppTheme.metroOrange,
                  () => _showScooterOptions(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(String title, String subtitle, String price, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularServices() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            'Uber',
            'Ride-hailing service',
            '₹8-12 per km',
            'Available 24/7',
            Icons.local_taxi,
            Colors.black,
          ),
          const SizedBox(height: 8),
          _buildServiceCard(
            'Ola',
            'Ride-hailing service',
            '₹8-12 per km',
            'Available 24/7',
            Icons.local_taxi,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildServiceCard(
            'Yulu',
            'Electric bike sharing',
            '₹2-5 per km',
            'Select areas',
            Icons.pedal_bike,
            AppTheme.metroGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String description, String price, String availability, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  availability,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.metroBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Fare Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFareRow('Auto Rickshaw', '₹10-15 per km', 'Base fare: ₹25'),
          _buildFareRow('Uber/Ola', '₹8-12 per km', 'Base fare: ₹40'),
          _buildFareRow('Bike Rental', '₹2-5 per km', 'Minimum: ₹10'),
          _buildFareRow('Scooter Rental', '₹2-4 per km', 'Minimum: ₹15'),
        ],
      ),
    );
  }

  Widget _buildFareRow(String transport, String fare, String baseFare) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transport,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                baseFare,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Text(
            fare,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.metroBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoOptions(BuildContext context) {
    _showTransportModal(context, 'Auto Rickshaw Options', [
      {'title': 'Auto Rickshaw', 'description': 'Traditional three-wheeler', 'price': '₹10-15 per km', 'availability': 'Available everywhere', 'icon': Icons.auto_awesome, 'color': AppTheme.accentColor},
    ]);
  }

  void _showCabOptions(BuildContext context) {
    _showTransportModal(context, 'Cab Services', [
      {'title': 'Uber', 'description': 'Ride-hailing service', 'price': '₹8-12 per km', 'availability': 'App-based booking', 'icon': Icons.local_taxi, 'color': Colors.black},
      {'title': 'Ola', 'description': 'Ride-hailing service', 'price': '₹8-12 per km', 'availability': 'App-based booking', 'icon': Icons.local_taxi, 'color': Colors.orange},
      {'title': 'Meru Cabs', 'description': 'Premium cab service', 'price': '₹12-18 per km', 'availability': 'Pre-booked rides', 'icon': Icons.local_taxi, 'color': Colors.blue},
    ]);
  }

  void _showBikeOptions(BuildContext context) {
    _showTransportModal(context, 'Bike Rental Services', [
      {'title': 'Yulu', 'description': 'Electric bike sharing', 'price': '₹2-5 per km', 'availability': 'Available in select areas', 'icon': Icons.pedal_bike, 'color': AppTheme.metroGreen},
      {'title': 'Rapido', 'description': 'Bike taxi service', 'price': '₹3-6 per km', 'availability': 'On-demand rides', 'icon': Icons.motorcycle, 'color': AppTheme.metroOrange},
      {'title': 'Mobike', 'description': 'Bike sharing platform', 'price': '₹1-3 per km', 'availability': 'Station-based pickup', 'icon': Icons.pedal_bike, 'color': Colors.orange},
    ]);
  }

  void _showScooterOptions(BuildContext context) {
    _showTransportModal(context, 'Scooter Rental Services', [
      {'title': 'Rapido', 'description': 'Bike taxi service', 'price': '₹3-6 per km', 'availability': 'On-demand rides', 'icon': Icons.motorcycle, 'color': AppTheme.metroOrange},
      {'title': 'Bounce', 'description': 'Scooter sharing', 'price': '₹2-4 per km', 'availability': 'Self-ride option', 'icon': Icons.motorcycle, 'color': Colors.blue},
      {'title': 'Vogo', 'description': 'Scooter rental', 'price': '₹1-3 per km', 'availability': 'Station-based pickup', 'icon': Icons.motorcycle, 'color': Colors.green},
    ]);
  }

  void _showTransportModal(BuildContext context, String title, List<Map<String, dynamic>> options) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: options.map((option) => _buildTransportOption(
                    option['title'],
                    option['description'],
                    option['price'],
                    option['availability'],
                    option['icon'],
                    option['color'],
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportOption(String title, String description, String price, String availability, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  availability,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
