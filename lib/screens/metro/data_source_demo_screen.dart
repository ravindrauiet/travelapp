import 'package:flutter/material.dart';
import '../../services/metro_data_parser.dart';
import '../../services/accurate_fare_calculator.dart';

/// Demo screen showing that the app uses data from assets/data/ folder
class DataSourceDemoScreen extends StatefulWidget {
  const DataSourceDemoScreen({super.key});

  @override
  State<DataSourceDemoScreen> createState() => _DataSourceDemoScreenState();
}

class _DataSourceDemoScreenState extends State<DataSourceDemoScreen> {
  List<MetroStation> _stations = [];
  List<MetroLine> _metroLines = [];
  List<BusRoute> _busRoutes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load data from your JSON files
      final stations = await MetroDataParser.getMetroStations();
      final metroLines = await MetroDataParser.getMetroLines();
      final busRoutes = await MetroDataParser.getBusRoutes();

      setState(() {
        _stations = stations;
        _metroLines = metroLines;
        _busRoutes = busRoutes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Source Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                      _buildDataOverview(),
                      const SizedBox(height: 20),
                      _buildMetroStations(),
                      const SizedBox(height: 20),
                      _buildMetroLines(),
                      const SizedBox(height: 20),
                      _buildBusRoutes(),
                      const SizedBox(height: 20),
                      _buildFareCalculator(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDataOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Source Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('✅ Using data from assets/data/ folder'),
            const Text('✅ metro_stations.json - Metro station data'),
            const Text('✅ delhi_metro_2025.json - Metro line data'),
            const Text('✅ delhi_bus_routes_2025.json - Bus route data'),
            const SizedBox(height: 10),
            Text('Metro Stations: ${_stations.length}'),
            Text('Metro Lines: ${_metroLines.length}'),
            Text('Bus Routes: ${_busRoutes.length}'),
            const SizedBox(height: 10),
            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Accurate fare calculation with August 2025 rates'),
            const Text('• Smart card discounts (10% + 10% off-peak)'),
            const Text('• Holiday fare discounts'),
            const Text('• Maximum Permissible Time (MPT) validation'),
            const Text('• Dijkstra algorithm for optimal routing'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetroStations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metro Stations (from metro_stations.json)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._stations.take(10).map((station) => ListTile(
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
            if (_stations.length > 10)
              Text(
                '... and ${_stations.length - 10} more stations',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetroLines() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metro Lines (from delhi_metro_2025.json)',
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

  Widget _buildBusRoutes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bus Routes (from delhi_bus_routes_2025.json)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._busRoutes.take(5).map((route) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.directions_bus, color: Colors.white),
              ),
              title: Text(route.name),
              subtitle: Text('${route.fromLocation} → ${route.toLocation}'),
              trailing: Text('₹${route.fare.toStringAsFixed(0)}'),
            )),
            if (_busRoutes.length > 5)
              Text(
                '... and ${_busRoutes.length - 5} more routes',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
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
}
