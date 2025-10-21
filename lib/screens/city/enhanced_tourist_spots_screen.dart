import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';

class EnhancedTouristSpotsScreen extends StatefulWidget {
  const EnhancedTouristSpotsScreen({super.key});

  @override
  State<EnhancedTouristSpotsScreen> createState() => _EnhancedTouristSpotsScreenState();
}

class _EnhancedTouristSpotsScreenState extends State<EnhancedTouristSpotsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Monuments', 'Markets', 'Parks', 'Museums', 'Religious', 'Entertainment'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Explore Delhi'),
        backgroundColor: AppTheme.metroMagenta,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'All Places'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildAllPlacesTab(),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.metroMagenta, AppTheme.metroMagenta.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.explore, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Discover Delhi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore the rich heritage, vibrant markets, and beautiful attractions of India\'s capital city',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatChip('50+', 'Monuments'),
                    const SizedBox(width: 12),
                    _buildStatChip('25+', 'Markets'),
                    const SizedBox(width: 12),
                    _buildStatChip('30+', 'Parks'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Categories Grid
          const Text(
            'Explore by Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildCategoryCard(
                'Monuments',
                Icons.account_balance,
                AppTheme.metroRed,
                '50+ Historic Sites',
                () => _showCategoryDetails('Monuments'),
              ),
              _buildCategoryCard(
                'Markets',
                Icons.shopping_bag,
                AppTheme.metroOrange,
                '25+ Shopping Areas',
                () => _showCategoryDetails('Markets'),
              ),
              _buildCategoryCard(
                'Parks',
                Icons.park,
                AppTheme.metroGreen,
                '30+ Green Spaces',
                () => _showCategoryDetails('Parks'),
              ),
              _buildCategoryCard(
                'Museums',
                Icons.museum,
                AppTheme.metroBlue,
                '15+ Museums',
                () => _showCategoryDetails('Museums'),
              ),
              _buildCategoryCard(
                'Religious',
                Icons.temple_buddhist,
                AppTheme.metroViolet,
                '20+ Sacred Places',
                () => _showCategoryDetails('Religious'),
              ),
              _buildCategoryCard(
                'Entertainment',
                Icons.movie,
                AppTheme.metroPink,
                '10+ Entertainment',
                () => _showCategoryDetails('Entertainment'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllPlacesTab() {
    return Column(
      children: [
        // Filter Chips
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: AppTheme.metroMagenta.withOpacity(0.2),
                  checkmarkColor: AppTheme.metroMagenta,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.metroMagenta : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Places List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _getFilteredPlaces().length,
            itemBuilder: (context, index) {
              final place = _getFilteredPlaces()[index];
              return _buildPlaceCard(place);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: place['color'].withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    place['icon'],
                    size: 64,
                    color: place['color'].withOpacity(0.3),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: place['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      place['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place['rating'],
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  place['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place['location'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      place['timings'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                    Text(
                      place['entryFee'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaps(place['name']),
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: place['color'],
                          side: BorderSide(color: place['color']),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPlaceDetails(place),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: place['color'],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredPlaces() {
    final allPlaces = _getAllPlaces();
    if (_selectedCategory == 'All') {
      return allPlaces;
    }
    return allPlaces.where((place) => place['category'] == _selectedCategory).toList();
  }

  List<Map<String, dynamic>> _getAllPlaces() {
    return [
      // Monuments
      {
        'name': 'Red Fort',
        'description': 'A historic fort and UNESCO World Heritage Site built by Mughal Emperor Shah Jahan. The fort served as the main residence of the Mughal emperors for nearly 200 years.',
        'location': 'Netaji Subhash Marg, Lal Qila, Old Delhi',
        'timings': '9:30 AM - 4:30 PM (Closed Mondays)',
        'entryFee': '₹50 (Indians), ₹500 (Foreigners)',
        'rating': '4.5★',
        'category': 'Monuments',
        'icon': Icons.account_balance,
        'color': AppTheme.metroRed,
        'metroStation': 'Chandni Chowk (Yellow Line)',
        'bestTime': 'October to March',
        'visitDuration': '2-3 hours',
        'highlights': ['Sound & Light Show', 'Museum', 'Diwan-i-Aam', 'Diwan-i-Khas'],
      },
      {
        'name': 'India Gate',
        'description': 'A war memorial dedicated to the 70,000 soldiers of the British Indian Army who died in World War I. It\'s a popular picnic spot and evening destination.',
        'location': 'Rajpath, India Gate, New Delhi',
        'timings': '24 Hours',
        'entryFee': 'Free',
        'rating': '4.3★',
        'category': 'Monuments',
        'icon': Icons.flag,
        'color': AppTheme.metroRed,
        'metroStation': 'Central Secretariat (Yellow Line)',
        'bestTime': 'Evening (6 PM - 9 PM)',
        'visitDuration': '1-2 hours',
        'highlights': ['Amar Jawan Jyoti', 'Evening Lights', 'Street Food', 'Photography'],
      },
      {
        'name': 'Qutub Minar',
        'description': 'The tallest brick minaret in the world, built in 1193. This UNESCO World Heritage Site is a masterpiece of Indo-Islamic architecture.',
        'location': 'Mehrauli, New Delhi',
        'timings': '6:00 AM - 6:00 PM',
        'entryFee': '₹40 (Indians), ₹600 (Foreigners)',
        'rating': '4.4★',
        'category': 'Monuments',
        'icon': Icons.architecture,
        'color': AppTheme.metroRed,
        'metroStation': 'Qutub Minar (Yellow Line)',
        'bestTime': 'October to March',
        'visitDuration': '2-3 hours',
        'highlights': ['Iron Pillar', 'Quwwat-ul-Islam Mosque', 'Alai Darwaza', 'Tomb of Iltutmish'],
      },
      {
        'name': 'Humayun\'s Tomb',
        'description': 'The first garden-tomb on the Indian subcontinent, built in 1570. It inspired the construction of the Taj Mahal and is a UNESCO World Heritage Site.',
        'location': 'Mathura Road, Nizamuddin, New Delhi',
        'timings': '6:00 AM - 6:00 PM',
        'entryFee': '₹40 (Indians), ₹600 (Foreigners)',
        'rating': '4.2★',
        'category': 'Monuments',
        'icon': Icons.account_balance,
        'color': AppTheme.metroRed,
        'metroStation': 'JLN Stadium (Violet Line)',
        'bestTime': 'October to March',
        'visitDuration': '2-3 hours',
        'highlights': ['Garden Layout', 'Persian Architecture', 'Isa Khan\'s Tomb', 'Barber\'s Tomb'],
      },
      
      // Markets
      {
        'name': 'Chandni Chowk',
        'description': 'One of the oldest and busiest markets in Old Delhi, famous for its narrow lanes, traditional shops, and authentic street food.',
        'location': 'Chandni Chowk, Old Delhi',
        'timings': '10:00 AM - 8:00 PM',
        'entryFee': 'Free',
        'rating': '4.1★',
        'category': 'Markets',
        'icon': Icons.shopping_bag,
        'color': AppTheme.metroOrange,
        'metroStation': 'Chandni Chowk (Yellow Line)',
        'bestTime': 'Morning (10 AM - 2 PM)',
        'visitDuration': '3-4 hours',
        'highlights': ['Paranthe Wali Gali', 'Jama Masjid', 'Spice Market', 'Jewelry Shops'],
      },
      {
        'name': 'Connaught Place',
        'description': 'A commercial and financial hub in New Delhi, known for its Georgian architecture, shopping centers, restaurants, and nightlife.',
        'location': 'Connaught Place, New Delhi',
        'timings': '10:00 AM - 10:00 PM',
        'entryFee': 'Free',
        'rating': '4.0★',
        'category': 'Markets',
        'icon': Icons.shopping_bag,
        'color': AppTheme.metroOrange,
        'metroStation': 'Rajiv Chowk (Blue & Yellow Line)',
        'bestTime': 'Evening (6 PM - 10 PM)',
        'visitDuration': '2-3 hours',
        'highlights': ['Central Park', 'Palika Bazaar', 'Restaurants', 'Branded Stores'],
      },
      {
        'name': 'Dilli Haat',
        'description': 'An open-air food plaza and craft bazaar showcasing the diverse culture of India. Features handicrafts, handlooms, and regional cuisines.',
        'location': 'INA, New Delhi',
        'timings': '10:30 AM - 10:00 PM',
        'entryFee': '₹30 (Adults), ₹15 (Children)',
        'rating': '4.2★',
        'category': 'Markets',
        'icon': Icons.shopping_bag,
        'color': AppTheme.metroOrange,
        'metroStation': 'INA (Yellow Line)',
        'bestTime': 'Evening (6 PM - 9 PM)',
        'visitDuration': '2-3 hours',
        'highlights': ['Handicrafts', 'Regional Food', 'Cultural Shows', 'Artisan Workshops'],
      },
      
      // Parks
      {
        'name': 'Lodhi Garden',
        'description': 'A city park spread over 90 acres, featuring historical monuments from the Lodhi dynasty, beautiful landscaping, and jogging tracks.',
        'location': 'Lodhi Road, New Delhi',
        'timings': '5:00 AM - 8:00 PM',
        'entryFee': 'Free',
        'rating': '4.3★',
        'category': 'Parks',
        'icon': Icons.park,
        'color': AppTheme.metroGreen,
        'metroStation': 'Jor Bagh (Yellow Line)',
        'bestTime': 'Morning (6 AM - 9 AM)',
        'visitDuration': '1-2 hours',
        'highlights': ['Lodhi Tombs', 'Jogging Track', 'Rose Garden', 'Bird Watching'],
      },
      {
        'name': 'Garden of Five Senses',
        'description': 'A unique park designed to stimulate all five senses through its various sections, including musical fountains, sculptures, and themed gardens.',
        'location': 'Said-ul-Ajaib, Saket, New Delhi',
        'timings': '9:00 AM - 6:00 PM',
        'entryFee': '₹35 (Adults), ₹15 (Children)',
        'rating': '4.1★',
        'category': 'Parks',
        'icon': Icons.park,
        'color': AppTheme.metroGreen,
        'metroStation': 'Saket (Yellow Line)',
        'bestTime': 'October to March',
        'visitDuration': '2-3 hours',
        'highlights': ['Musical Fountains', 'Sculpture Garden', 'Food Court', 'Amphitheater'],
      },
      
      // Museums
      {
        'name': 'National Museum',
        'description': 'India\'s largest museum, housing over 200,000 works of art covering 5,000 years of Indian history, culture, and heritage.',
        'location': 'Janpath, New Delhi',
        'timings': '10:00 AM - 6:00 PM (Closed Mondays)',
        'entryFee': '₹20 (Indians), ₹650 (Foreigners)',
        'rating': '4.0★',
        'category': 'Museums',
        'icon': Icons.museum,
        'color': AppTheme.metroBlue,
        'metroStation': 'Central Secretariat (Yellow Line)',
        'bestTime': 'October to March',
        'visitDuration': '3-4 hours',
        'highlights': ['Harappan Gallery', 'Buddhist Art', 'Manuscripts', 'Arms & Armor'],
      },
      {
        'name': 'Railway Museum',
        'description': 'A unique museum showcasing the history of Indian Railways with vintage locomotives, carriages, and railway artifacts.',
        'location': 'Chanakyapuri, New Delhi',
        'timings': '9:30 AM - 5:30 PM (Closed Mondays)',
        'entryFee': '₹50 (Adults), ₹10 (Children)',
        'rating': '4.2★',
        'category': 'Museums',
        'icon': Icons.train,
        'color': AppTheme.metroBlue,
        'metroStation': 'Dhaula Kuan (Airport Express)',
        'bestTime': 'October to March',
        'visitDuration': '2-3 hours',
        'highlights': ['Fairy Queen', 'Patiala State Monorail', 'Toy Train Ride', 'Railway Models'],
      },
      
      // Religious
      {
        'name': 'Lotus Temple',
        'description': 'A Baháʼí House of Worship known for its flowerlike shape. It\'s open to all religions and is one of the most visited buildings in the world.',
        'location': 'Bahapur, Kalkaji, New Delhi',
        'timings': '9:00 AM - 7:00 PM (Closed Mondays)',
        'entryFee': 'Free',
        'rating': '4.4★',
        'category': 'Religious',
        'icon': Icons.temple_buddhist,
        'color': AppTheme.metroViolet,
        'metroStation': 'Kalkaji Mandir (Violet Line)',
        'bestTime': 'Morning (9 AM - 12 PM)',
        'visitDuration': '1-2 hours',
        'highlights': ['Architecture', 'Peaceful Environment', 'Information Center', 'Garden'],
      },
      {
        'name': 'Jama Masjid',
        'description': 'One of the largest mosques in India, built by Mughal Emperor Shah Jahan. It can accommodate 25,000 worshippers in its courtyard.',
        'location': 'Jama Masjid, Old Delhi',
        'timings': '7:00 AM - 12:00 PM, 1:30 PM - 6:30 PM',
        'entryFee': 'Free (₹300 for camera)',
        'rating': '4.3★',
        'category': 'Religious',
        'icon': Icons.mosque,
        'color': AppTheme.metroViolet,
        'metroStation': 'Chandni Chowk (Yellow Line)',
        'bestTime': 'Morning (7 AM - 12 PM)',
        'visitDuration': '1-2 hours',
        'highlights': ['Minaret Views', 'Courtyard', 'Architecture', 'Street Food Nearby'],
      },
      
      // Entertainment
      {
        'name': 'Kingdom of Dreams',
        'description': 'India\'s first live entertainment, theatre and leisure destination, featuring Bollywood musicals, cultural shows, and themed restaurants.',
        'location': 'Sector 29, Gurgaon',
        'timings': '12:30 PM - 11:30 PM',
        'entryFee': '₹999 - ₹2999',
        'rating': '4.1★',
        'category': 'Entertainment',
        'icon': Icons.movie,
        'color': AppTheme.metroPink,
        'metroStation': 'Huda City Centre (Yellow Line)',
        'bestTime': 'Evening (6 PM - 11 PM)',
        'visitDuration': '3-4 hours',
        'highlights': ['Bollywood Shows', 'Cultural Village', 'Restaurants', 'Shopping'],
      },
    ];
  }

  void _showCategoryDetails(String category) {
    final places = _getAllPlaces().where((place) => place['category'] == category).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '$category in Delhi',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${places.length} places to explore',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _buildPlaceCard(place);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name'],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place['description'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Location', place['location'], Icons.location_on),
                    _buildDetailRow('Timings', place['timings'], Icons.access_time),
                    _buildDetailRow('Entry Fee', place['entryFee'], Icons.currency_rupee),
                    _buildDetailRow('Rating', place['rating'], Icons.star),
                    _buildDetailRow('Metro Station', place['metroStation'], Icons.train),
                    _buildDetailRow('Best Time to Visit', place['bestTime'], Icons.calendar_today),
                    _buildDetailRow('Visit Duration', place['visitDuration'], Icons.timer),
                    const SizedBox(height: 20),
                    const Text(
                      'Highlights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (place['highlights'] as List<String>).map((highlight) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: place['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: place['color'].withOpacity(0.3)),
                          ),
                          child: Text(
                            highlight,
                            style: TextStyle(
                              color: place['color'],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openMaps(place['name']),
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: place['color'],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openMaps(String placeName) async {
    final url = 'https://www.google.com/maps/search/$placeName+Delhi';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open maps'),
        ),
      );
    }
  }
}
