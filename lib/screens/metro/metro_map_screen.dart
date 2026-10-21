import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/metro_provider.dart';
import '../../models/metro_station.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/ui_kit.dart';

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
      'stations': 57,
      'code': 'BLUE',
    },
    {
      'name': 'Airport Express',
      'color': Color(0xFFEA580C),
      'terminals': 'New Delhi ↔ IGI Airport T3 ↔ Yashobhoomi Dwarka Sec 25',
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
      'terminals': 'Inderlok / Kirti Nagar ↔ Brig. Hoshiyar Singh',
      'stations': 23,
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
      } else if (mounted) {
        context.push('/metro/pdf-viewer');
      }
    } catch (_) {
      if (mounted) context.push('/metro/pdf-viewer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(
          children: [
            GradientHeader(
              title: 'Metro Map & Lines',
              subtitle: 'Explore every station and corridor',
              icon: Icons.hub_rounded,
              gradient: AppTheme.royalGradient,
              actions: [
                HeaderIconButton(
                  icon: Icons.picture_as_pdf_rounded,
                  tooltip: 'View HD PDF',
                  onTap: () => context.push('/metro/pdf-viewer'),
                ),
              ],
              bottom: _buildSegmentedTabs(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNetworkExplorerTab(),
                  _buildLinesDirectoryTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    Tab tab(IconData icon, String label) => Tab(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17),
              const SizedBox(width: 6),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandNight.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.brandViolet,
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: AppTheme.fontFamily),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: AppTheme.fontFamily),
        splashBorderRadius: BorderRadius.circular(12),
        tabs: [
          tab(Icons.hub_rounded, 'Network Explorer'),
          tab(Icons.linear_scale_rounded, 'Lines Directory'),
        ],
      ),
    );
  }

  // ── Tab 1: Network Explorer & Station Navigator ─────────────────────────────

  Widget _buildNetworkExplorerTab() {
    final p = context.palette;
    return Consumer<MetroProvider>(
      builder: (context, metroProvider, _) {
        if (metroProvider.isLoading && metroProvider.stations.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: p.primary),
                const SizedBox(height: 14),
                Text(
                  'Loading metro network…',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.textSecondary),
                ),
              ],
            ),
          );
        }

        final allStations = metroProvider.stations;
        final filteredStations = allStations.where((s) {
          // Interchange stations belong to every line they serve.
          final sel = _selectedLine.toLowerCase();
          final matchesLine = _selectedLine == 'All' ||
              s.line.toLowerCase().contains(sel) ||
              s.interchangeLines.any((l) => l.toLowerCase().contains(sel));
          final matchesSearch = _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.line.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesLine && matchesSearch;
        }).toList();

        return Column(
          children: [
            const SizedBox(height: 14),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border.withValues(alpha: 0.8)),
                  boxShadow: p.shadow,
                ),
                child: TextField(
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search station on map...',
                    hintStyle: TextStyle(fontSize: 13.5, color: p.textTertiary),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.primary),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            const SizedBox(height: 12),

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

            // Official DMRC HD Map Launch Strip
            AppCard(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(14),
              radius: 20,
              gradient: AppTheme.heroGradient,
              onTap: _openOfficialDMRCMap,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Official DMRC Network Map',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'View high-definition zoomable map of all 12 lines',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.sunsetGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.glow(AppTheme.brandRose, alpha: 0.35),
                    ),
                    child: const Text(
                      'OPEN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Station count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: Row(
                children: [
                  Text(
                    '${filteredStations.length} station${filteredStations.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.textSecondary),
                  ),
                  const Spacer(),
                  if (_selectedLine != 'All')
                    TagPill(label: _selectedLine.toUpperCase(), color: _getLineColor(_selectedLine)),
                ],
              ),
            ),

            // Station List with Visual Route Rail
            Expanded(
              child: filteredStations.isEmpty
                  ? SingleChildScrollView(
                      child: EmptyState(
                        title: 'No stations found',
                        message: _searchQuery.isNotEmpty
                            ? 'Nothing matches "$_searchQuery". Try a different name or line.'
                            : 'No stations available for this line yet.',
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
    final p = context.palette;
    final isSelected = _selectedLine == name;
    final accent = color ?? p.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedLine = name),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accent : p.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? accent : p.border),
              boxShadow: isSelected ? AppTheme.glow(accent, alpha: 0.3) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStationCard(MetroStation station) {
    final p = context.palette;
    final lineColor = _getLineColor(station.line);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      radius: 20,
      child: Row(
        children: [
          // Visual line colored dot
          IconBubble(icon: Icons.train_rounded, color: lineColor, size: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 190),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.tint(lineColor),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              station.line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: lineColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (station.isInterchange)
                      const TagPill(
                        label: 'INTERCHANGE',
                        color: AppTheme.warningColor,
                        icon: Icons.swap_horiz_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: p.tint(AppTheme.accentColor),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_rounded, color: AppTheme.accentColor, size: 20),
            ),
            tooltip: 'Plan route from this station',
            onPressed: () => context.push('/metro/route-finder'),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Lines Directory & Infrastructure ─────────────────────────────────

  Widget _buildLinesDirectoryTab() {
    final p = context.palette;
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _metroLines.length,
      itemBuilder: (context, index) {
        final line = _metroLines[index];
        final color = line['color'] as Color;

        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          radius: 22,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.45)]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBubble(icon: Icons.train_rounded, color: color, filled: true, size: 40, radius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  line['terminals'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TagPill(label: '${line['stations']} STN', color: color),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: p.textTertiary, size: 15),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _typicalHeadway(line['code'] as String),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, color: p.textSecondary, fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedLine = line['name'] as String;
                                _tabController.animateTo(0);
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: color,
                              backgroundColor: p.tint(color),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, fontFamily: AppTheme.fontFamily),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View Stations'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Typical (timetabled) frequency for a line — not live status.
  String _typicalHeadway(String code) {
    for (final l in DelhiMetroNetwork.allLines) {
      if (l.code == code) return 'Typical frequency: every ${l.typicalHeadway}';
    }
    return 'Typical frequency: see DMRC timetable';
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
