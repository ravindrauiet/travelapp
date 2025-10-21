import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class TouristSpotsScreen extends StatefulWidget {
  const TouristSpotsScreen({super.key});

  @override
  State<TouristSpotsScreen> createState() => _TouristSpotsScreenState();
}

class _TouristSpotsScreenState extends State<TouristSpotsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Monuments', 'Markets', 'Parks', 'Museums', 'Religious', 'Entertainment'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourist Spots'),
        backgroundColor: AppTheme.metroMagenta,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                        Icon(Icons.place, color: AppTheme.metroMagenta),
                        SizedBox(width: 8),
                        Text(
                          'Delhi Tourist Attractions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore famous monuments, markets, and attractions in Delhi with detailed information and directions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Categories
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildCategoryCard('Monuments', Icons.account_balance, AppTheme.metroRed, () => _showMonuments(context)),
                _buildCategoryCard('Markets', Icons.shopping_bag, AppTheme.metroOrange, () => _showMarkets(context)),
                _buildCategoryCard('Parks', Icons.park, AppTheme.metroGreen, () => _showParks(context)),
                _buildCategoryCard('Museums', Icons.museum, AppTheme.metroBlue, () => _showMuseums(context)),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Popular Attractions
            const Text(
              'Popular Attractions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildAttractionCard(
              'Red Fort',
              'Historic fort and UNESCO World Heritage Site',
              'Old Delhi',
              '9:00 AM - 6:00 PM',
              '₹50',
              Icons.account_balance,
              AppTheme.metroRed,
              () => _openMaps('Red Fort, Delhi'),
            ),
            
            _buildAttractionCard(
              'India Gate',
              'War memorial and iconic landmark',
              'Central Delhi',
              '24 Hours',
              'Free',
              Icons.flag,
              AppTheme.metroBlue,
              () => _openMaps('India Gate, Delhi'),
            ),
            
            _buildAttractionCard(
              'Qutub Minar',
              'Tallest brick minaret in the world',
              'Mehrauli',
              '6:00 AM - 6:00 PM',
              '₹40',
              Icons.location_city,
              AppTheme.metroOrange,
              () => _openMaps('Qutub Minar, Delhi'),
            ),
            
            _buildAttractionCard(
              'Lotus Temple',
              'Bahá\'í House of Worship',
              'Kalkaji',
              '9:00 AM - 7:00 PM',
              'Free',
              Icons.temple_buddhist,
              AppTheme.metroGreen,
              () => _openMaps('Lotus Temple, Delhi'),
            ),
            
            _buildAttractionCard(
              'Chandni Chowk',
              'Historic market and food street',
              'Old Delhi',
              '10:00 AM - 8:00 PM',
              'Free',
              Icons.shopping_bag,
              AppTheme.metroPink,
              () => _openMaps('Chandni Chowk, Delhi'),
            ),
            
            _buildAttractionCard(
              'Connaught Place',
              'Commercial and business hub',
              'Central Delhi',
              '10:00 AM - 10:00 PM',
              'Free',
              Icons.business,
              AppTheme.metroViolet,
              () => _openMaps('Connaught Place, Delhi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttractionCard(String name, String description, String location, String timings, String price, IconData icon, Color color, VoidCallback onTap) {
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
                      name,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          timings,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.attach_money, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonuments(BuildContext context) {
    _showCategoryModal(context, 'Monuments', [
      {'name': 'Red Fort', 'description': 'Historic fort and UNESCO World Heritage Site'},
      {'name': 'Qutub Minar', 'description': 'Tallest brick minaret in the world'},
      {'name': 'Humayun\'s Tomb', 'description': 'Mughal emperor\'s tomb'},
      {'name': 'Jama Masjid', 'description': 'Largest mosque in India'},
      {'name': 'India Gate', 'description': 'War memorial and iconic landmark'},
    ]);
  }

  void _showMarkets(BuildContext context) {
    _showCategoryModal(context, 'Markets', [
      {'name': 'Chandni Chowk', 'description': 'Historic market and food street'},
      {'name': 'Connaught Place', 'description': 'Commercial and business hub'},
      {'name': 'Sarojini Nagar', 'description': 'Fashion and clothing market'},
      {'name': 'Lajpat Nagar', 'description': 'Textile and fashion market'},
      {'name': 'Karol Bagh', 'description': 'Electronics and fashion market'},
    ]);
  }

  void _showParks(BuildContext context) {
    _showCategoryModal(context, 'Parks', [
      {'name': 'Lodi Gardens', 'description': 'Historic park with tombs'},
      {'name': 'India Gate Lawns', 'description': 'Popular picnic spot'},
      {'name': 'Garden of Five Senses', 'description': 'Themed park with sculptures'},
      {'name': 'Nehru Park', 'description': 'Green space in Chanakyapuri'},
      {'name': 'Deer Park', 'description': 'Park with deer and other animals'},
    ]);
  }

  void _showMuseums(BuildContext context) {
    _showCategoryModal(context, 'Museums', [
      {'name': 'National Museum', 'description': 'India\'s largest museum'},
      {'name': 'Railway Museum', 'description': 'Railway heritage museum'},
      {'name': 'Crafts Museum', 'description': 'Traditional Indian crafts'},
      {'name': 'Air Force Museum', 'description': 'Aviation history museum'},
      {'name': 'Gandhi Smriti', 'description': 'Mahatma Gandhi memorial'},
    ]);
  }

  void _showCategoryModal(BuildContext context, String title, List<Map<String, String>> items) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item['name']!),
                        subtitle: Text(item['description']!),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _openMaps(item['name']!);
                        },
                      ),
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

  void _openMaps(String location) async {
    final url = 'https://maps.google.com/maps/search/$location';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
