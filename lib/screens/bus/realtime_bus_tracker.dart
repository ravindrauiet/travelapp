import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/gtfs_service.dart';
import '../../models/gtfs_models.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/location_provider.dart';

class RealtimeBusTracker extends StatefulWidget {
  const RealtimeBusTracker({super.key});

  @override
  State<RealtimeBusTracker> createState() => _RealtimeBusTrackerState();
}

class _RealtimeBusTrackerState extends State<RealtimeBusTracker> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<GTFSVehiclePosition> _vehicles = [];
  List<GTFSRoute> _routes = [];
  String? _selectedRouteId;
  bool _isLoading = true;
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefresh = false;
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await GTFSService.getRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
      
      await _updateVehiclePositions();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _updateVehiclePositions() async {
    try {
      List<GTFSVehiclePosition> vehicles;
      
      if (_selectedRouteId != null) {
        vehicles = await GTFSService.getVehiclesForRoute(_selectedRouteId!);
      } else {
        vehicles = await GTFSService.getRealTimeVehiclePositions();
      }
      
      setState(() {
        _vehicles = vehicles;
      });
      
      _updateMapMarkers();
    } catch (e) {
      print('Error updating vehicle positions: $e');
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};
    
    for (int i = 0; i < _vehicles.length; i++) {
      final vehicle = _vehicles[i];
      final route = _routes.firstWhere(
        (r) => r.routeId == vehicle.routeId,
        orElse: () => _routes.first,
      );
      
      markers.add(
        Marker(
          markerId: MarkerId('vehicle_${vehicle.vehicleId}'),
          position: LatLng(vehicle.latitude, vehicle.longitude),
          infoWindow: InfoWindow(
            title: 'Bus ${route.routeShortName}',
            snippet: 'Speed: ${vehicle.speed?.toStringAsFixed(1) ?? 'N/A'} km/h\n'
                'Status: ${_getStatusText(vehicle.currentStatus)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getRouteColor(route.routeColor),
          ),
          rotation: vehicle.bearing ?? 0,
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  double _getRouteColor(String? colorHex) {
    if (colorHex == null) return BitmapDescriptor.hueBlue;
    
    try {
      final color = int.parse('FF$colorHex', radix: 16);
      // Convert to hue value (simplified)
      return BitmapDescriptor.hueBlue; // For demo, return blue
    } catch (e) {
      return BitmapDescriptor.hueBlue;
    }
  }

  String _getStatusText(int? status) {
    switch (status) {
      case 0:
        return 'Incoming';
      case 1:
        return 'Stopped';
      case 2:
        return 'In Transit';
      default:
        return 'Unknown';
    }
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (_autoRefresh && mounted) {
        _updateVehiclePositions();
        _startAutoRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Bus Tracker'),
        backgroundColor: AppTheme.infoColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _autoRefresh = !_autoRefresh;
              });
              if (_autoRefresh) {
                _startAutoRefresh();
              }
            },
            tooltip: _autoRefresh ? 'Pause Auto Refresh' : 'Start Auto Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateVehiclePositions,
            tooltip: 'Refresh Now',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(28.6139, 77.2090), // Delhi center
                    zoom: 12.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
                
                // Route Filter
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter by Route',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _routes.length + 1, // +1 for "All Routes"
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildRouteChip('All Routes', null);
                              }
                              
                              final route = _routes[index - 1];
                              return _buildRouteChip(
                                'Route ${route.routeShortName}',
                                route.routeId,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Vehicle Count & Status
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Buses: ${_vehicles.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Last Update: ${_getLastUpdateTime()}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              _autoRefresh ? Icons.sync : Icons.sync_disabled,
                              color: _autoRefresh ? Colors.green : Colors.grey,
                            ),
                            Text(
                              _autoRefresh ? 'Auto Refresh ON' : 'Auto Refresh OFF',
                              style: TextStyle(
                                color: _autoRefresh ? Colors.green : Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRouteChip(String label, String? routeId) {
    final isSelected = _selectedRouteId == routeId;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRouteId = routeId;
          });
          _updateVehiclePositions();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.infoColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  String _getLastUpdateTime() {
    if (_vehicles.isEmpty) return 'Never';
    
    final latestUpdate = _vehicles
        .map((v) => v.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    
    final now = DateTime.now();
    final difference = now.difference(latestUpdate);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}



