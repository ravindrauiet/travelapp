import 'package:flutter/material.dart';
import '../../services/gtfs_service.dart';
import '../../models/gtfs_models.dart';
import '../../utils/app_theme.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _status = 'Ready to test API';
  List<String> _logs = [];
  List<GTFSVehiclePosition> _vehicles = [];
  List<GTFSRoute> _routes = [];
  List<GTFSStop> _stops = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print(message);
  }

  Future<void> _testRealTimeAPI() async {
    setState(() {
      _status = 'Testing Real-Time API...';
      _logs.clear();
    });

    _addLog('Starting real-time API test...');
    
    try {
      final vehicles = await GTFSService.getRealTimeVehiclePositions();
      setState(() {
        _vehicles = vehicles;
        _status = 'Real-Time API Test Complete';
      });
      _addLog('Found ${vehicles.length} vehicles');
      
      for (final vehicle in vehicles) {
        _addLog('Vehicle: ${vehicle.vehicleId} - Route: ${vehicle.routeId} - Lat: ${vehicle.latitude} - Lng: ${vehicle.longitude}');
      }
    } catch (e) {
      setState(() {
        _status = 'Real-Time API Test Failed';
      });
      _addLog('Error: $e');
    }
  }

  Future<void> _testStaticDataAPI() async {
    setState(() {
      _status = 'Testing Static Data API...';
      _logs.clear();
    });

    _addLog('Starting static data API test...');
    
    try {
      // Test routes
      _addLog('Fetching routes...');
      final routes = await GTFSService.getRoutes();
      setState(() {
        _routes = routes;
      });
      _addLog('Found ${routes.length} routes');
      
      // Test stops
      _addLog('Fetching stops...');
      final stops = await GTFSService.getStops();
      setState(() {
        _stops = stops;
      });
      _addLog('Found ${stops.length} stops');
      
      setState(() {
        _status = 'Static Data API Test Complete';
      });
    } catch (e) {
      setState(() {
        _status = 'Static Data API Test Failed';
      });
      _addLog('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test Screen'),
        backgroundColor: AppTheme.infoColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.infoColor),
              ),
              child: Text(
                _status,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testRealTimeAPI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.metroRed,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Real-Time API'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testStaticDataAPI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.metroBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Static Data API'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results Summary
            if (_vehicles.isNotEmpty || _routes.isNotEmpty || _stops.isNotEmpty) ...[
              const Text(
                'Results Summary:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('Vehicles: ${_vehicles.length}'),
              Text('Routes: ${_routes.length}'),
              Text('Stops: ${_stops.length}'),
              const SizedBox(height: 16),
            ],
            
            // Logs
            const Text(
              'API Logs:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




