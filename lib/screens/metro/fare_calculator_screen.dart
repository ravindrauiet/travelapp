import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/metro_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/searchable_station_dropdown.dart';

class MetroFareCalculatorScreen extends StatefulWidget {
  const MetroFareCalculatorScreen({super.key});

  @override
  State<MetroFareCalculatorScreen> createState() => _MetroFareCalculatorScreenState();
}

class _MetroFareCalculatorScreenState extends State<MetroFareCalculatorScreen> {
  String? _fromStation;
  String? _toStation;
  Map<String, dynamic>? _fareData;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    // Load stations when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Fare Calculator'),
        backgroundColor: AppTheme.metroBlue,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Consumer<MetroProvider>(
        builder: (context, metroProvider, child) {
          // Show loading state while stations are being loaded
          if (metroProvider.isLoading && metroProvider.stations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading metro stations from GTFS data...'),
                ],
              ),
            );
          }

          // Show error state if there's an error
          if (metroProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${metroProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => metroProvider.loadStations(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
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
                            Icon(Icons.info_outline, color: AppTheme.infoColor),
                            SizedBox(width: 8),
                            Text(
                              'Fare Calculator',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your starting and destination stations to calculate the exact fare for your metro journey.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loaded ${metroProvider.stations.length} stations from data',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (metroProvider.stations.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Sample stations: ${metroProvider.stations.take(3).map((s) => s.name).join(', ')}...',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // From Station Search
                const Text(
                  'From Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SearchableStationDropdown(
                  stations: metroProvider.stations,
                  selectedStation: _fromStation,
                  hintText: 'Search and select starting station',
                  prefixIcon: Icons.location_on,
                  onChanged: (value) {
                    setState(() {
                      _fromStation = value;
                      _fareData = null;
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // To Station Search
                const Text(
                  'To Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SearchableStationDropdown(
                  stations: metroProvider.stations,
                  selectedStation: _toStation,
                  hintText: 'Search and select destination station',
                  prefixIcon: Icons.flag,
                  onChanged: (value) {
                    setState(() {
                      _toStation = value;
                      _fareData = null;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Calculate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canCalculate() ? _calculateFare : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.metroBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isCalculating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Calculate Fare',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Fare Results - Two Small Cards Side by Side
                if (_fareData != null)
                  Row(
                    children: [
                      // Normal Ticket Fare Card
                      Expanded(
                        child: Card(
                          color: Colors.orange.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.confirmation_number,
                                  size: 32,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_fareData!['ticketFare']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ticket Fare',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Smart Card Fare Card
                      Expanded(
                        child: Card(
                          color: AppTheme.metroBlue.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.credit_card,
                                  size: 32,
                                  color: AppTheme.metroBlue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_fareData!['smartCardFare']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.metroBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Smart Card',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Save ₹${_fareData!['totalSavings'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
                
                // Fare Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fare Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFareRow('0-2 km', '₹11'),
                        _buildFareRow('2-5 km', '₹21'),
                        _buildFareRow('5-12 km', '₹32'),
                        _buildFareRow('12-21 km', '₹43'),
                        _buildFareRow('21-32 km', '₹54'),
                        _buildFareRow('32+ km', '₹64'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, 1),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.metroBlue, AppTheme.metroRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.train,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Metro Fare Calculator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Calculate metro fares',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: AppTheme.primaryColor),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.train, color: AppTheme.metroBlue),
            title: const Text('Metro Services'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate, color: AppTheme.metroBlue),
            title: const Text('Fare Calculator'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/fare-calculator');
            },
          ),
          ListTile(
            leading: const Icon(Icons.route, color: AppTheme.metroRed),
            title: const Text('Route Finder'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/route-finder');
            },
          ),
          ListTile(
            leading: const Icon(Icons.update, color: AppTheme.metroGreen),
            title: const Text('Live Updates'),
            onTap: () {
              Navigator.pop(context);
              context.go('/metro/live-updates');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.directions_bus, color: AppTheme.infoColor),
            title: const Text('Bus Services'),
            onTap: () {
              Navigator.pop(context);
              context.go('/bus');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_taxi, color: AppTheme.accentColor),
            title: const Text('Other Transport'),
            onTap: () {
              Navigator.pop(context);
              context.go('/transport');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/metro');
            break;
          case 2:
            context.go('/bus');
            break;
          case 3:
            context.go('/transport');
            break;
          case 4:
            context.go('/games/snake');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.train),
          label: 'Metro',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus),
          label: 'Bus',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_taxi),
          label: 'Transport',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.games),
          label: 'Games',
        ),
      ],
    );
  }

  bool _canCalculate() {
    return _fromStation != null && _toStation != null && !_isCalculating;
  }

  void _calculateFare() async {
    if (!_canCalculate()) return;
    
    setState(() {
      _isCalculating = true;
    });
    
    try {
      final metroProvider = context.read<MetroProvider>();
      final fareData = await metroProvider.calculateFare(_fromStation!, _toStation!);
      
      setState(() {
        _fareData = fareData;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating fare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFareInfo(String label, String station) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          station,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFareRow(String distance, String fare) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(distance),
          Text(
            fare,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.metroBlue,
            ),
          ),
        ],
      ),
    );
  }
}
