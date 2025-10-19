import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../models/metro_route.dart';
import '../../utils/app_theme.dart';
import '../../widgets/searchable_station_dropdown.dart';

class MetroRouteFinderScreen extends StatefulWidget {
  const MetroRouteFinderScreen({super.key});

  @override
  State<MetroRouteFinderScreen> createState() => _MetroRouteFinderScreenState();
}

class _MetroRouteFinderScreenState extends State<MetroRouteFinderScreen> {
  String? _fromStation;
  String? _toStation;
  List<MetroRoute> _routes = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Load stations when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Route Finder'),
        backgroundColor: AppTheme.metroRed,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MetroProvider>(
        builder: (context, metroProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                            Icon(Icons.route, color: AppTheme.metroRed),
                            SizedBox(width: 8),
                            Text(
                              'Route Finder',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Find the fastest metro route between two stations with detailed information about line changes and journey time.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if (metroProvider.isLoading)
                          const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading stations from GTFS data...',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else if (metroProvider.error != null)
                          Text(
                            'Error: ${metroProvider.error}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            'Loaded ${metroProvider.stations.length} stations from GTFS data',
                            style: TextStyle(
                              color: metroProvider.stations.isEmpty ? Colors.red : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // From Station Search
                const Text(
                  'From Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SearchableStationDropdown(
                  stations: metroProvider.stations,
                  selectedStation: _fromStation,
                  hintText: metroProvider.isLoading 
                    ? 'Loading stations...' 
                    : metroProvider.stations.isEmpty 
                      ? 'No stations available' 
                      : 'Search and select starting station',
                  prefixIcon: Icons.location_on,
                  onChanged: (value) {
                    if (metroProvider.stations.isNotEmpty) {
                      setState(() {
                        _fromStation = value;
                        _routes = [];
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 20),
                
                // To Station Search
                const Text(
                  'To Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SearchableStationDropdown(
                  stations: metroProvider.stations,
                  selectedStation: _toStation,
                  hintText: metroProvider.isLoading 
                    ? 'Loading stations...' 
                    : metroProvider.stations.isEmpty 
                      ? 'No stations available' 
                      : 'Search and select destination station',
                  prefixIcon: Icons.flag,
                  onChanged: (value) {
                    if (metroProvider.stations.isNotEmpty) {
                      setState(() {
                        _toStation = value;
                        _routes = [];
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSearch() ? _searchRoutes : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.metroRed,
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
                            'Find Route',
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
                  ..._routes.map((route) => _buildRouteCard(route)).toList(),
                ] else if (_isSearching) ...[
                  const SizedBox(height: 100),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 100),
                ] else if (_fromStation != null && _toStation != null) ...[
                  const SizedBox(height: 100),
                  const Center(
                    child: Text(
                      'No routes found. Please try different stations.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canSearch() {
    return _fromStation != null && _toStation != null && !_isSearching;
  }

  void _searchRoutes() async {
    if (!_canSearch()) return;
    
    setState(() {
      _isSearching = true;
    });
    
    print('Route Finder: Searching route from $_fromStation to $_toStation');
    print('Route Finder: Available stations: ${context.read<MetroProvider>().stations.length}');
    
    final metroProvider = context.read<MetroProvider>();
    final routes = await metroProvider.findRoute(_fromStation!, _toStation!);
    
    print('Route Finder: Found ${routes.length} routes');
    for (int i = 0; i < routes.length; i++) {
      print('Route ${i + 1}: ${routes[i].totalTime} minutes, ${routes[i].totalStations} stations, ${routes[i].interchangeStations.length} interchanges');
    }
    
    setState(() {
      _routes = routes;
      _isSearching = false;
    });
  }

  Widget _buildRouteCard(MetroRoute route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Header with comprehensive info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route ${_routes.indexOf(route) + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.metroRed,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route.fromStation} → ${route.toStation}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.metroRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.metroRed),
                          const SizedBox(width: 4),
                          Text(
                            '${route.totalTime} min',
                            style: const TextStyle(
                              color: AppTheme.metroRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.metroBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.currency_rupee, size: 16, color: AppTheme.metroBlue),
                          const SizedBox(width: 4),
                          Text(
                            '${route.totalFare.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.metroBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Journey Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(Icons.train, '${route.totalStations}', 'Stations'),
                  _buildSummaryItem(Icons.swap_horiz, '${route.interchangeStations.length}', 'Interchanges'),
                  _buildSummaryItem(Icons.route, '${route.segments.length}', 'Segments'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Detailed Route Segments
            const Text(
              'Journey Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.metroRed,
              ),
            ),
            const SizedBox(height: 12),
            
            ...route.segments.asMap().entries.map((entry) {
              final index = entry.key;
              final segment = entry.value;
              return _buildDetailedSegment(segment, index + 1, route.segments.length);
            }),
            
            if (route.interchangeStations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Interchange Stations',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            route.interchangeStations.join(', '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Additional Tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tip: Arrive 5 minutes early for interchanges. Smart card saves 10% on fares.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
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

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.metroRed),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.metroRed,
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
    );
  }

  Widget _buildDetailedSegment(RouteSegment segment, int segmentNumber, int totalSegments) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(int.parse(segment.lineColor.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$segmentNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      segment.line,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.metroRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${segment.fromStation} → ${segment.toStation}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${segment.timeMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.currency_rupee, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${segment.fare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.train, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${segment.stationsCount} stations',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              if (segmentNumber < totalSegments)
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(RouteSegment segment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(int.parse(segment.lineColor.replaceFirst('#', '0xFF'))),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${segment.fromStation} → ${segment.toStation}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '${segment.stationsCount} stations',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
