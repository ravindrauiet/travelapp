import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/map_service.dart';
import '../../models/metro_line.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/location_provider.dart';

class AdvancedRouteFinder extends StatefulWidget {
  const AdvancedRouteFinder({super.key});

  @override
  State<AdvancedRouteFinder> createState() => _AdvancedRouteFinderState();
}

class _AdvancedRouteFinderState extends State<AdvancedRouteFinder> {
  List<MetroStation> _stations = [];
  List<MetroStation> _filteredStations = [];
  MetroStation? _fromStation;
  MetroStation? _toStation;
  List<MetroStation> _route = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stations = await MapService.getAllMetroStations();
      setState(() {
        _stations = stations;
        _filteredStations = stations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stations: $e')),
      );
    }
  }

  void _filterStations(String query) {
    setState(() {
      _filteredStations = _stations
          .where((station) =>
              station.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _findRoute() async {
    if (_fromStation == null || _toStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both from and to stations')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final route = await MapService.findRoute(_fromStation!.id, _toStation!.id);
      setState(() {
        _route = route;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding route: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Route Finder'),
        backgroundColor: AppTheme.metroBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _stations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Selection Section
                Container(
                  padding: EdgeInsets.all(ResponsiveHelper.getCardPadding(context)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: _filterStations,
                        decoration: InputDecoration(
                          hintText: 'Search stations...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Station Selection
                      Row(
                        children: [
                          Expanded(
                            child: _buildStationSelector(
                              'From',
                              _fromStation,
                              (station) {
                                setState(() {
                                  _fromStation = station;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStationSelector(
                              'To',
                              _toStation,
                              (station) {
                                setState(() {
                                  _toStation = station;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Find Route Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _findRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.metroBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Find Route'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Results Section
                Expanded(
                  child: _route.isEmpty
                      ? _buildStationList()
                      : _buildRouteResult(),
                ),
              ],
            ),
    );
  }

  Widget _buildStationSelector(
    String label,
    MetroStation? selectedStation,
    Function(MetroStation) onStationSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showStationPicker(onStationSelected),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.train,
                  color: selectedStation != null ? AppTheme.metroBlue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedStation?.name ?? 'Select station',
                    style: TextStyle(
                      color: selectedStation != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStationPicker(Function(MetroStation) onStationSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Select Station',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredStations.length,
                  itemBuilder: (context, index) {
                    final station = _filteredStations[index];
                    return ListTile(
                      leading: Icon(
                        station.isInterchange ? Icons.swap_horiz : Icons.train,
                        color: station.isInterchange ? AppTheme.metroRed : AppTheme.metroBlue,
                      ),
                      title: Text(station.name),
                      subtitle: station.isInterchange
                          ? const Text('Interchange Station')
                          : null,
                      onTap: () {
                        onStationSelected(station);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStations.length,
      itemBuilder: (context, index) {
        final station = _filteredStations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              station.isInterchange ? Icons.swap_horiz : Icons.train,
              color: station.isInterchange ? AppTheme.metroRed : AppTheme.metroBlue,
            ),
            title: Text(station.name),
            subtitle: station.isInterchange
                ? const Text('Interchange Station')
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Could add station details here
            },
          ),
        );
      },
    );
  }

  Widget _buildRouteResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _route.length,
              itemBuilder: (context, index) {
                final station = _route[index];
                final isFirst = index == 0;
                final isLast = index == _route.length - 1;
                
                return Row(
                  children: [
                    // Station marker
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isFirst || isLast ? AppTheme.metroRed : AppTheme.metroBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        isFirst ? Icons.play_arrow : isLast ? Icons.stop : Icons.circle,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Station info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (station.isInterchange)
                            const Text(
                              'Interchange Station',
                              style: TextStyle(
                                color: AppTheme.metroRed,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Step number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.metroBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.metroBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


