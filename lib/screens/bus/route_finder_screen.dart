import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
import '../../models/bus_route.dart';
import '../../utils/app_theme.dart';

class BusRouteFinderScreen extends StatefulWidget {
  const BusRouteFinderScreen({super.key});

  @override
  State<BusRouteFinderScreen> createState() => _BusRouteFinderScreenState();
}

class _BusRouteFinderScreenState extends State<BusRouteFinderScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  List<BusRoute> _routes = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Route Finder'),
        backgroundColor: AppTheme.infoColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BusProvider>(
        builder: (context, busProvider, child) {
          return Padding(
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
                            Icon(Icons.directions_bus, color: AppTheme.infoColor),
                            SizedBox(width: 8),
                            Text(
                              'Bus Route Finder',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your starting point and destination to find available bus routes with timings and fare information.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // From Location
                const Text(
                  'From',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    hintText: 'Enter starting location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // To Location
                const Text(
                  'To',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    hintText: 'Enter destination',
                    prefixIcon: Icon(Icons.flag),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSearch() ? _searchRoutes : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Find Bus Routes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Routes List
                if (_routes.isNotEmpty) ...[
                  const Text(
                    'Available Routes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        return _buildRouteCard(route);
                      },
                    ),
                  ),
                ] else if (_isSearching) ...[
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (_fromController.text.isNotEmpty && _toController.text.isNotEmpty) ...[
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No bus routes found. Please try different locations.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canSearch() {
    return _fromController.text.isNotEmpty && 
           _toController.text.isNotEmpty && 
           !_isSearching;
  }

  void _searchRoutes() async {
    if (!_canSearch()) return;
    
    setState(() {
      _isSearching = true;
    });
    
    final busProvider = context.read<BusProvider>();
    final routes = await busProvider.findRoute(_fromController.text, _toController.text);
    
    setState(() {
      _routes = routes;
      _isSearching = false;
    });
  }

  Widget _buildRouteCard(BusRoute route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Bus ${route.busNumber}',
                    style: const TextStyle(
                      color: AppTheme.infoColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${route.totalTime} min',
                    style: const TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.metroGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${route.fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.metroGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Route Path
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.fromLocation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.toLocation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Route Details
            Row(
              children: [
                _buildDetailItem(Icons.schedule, route.frequency),
                const SizedBox(width: 16),
                _buildDetailItem(Icons.straighten, '${route.totalDistance.toStringAsFixed(1)} km'),
                const SizedBox(width: 16),
                _buildDetailItem(Icons.bus_alert, '${route.stops.length} stops'),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Timing Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'First Bus: ${route.firstBus}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Last Bus: ${route.lastBus}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to route details or live tracking
                  _showRouteDetails(route);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.infoColor,
                  side: const BorderSide(color: AppTheme.infoColor),
                ),
                child: const Text('View Route Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showRouteDetails(BusRoute route) {
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
                'Bus ${route.busNumber} - Route Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: route.stops.length,
                  itemBuilder: (context, index) {
                    final stop = route.stops[index];
                    final isFirst = index == 0;
                    final isLast = index == route.stops.length - 1;
                    
                    return ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isFirst || isLast 
                              ? AppTheme.infoColor 
                              : Colors.grey.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFirst ? Icons.play_arrow : 
                          isLast ? Icons.flag : Icons.circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        stop,
                        style: TextStyle(
                          fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: isFirst 
                          ? const Text('Starting Point')
                          : isLast 
                              ? const Text('Destination')
                              : Text('Stop ${index + 1}'),
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
