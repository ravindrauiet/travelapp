import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/metro_provider.dart';
import '../../models/metro_station.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';

class MetroMapScreen extends StatefulWidget {
  const MetroMapScreen({super.key});

  @override
  State<MetroMapScreen> createState() => _MetroMapScreenState();
}

class _MetroMapScreenState extends State<MetroMapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLine = 'All';
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _metroLines = [
    {
      'name': 'Yellow Line',
      'color': Color(0xFFF59E0B),
      'terminals': 'Samaypur Badli ↔ Millennium City Centre',
      'stations': 37,
      'code': 'YELLOW',
    },
    {
      'name': 'Blue Line',
      'color': Color(0xFF1D4ED8),
      'terminals': 'Dwarka Sec 21 ↔ Noida Electronic City / Vaishali',
      'stations': 58,
      'code': 'BLUE',
    },
    {
      'name': 'Airport Express',
      'color': Color(0xFFEA580C),
      'terminals': 'New Delhi ↔ IGI Airport T3 (Yashobhoomi)',
      'stations': 7,
      'code': 'AIRPORT',
    },
    {
      'name': 'Red Line',
      'color': Color(0xFFDC2626),
      'terminals': 'Rithala ↔ Shaheed Sthal (New Bus Adda)',
      'stations': 29,
      'code': 'RED',
    },
    {
      'name': 'Violet Line',
      'color': Color(0xFF7C3AED),
      'terminals': 'Kashmere Gate ↔ Raja Nahar Singh',
      'stations': 34,
      'code': 'VIOLET',
    },
    {
      'name': 'Pink Line',
      'color': Color(0xFFDB2777),
      'terminals': 'Majlis Park ↔ Shiv Vihar (Ring Metro)',
      'stations': 38,
      'code': 'PINK',
    },
    {
      'name': 'Magenta Line',
      'color': Color(0xFFC026D3),
      'terminals': 'Janakpuri West ↔ Botanical Garden',
      'stations': 25,
      'code': 'MAGENTA',
    },
    {
      'name': 'Green Line',
      'color': Color(0xFF16A34A),
      'terminals': 'Inderlok ↔ Brig. Hoshiyar Singh',
      'stations': 24,
      'code': 'GREEN',
    },
    {
      'name': 'Grey Line',
      'color': Color(0xFF64748B),
      'terminals': 'Dwarka ↔ Dhansa Bus Stand',
      'stations': 4,
      'code': 'GREY',
    },
    {
      'name': 'Aqua Line',
      'color': Color(0xFF06B6D4),
      'terminals': 'Noida Sector 51 ↔ Depot',
      'stations': 21,
      'code': 'AQUA',
    },
    {
      'name': 'Rapid Metro',
      'color': Color(0xFF0EA5E9),
      'terminals': 'Sector 55-56 ↔ Cyber City Gurugram',
      'stations': 11,
      'code': 'RAPID',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openOfficialDMRCMap() async {
    const url = 'https://www.delhimetrorail.com/network_map';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        context.push('/metro/pdf-viewer');
      }
    } catch (_) {
      context.push('/metro/pdf-viewer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Delhi Metro Map & Lines',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB)),
            tooltip: 'View HD PDF',
            onPressed: () => context.push('/metro/pdf-viewer'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF4D2D), // Zomato / Swiggy energetic brand color
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFFFF4D2D),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'Network Explorer', icon: Icon(Icons.hub_rounded, size: 20)),
            Tab(text: 'Lines Directory', icon: Icon(Icons.linear_scale_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNetworkExplorerTab(),
          _buildLinesDirectoryTab(),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
    );
  }

  // ── Tab 1: Network Explorer & Station Navigator ─────────────────────────────

  Widget _buildNetworkExplorerTab() {
    return Consumer<MetroProvider>(
      builder: (context, metroProvider, _) {
        if (metroProvider.isLoading && metroProvider.stations.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
        }

        final allStations = metroProvider.stations;
        final filteredStations = allStations.where((s) {
          final matchesLine = _selectedLine == 'All' || s.line.toLowerCase().contains(_selectedLine.toLowerCase());
          final matchesSearch = _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.line.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesLine && matchesSearch;
        }).toList();

        return Column(
          children: [
            // Top Interactive Line Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search station on map...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Line Selector Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildLineFilterChip('All', null),
                        ..._metroLines.map((l) {
                          return _buildLineFilterChip(l['name'] as String, l['color'] as Color);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Official DMRC HD Map Launch Strip
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official DMRC Network Map',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'View high-definition zoomable map of all 12 lines',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _openOfficialDMRCMap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('OPEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),

            // Station List with Visual Route Rail
            Expanded(
              child: filteredStations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'No stations found',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: filteredStations.length,
                      itemBuilder: (context, index) {
                        final station = filteredStations[index];
                        return _buildStationCard(station);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLineFilterChip(String name, Color? color) {
    final isSelected = _selectedLine == name;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedLine = name),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationCard(MetroStation station) {
    final lineColor = _getLineColor(station.line);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Visual line colored dot
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: lineColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: lineColor, width: 2),
            ),
            child: Icon(Icons.train_rounded, color: lineColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: lineColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        station.line,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: lineColor,
                        ),
                      ),
                    ),
                    if (station.isInterchange) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'INTERCHANGE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.directions_rounded, color: Color(0xFF2563EB), size: 22),
            tooltip: 'Plan route from this station',
            onPressed: () => context.push('/metro/route-finder'),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Lines Directory & Infrastructure ─────────────────────────────────

  Widget _buildLinesDirectoryTab() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _metroLines.length,
      itemBuilder: (context, index) {
        final line = _metroLines[index];
        final color = line['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        line['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${line['stations']} Stations',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                line['terminals'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Normal Operational Frequency',
                        style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedLine = line['name'] as String;
                        _tabController.animateTo(0);
                      });
                    },
                    child: const Text(
                      'View Stations ➔',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getLineColor(String lineName) {
    final lower = lineName.toLowerCase();
    if (lower.contains('yellow')) return const Color(0xFFF59E0B);
    if (lower.contains('blue')) return const Color(0xFF1D4ED8);
    if (lower.contains('red')) return const Color(0xFFDC2626);
    if (lower.contains('green')) return const Color(0xFF16A34A);
    if (lower.contains('violet')) return const Color(0xFF7C3AED);
    if (lower.contains('pink')) return const Color(0xFFDB2777);
    if (lower.contains('magenta')) return const Color(0xFFC026D3);
    if (lower.contains('airport') || lower.contains('orange')) return const Color(0xFFEA580C);
    if (lower.contains('grey')) return const Color(0xFF64748B);
    if (lower.contains('aqua')) return const Color(0xFF06B6D4);
    if (lower.contains('rapid')) return const Color(0xFF0EA5E9);
    return const Color(0xFF2563EB);
  }
}
