import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/searchable_station_dropdown.dart';

class MetroFareCalculatorScreen extends StatefulWidget {
  const MetroFareCalculatorScreen({super.key});

  @override
  State<MetroFareCalculatorScreen> createState() => _MetroFareCalculatorScreenState();
}

class _MetroFareCalculatorScreenState extends State<MetroFareCalculatorScreen> {
  String? _fromStation;
  String? _toStation;
  Map<String, dynamic>? _fareData;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadStations();
    });
  }

  void _swapStations() {
    setState(() {
      final temp = _fromStation;
      _fromStation = _toStation;
      _toStation = temp;
      _fareData = null;
    });
  }

  bool _canCalculate() {
    return _fromStation != null && _toStation != null && !_isCalculating;
  }

  void _calculateFare() async {
    if (!_canCalculate()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final metroProvider = context.read<MetroProvider>();
      final fareData = await metroProvider.calculateFare(_fromStation!, _toStation!);

      if (mounted) {
        setState(() {
          _fareData = fareData;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating fare: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Fare Calculator',
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
      ),
      body: Consumer<MetroProvider>(
        builder: (context, metroProvider, child) {
          if (metroProvider.isLoading && metroProvider.stations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2563EB)),
                  SizedBox(height: 16),
                  Text(
                    'Loading metro stations…',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          if (metroProvider.error != null && metroProvider.stations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFEF4444)),
                    const SizedBox(height: 16),
                    Text('Error: ${metroProvider.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => metroProvider.loadStations(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Station Selection Card
                _buildStationInputCard(metroProvider),
                const SizedBox(height: 20),

                // Calculate Action Button
                _buildCalculateButton(),
                const SizedBox(height: 24),

                // Calculated Results Card
                if (_fareData != null) ...[
                  _buildFareResultCard(),
                  const SizedBox(height: 20),
                ],

                // Official DMRC Fare Slabs Table
                _buildFareSlabsCard(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
    );
  }

  // ── Input Card ─────────────────────────────────────────────────────────────

  Widget _buildStationInputCard(MetroProvider metroProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.route_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Select Stations',
                    style: TextStyle(
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${metroProvider.stations.length} STATIONS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // FROM Station
          const Text(
            'STARTING STATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SearchableStationDropdown(
            stations: metroProvider.stations,
            selectedStation: _fromStation,
            hintText: 'Select origin station',
            prefixIcon: Icons.my_location_rounded,
            onChanged: (value) {
              setState(() {
                _fromStation = value;
                _fareData = null;
              });
            },
          ),

          // Station Swap Button Row
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: _swapStations,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ),

          // TO Station
          const Text(
            'DESTINATION STATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SearchableStationDropdown(
            stations: metroProvider.stations,
            selectedStation: _toStation,
            hintText: 'Select destination station',
            prefixIcon: Icons.location_on_rounded,
            onChanged: (value) {
              setState(() {
                _toStation = value;
                _fareData = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── Calculate Button ───────────────────────────────────────────────────────

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _canCalculate() ? _calculateFare : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4D2D), // Zomato / Swiggy signature flame
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _canCalculate() ? 4 : 0,
          shadowColor: const Color(0xFFFF4D2D).withValues(alpha: 0.4),
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calculate_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Calculate Exact Fare',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Calculated Fare Result Card ────────────────────────────────────────────

  Widget _buildFareResultCard() {
    final ticketFare = _fareData!['ticketFare'] ?? 0;
    final smartCardFare = _fareData!['smartCardFare'] ?? 0;
    final savings = _fareData!['totalSavings'] ?? 0.0;
    final mpt = _fareData!['mpt'] ?? 65;
    final isOffPeak = _fareData!['isOffPeak'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with savings banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save ₹${savings.toStringAsFixed(0)} with Smart Card',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOffPeak ? '20% OFF-PEAK' : '10% DISCOUNT',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Two comparison price cards
                Row(
                  children: [
                    // Smart Card Price Card (Highlighted)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.credit_card_rounded, color: Color(0xFF16A34A), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'SMART CARD',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹$smartCardFare',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            const Text(
                              'Recommended',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Standard Token Price Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.token_rounded, color: Color(0xFF64748B), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'TOKEN TICKET',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹$ticketFare',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const Text(
                              'Standard DMRC',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Journey Info Strip (MPT, Peak status)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Text(
                            'Max Allowed Time (MPT): $mpt mins',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isOffPeak ? '🟢 Off-Peak Time' : '🟡 Standard Peak',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Official DMRC Fare Slabs Card ──────────────────────────────────────────

  Widget _buildFareSlabsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.table_chart_rounded, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 8),
              Text(
                'Official DMRC Fare Slabs',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Applicable across all normal Delhi Metro lines (2026)',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          _buildFareSlabRow('0 – 2 km', '₹11', '₹10', false),
          _buildFareSlabRow('2 – 5 km', '₹21', '₹19', true),
          _buildFareSlabRow('5 – 12 km', '₹32', '₹29', false),
          _buildFareSlabRow('12 – 21 km', '₹43', '₹39', true),
          _buildFareSlabRow('21 – 32 km', '₹54', '₹49', false),
          _buildFareSlabRow('32+ km', '₹64', '₹58', true),
        ],
      ),
    );
  }

  Widget _buildFareSlabRow(String distance, String tokenFare, String cardFare, bool isAlt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAlt ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            distance,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          Row(
            children: [
              Text(
                tokenFare,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cardFare,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
