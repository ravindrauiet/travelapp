import 'package:flutter/material.dart';
import '../../services/gtfs_data_parser.dart';
import '../../services/accurate_fare_calculator.dart';
import '../../services/accurate_route_finder.dart';
import '../../models/metro_station.dart';
import '../../models/metro_route.dart';

/// Demo screen showcasing real GTFS data from assets/gtfs_data/ folder
/// Shows all 7 GTFS files with accurate DMRC information
class GTFSRealDataDemoScreen extends StatefulWidget {
  const GTFSRealDataDemoScreen({super.key});

  @override
  State<GTFSRealDataDemoScreen> createState() => _GTFSRealDataDemoScreenState();
}

class _GTFSRealDataDemoScreenState extends State<GTFSRealDataDemoScreen> {
  List<MetroStation> _stations = [];
  List<MetroLine> _metroLines = [];
  bool _isLoading = true;
  String? _error;
  
  // Demo route planning
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  List<MetroRoute> _demoRoutes = [];
  bool _isCalculatingRoute = false;

  @override
  void initState() {
    super.initState();
    _loadGTFSData();
  }

  Future<void> _loadGTFSData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load real GTFS data from your 7 files
      final stations = await GTFSDataParser.getMetroStations();
      final metroLines = await GTFSDataParser.getMetroLines();

      setState(() {
        _stations = stations;
        _metroLines = metroLines;
        _isLoading = false;
      });

      print('Successfully loaded GTFS data:');
      print('- Stations: ${stations.length}');
      print('- Metro Lines: ${metroLines.length}');

    } catch (e) {
      setState(() {
        _error = 'Failed to load GTFS data: $e';
        _isLoading = false;
      });
      print('Error loading GTFS data: $e');
    }
  }

  Future<void> _calculateRoute() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both from and to stations')),
      );
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final routes = await AccurateRouteFinder.findOptimalRoute(
        fromStationName: _fromController.text,
        toStationName: _toController.text,
        stations: _stations,
        travelTime: DateTime.now(),
        isSmartCard: true,
      );

      setState(() {
        _demoRoutes = routes;
        _isCalculatingRoute = false;
      });
    } catch (e) {
      setState(() {
        _isCalculatingRoute = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route calculation failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real GTFS Data Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGTFSData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGTFSDataOverview(),
                      const SizedBox(height: 20),
                      _buildFareCalculator(),
                      const SizedBox(height: 20),
                      _buildRoutePlanner(),
                      const SizedBox(height: 20),
                      _buildStationList(),
                      const SizedBox(height: 20),
                      _buildMetroLinesList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGTFSDataOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real GTFS Data from assets/gtfs_data/',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('✅ Using your 7 GTFS files with real DMRC data:'),
            const Text('  • agency.txt - DMRC agency information'),
            const Text('  • routes.txt - 37 metro routes'),
            const Text('  • stops.txt - 264 real metro stations'),
            const Text('  • trips.txt - 5,420+ scheduled trips'),
            const Text('  • stop_times.txt - 128,000+ timetables'),
            const Text('  • calendar.txt - Service schedules'),
            const Text('  • shapes.txt - 6,600+ route geometry points'),
            const SizedBox(height: 10),
            Text('Loaded Stations: ${_stations.length}'),
            Text('Loaded Metro Lines: ${_metroLines.length}'),
            const SizedBox(height: 10),
            const Text(
              'Features with Real Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Accurate fare calculation (August 2025 rates)'),
            const Text('• Smart card discounts (10% + 10% off-peak)'),
            const Text('• Holiday fare discounts'),
            const Text('• Maximum Permissible Time (MPT) validation'),
            const Text('• Dijkstra algorithm for optimal routing'),
            const Text('• Real station coordinates and interchange data'),
          ],
        ),
      ),
    );
  }

  Widget _buildFareCalculator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fare Calculator (August 2025 Rates)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildFareTest('Short Distance (1 km)', 1.0),
            _buildFareTest('Medium Distance (8 km)', 8.0),
            _buildFareTest('Long Distance (25 km)', 25.0),
            _buildFareTest('Airport Express (15 km)', 15.0, isAirportExpress: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFareTest(String description, double distance, {bool isAirportExpress = false}) {
    final normalFare = AccurateFareCalculator.calculateFare(
      distance: distance,
      travelTime: DateTime.now(),
      isSmartCard: false,
      isAirportExpress: isAirportExpress,
    );
    
    final smartCardFare = AccurateFareCalculator.calculateFare(
      distance: distance,
      travelTime: DateTime.now(),
      isSmartCard: true,
      isAirportExpress: isAirportExpress,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Normal: ₹${normalFare.finalFare}'),
              Text('Smart Card: ₹${smartCardFare.finalFare}'),
              if (smartCardFare.isOffPeak)
                const Text('(Off-peak discount applied)', style: TextStyle(fontSize: 12, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePlanner() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Planner with Real GTFS Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromController,
                    decoration: const InputDecoration(
                      labelText: 'From Station',
                      hintText: 'e.g., Rajiv Chowk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _toController,
                    decoration: const InputDecoration(
                      labelText: 'To Station',
                      hintText: 'e.g., Kashmere Gate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isCalculatingRoute ? null : _calculateRoute,
                  child: _isCalculatingRoute
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Find Route'),
                ),
              ],
            ),
            if (_demoRoutes.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Text(
                'Route Results:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._demoRoutes.map((route) => _buildRouteCard(route)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(MetroRoute route) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${route.fromStation} → ${route.toStation}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time: ${route.totalTime} min'),
                Text('Fare: ₹${route.totalFare.toStringAsFixed(0)}'),
                Text('Stations: ${route.totalStations}'),
              ],
            ),
            if (route.interchangeStations.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Interchanges: ${route.interchangeStations.join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStationList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real Metro Stations (from stops.txt)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Total Stations: ${_stations.length}'),
            const SizedBox(height: 10),
            ..._stations.take(20).map((station) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(station.lineColor.replaceFirst('#', '0xFF'))),
                child: Text(
                  station.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(station.name),
              subtitle: Text('${station.line} • ${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}'),
              trailing: station.isInterchange
                  ? const Icon(Icons.swap_horiz, color: Colors.blue)
                  : null,
            )),
            if (_stations.length > 20)
              Text(
                '... and ${_stations.length - 20} more stations from real GTFS data',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetroLinesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real Metro Lines (from routes.txt)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._metroLines.map((line) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(line.color.replaceFirst('#', '0xFF'))),
                child: Text(
                  line.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(line.name),
              subtitle: Text('${line.stations.length} stations'),
              trailing: Text(
                line.color,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
}
