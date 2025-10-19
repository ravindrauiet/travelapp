import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/map_service.dart';
import '../../models/metro_line.dart';
import '../../models/bus_route.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/location_provider.dart';

class MetroMapScreen extends StatefulWidget {
  const MetroMapScreen({super.key});

  @override
  State<MetroMapScreen> createState() => _MetroMapScreenState();
}

class _MetroMapScreenState extends State<MetroMapScreen> {
  GoogleMapController? _mapController;
  List<MetroLine> _metroLines = [];
  List<BusRoute> _busRoutes = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _showMetro = true;
  bool _showBus = false;
  bool _isLoading = true;
  bool _googleMapsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleMapsAvailability();
    _loadMapData();
  }

  void _checkGoogleMapsAvailability() {
    // For web, Google Maps might not be available
    // We'll assume it's not available and show fallback
    // This can be enhanced later with proper API key detection
    _googleMapsAvailable = false;
  }

  Future<void> _loadMapData() async {
    try {
      final metroLines = await MapService.getMetroLines();
      final busRoutes = await MapService.getBusRoutes();
      
      setState(() {
        _metroLines = metroLines;
        _busRoutes = busRoutes;
        _isLoading = false;
      });
      
      _updateMapMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading map data: $e')),
      );
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    if (_showMetro) {
      // Add metro stations and lines
      for (final line in _metroLines) {
        final color = Color(int.parse(line.color.replaceFirst('#', '0xFF')));
        
        // Add station markers
        for (int i = 0; i < line.stations.length; i++) {
          final station = line.stations[i];
          markers.add(
            Marker(
              markerId: MarkerId('metro_${station.id}'),
              position: LatLng(station.latitude, station.longitude),
              infoWindow: InfoWindow(
                title: station.name,
                snippet: '${line.name} • ${station.isInterchange ? 'Interchange' : 'Station'}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                station.isInterchange ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
              ),
            ),
          );
        }

        // Add metro line polylines
        if (line.stations.length > 1) {
          final points = line.stations
              .map((station) => LatLng(station.latitude, station.longitude))
              .toList();
          
          polylines.add(
            Polyline(
              polylineId: PolylineId('metro_line_${line.id}'),
              points: points,
              color: color,
              width: 6,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        }
      }
    }

    if (_showBus) {
      // Add bus stops and routes
      for (final route in _busRoutes) {
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
              color: Colors.green,
              width: 4,
              patterns: [PatternItem.dot, PatternItem.gap(5)],
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

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delhi Metro & Bus Map'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMapContent(),
    );
  }

  Widget _buildMapContent() {
    return Stack(
      children: [
        // Try to show Google Map, fallback to message if not available
        _buildGoogleMapOrFallback(),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildToggleButton(
                'Metro',
                _showMetro,
                Icons.train,
                () {
                  setState(() {
                    _showMetro = !_showMetro;
                  });
                  _updateMapMarkers();
                },
              ),
              const SizedBox(height: 8),
              _buildToggleButton(
                'Bus',
                _showBus,
                Icons.directions_bus,
                () {
                  setState(() {
                    _showBus = !_showBus;
                  });
                  _updateMapMarkers();
                },
              ),
            ],
          ),
        ),
        if (ResponsiveHelper.isTablet(context))
          Positioned(
            left: 16,
            top: 16,
            child: _buildLegend(),
          ),
      ],
    );
  }

  Widget _buildGoogleMapOrFallback() {
    if (!_googleMapsAvailable) {
      return _buildMapFallback();
    }
    
    return GoogleMap(
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
    );
  }

  Widget _buildMapFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 80,
                      color: AppTheme.metroBlue,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Metro Map',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.metroRed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Interactive map is not available in this version.\nUse our route finder for navigation assistance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/metro/route-finder');
                          },
                          icon: const Icon(Icons.route, size: 20),
                          label: const Text('Find Routes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.metroRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/metro/fare-calculator');
                          },
                          icon: const Icon(Icons.calculate, size: 20),
                          label: const Text('Calculate Fare'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.metroBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Available Features:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildFeatureChip('Route Planning', Icons.directions),
                        _buildFeatureChip('Fare Calculator', Icons.currency_rupee),
                        _buildFeatureChip('Station Info', Icons.info),
                        _buildFeatureChip('Live Updates', Icons.update),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.metroBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
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
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (_showMetro) ...[
            const Text(
              'Metro Lines:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._metroLines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Color(int.parse(line.color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    line.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
          ],
          if (_showBus) ...[
            const Text(
              'Bus Routes:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bus Routes',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ],
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




