import 'package:flutter/material.dart';
import '../models/metro_station.dart';
import '../utils/app_theme.dart';
import 'ui_kit.dart';

class SearchableStationDropdown extends StatefulWidget {
  final List<MetroStation> stations;
  final String? selectedStation;
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<String?> onChanged;

  /// Optional accent for the leading icon bubble and focus ring.
  final Color? accentColor;

  const SearchableStationDropdown({
    super.key,
    required this.stations,
    this.selectedStation,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
    this.accentColor,
  });

  @override
  State<SearchableStationDropdown> createState() => _SearchableStationDropdownState();
}

class _SearchableStationDropdownState extends State<SearchableStationDropdown> {
  final TextEditingController _searchController = TextEditingController();
  List<MetroStation> _filteredStations = [];
  bool _isExpanded = false;
  String? _selectedStation;

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.selectedStation;
    _filteredStations = widget.stations;
    _updateSearchController();
    _searchController.addListener(_filterStations);
  }

  @override
  void didUpdateWidget(SearchableStationDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStation != widget.selectedStation) {
      _selectedStation = widget.selectedStation;
      _updateSearchController();
    }
    if (oldWidget.stations != widget.stations) {
      _filteredStations = widget.stations;
      _filterStations();
    }
  }

  void _updateSearchController() {
    if (_selectedStation != null) {
      _searchController.text = _selectedStation!;
    } else {
      _searchController.clear();
    }
  }

  /// Relevance-based station search:
  /// Matches on Station Name rank MUCH higher than matches on Line Name.
  /// (e.g. typing "Airport" ranks "IGI Airport" first, not "Shivaji Stadium" on Airport Express)
  void _filterStations() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStations = widget.stations;
      } else {
        final matches = <MapEntry<MetroStation, int>>[];

        for (final station in widget.stations) {
          final name = station.name.toLowerCase();
          final line = station.line.toLowerCase();
          int score = 0;

          if (name == query) {
            score = 1000;
          } else if (name.startsWith(query)) {
            score = 600;
          } else if (name.split(' ').any((w) => w.startsWith(query))) {
            score = 400;
          } else if (name.contains(query)) {
            score = 250;
          } else if (line.startsWith(query)) {
            score = 50;
          } else if (line.contains(query)) {
            score = 20;
          }

          if (score > 0) {
            matches.add(MapEntry(station, score));
          }
        }

        matches.sort((a, b) => b.value.compareTo(a.value));
        _filteredStations = matches.map((e) => e.key).toList();
      }
    });
  }

  void _selectStation(MetroStation station) {
    setState(() {
      _selectedStation = station.name;
      _searchController.text = station.name;
      _isExpanded = false;
    });
    widget.onChanged(station.name);
  }

  void _clearSelection() {
    setState(() {
      _selectedStation = null;
      _searchController.clear();
      _isExpanded = false;
    });
    widget.onChanged(null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = widget.accentColor ?? p.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Field
        TextFormField(
          controller: _searchController,
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.textTertiary),
            filled: true,
            fillColor: p.cardAlt,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.tint(accent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.prefixIcon, size: 18, color: accent),
              ),
            ),
            suffixIcon: _selectedStation != null
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: p.textTertiary, size: 20),
                    tooltip: 'Clear selection',
                    onPressed: _clearSelection,
                  )
                : IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: p.textSecondary,
                    ),
                    tooltip: _isExpanded ? 'Collapse list' : 'Expand list',
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: p.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: p.border.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 1.8),
            ),
          ),
          onTap: () {
            setState(() {
              _isExpanded = true;
            });
          },
          readOnly: false,
        ),

        // Dropdown List
        if (_isExpanded && _filteredStations.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(18),
              color: p.card,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandNight.withValues(alpha: p.isDark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _filteredStations.length,
                itemBuilder: (context, index) {
                  final station = _filteredStations[index];
                  final isSelected = _selectedStation == station.name;

                  Color tagColor = AppTheme.metroBlue;
                  try {
                    tagColor = Color(int.parse(station.lineColor.replaceFirst('#', '0xff')));
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Material(
                      color: isSelected ? p.tint(accent) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _selectStation(station),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: p.tint(tagColor),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: tagColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      station.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: isSelected ? accent : p.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      station.line,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: tagColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: accent,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // No results message
        if (_isExpanded && _filteredStations.isEmpty && _searchController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(16),
              color: p.card,
            ),
            child: Row(
              children: [
                Icon(Icons.search_off_rounded, size: 18, color: p.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No metro stations match your query',
                    style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
