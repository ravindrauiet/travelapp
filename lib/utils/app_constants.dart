import 'package:flutter/material.dart';

/// Centralized constants for Metromate.
/// Ensures all screens, calculators, and cards stay in sync and never drift apart.
class AppConstants {
  // ── Network Metrics ──────────────────────────────────────────────────────────
  static const int metroLinesCount = 12;
  static const int metroStationsCount = 288;
  static const int metroInterchangesCount = 28;
  static const double metroNetworkLengthKm = 393.0;

  // ── DMRC Fares ──────────────────────────────────────────────────────────────
  static const int metroMinFare = 11;
  static const int metroMaxFare = 64;
  static const int metroHolidayMinFare = 11;
  static const int metroHolidayMaxFare = 54;
  static const String fareRangeDisplay = '₹11–₹64';
  static const String holidayFareRangeDisplay = '₹11–₹54';

  // ── Airport Express (AEL) ──────────────────────────────────────────────────
  static const int airportExpressMinFare = 20;
  static const int airportExpressMaxFare = 60;
  static const int airportExpressTravelTimeMin = 19; // New Delhi to IGI Airport T3
  static const String airportExpressTimeDisplay = '19 min';

  // ── Bus Statistics ──────────────────────────────────────────────────────────
  static const String busRoutesCount = '1,000+'; // ~1,080 route numbers in the OTD GTFS feed
  static const String busFleetCount = '7,200+';
  static const String busDailyRidership = '4.2M+';

  // ── Tourist Spots ───────────────────────────────────────────────────────────
  static const String touristSpotsCount = 'Top 35';

  // ── Auto Rickshaw Notified Rates (Delhi Government Transport Dept) ───────────
  static const int autoBaseFare = 30; // for first 1.5 km
  static const int autoPerKmFare = 11; // per km thereafter
  static const int autoNightChargePercent = 25; // 23:00 to 05:00
  static const String autoFareSummary = '₹30 base (1.5 km), ₹11/km after';

  // ── Emergency Helplines ─────────────────────────────────────────────────────
  static const String nationalEmergencyNumber = '112';
  static const String policeNumber = '112'; // Unified National Emergency Number
  static const String ambulanceNumber = '102';
  static const String fireNumber = '101';
  static const String delhiWomenHelpline = '181'; // Delhi Govt Women in Distress
  static const String womenSafetyHelpline = '1091';
  static const String disasterHelpline = '1077'; // Delhi Disaster Management Authority
  static const String childHelpline = '1098';
  static const String dmrcMetroHelpline = '155370'; // DMRC 24x7 Helpline
  static const String dtcBusHelpline = '1800118181';
  static const String trafficPoliceHelpline = '1095';
  static const String seniorCitizenHelpline = '14567';

  // ── Open Transit Data (Delhi Govt OTD) ──────────────────────────────────────
  static const String otdApiKey = '7brhWCYIy6TT0nCAXxWIvXoPCU56Lzox';
  static const String otdRealtimeUrl =
      'https://otd.delhi.gov.in/api/realtime/VehiclePositions.pb';
  static const String otdPortalUrl = 'https://otd.delhi.gov.in';

  // ── Compliance & Policies ───────────────────────────────────────────────────
  static const String privacyPolicyUrl =
      'https://metromate-delhi.web.app/privacy-policy';
  static const String appVersion = '1.0.2';

  // ── India CPCB Air Quality Index (AQI) Standard ────────────────────────────
  static String getAqiCategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Satisfactory';
    if (aqi <= 200) return 'Moderate';
    if (aqi <= 300) return 'Poor';
    if (aqi <= 400) return 'Very Poor';
    return 'Severe';
  }

  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF10B981);
    if (aqi <= 100) return const Color(0xFF84CC16);
    if (aqi <= 200) return const Color(0xFFF59E0B);
    if (aqi <= 300) return const Color(0xFFEA580C);
    if (aqi <= 400) return const Color(0xFFDC2626);
    return const Color(0xFF7F1D1D);
  }

  // ── Landmark to Nearest Metro Station Mapping ──────────────────────────────
  static const Map<String, String> landmarkToMetroStation = {
    'India Gate': 'Central Secretariat',
    'Connaught Place': 'Rajiv Chowk',
    'CP': 'Rajiv Chowk',
    'Red Fort': 'Lal Quila',
    'Lal Qila': 'Lal Quila',
    'Hauz Khas': 'Hauz Khas',
    'Hauz Khas Village': 'Hauz Khas',
    'IGI Airport': 'IGI Airport',
    'IGI Airport T3': 'IGI Airport',
    'Airport': 'IGI Airport',
    'Chandni Chowk': 'Chandni Chowk',
    'Kashmere Gate': 'Kashmere Gate',
    'Noida Sec 18': 'Noida Sector 18',
    'Gurugram Cyber City': 'Cyber City (Rapid Metro)',
    'Cyber Hub': 'Cyber City (Rapid Metro)',
    'Cyber Hub Gurugram': 'Cyber City (Rapid Metro)',
    'Lotus Temple': 'Kalkaji Mandir',
    'Qutub Minar': 'Qutab Minar',
    'Qutab Minar': 'Qutab Minar',
    'Akshardham': 'Akshardham',
    'Akshardham Temple': 'Akshardham',
    'Dilli Haat': 'Dilli Haat - INA',
    'Dilli Haat INA': 'Dilli Haat - INA',
    'Bangla Sahib': 'Patel Chowk',
    'Gurudwara Bangla Sahib': 'Patel Chowk',
    'Humayun Tomb': 'Jawaharlal Nehru Stadium',
    "Humayun's Tomb": 'Jawaharlal Nehru Stadium',
    'Sunder Nursery': 'Jawaharlal Nehru Stadium',
    'National Rail Museum': 'Durgabai Deshmukh South Campus',
    'Rail Museum': 'Durgabai Deshmukh South Campus',
    'National Museum': 'Udyog Bhawan',
    'Rajghat': 'Delhi Gate',
    'Jama Masjid': 'Jama Masjid',
    'Sarojini Nagar Market': 'Sarojini Nagar',
    'Lajpat Nagar Market': 'Lajpat Nagar',
    'Khan Market': 'Khan Market',
    'National Gallery of Modern Art': 'Khan Market',
    'Purana Qila': 'Supreme Court',
    'Zoo': 'Supreme Court',
    'Lodhi Garden': 'Jor Bagh',
    'Lodi Garden': 'Jor Bagh',
    'Jantar Mantar': 'Janpath',
  };

  /// Resolves any landmark or station name to a Metro station name that the
  /// route finder accepts.
  ///
  /// 1. exact landmark name (case-insensitive) → mapped station;
  /// 2. a real station name is returned unchanged (so "Terminal 1-IGI Airport"
  ///    is never hijacked by the "IGI Airport" landmark);
  /// 3. a landmark contained in the input as whole words, longest first
  ///    (e.g. "Red Fort, Old Delhi" → Lal Quila);
  /// 4. otherwise the input itself (the route finder does fuzzy matching).
  static String resolveToMetroStation(String input) {
    final trimmed = input.trim();
    final lower = trimmed.toLowerCase();
    for (final entry in landmarkToMetroStation.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    for (final line in DelhiMetroNetwork.allLines) {
      for (final station in line.stations) {
        if (station.toLowerCase() == lower) return station;
      }
    }
    final keys = landmarkToMetroStation.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in keys) {
      final pattern = RegExp('(^|[^a-z0-9])${RegExp.escape(key.toLowerCase())}(\$|[^a-z0-9])');
      if (pattern.hasMatch(lower)) return landmarkToMetroStation[key]!;
    }
    return trimmed;
  }
}

/// Detailed line model used for line exploration and bottom sheet details
class MetroLineDetails {
  final String name;
  final String code;
  final Color color;
  final String route;
  final int stationCount;
  final String typicalHeadway;
  final String operatingHours;
  final List<String> stations;
  final Map<String, List<String>> interchanges; // stationName -> other lines

  const MetroLineDetails({
    required this.name,
    required this.code,
    required this.color,
    required this.route,
    required this.stationCount,
    required this.typicalHeadway,
    required this.operatingHours,
    required this.stations,
    this.interchanges = const {},
  });
}

/// Authentic Delhi Metro Lines with complete ordered station sequences
class DelhiMetroNetwork {
  static const List<MetroLineDetails> allLines = [
    MetroLineDetails(
      name: 'Yellow Line',
      code: 'YELLOW',
      color: Color(0xFFF59E0B),
      route: 'Samaypur Badli ↔ Millennium City Centre Gurugram',
      stationCount: 37,
      typicalHeadway: '2.5–4 min',
      operatingHours: '05:30 AM – 11:30 PM',
      interchanges: {
        'Samaypur Badli': ['Northern Railway'],
        'Azadpur': ['Pink Line'],
        'Kashmere Gate': ['Red Line', 'Violet Line', 'ISBT Kashmere Gate'],
        'Chandni Chowk': ['Old Delhi Railway Station'],
        'New Delhi': ['Airport Express', 'New Delhi Railway Station'],
        'Rajiv Chowk': ['Blue Line'],
        'Central Secretariat': ['Violet Line'],
        'Dilli Haat - INA': ['Pink Line'],
        'Hauz Khas': ['Magenta Line'],
        'Sikanderpur': ['Rapid Metro'],
      },
      stations: [
        'Samaypur Badli',
        'Rohini Sector 18-19',
        'Haiderpur Badli Mor',
        'Jahangirpuri',
        'Adarsh Nagar',
        'Azadpur',
        'Model Town',
        'Guru Tegh Bahadur Nagar',
        'Vishwavidyalaya',
        'Vidhan Sabha',
        'Civil Lines',
        'Kashmere Gate',
        'Chandni Chowk',
        'Chawri Bazar',
        'New Delhi',
        'Rajiv Chowk',
        'Patel Chowk',
        'Central Secretariat',
        'Udyog Bhawan',
        'Lok Kalyan Marg',
        'Jor Bagh',
        'Dilli Haat - INA',
        'AIIMS',
        'Green Park',
        'Hauz Khas',
        'Malviya Nagar',
        'Saket',
        'Qutab Minar',
        'Chhatarpur',
        'Sultanpur',
        'Ghitorni',
        'Arjan Garh',
        'Guru Dronacharya',
        'Sikanderpur',
        'MG Road',
        'IFFCO Chowk',
        'Millennium City Centre Gurugram',
      ],
    ),
    MetroLineDetails(
      name: 'Blue Line',
      code: 'BLUE',
      color: Color(0xFF1D4ED8),
      route: 'Dwarka Sector 21 ↔ Noida Electronic City / Vaishali',
      stationCount: 50,
      typicalHeadway: '2.5–4 min',
      operatingHours: '05:30 AM – 11:30 PM',
      interchanges: {
        'Dwarka Sector 21': ['Airport Express'],
        'Dwarka': ['Grey Line'],
        'Janakpuri West': ['Magenta Line'],
        'Rajouri Garden': ['Pink Line'],
        'Kirti Nagar': ['Green Line'],
        'Mandi House': ['Violet Line'],
        'Rajiv Chowk': ['Yellow Line'],
        'Yamuna Bank': ['Blue Line Branch (Vaishali)'],
        'Mayur Vihar-I': ['Pink Line'],
        'Botanical Garden': ['Magenta Line'],
        'Noida Sector 52': ['Aqua Line (Noida Sector 51, via walkway)'],
      },
      stations: [
        'Dwarka Sector 21',
        'Dwarka Sector 8',
        'Dwarka Sector 9',
        'Dwarka Sector 10',
        'Dwarka Sector 11',
        'Dwarka Sector 12',
        'Dwarka Sector 13',
        'Dwarka Sector 14',
        'Dwarka',
        'Dwarka Mor',
        'Nawada',
        'Uttam Nagar West',
        'Uttam Nagar East',
        'Janakpuri West',
        'Janakpuri East',
        'Tilak Nagar',
        'Subhash Nagar',
        'Tagore Garden',
        'Rajouri Garden',
        'Ramesh Nagar',
        'Moti Nagar',
        'Kirti Nagar',
        'Shadipur',
        'Patel Nagar',
        'Rajendra Place',
        'Karol Bagh',
        'Jhandewalan',
        'Ramakrishna Ashram Marg',
        'Rajiv Chowk',
        'Barakhamba Road',
        'Mandi House',
        'Supreme Court',
        'Indraprastha',
        'Yamuna Bank',
        'Akshardham',
        'Mayur Vihar-I',
        'Mayur Vihar Extension',
        'New Ashok Nagar',
        'Noida Sector 15',
        'Noida Sector 16',
        'Noida Sector 18',
        'Botanical Garden',
        'Golf Course',
        'Noida City Centre',
        'Noida Sector 34',
        'Noida Sector 52',
        'Noida Sector 61',
        'Noida Sector 59',
        'Noida Sector 62',
        'Noida Electronic City',
      ],
    ),
    MetroLineDetails(
      name: 'Airport Express',
      code: 'AIRPORT',
      color: Color(0xFFEA580C),
      route: 'New Delhi ↔ Yashobhoomi Dwarka Sector 25',
      stationCount: 7,
      typicalHeadway: '10 min',
      operatingHours: '04:45 AM – 11:40 PM',
      interchanges: {
        'New Delhi': ['Yellow Line', 'New Delhi Railway Station'],
        'Shivaji Stadium': ['Connaught Place Outer Ring'],
        'Dhaula Kuan': ['Pink Line (Durgabai Deshmukh South Campus via travelator)'],
        'Delhi Aerocity': ['Aerocity Hospitality District'],
        'IGI Airport': ['Indira Gandhi International Airport T3 & T2'],
        'Dwarka Sector 21': ['Blue Line'],
        'Yashobhoomi Dwarka Sector 25': ['IICC Convention Centre'],
      },
      stations: [
        'New Delhi',
        'Shivaji Stadium',
        'Dhaula Kuan',
        'Delhi Aerocity',
        'IGI Airport',
        'Dwarka Sector 21',
        'Yashobhoomi Dwarka Sector 25',
      ],
    ),
    MetroLineDetails(
      name: 'Red Line',
      code: 'RED',
      color: Color(0xFFDC2626),
      route: 'Rithala ↔ Shaheed Sthal (New Bus Adda)',
      stationCount: 29,
      typicalHeadway: '3.5–5 min',
      operatingHours: '05:30 AM – 11:00 PM',
      interchanges: {
        'Netaji Subhash Place': ['Pink Line'],
        'Inderlok': ['Green Line'],
        'Kashmere Gate': ['Yellow Line', 'Violet Line'],
        'Welcome': ['Pink Line'],
      },
      stations: [
        'Rithala',
        'Rohini West',
        'Rohini East',
        'Pitampura',
        'Kohat Enclave',
        'Netaji Subhash Place',
        'Keshav Puram',
        'Kanhaiya Nagar',
        'Inderlok',
        'Shastri Nagar',
        'Pratap Nagar',
        'Pul Bangash',
        'Tis Hazari',
        'Kashmere Gate',
        'Shastri Park',
        'Seelampur',
        'Welcome',
        'Shahdara',
        'Mansarovar Park',
        'Jhilmil',
        'Dilshad Garden',
        'Shahid Nagar',
        'Raj Bagh',
        'Major Mohit Sharma Rajendra Nagar',
        'Shyam Park',
        'Mohan Nagar',
        'Arthala',
        'Hindon River',
        'Shaheed Sthal (New Bus Adda)',
      ],
    ),
    MetroLineDetails(
      name: 'Violet Line',
      code: 'VIOLET',
      color: Color(0xFF7C3AED),
      route: 'Kashmere Gate ↔ Raja Nahar Singh (Ballabhgarh)',
      stationCount: 34,
      typicalHeadway: '4–6 min',
      operatingHours: '05:30 AM – 11:30 PM',
      interchanges: {
        'Kashmere Gate': ['Red Line', 'Yellow Line'],
        'Mandi House': ['Blue Line'],
        'Central Secretariat': ['Yellow Line'],
        'Lajpat Nagar': ['Pink Line'],
        'Kalkaji Mandir': ['Magenta Line'],
      },
      stations: [
        'Kashmere Gate',
        'Lal Quila',
        'Jama Masjid',
        'Delhi Gate',
        'ITO',
        'Mandi House',
        'Janpath',
        'Central Secretariat',
        'Khan Market',
        'Jawaharlal Nehru Stadium',
        'Jangpura',
        'Lajpat Nagar',
        'Moolchand',
        'Kailash Colony',
        'Nehru Place',
        'Kalkaji Mandir',
        'Govind Puri',
        'Harkesh Nagar Okhla',
        'Jasola Apollo',
        'Sarita Vihar',
        'Mohan Estate',
        'Tughlakabad Station',
        'Badarpur Border',
        'Sarai',
        'NHPC Chowk',
        'Mewala Maharajpur',
        'Sector 28',
        'Badkal Mor',
        'Old Faridabad',
        'Neelam Chowk Ajronda',
        'Bata Chowk',
        'Escorts Mujesar',
        'Sant Surdas (Sihi)',
        'Raja Nahar Singh (Ballabhgarh)',
      ],
    ),
    MetroLineDetails(
      name: 'Pink Line',
      code: 'PINK',
      color: Color(0xFFDB2777),
      route: 'Majlis Park ↔ Shiv Vihar (Ring Line)',
      stationCount: 38,
      typicalHeadway: '4–6 min',
      operatingHours: '06:00 AM – 11:00 PM',
      interchanges: {
        'Azadpur': ['Yellow Line'],
        'Netaji Subhash Place': ['Red Line'],
        'Rajouri Garden': ['Blue Line'],
        'Durgabai Deshmukh South Campus': ['Airport Express via Dhaula Kuan'],
        'Dilli Haat - INA': ['Yellow Line'],
        'Lajpat Nagar': ['Violet Line'],
        'Mayur Vihar-I': ['Blue Line'],
        'Anand Vihar ISBT': ['Blue Line Branch', 'Railway Station'],
        'Welcome': ['Red Line'],
      },
      stations: [
        'Majlis Park',
        'Azadpur',
        'Shalimar Bagh',
        'Netaji Subhash Place',
        'Shakurpur',
        'Punjabi Bagh West',
        'ESI Hospital',
        'Rajouri Garden',
        'Maya Puri',
        'Naraina Vihar',
        'Delhi Cantt',
        'Durgabai Deshmukh South Campus',
        'Sir M. Vishweshwaraiah Moti Bagh',
        'Bhikaji Cama Place',
        'Sarojini Nagar',
        'Dilli Haat - INA',
        'South Extension',
        'Lajpat Nagar',
        'Vinobapuri',
        'Ashram',
        'Sarai Kale Khan - Nizamuddin',
        'Mayur Vihar-I',
        'Mayur Vihar Pocket 1',
        'Trilokpuri Sanjay Lake',
        'East Vinod Nagar - Mayur Vihar-II',
        'Mandawali - West Vinod Nagar',
        'IP Extension',
        'Anand Vihar ISBT',
        'Karkarduma',
        'Karkarduma Court',
        'Krishna Nagar',
        'East Azad Nagar',
        'Welcome',
        'Jaffrabad',
        'Maujpur - Babarpur',
        'Gokulpuri',
        'Johri Enclave',
        'Shiv Vihar',
      ],
    ),
    MetroLineDetails(
      name: 'Magenta Line',
      code: 'MAGENTA',
      color: Color(0xFFC026D3),
      route: 'Janakpuri West ↔ Botanical Garden',
      stationCount: 25,
      typicalHeadway: '3.5–5 min',
      operatingHours: '05:30 AM – 11:30 PM',
      interchanges: {
        'Janakpuri West': ['Blue Line'],
        'Hauz Khas': ['Yellow Line'],
        'Kalkaji Mandir': ['Violet Line'],
        'Botanical Garden': ['Blue Line'],
      },
      stations: [
        'Janakpuri West',
        'Dabri Mor - South Janakpuri',
        'Dashrath Puri',
        'Palam',
        'Sadar Bazar Cantonment',
        'Terminal 1-IGI Airport',
        'Shankar Vihar',
        'Vasant Vihar',
        'Munirka',
        'RK Puram',
        'IIT Delhi',
        'Hauz Khas',
        'Panchsheel Park',
        'Chirag Delhi',
        'Greater Kailash',
        'Nehru Enclave',
        'Kalkaji Mandir',
        'Okhla NSIC',
        'Sukhdev Vihar',
        'Jamia Millia Islamia',
        'Okhla Vihar',
        'Jasola Vihar Shaheen Bagh',
        'Kalindi Kunj',
        'Okhla Bird Sanctuary',
        'Botanical Garden',
      ],
    ),
    MetroLineDetails(
      name: 'Green Line',
      code: 'GREEN',
      color: Color(0xFF16A34A),
      route: 'Inderlok / Kirti Nagar ↔ Brigadier Hoshiyar Singh (Bahadurgarh)',
      stationCount: 23,
      typicalHeadway: '5–8 min',
      operatingHours: '06:00 AM – 11:00 PM',
      interchanges: {
        'Inderlok': ['Red Line'],
        'Kirti Nagar': ['Blue Line'],
        'Punjabi Bagh': ['Pink Line (Punjabi Bagh West, via skywalk)'],
      },
      stations: [
        'Inderlok',
        'Kirti Nagar',
        'Satguru Ram Singh Marg',
        'Ashok Park Main',
        'Punjabi Bagh',
        'Shivaji Park',
        'Madipur',
        'Paschim Vihar East',
        'Paschim Vihar West',
        'Peeragarhi',
        'Udyog Nagar',
        'Maharaja Surajmal Stadium',
        'Nangloi',
        'Nangloi Railway Station',
        'Rajdhani Park',
        'Mundka',
        'Mundka Industrial Area',
        'Ghevra Metro Station',
        'Tikri Kalan',
        'Tikri Border',
        'Pandit Shree Ram Sharma',
        'Bahadurgarh City',
        'Brigadier Hoshiyar Singh',
      ],
    ),
    MetroLineDetails(
      name: 'Grey Line',
      code: 'GREY',
      color: Color(0xFF64748B),
      route: 'Dwarka ↔ Dhansa Bus Stand',
      stationCount: 4,
      typicalHeadway: '7–10 min',
      operatingHours: '06:00 AM – 11:00 PM',
      interchanges: {
        'Dwarka': ['Blue Line'],
      },
      stations: [
        'Dwarka',
        'Nangli',
        'Najafgarh',
        'Dhansa Bus Stand',
      ],
    ),
    MetroLineDetails(
      name: 'Aqua Line',
      code: 'AQUA',
      color: Color(0xFF06B6D4),
      route: 'Noida Sector 51 ↔ Depot Station (Greater Noida)',
      stationCount: 21,
      typicalHeadway: '7–10 min',
      operatingHours: '06:00 AM – 10:45 PM',
      interchanges: {
        'Noida Sector 51': ['Blue Line (via walkway to Sector 52)'],
      },
      stations: [
        'Noida Sector 51',
        'Noida Sector 50',
        'Noida Sector 76',
        'Noida Sector 101',
        'Noida Sector 81',
        'NSEZ',
        'Noida Sector 83',
        'Noida Sector 137',
        'Noida Sector 142',
        'Noida Sector 143',
        'Noida Sector 144',
        'Noida Sector 145',
        'Noida Sector 146',
        'Noida Sector 147',
        'Noida Sector 148',
        'Knowledge Park II',
        'Pari Chowk',
        'Alpha 1',
        'Delta 1',
        'GNIDA Office',
        'Depot Station',
      ],
    ),
    MetroLineDetails(
      name: 'Rapid Metro',
      code: 'RAPID',
      color: Color(0xFF0284C7),
      route: 'Sector 55-56 ↔ Phase 3 (Gurugram Cyber City)',
      stationCount: 11,
      typicalHeadway: '4–6 min',
      operatingHours: '06:05 AM – 10:00 PM',
      interchanges: {
        'Sikanderpur': ['Yellow Line'],
      },
      stations: [
        'Sector 55-56',
        'Sector 54 Chowk',
        'Sector 53-54',
        'Sector 42-43',
        'Phase 1',
        'Sikanderpur',
        'Phase 2',
        'Belvedere Towers',
        'Cyber City',
        'Moulsari Avenue',
        'Phase 3',
      ],
    ),
    MetroLineDetails(
      name: 'Blue Line Branch',
      code: 'BLUE_BRANCH',
      color: Color(0xFF2563EB),
      route: 'Yamuna Bank ↔ Vaishali',
      stationCount: 8,
      typicalHeadway: '4–7 min',
      operatingHours: '05:30 AM – 11:30 PM',
      interchanges: {
        'Yamuna Bank': ['Blue Line Main (Dwarka ↔ Noida)'],
        'Anand Vihar ISBT': ['Pink Line', 'Railway Station'],
      },
      stations: [
        'Yamuna Bank',
        'Laxmi Nagar',
        'Nirman Vihar',
        'Preet Vihar',
        'Karkarduma',
        'Anand Vihar ISBT',
        'Kaushambi',
        'Vaishali',
      ],
    ),
  ];
}
