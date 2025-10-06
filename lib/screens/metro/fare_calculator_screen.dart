import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/metro_provider.dart';
import '../../utils/app_theme.dart';

class MetroFareCalculatorScreen extends StatefulWidget {
  const MetroFareCalculatorScreen({super.key});

  @override
  State<MetroFareCalculatorScreen> createState() => _MetroFareCalculatorScreenState();
}

class _MetroFareCalculatorScreenState extends State<MetroFareCalculatorScreen> {
  String? _fromStation;
  String? _toStation;
  double? _calculatedFare;
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

          return Padding(
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
                          'Loaded ${metroProvider.stations.length} stations from GTFS data',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // From Station Dropdown
                const Text(
                  'From Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _fromStation,
                  decoration: const InputDecoration(
                    hintText: 'Select starting station',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: metroProvider.stations.map((station) {
                    return DropdownMenuItem<String>(
                      value: station.name,
                      child: Text(station.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _fromStation = value;
                      _calculatedFare = null;
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // To Station Dropdown
                const Text(
                  'To Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _toStation,
                  decoration: const InputDecoration(
                    hintText: 'Select destination station',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: metroProvider.stations.map((station) {
                    return DropdownMenuItem<String>(
                      value: station.name,
                      child: Text(station.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _toStation = value;
                      _calculatedFare = null;
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
                
                // Result Card
                if (_calculatedFare != null)
                  Card(
                    color: AppTheme.metroBlue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.calculate,
                            size: 48,
                            color: AppTheme.metroBlue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '₹${_calculatedFare!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.metroBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Estimated Fare',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFareInfo('From', _fromStation!),
                              const Icon(Icons.arrow_forward, color: Colors.grey),
                              _buildFareInfo('To', _toStation!),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                        _buildFareRow('0-2 km', '₹10'),
                        _buildFareRow('2-5 km', '₹20'),
                        _buildFareRow('5-12 km', '₹30'),
                        _buildFareRow('12-21 km', '₹40'),
                        _buildFareRow('21-32 km', '₹50'),
                        _buildFareRow('32+ km', '₹60'),
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
            context.go('/weather');
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
          icon: Icon(Icons.wb_sunny),
          label: 'Weather',
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
    
    // Simulate calculation delay
    await Future.delayed(const Duration(seconds: 1));
    
    final metroProvider = context.read<MetroProvider>();
    final fare = metroProvider.calculateFare(_fromStation!, _toStation!);
    
    setState(() {
      _calculatedFare = fare;
      _isCalculating = false;
    });
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
