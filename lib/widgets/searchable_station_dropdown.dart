import 'package:flutter/material.dart';
import '../models/metro_station.dart';

class SearchableStationDropdown extends StatefulWidget {
  final List<MetroStation> stations;
  final String? selectedStation;
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<String?> onChanged;

  const SearchableStationDropdown({
    super.key,
    required this.stations,
    this.selectedStation,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
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

  void _filterStations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStations = widget.stations;
      } else {
        _filteredStations = widget.stations
            .where((station) => 
                station.name.toLowerCase().contains(query) ||
                station.line.toLowerCase().contains(query))
            .toList();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: _selectedStation != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSelection,
                  )
                : IconButton(
                    icon: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
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
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredStations.length,
              itemBuilder: (context, index) {
                final station = _filteredStations[index];
                final isSelected = _selectedStation == station.name;
                
                return InkWell(
                  onTap: () => _selectStation(station),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                      border: index < _filteredStations.length - 1
                          ? Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(int.parse(station.lineColor.replaceFirst('#', '0xff'))),
                            shape: BoxShape.circle,
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
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                station.line,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        
        // No results message
        if (_isExpanded && _filteredStations.isEmpty && _searchController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: const Text(
              'No stations found matching your search',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
