import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../models/metro_route.dart';
import '../../utils/app_theme.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Route Finder'),
        backgroundColor: AppTheme.metroRed,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MetroProvider>(
        builder: (context, metroProvider, child) {
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
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // From Station Dropdown
                const Text(
                  'From Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _fromStation,
                  decoration: const InputDecoration(
                    hintText: 'Select starting station',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: metroProvider.stations.map((station) {
                    return DropdownMenuItem<String>(
                      value: station.name,
                      child: Text(station.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _fromStation = value;
                      _routes = [];
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // To Station Dropdown
                const Text(
                  'To Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _toStation,
                  decoration: const InputDecoration(
                    hintText: 'Select destination station',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: metroProvider.stations.map((station) {
                    return DropdownMenuItem<String>(
                      value: station.name,
                      child: Text(station.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _toStation = value;
                      _routes = [];
                    });
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
                ] else if (_fromStation != null && _toStation != null) ...[
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No routes found. Please try different stations.',
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
    return _fromStation != null && _toStation != null && !_isSearching;
  }

  void _searchRoutes() async {
    if (!_canSearch()) return;
    
    setState(() {
      _isSearching = true;
    });
    
    final metroProvider = context.read<MetroProvider>();
    final routes = await metroProvider.findRoute(_fromStation!, _toStation!);
    
    setState(() {
      _routes = routes;
      _isSearching = false;
    });
  }

  Widget _buildRouteCard(MetroRoute route) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.metroRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${route.totalTime} min',
                    style: const TextStyle(
                      color: AppTheme.metroRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.metroBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${route.totalFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.metroBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${route.totalStations} stations',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
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
                    route.fromStation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.toStation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Route Segments
            ...route.segments.map((segment) => _buildSegment(segment)),
            
            if (route.interchangeStations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Interchange at: ${route.interchangeStations.join(', ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
