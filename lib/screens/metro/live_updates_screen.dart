import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../models/metro_station.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';

class MetroLiveUpdatesScreen extends StatefulWidget {
  const MetroLiveUpdatesScreen({super.key});

  @override
  State<MetroLiveUpdatesScreen> createState() => _MetroLiveUpdatesScreenState();
}

class _MetroLiveUpdatesScreenState extends State<MetroLiveUpdatesScreen> with TickerProviderStateMixin {
  String _selectedStation = '';
  String _selectedLine = '';
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  final List<String> _popularStations = [
    'Rajiv Chowk', 'Kashmere Gate', 'Central Secretariat', 'New Delhi',
    'Connaught Place', 'Karol Bagh', 'Lajpat Nagar', 'Hauz Khas',
    'Saket', 'Dwarka', 'Vaishali', 'Noida City Centre'
  ];

  final List<String> _metroLines = [
    'Red Line', 'Blue Line', 'Yellow Line', 'Green Line', 
    'Violet Line', 'Pink Line', 'Magenta Line', 'Airport Express'
  ];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadLiveUpdates();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Metro Live Info'),
        backgroundColor: AppTheme.metroGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: AnimatedBuilder(
              animation: _refreshController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshController.value * 2 * 3.14159,
                  child: const Icon(Icons.refresh),
                );
              },
            ),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildQuickActions(),
            _buildStationSelector(),
            _buildTrainTimings(),
            _buildCrowdDensity(),
            _buildPlatformInfo(),
            _buildEmergencyInfo(),
          ],
        ),
      ),
    );
  }

  void _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    
    _refreshController.forward().then((_) {
      _refreshController.reset();
    });
    
    await context.read<MetroProvider>().loadLiveUpdates();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.metroGreen, AppTheme.metroGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.metroGreen.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Find Nearest Station',
                  Icons.location_on,
                  () => _findNearestStation(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Emergency',
                  Icons.emergency,
                  () => _showEmergencyContacts(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Metro Card Balance',
                  Icons.credit_card,
                  () => _checkMetroCardBalance(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Lost & Found',
                  Icons.search,
                  () => _showLostAndFound(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.train, color: AppTheme.metroGreen),
              const SizedBox(width: 8),
              const Text(
                'Select Station',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedStation.isEmpty ? null : _selectedStation,
            decoration: InputDecoration(
              hintText: 'Choose a station',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.location_city),
            ),
            items: _popularStations.map((station) {
              return DropdownMenuItem(
                value: station,
                child: Text(station),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStation = value ?? '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrainTimings() {
    if (_selectedStation.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Select a station to see train timings',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppTheme.metroBlue),
              const SizedBox(width: 8),
              const Text(
                'Next Trains',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.metroBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedStation,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.metroBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrainTimingRow('Towards Rithala', '2 min', 'Platform 1'),
          _buildTrainTimingRow('Towards Shaheed Sthal', '5 min', 'Platform 2'),
          _buildTrainTimingRow('Towards Rithala', '8 min', 'Platform 1'),
          _buildTrainTimingRow('Towards Shaheed Sthal', '12 min', 'Platform 2'),
        ],
      ),
    );
  }

  Widget _buildTrainTimingRow(String destination, String time, String platform) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  platform,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.metroBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.metroBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdDensity() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Crowd Density by Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeBasedCrowdChart(),
        ],
      ),
    );
  }

  Widget _buildTimeBasedCrowdChart() {
    final currentHour = DateTime.now().hour;
    
    return Column(
      children: [
        // Current time indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.metroGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.metroGreen.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 16, color: AppTheme.metroGreen),
              const SizedBox(width: 8),
              Text(
                'Current Time: ${currentHour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.metroGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Time slots with crowd levels
        _buildCrowdTimeSlot('6:00 AM - 9:00 AM', 'High', Colors.red, 'Peak Morning'),
        _buildCrowdTimeSlot('9:00 AM - 11:00 AM', 'Medium', Colors.orange, 'Moderate'),
        _buildCrowdTimeSlot('11:00 AM - 2:00 PM', 'Low', Colors.green, 'Light'),
        _buildCrowdTimeSlot('2:00 PM - 5:00 PM', 'Medium', Colors.orange, 'Moderate'),
        _buildCrowdTimeSlot('5:00 PM - 8:00 PM', 'High', Colors.red, 'Peak Evening'),
        _buildCrowdTimeSlot('8:00 PM - 11:00 PM', 'Low', Colors.green, 'Light'),
        _buildCrowdTimeSlot('11:00 PM - 6:00 AM', 'Very Low', Colors.blue, 'Minimal'),
      ],
    );
  }

  Widget _buildCrowdTimeSlot(String timeRange, String level, Color color, String description) {
    final currentHour = DateTime.now().hour;
    bool isCurrentTime = false;
    
    // Check if current time falls in this range
    if (timeRange.contains('6:00 AM - 9:00 AM') && currentHour >= 6 && currentHour < 9) {
      isCurrentTime = true;
    } else if (timeRange.contains('9:00 AM - 11:00 AM') && currentHour >= 9 && currentHour < 11) {
      isCurrentTime = true;
    } else if (timeRange.contains('11:00 AM - 2:00 PM') && currentHour >= 11 && currentHour < 14) {
      isCurrentTime = true;
    } else if (timeRange.contains('2:00 PM - 5:00 PM') && currentHour >= 14 && currentHour < 17) {
      isCurrentTime = true;
    } else if (timeRange.contains('5:00 PM - 8:00 PM') && currentHour >= 17 && currentHour < 20) {
      isCurrentTime = true;
    } else if (timeRange.contains('8:00 PM - 11:00 PM') && currentHour >= 20 && currentHour < 23) {
      isCurrentTime = true;
    } else if (timeRange.contains('11:00 PM - 6:00 AM') && (currentHour >= 23 || currentHour < 6)) {
      isCurrentTime = true;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentTime ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentTime ? color : Colors.grey[200]!,
          width: isCurrentTime ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Time range
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeRange,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCurrentTime ? color : Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Crowd level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Current time indicator
          if (isCurrentTime) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.metroGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location,
                size: 12,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildPlatformInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.metroGreen),
              const SizedBox(width: 8),
              const Text(
                'Platform Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Lift Available', 'Yes', Icons.elevator),
          _buildInfoRow('Escalator', 'Working', Icons.stairs),
          _buildInfoRow('Wheelchair Access', 'Available', Icons.accessible),
          _buildInfoRow('Parking', 'Available', Icons.local_parking),
          _buildInfoRow('ATM', 'Available', Icons.atm),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEmergencyContact('Metro Helpline', '155370', Icons.phone),
          _buildEmergencyContact('Medical Emergency', '102', Icons.medical_services),
          _buildEmergencyContact('Security', '100', Icons.security),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String service, String number, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              service,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _callNumber(number),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _findNearestStation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finding nearest metro station...'),
        backgroundColor: AppTheme.metroGreen,
      ),
    );
  }

  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contacts'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone, color: Colors.red),
              title: Text('Metro Helpline'),
              subtitle: Text('155370'),
            ),
            ListTile(
              leading: Icon(Icons.medical_services, color: Colors.red),
              title: Text('Medical Emergency'),
              subtitle: Text('102'),
            ),
            ListTile(
              leading: Icon(Icons.security, color: Colors.red),
              title: Text('Security'),
              subtitle: Text('100'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _checkMetroCardBalance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metro card balance check feature coming soon!'),
        backgroundColor: AppTheme.metroBlue,
      ),
    );
  }

  void _showLostAndFound() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lost & Found: Contact station staff or call 155370'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _callNumber(String number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $number...'),
        backgroundColor: Colors.red,
      ),
    );
  }

}
