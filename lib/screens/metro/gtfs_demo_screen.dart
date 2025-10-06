import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../services/gtfs_data_parser.dart';
import '../../utils/app_theme.dart';

class GTFSDemoScreen extends StatefulWidget {
  const GTFSDemoScreen({super.key});

  @override
  State<GTFSDemoScreen> createState() => _GTFSDemoScreenState();
}

class _GTFSDemoScreenState extends State<GTFSDemoScreen> {
  bool _isLoading = true;
  String _status = 'Initializing GTFS data...';
  int _totalStations = 0;
  int _totalLines = 0;
  int _totalTrips = 0;
  List<String> _sampleStations = [];
  List<String> _sampleLines = [];

  @override
  void initState() {
    super.initState();
    _loadGTFSData();
  }

  Future<void> _loadGTFSData() async {
    try {
      setState(() {
        _status = 'Loading agencies...';
      });
      final agencies = await GTFSDataParser.getAgencies();
      
      setState(() {
        _status = 'Loading stops...';
      });
      final stops = await GTFSDataParser.getStops();
      
      setState(() {
        _status = 'Loading routes...';
      });
      final routes = await GTFSDataParser.getRoutes();
      
      setState(() {
        _status = 'Loading trips...';
      });
      final trips = await GTFSDataParser.getTrips();
      
      setState(() {
        _status = 'Loading metro stations...';
      });
      final metroStations = await GTFSDataParser.getMetroStations();
      
      setState(() {
        _status = 'Loading metro lines...';
      });
      final metroLines = await GTFSDataParser.getMetroLines();
      
      setState(() {
        _isLoading = false;
        _status = 'GTFS data loaded successfully!';
        _totalStations = metroStations.length;
        _totalLines = metroLines.length;
        _totalTrips = trips.length;
        _sampleStations = metroStations.take(10).map((s) => s.name).toList();
        _sampleLines = metroLines.map((l) => l.name).toList();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error loading GTFS data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GTFS Data Integration Demo'),
        backgroundColor: AppTheme.metroBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _buildDataView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.metroBlue,
          ),
          const SizedBox(height: 24),
          Text(
            _status,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            color: _status.contains('Error') 
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _status.contains('Error') ? Icons.error : Icons.check_circle,
                    color: _status.contains('Error') ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _status.contains('Error') ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Statistics
          const Text(
            'GTFS Data Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Metro Stations',
                  _totalStations.toString(),
                  Icons.train,
                  AppTheme.metroBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Metro Lines',
                  _totalLines.toString(),
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
                  'Active Trips',
                  _totalTrips.toString(),
                  Icons.directions_transit,
                  AppTheme.metroGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Data Source',
                  'GTFS',
                  Icons.database,
                  AppTheme.metroViolet,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sample Data
          const Text(
            'Sample Metro Lines',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._sampleLines.map((line) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.metroBlue,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(line),
              subtitle: Text('Metro Line'),
            ),
          )),
          
          const SizedBox(height: 24),
          
          const Text(
            'Sample Metro Stations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._sampleStations.map((station) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.location_on, color: AppTheme.metroBlue),
              title: Text(station),
              subtitle: const Text('Metro Station'),
            ),
          )),
          
          const SizedBox(height: 32),
          
          // Test Route Finding
          const Text(
            'Test Route Finding',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ElevatedButton(
            onPressed: _testRouteFinding,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.metroBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Test Route: Dwarka Sector 21 → Rajiv Chowk',
              style: TextStyle(color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: _testFareCalculation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.metroRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Test Fare Calculation',
              style: TextStyle(color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Refresh Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _status = 'Refreshing GTFS data...';
                });
                _loadGTFSData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.metroGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Refresh GTFS Data',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _testRouteFinding() async {
    try {
      final metroProvider = context.read<MetroProvider>();
      final routes = await metroProvider.findRoute('Dwarka Sector 21', 'Rajiv Chowk');
      
      if (routes.isNotEmpty) {
        final route = routes.first;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Route Found!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From: ${route.fromStation}'),
                Text('To: ${route.toStation}'),
                Text('Total Time: ${route.totalTime} minutes'),
                Text('Total Fare: ₹${route.totalFare.toStringAsFixed(0)}'),
                Text('Total Stations: ${route.totalStations}'),
                if (route.interchangeStations.isNotEmpty)
                  Text('Interchange: ${route.interchangeStations.join(', ')}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog('No route found');
      }
    } catch (e) {
      _showErrorDialog('Error finding route: $e');
    }
  }

  void _testFareCalculation() async {
    try {
      final metroProvider = context.read<MetroProvider>();
      final fare = metroProvider.calculateFare('Dwarka Sector 21', 'Rajiv Chowk');
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fare Calculation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('From: Dwarka Sector 21'),
              const Text('To: Rajiv Chowk'),
              Text('Fare: ₹${fare?.toStringAsFixed(0) ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Error calculating fare: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
