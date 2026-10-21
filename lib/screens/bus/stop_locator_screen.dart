import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/bus_provider.dart';
import '../../models/bus_station.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/ui_kit.dart';

class BusStopLocatorScreen extends StatefulWidget {
  const BusStopLocatorScreen({super.key});

  @override
  State<BusStopLocatorScreen> createState() => _BusStopLocatorScreenState();
}

class _BusStopLocatorScreenState extends State<BusStopLocatorScreen> {
  static const _busGreen = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusProvider>().loadStations();
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Consumer2<BusProvider, LocationProvider>(
          builder: (context, busProvider, locationProvider, child) {
            final pos = locationProvider.currentPosition;
            final stations = pos != null
                ? busProvider.findNearestStations(pos.latitude, pos.longitude)
                : busProvider.stations;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    title: 'Nearby Bus Stops',
                    subtitle: 'DTC & cluster stops around you',
                    icon: Icons.place_rounded,
                    gradient: AppTheme.emeraldGradient,
                    illustration: 'assets/images/illus_bus.svg',
                    actions: [
                      HeaderIconButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Refresh Location',
                        onTap: () => context.read<LocationProvider>().getCurrentLocation(),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Status Banner
                        _buildLocationHeader(locationProvider),
                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Bus Stops in Your Area',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            TagPill(
                              label: '${stations.length} STOPS',
                              color: _busGreen,
                              icon: Icons.directions_bus_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bus Stops List
                if (busProvider.isLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(strokeWidth: 3, color: _busGreen),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Loading nearby bus stops…',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (stations.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        title: 'No bus stops found nearby',
                        message: 'Turn on location services or tap the locate button to try again.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final stop = stations[index];
                          final distance = pos != null
                              ? locationProvider.getDistanceTo(stop.latitude, stop.longitude)
                              : null;
                          return _buildStopCard(stop, distance);
                        },
                        childCount: stations.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
      ),
    );
  }

  Widget _buildLocationHeader(LocationProvider locationProvider) {
    final p = context.palette;
    final addr = locationProvider.currentAddress ?? 'Detecting GPS Location…';

    return AppCard(
      radius: 22,
      child: Row(
        children: [
          const IconBubble(icon: Icons.near_me_rounded, color: _busGreen, filled: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT LOCATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: p.textTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  addr,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (locationProvider.isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _busGreen),
            ),
        ],
      ),
    );
  }

  Widget _buildStopCard(BusStation stop, double? distance) {
    final p = context.palette;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(
                icon: stop.isTerminal ? Icons.garage_rounded : Icons.directions_bus_rounded,
                color: stop.isTerminal ? AppTheme.accentColor : _busGreen,
                size: 42,
                radius: 13,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Code: ${stop.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                          ),
                        ),
                        if (stop.isTerminal) ...[
                          const SizedBox(width: 6),
                          const TagPill(label: 'TERMINAL', color: AppTheme.accentColor),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (distance != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.tint(AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_walk_rounded, size: 13, color: p.primary),
                      const SizedBox(width: 3),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: p.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (stop.busNumbers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 12),

            // Bus numbers available chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stop.busNumbers.map((bus) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.tint(_busGreen),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _busGreen.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    bus,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _busGreen,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
