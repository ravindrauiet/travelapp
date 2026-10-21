import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/searchable_station_dropdown.dart';
import '../../widgets/ui_kit.dart';
import '../../models/metro_route.dart';

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

    if (_fromStation!.toLowerCase() == _toStation!.toLowerCase()) {
      _showError('Starting and destination station are the same. Pick a different destination.');
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final metroProvider = context.read<MetroProvider>();
      // Same route computation as the Route Finder: fare follows the fastest
      // route's track distance, one ticket per fare system.
      final fareData = await metroProvider.calculateFare(_fromStation!, _toStation!);

      if (mounted) {
        setState(() {
          _fareData = fareData;
          _isCalculating = false;
        });
        if (fareData == null) {
          _showError(metroProvider.error ?? 'Could not calculate the fare. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating fare: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Consumer<MetroProvider>(
          builder: (context, metroProvider, child) {
            final header = SliverToBoxAdapter(child: _buildHeader(metroProvider));

            if (metroProvider.isLoading && metroProvider.stations.isEmpty) {
              return CustomScrollView(
                slivers: [
                  header,
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: p.tint(AppTheme.successColor),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(strokeWidth: 3, color: AppTheme.successColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading metro stations…',
                            style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (metroProvider.error != null && metroProvider.stations.isEmpty) {
              return CustomScrollView(
                slivers: [
                  header,
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        title: 'Couldn\'t load stations',
                        message: 'Error: ${metroProvider.error}',
                        action: GradientButton(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          expand: false,
                          onPressed: () => metroProvider.loadStations(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header and card share one sliver so the card paints over the header
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeader(metroProvider),
                      Transform.translate(
                        offset: const Offset(0, -34),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Input Station Selection Card
                              _buildStationInputCard(metroProvider),
                              const SizedBox(height: 20),

                              // Calculated Results Card
                              if (_fareData != null) ...[
                                _buildFareResultCard(),
                                const SizedBox(height: 20),
                              ],

                              // Official DMRC Fare Slabs Table
                              _buildFareSlabsCard(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(MetroProvider metroProvider) {
    return GradientHeader(
      title: 'Fare Calculator',
      subtitle: 'Token vs Smart Card fares, instantly',
      icon: Icons.calculate_rounded,
      gradient: AppTheme.emeraldGradient,
      illustration: 'assets/images/illus_metro.svg',
      bottom: Padding(
        padding: const EdgeInsets.only(bottom: 34),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TagPill(
              label: '${metroProvider.stations.length} STATIONS',
              color: Colors.white,
              icon: Icons.location_on_rounded,
              onDark: true,
            ),
            const TagPill(label: 'UP TO 20% OFF', color: Colors.white, icon: Icons.local_offer_rounded, onDark: true),
          ],
        ),
      ),
    );
  }

  // ── Input Card ─────────────────────────────────────────────────────────────

  Widget _buildStationInputCard(MetroProvider metroProvider) {
    final p = context.palette;

    Widget label(String text, Color dot) {
      return Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: dot, width: 2.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: p.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.route_rounded, color: AppTheme.successColor, size: 38, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select stations',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                    Text(
                      'We\'ll compare token and card fares',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.textTertiary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // FROM Station
          label('STARTING STATION', AppTheme.successColor),
          SearchableStationDropdown(
            stations: metroProvider.stations,
            selectedStation: _fromStation,
            hintText: 'Select origin station',
            prefixIcon: Icons.my_location_rounded,
            accentColor: AppTheme.successColor,
            onChanged: (value) {
              setState(() {
                _fromStation = value;
                _fareData = null;
              });
            },
          ),

          // Station Swap Button Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider(color: p.border, height: 1)),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Swap stations',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _swapStations,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.emeraldGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.glow(AppTheme.successColor, alpha: 0.3),
                        ),
                        child: const Icon(Icons.swap_vert_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Divider(color: p.border, height: 1)),
              ],
            ),
          ),

          // TO Station
          label('DESTINATION STATION', AppTheme.accentColor),
          SearchableStationDropdown(
            stations: metroProvider.stations,
            selectedStation: _toStation,
            hintText: 'Select destination station',
            prefixIcon: Icons.location_on_rounded,
            accentColor: AppTheme.accentColor,
            onChanged: (value) {
              setState(() {
                _toStation = value;
                _fareData = null;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildCalculateButton(),
        ],
      ),
    );
  }

  // ── Calculate Button ───────────────────────────────────────────────────────

  Widget _buildCalculateButton() {
    return GradientButton(
      label: _isCalculating ? 'Calculating…' : 'Calculate Exact Fare',
      icon: _isCalculating ? Icons.hourglass_top_rounded : Icons.calculate_rounded,
      onPressed: _canCalculate() ? _calculateFare : null,
    );
  }

  // ── Calculated Fare Result Card ────────────────────────────────────────────

  Widget _buildFareResultCard() {
    final p = context.palette;
    final ticketFare = _fareData!['ticketFare'] ?? 0;
    final smartCardFare = _fareData!['smartCardFare'] ?? 0;
    final savings = _fareData!['totalSavings'] ?? 0.0;
    final mpt = _fareData!['mpt'] ?? 65;
    final isOffPeak = _fareData!['isOffPeak'] ?? false;
    final isHoliday = _fareData!['isHoliday'] ?? false;
    final distanceKm = (_fareData!['distanceKm'] ?? 0.0) as double;
    final stops = _fareData!['stations'] ?? 0;
    final changes = _fareData!['interchanges'] ?? 0;
    final fareLegs = (_fareData!['fareLegs'] as List<FareLeg>?) ?? const <FareLeg>[];
    final approximate = _fareData!['approximate'] == true;

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border.withValues(alpha: p.isDark ? 1 : 0.7)),
        boxShadow: p.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header with savings banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(gradient: AppTheme.emeraldGradient),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save ₹${savings.toStringAsFixed(0)} with Smart Card',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TagPill(
                  label: isOffPeak && fareLegs.every((l) => l.system == FareSystem.dmrc)
                      ? '20% OFF-PEAK'
                      : '10% DISCOUNT',
                  color: Colors.white,
                  onDark: true,
                ),
              ],
            ),
          ),

          if (_fromStation != null && _toStation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _fromStation!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.accentColor),
                  ),
                  Flexible(
                    child: Text(
                      _toStation!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
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
                          color: p.tint(AppTheme.successColor),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.45), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.credit_card_rounded, color: AppTheme.successColor, size: 16),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'SMART CARD',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.successColor,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              child: Text(
                                '₹$smartCardFare',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const TagPill(
                                label: 'RECOMMENDED', color: AppTheme.successColor, icon: Icons.check_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Standard Token Price Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: p.cardAlt,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: p.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.token_rounded, color: p.textTertiary, size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'TOKEN TICKET',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: p.textTertiary,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              child: Text(
                                '₹$ticketFare',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: p.textSecondary,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            TagPill(label: 'STANDARD DMRC', color: p.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Journey Info Strip (MPT, Peak status)
                Row(
                  children: [
                    Expanded(
                      child: _infoStrip(
                        Icons.timer_outlined,
                        'Max time (MPT)',
                        '$mpt mins',
                        AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoStrip(
                        isOffPeak ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        'Time band',
                        isOffPeak ? 'Off-Peak' : 'Standard Peak',
                        isOffPeak ? AppTheme.successColor : AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _infoStrip(
                        Icons.straighten_rounded,
                        'Route distance',
                        '${distanceKm.toStringAsFixed(1)} km',
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoStrip(
                        Icons.train_rounded,
                        'Stops · changes',
                        '$stops · $changes',
                        AppTheme.brandViolet,
                      ),
                    ),
                  ],
                ),
                if (isHoliday || fareLegs.length > 1 || approximate) ...[
                  const SizedBox(height: 10),
                  Text(
                    [
                      if (isHoliday) 'Sunday / national-holiday fares applied.',
                      if (fareLegs.length > 1)
                        'Needs separate tickets: ${fareLegs.map((l) => '${l.system.label} ₹${l.tokenFare}').join(' + ')}.',
                      if (approximate) 'Airport Express, Aqua Line and Rapid Metro fares are approximate.',
                    ].join(' '),
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoStrip(IconData icon, String label, String value, Color color) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.tint(color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: p.textTertiary),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.textPrimary),
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
    final p = context.palette;
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.table_chart_rounded, color: AppTheme.primaryColor, size: 38, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official DMRC fare slabs',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                    Text(
                      'DMRC lines, effective 25 Aug 2025 (Mon–Sat)',
                      style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('DISTANCE',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8)),
                ),
                SizedBox(
                  width: 52,
                  child: Text('TOKEN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8)),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: Text('CARD',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _buildFareSlabRow('0 – 2 km', '₹11', '₹10', false),
          _buildFareSlabRow('2 – 5 km', '₹21', '₹19', true),
          _buildFareSlabRow('5 – 12 km', '₹32', '₹29', false),
          _buildFareSlabRow('12 – 21 km', '₹43', '₹39', true),
          _buildFareSlabRow('21 – 32 km', '₹54', '₹49', false),
          _buildFareSlabRow('32+ km', '₹64', '₹58', true),
          const SizedBox(height: 10),
          Text(
            'Sundays & national holidays: ₹11 · 11 · 21 · 32 · 43 · 54. '
            'Smart Card gets 10% off, plus another 10% off-peak (before 8 AM, 12–5 PM, after 9 PM). '
            'Distance is measured along the metro route.',
            style: TextStyle(fontSize: 11, color: p.textTertiary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFareSlabRow(String distance, String tokenFare, String cardFare, bool isAlt) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isAlt ? p.cardAlt : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              distance,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              tokenFare,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: p.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: p.tint(AppTheme.successColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cardFare,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
