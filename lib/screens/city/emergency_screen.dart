import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Numbers'),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Card(
              color: AppTheme.errorColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emergency, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Contacts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quick access to emergency services and helplines in Delhi. Tap to call directly.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Emergency Numbers
            const Text(
              'Emergency Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildEmergencyCard(
              'Police',
              '100',
              'Emergency police assistance',
              Icons.local_police,
              AppTheme.errorColor,
              () => _makeCall('100'),
            ),
            
            _buildEmergencyCard(
              'Ambulance',
              '102',
              'Medical emergency services',
              Icons.medical_services,
              Colors.red,
              () => _makeCall('102'),
            ),
            
            _buildEmergencyCard(
              'Fire Department',
              '101',
              'Fire and rescue services',
              Icons.local_fire_department,
              Colors.orange,
              () => _makeCall('101'),
            ),
            
            _buildEmergencyCard(
              'Women Helpline',
              '1091',
              'Women safety and support',
              Icons.female,
              Colors.pink,
              () => _makeCall('1091'),
            ),
            
            _buildEmergencyCard(
              'Child Helpline',
              '1098',
              'Child protection services',
              Icons.child_care,
              Colors.blue,
              () => _makeCall('1098'),
            ),
            
            _buildEmergencyCard(
              'Disaster Management',
              '108',
              'Disaster response team',
              Icons.warning,
              Colors.orange,
              () => _makeCall('108'),
            ),
            
            const SizedBox(height: 20),
            
            // Government Services
            const Text(
              'Government Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildEmergencyCard(
              'Delhi Police Control Room',
              '100',
              '24/7 police assistance',
              Icons.security,
              AppTheme.errorColor,
              () => _makeCall('100'),
            ),
            
            _buildEmergencyCard(
              'Traffic Police',
              '1095',
              'Traffic related complaints',
              Icons.traffic,
              Colors.orange,
              () => _makeCall('1095'),
            ),
            
            _buildEmergencyCard(
              'Municipal Corporation',
              '155304',
              'Civic issues and complaints',
              Icons.location_city,
              Colors.blue,
              () => _makeCall('155304'),
            ),
            
            _buildEmergencyCard(
              'Electricity Helpline',
              '1912',
              'Power supply issues',
              Icons.electrical_services,
              Colors.yellow,
              () => _makeCall('1912'),
            ),
            
            _buildEmergencyCard(
              'Water Helpline',
              '1916',
              'Water supply complaints',
              Icons.water_drop,
              Colors.cyan,
              () => _makeCall('1916'),
            ),
            
            const SizedBox(height: 20),
            
            // Healthcare
            const Text(
              'Healthcare Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildEmergencyCard(
              'AIIMS Emergency',
              '011-26588500',
              'All India Institute of Medical Sciences',
              Icons.local_hospital,
              Colors.red,
              () => _makeCall('01126588500'),
            ),
            
            _buildEmergencyCard(
              'Safdarjung Hospital',
              '011-26165000',
              'Government hospital emergency',
              Icons.local_hospital,
              Colors.red,
              () => _makeCall('01126165000'),
            ),
            
            _buildEmergencyCard(
              'Ram Manohar Lohia Hospital',
              '011-23365525',
              'Government hospital emergency',
              Icons.local_hospital,
              Colors.red,
              () => _makeCall('01123365525'),
            ),
            
            const SizedBox(height: 20),
            
            // Important Tips
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Important Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Keep emergency numbers saved in your phone\n'
                      '• Stay calm and provide clear information\n'
                      '• Know your exact location when calling\n'
                      '• Keep important documents handy\n'
                      '• Inform family/friends about your location',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(String title, String number, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Icon(Icons.phone, size: 16, color: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _makeCall(String number) async {
    final url = 'tel:$number';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
