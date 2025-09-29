import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/location_provider.dart';
import '../../providers/metro_provider.dart';
import '../../widgets/feature_card.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';

class MetroHomeScreen extends StatefulWidget {
  const MetroHomeScreen({super.key});

  @override
  State<MetroHomeScreen> createState() => _MetroHomeScreenState();
}

class _MetroHomeScreenState extends State<MetroHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delhi Metro'),
        backgroundColor: AppTheme.metroBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MetroProvider>().loadStations();
              context.read<LocationProvider>().getCurrentLocation();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Consumer2<MetroProvider, LocationProvider>(
        builder: (context, metroProvider, locationProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Location Card
                if (locationProvider.currentAddress != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.metroBlue.withOpacity(0.1),
                          AppTheme.metroBlue.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.metroBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.metroBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppTheme.metroBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Location',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                locationProvider.currentAddress!,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Metro Features
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Metro Services',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Plan your metro journey',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.metroBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.train,
                        color: AppTheme.metroBlue,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
                  crossAxisSpacing: ResponsiveHelper.getGridSpacing(context),
                  mainAxisSpacing: ResponsiveHelper.getGridSpacing(context),
                  childAspectRatio: ResponsiveHelper.getGridChildAspectRatio(context),
                  children: [
                    FeatureCard(
                      title: 'Fare Calculator',
                      subtitle: 'Calculate fare',
                      icon: Icons.calculate,
                      color: AppTheme.metroBlue,
                      onTap: () => context.go('/metro/fare-calculator'),
                    ),
                    FeatureCard(
                      title: 'Route Finder',
                      subtitle: 'Find best route',
                      icon: Icons.route,
                      color: AppTheme.metroRed,
                      onTap: () => context.go('/metro/route-finder'),
                    ),
                    FeatureCard(
                      title: 'Live Updates',
                      subtitle: 'Real-time info',
                      icon: Icons.update,
                      color: AppTheme.metroGreen,
                      onTap: () => context.go('/metro/live-updates'),
                    ),
                    FeatureCard(
                      title: 'Nearest Station',
                      subtitle: 'Find nearby',
                      icon: Icons.location_on,
                      color: AppTheme.metroViolet,
                      onTap: _showNearestStations,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Quick Stats
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Stats',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Metro system overview',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.metroGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: AppTheme.metroGreen,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Stations',
                        '${metroProvider.stations.length}',
                        Icons.train,
                        AppTheme.metroBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Metro Lines',
                        '8',
                        Icons.timeline,
                        AppTheme.metroRed,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Interchange Stations',
                        '12',
                        Icons.swap_horiz,
                        AppTheme.metroGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Daily Ridership',
                        '2.8M',
                        Icons.people,
                        AppTheme.metroViolet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, 1),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.metroBlue, AppTheme.metroRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.train,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Delhi Metro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Metro services & routes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: AppTheme.primaryColor),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.train, color: AppTheme.metroBlue),
            title: const Text('Metro Services'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate, color: AppTheme.metroBlue),
            title: const Text('Fare Calculator'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/fare-calculator');
            },
          ),
          ListTile(
            leading: const Icon(Icons.route, color: AppTheme.metroRed),
            title: const Text('Route Finder'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/route-finder');
            },
          ),
          ListTile(
            leading: const Icon(Icons.update, color: AppTheme.metroGreen),
            title: const Text('Live Updates'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/live-updates');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.directions_bus, color: AppTheme.infoColor),
            title: const Text('Bus Services'),
            onTap: () {
              Navigator.pop(context);
              context.go('/bus');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_taxi, color: AppTheme.accentColor),
            title: const Text('Other Transport'),
            onTap: () {
              Navigator.pop(context);
              context.go('/transport');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/metro');
            break;
          case 2:
            context.go('/bus');
            break;
          case 3:
            context.go('/transport');
            break;
          case 4:
            context.go('/weather');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.train),
          label: 'Metro',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus),
          label: 'Bus',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_taxi),
          label: 'Transport',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wb_sunny),
          label: 'Weather',
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNearestStations() {
    final locationProvider = context.read<LocationProvider>();
    final metroProvider = context.read<MetroProvider>();
    
    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable location services to find nearest stations'),
        ),
      );
      return;
    }
    
    final nearestStations = metroProvider.findNearestStations(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );
    
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
                'Nearest Metro Stations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: nearestStations.length,
                  itemBuilder: (context, index) {
                    final station = nearestStations[index];
                    final distance = locationProvider.getDistanceTo(
                      station.latitude,
                      station.longitude,
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(int.parse(station.lineColor.replaceFirst('#', '0xFF'))),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(station.name),
                        subtitle: Text('${station.line} • ${distance?.toStringAsFixed(1) ?? 'N/A'} km'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to station details
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
