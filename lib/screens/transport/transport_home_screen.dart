import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/app_theme.dart';

class TransportHomeScreen extends StatelessWidget {
  const TransportHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Transport'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(
        title: 'Other Transport',
        subtitle: 'Auto, cabs & rentals',
        primaryColor: AppTheme.accentColor,
        secondaryColor: AppTheme.metroOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_taxi, color: AppTheme.accentColor),
                        SizedBox(width: 8),
                        Text(
                          'Other Transport Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore various transport options available in Delhi including autos, cabs, and bike rentals.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Transport Options
            const Text(
              'Available Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                FeatureCard(
                  title: 'Auto & Cab',
                  icon: Icons.local_taxi,
                  color: AppTheme.accentColor,
                  onTap: () => _showAutoCabOptions(context),
                ),
                FeatureCard(
                  title: 'Cycle Rentals',
                  icon: Icons.pedal_bike,
                  color: AppTheme.metroGreen,
                  onTap: () => _showCycleRentals(context),
                ),
                FeatureCard(
                  title: 'Scooter Rentals',
                  icon: Icons.motorcycle,
                  color: AppTheme.metroOrange,
                  onTap: () => _showScooterRentals(context),
                ),
                FeatureCard(
                  title: 'Fare Calculator',
                  icon: Icons.calculate,
                  color: AppTheme.metroBlue,
                  onTap: () => _showFareCalculator(context),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Quick Info Cards
            _buildInfoCard(
              'Auto Rickshaws',
              'Traditional three-wheeler transport',
              '₹10-15 per km',
              Icons.auto_awesome,
              AppTheme.accentColor,
            ),
            
            const SizedBox(height: 12),
            
            _buildInfoCard(
              'Cab Services',
              'Uber, Ola, and other app-based cabs',
              '₹8-12 per km',
              Icons.local_taxi,
              AppTheme.metroBlue,
            ),
            
            const SizedBox(height: 12),
            
            _buildInfoCard(
              'Bike Rentals',
              'Yulu, Rapido, and other bike sharing',
              '₹2-5 per km',
              Icons.pedal_bike,
              AppTheme.metroGreen,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildInfoCard(String title, String description, String price, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  void _showAutoCabOptions(BuildContext context) {
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
              const Text(
                'Auto & Cab Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildTransportOption(
                      'Auto Rickshaw',
                      'Traditional three-wheeler',
                      '₹10-15 per km',
                      'Available everywhere',
                      Icons.auto_awesome,
                      AppTheme.accentColor,
                    ),
                    _buildTransportOption(
                      'Uber',
                      'Ride-hailing service',
                      '₹8-12 per km',
                      'App-based booking',
                      Icons.local_taxi,
                      Colors.black,
                    ),
                    _buildTransportOption(
                      'Ola',
                      'Ride-hailing service',
                      '₹8-12 per km',
                      'App-based booking',
                      Icons.local_taxi,
                      Colors.orange,
                    ),
                    _buildTransportOption(
                      'Meru Cabs',
                      'Premium cab service',
                      '₹12-18 per km',
                      'Pre-booked rides',
                      Icons.local_taxi,
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCycleRentals(BuildContext context) {
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
              const Text(
                'Cycle Rental Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildTransportOption(
                      'Yulu',
                      'Electric bike sharing',
                      '₹2-5 per km',
                      'Available in select areas',
                      Icons.pedal_bike,
                      AppTheme.metroGreen,
                    ),
                    _buildTransportOption(
                      'Rapido',
                      'Bike taxi service',
                      '₹3-6 per km',
                      'On-demand rides',
                      Icons.motorcycle,
                      AppTheme.metroOrange,
                    ),
                    _buildTransportOption(
                      'Mobike',
                      'Bike sharing platform',
                      '₹1-3 per km',
                      'Station-based pickup',
                      Icons.pedal_bike,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScooterRentals(BuildContext context) {
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
              const Text(
                'Scooter Rental Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildTransportOption(
                      'Rapido',
                      'Bike taxi service',
                      '₹3-6 per km',
                      'On-demand rides',
                      Icons.motorcycle,
                      AppTheme.metroOrange,
                    ),
                    _buildTransportOption(
                      'Bounce',
                      'Scooter sharing',
                      '₹2-4 per km',
                      'Self-ride option',
                      Icons.motorcycle,
                      Colors.blue,
                    ),
                    _buildTransportOption(
                      'Vogo',
                      'Scooter rental',
                      '₹1-3 per km',
                      'Station-based pickup',
                      Icons.motorcycle,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFareCalculator(BuildContext context) {
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
              const Text(
                'Fare Calculator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildFareCard('Auto Rickshaw', '₹10-15 per km', 'Base fare: ₹25'),
                    _buildFareCard('Uber/Ola', '₹8-12 per km', 'Base fare: ₹40'),
                    _buildFareCard('Cycle Rental', '₹2-5 per km', 'Minimum: ₹10'),
                    _buildFareCard('Scooter Rental', '₹2-4 per km', 'Minimum: ₹15'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportOption(String title, String description, String price, String availability, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildFareCard(String transport, String fare, String baseFare) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transport,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
