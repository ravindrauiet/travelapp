import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/gtfs_service.dart';
import '../../models/gtfs_models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_kit.dart';

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
                'Status: ${_getStatusText(vehicle.currentStatus ?? 'UNKNOWN')}',
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
      int.parse('FF$colorHex', radix: 16);
      // Convert to hue value (simplified)
      return BitmapDescriptor.hueBlue; // For demo, return blue
    } catch (e) {
      return BitmapDescriptor.hueBlue;
    }
  }

  String _getStatusText(String status) {
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

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (_autoRefresh && mounted) {
        _updateVehiclePositions();
        _startAutoRefresh();
      }
    });
  }

  static const _busGreen = Color(0xFF059669);

  List<BoxShadow> get _floatingShadow => [
        BoxShadow(
          color: AppTheme.brandNight.withValues(alpha: 0.16),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(
          children: [
            GradientHeader(
              title: 'Live Bus Tracker',
              subtitle: 'Real-time positions, refreshed every 30s',
              icon: Icons.radar_rounded,
              gradient: AppTheme.emeraldGradient,
              illustration: 'assets/images/illus_bus.svg',
              actions: [
                HeaderIconButton(
                  icon: _autoRefresh ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onTap: () {
                    setState(() {
                      _autoRefresh = !_autoRefresh;
                    });
                    if (_autoRefresh) {
                      _startAutoRefresh();
                    }
                  },
                  tooltip: _autoRefresh ? 'Pause Auto Refresh' : 'Start Auto Refresh',
                ),
                const SizedBox(width: 8),
                HeaderIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: _updateVehiclePositions,
                  tooltip: 'Refresh Now',
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(strokeWidth: 3, color: _busGreen),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Locating buses near you…',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
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
                              color: p.card,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: p.border),
                              boxShadow: _floatingShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const IconBubble(
                                      icon: Icons.filter_alt_rounded,
                                      color: _busGreen,
                                      size: 32,
                                      radius: 10,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Filter by Route',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 38,
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
                              color: p.card,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: p.border),
                              boxShadow: _floatingShadow,
                            ),
                            child: Row(
                              children: [
                                const IconBubble(
                                  icon: Icons.directions_bus_rounded,
                                  color: _busGreen,
                                  filled: true,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active Buses: ${_vehicles.length}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Last Update: ${_getLastUpdateTime()}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: p.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TagPill(
                                  label: _autoRefresh ? 'AUTO ON' : 'AUTO OFF',
                                  color: _autoRefresh ? _busGreen : p.textTertiary,
                                  icon: _autoRefresh ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                                ),
                              ],
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

  Widget _buildRouteChip(String label, String? routeId) {
    final isSelected = _selectedRouteId == routeId;
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRouteId = routeId;
          });
          _updateVehiclePositions();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.emeraldGradient : null,
            color: isSelected ? null : p.cardAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : p.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : p.textSecondary,
              fontWeight: FontWeight.w700,
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
        .reduce((a, b) => DateTime.fromMillisecondsSinceEpoch(a).isAfter(DateTime.fromMillisecondsSinceEpoch(b)) ? a : b);
    
    final now = DateTime.now();
    final difference = now.difference(DateTime.fromMillisecondsSinceEpoch(latestUpdate));
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}



