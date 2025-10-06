import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/map_service.dart';
import '../../services/gtfs_service.dart';
import '../../models/bus_route.dart';
import '../../models/gtfs_models.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/location_provider.dart';

class BusMapScreen extends StatefulWidget {
  const BusMapScreen({super.key});

  @override
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> {
  GoogleMapController? _mapController;
  List<BusRoute> _busRoutes = [];
  List<GTFSVehiclePosition> _realTimeVehicles = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _showRealTime = true;
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    _loadBusData();
  }

  Future<void> _loadBusData() async {
    try {
      final busRoutes = await MapService.getBusRoutes();
      final realTimeVehicles = await GTFSService.getRealTimeVehiclePositions();
      
      setState(() {
        _busRoutes = busRoutes;
        _realTimeVehicles = realTimeVehicles;
        _isLoading = false;
      });
      
      _updateMapMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bus data: $e')),
      );
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    for (final route in _busRoutes) {
      final isSelected = _selectedRouteId == null || _selectedRouteId == route.id;
      final opacity = isSelected ? 1.0 : 0.3;
      
      // Add bus stop markers
      for (final stop in route.stops) {
        markers.add(
          Marker(
            markerId: MarkerId('bus_${stop.id}'),
            position: LatLng(stop.latitude, stop.longitude),
            infoWindow: InfoWindow(
              title: stop.name,
              snippet: 'Bus Route ${route.number} • ${route.name}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            alpha: opacity,
          ),
        );
      }

      // Add bus route polylines
      if (route.stops.length > 1) {
        final points = route.stops
            .map((stop) => LatLng(stop.latitude, stop.longitude))
            .toList();
        
        polylines.add(
          Polyline(
            polylineId: PolylineId('bus_route_${route.id}'),
            points: points,
            color: Colors.green.withOpacity(opacity),
            width: 4,
            patterns: [PatternItem.dot, PatternItem.gap(5)],
          ),
        );
      }
    }

    // Add real-time vehicle markers
    if (_showRealTime) {
      for (final vehicle in _realTimeVehicles) {
        final isVehicleSelected = _selectedRouteId == null || 
            _selectedRouteId == vehicle.routeId;
        
        if (isVehicleSelected) {
          markers.add(
            Marker(
              markerId: MarkerId('vehicle_${vehicle.vehicleId}'),
              position: LatLng(vehicle.latitude, vehicle.longitude),
              infoWindow: InfoWindow(
                title: 'Bus ${vehicle.routeId}',
                snippet: 'Speed: ${vehicle.speed?.toStringAsFixed(1) ?? 'N/A'} km/h\n'
                    'Status: ${_getVehicleStatus(vehicle.currentStatus ?? 'UNKNOWN')}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              rotation: vehicle.bearing ?? 0,
            ),
          );
        }
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  String _getVehicleStatus(String status) {
    switch (status) {
      case 'INCOMING':
        return 'Incoming';
      case 'STOPPED':
        return 'Stopped';
      case 'IN_TRANSIT':
        return 'In Transit';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delhi Bus Routes'),
        backgroundColor: AppTheme.infoColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showRealTime ? Icons.location_on : Icons.location_off),
            onPressed: () {
              setState(() {
                _showRealTime = !_showRealTime;
              });
              _updateMapMarkers();
            },
            tooltip: _showRealTime ? 'Hide Real-Time Buses' : 'Show Real-Time Buses',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
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
                    zoom: 11.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
                if (isTablet)
                  Positioned(
                    left: 16,
                    top: 16,
                    child: _buildRouteSelector(),
                  )
                else
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildRouteSelector(),
                  ),
              ],
            ),
    );
  }

  Widget _buildRouteSelector() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bus Routes',
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
              itemCount: _busRoutes.length + 1, // +1 for "All Routes"
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildRouteChip('All Routes', null);
                }
                
                final route = _busRoutes[index - 1];
                return _buildRouteChip('Route ${route.number}', route.id);
              },
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
          _updateMapMarkers();
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

  Future<void> _goToCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.getCurrentLocation();
    
    if (locationProvider.currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          ),
        ),
      );
    }
  }
}
