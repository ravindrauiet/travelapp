import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/location_provider.dart';
import '../../providers/bus_provider.dart';
import '../../models/bus_station.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/app_theme.dart';

class BusHomeScreen extends StatefulWidget {
  const BusHomeScreen({super.key});

  @override
  State<BusHomeScreen> createState() => _BusHomeScreenState();
}

class _BusHomeScreenState extends State<BusHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusProvider>().loadStations();
      context.read<BusProvider>().loadLiveTimings();
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delhi Bus Services'),
        backgroundColor: AppTheme.infoColor,
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
              context.read<BusProvider>().loadStations();
              context.read<BusProvider>().loadLiveTimings();
              context.read<LocationProvider>().getCurrentLocation();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(
        title: 'Delhi Bus Services',
        subtitle: 'Bus routes & timings',
        primaryColor: AppTheme.infoColor,
        secondaryColor: AppTheme.warningColor,
      ),
      body: Consumer2<BusProvider, LocationProvider>(
        builder: (context, busProvider, locationProvider, child) {
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
                          AppTheme.infoColor.withOpacity(0.1),
                          AppTheme.infoColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.infoColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppTheme.infoColor,
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
                                  color: AppTheme.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                locationProvider.currentAddress!,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.textPrimary,
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
                
                // Bus Features
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bus Services',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Explore bus routes',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: AppTheme.infoColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    FeatureCard(
                      title: 'Route Finder',
                      subtitle: 'Find bus routes',
                      icon: Icons.directions_bus,
                      color: AppTheme.infoColor,
                      onTap: () => context.go('/bus/route-finder'),
                    ),
                    FeatureCard(
                      title: 'Stop Locator',
                      subtitle: 'Find bus stops',
                      icon: Icons.bus_alert,
                      color: AppTheme.warningColor,
                      onTap: () => context.go('/bus/stop-locator'),
                    ),
                    FeatureCard(
                      title: 'Live Timing',
                      subtitle: 'Real-time schedule',
                      icon: Icons.schedule,
                      color: AppTheme.metroOrange,
                      onTap: _showLiveTimings,
                    ),
                    FeatureCard(
                      title: 'Nearest Stops',
                      subtitle: 'Find nearby',
                      icon: Icons.location_searching,
                      color: AppTheme.metroPink,
                      onTap: _showNearestStops,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Live Timings Preview
                if (busProvider.liveTimings.isNotEmpty) ...[
                  const Text(
                    'Live Bus Timings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule, color: AppTheme.infoColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Real-time Updates',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => context.read<BusProvider>().loadLiveTimings(),
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...busProvider.liveTimings.take(3).map((timing) => _buildTimingItem(timing)),
                          if (busProvider.liveTimings.length > 3)
                            TextButton(
                              onPressed: _showLiveTimings,
                              child: Text('View all ${busProvider.liveTimings.length} timings'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Quick Stats
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Stops',
                        '${busProvider.stations.length}',
                        Icons.bus_alert,
                        AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Bus Routes',
                        '150+',
                        Icons.route,
                        AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Terminal Stations',
                        '8',
                        Icons.directions_transit,
                        AppTheme.metroOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Daily Ridership',
                        '4.2M',
                        Icons.people,
                        AppTheme.metroPink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingItem(BusTiming timing) {
    Color statusColor;
    IconData statusIcon;
    
    switch (timing.status) {
      case 'on_time':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'delayed':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'arrived':
        statusColor = Colors.blue;
        statusIcon = Icons.done;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              timing.busNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.infoColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              timing.stationName,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            _formatTime(timing.expectedArrival),
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showLiveTimings() {
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
                'Live Bus Timings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<BusProvider>(
                  builder: (context, busProvider, child) {
                    if (busProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: busProvider.liveTimings.length,
                      itemBuilder: (context, index) {
                        final timing = busProvider.liveTimings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.infoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                timing.busNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.infoColor,
                                ),
                              ),
                            ),
                            title: Text(timing.stationName),
                            subtitle: Text(_formatTime(timing.expectedArrival)),
                            trailing: Icon(
                              timing.status == 'on_time' ? Icons.check_circle : Icons.schedule,
                              color: timing.status == 'on_time' ? Colors.green : Colors.orange,
                            ),
                          ),
                        );
                      },
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

  void _showNearestStops() {
    final locationProvider = context.read<LocationProvider>();
    final busProvider = context.read<BusProvider>();
    
    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable location services to find nearest stops'),
        ),
      );
      return;
    }
    
    final nearestStops = busProvider.findNearestStations(
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
                'Nearest Bus Stops',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: nearestStops.length,
                  itemBuilder: (context, index) {
                    final stop = nearestStops[index];
                    final distance = locationProvider.getDistanceTo(
                      stop.latitude,
                      stop.longitude,
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.bus_alert, color: AppTheme.infoColor),
                        title: Text(stop.name),
                        subtitle: Text('${stop.busNumbers.length} buses • ${distance?.toStringAsFixed(1) ?? 'N/A'} km'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to stop details
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
