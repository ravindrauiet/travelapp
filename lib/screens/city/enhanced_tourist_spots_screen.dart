import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/ui_kit.dart';

class EnhancedTouristSpotsScreen extends StatefulWidget {
  const EnhancedTouristSpotsScreen({super.key});

  @override
  State<EnhancedTouristSpotsScreen> createState() => _EnhancedTouristSpotsScreenState();
}

class _EnhancedTouristSpotsScreenState extends State<EnhancedTouristSpotsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Monuments', 'Markets', 'Parks', 'Museums', 'Religious', 'Entertainment'];

  static const Color _metroBlue = AppTheme.metroBlue;
  static const Color _feeGreen = Color(0xFF059669);

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
    final p = context.palette;
    final isDark = p.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: _buildSliverHeader(context),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoriesTab(isDark),
              _buildAllPlacesTab(isDark),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
      ),
    );
  }

  // ── Collapsing gradient header with tabs ─────────────────────────────────

  Widget _buildSliverHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: AppTheme.royalGradient.colors.first,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      title: const Text(
        'Discover Delhi',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppTheme.royalGradient),
        child: FlexibleSpaceBar(
          collapseMode: CollapseMode.parallax,
          background: Stack(
            children: [
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              Positioned(
                bottom: 30,
                left: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              Positioned(
                right: 4,
                top: topPad + kToolbarHeight - 16,
                child: Opacity(
                  opacity: 0.95,
                  child: SvgPicture.asset('assets/images/illus_explore.svg', width: 100, height: 100),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: kTextTabBarHeight + 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 110),
                      child: Text(
                        'Heritage landmarks, vibrant bazaars & cultural monuments reachable directly by Delhi Metro.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildStatChip(AppConstants.touristSpotsCount, 'Curated Spots', Icons.place_rounded),
                        const SizedBox(width: 8),
                        _buildStatChip('100% Metro', 'Connected', Icons.subway_rounded),
                        const SizedBox(width: 8),
                        _buildStatChip('₹0–₹50', 'Avg Ticket', Icons.confirmation_number_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.brandSaffron, width: 3.5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, fontFamily: AppTheme.fontFamily),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, fontFamily: AppTheme.fontFamily),
        tabs: const [
          Tab(text: 'Categories'),
          Tab(text: 'Top Curated Spots'),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 9.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Categories tab ───────────────────────────────────────────────────────

  Widget _buildCategoriesTab(bool isDark) {
    final picks = _getAllPlaces().where((p) {
      final r = double.tryParse((p['rating'] as String).replaceAll('★', '')) ?? 0;
      return r >= 4.6;
    }).toList();

    return Builder(
      builder: (context) => CustomScrollView(
        key: const PageStorageKey('tourist-categories'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Explore by category',
              subtitle: 'Pick a vibe — we\'ll show the best spots',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildCategoryCard(
                  'Monuments',
                  Icons.account_balance_rounded,
                  const Color(0xFFDC2626),
                  '${AppConstants.touristSpotsCount} Historic Sites',
                  () => _showCategoryDetails('Monuments', isDark),
                  isDark,
                ),
                _buildCategoryCard(
                  'Markets',
                  Icons.shopping_bag_rounded,
                  const Color(0xFFEA580C),
                  'Iconic Bazaars',
                  () => _showCategoryDetails('Markets', isDark),
                  isDark,
                ),
                _buildCategoryCard(
                  'Parks & Gardens',
                  Icons.park_rounded,
                  const Color(0xFF059669),
                  'Lush Green Havens',
                  () => _showCategoryDetails('Parks', isDark),
                  isDark,
                ),
                _buildCategoryCard(
                  'Museums',
                  Icons.museum_rounded,
                  const Color(0xFF2563EB),
                  'Art & History',
                  () => _showCategoryDetails('Museums', isDark),
                  isDark,
                ),
                _buildCategoryCard(
                  'Spiritual Sites',
                  Icons.temple_buddhist_rounded,
                  const Color(0xFF9333EA),
                  'Temples & Mosques',
                  () => _showCategoryDetails('Religious', isDark),
                  isDark,
                ),
                _buildCategoryCard(
                  'Entertainment',
                  Icons.theater_comedy_rounded,
                  const Color(0xFFDB2777),
                  'Shows & Food Hubs',
                  () => _showCategoryDetails('Entertainment', isDark),
                  isDark,
                ),
              ],
            ),
          ),
          if (picks.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 26)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Editor\'s picks',
                subtitle: 'Highest-rated places in the city',
                actionLabel: 'See all',
                onAction: () => _showCategoryDetails('All', isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: picks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _buildPickCard(picks[i], isDark),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
    bool isDark,
  ) {
    final gradient = LinearGradient(
      colors: [color, Color.lerp(color, AppTheme.brandNight, 0.35)!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.glow(color, alpha: isDark ? 0.18 : 0.28),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  right: -14,
                  bottom: -14,
                  child: Icon(icon, size: 96, color: Colors.white.withValues(alpha: 0.14)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickCard(Map<String, dynamic> place, bool isDark) {
    return SizedBox(
      width: 168,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _showPlaceDetails(place, isDark),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: context.palette.shadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPlaceImage(place),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                        stops: const [0.35, 1.0],
                      ),
                    ),
                  ),
                  Positioned(top: 10, right: 10, child: _buildRatingBadge(place)),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.subway_rounded, size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place['metroStation'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
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
          ),
        ),
      ),
    );
  }

  // ── All places tab ───────────────────────────────────────────────────────

  Widget _buildAllPlacesTab(bool isDark) {
    final filtered = _getFilteredPlaces();

    return Builder(
      builder: (context) => CustomScrollView(
        key: const PageStorageKey('tourist-places'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
          // Category Filter Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterPill(category, isSelected),
                  );
                },
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  title: 'No spots here yet',
                  message: 'We haven\'t curated any $_selectedCategory places so far. Try another category.',
                  illustration: 'assets/images/illus_explore.svg',
                  action: GradientButton(
                    label: 'Show all spots',
                    icon: Icons.explore_rounded,
                    gradient: AppTheme.royalGradient,
                    expand: false,
                    onPressed: () => setState(() => _selectedCategory = 'All'),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildPlaceCard(filtered[index], isDark);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String category, bool isSelected) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected ? AppTheme.royalGradient : null,
        color: isSelected ? null : p.card,
        borderRadius: BorderRadius.circular(22),
        border: isSelected ? null : Border.all(color: p.border),
        boxShadow: isSelected ? AppTheme.glow(AppTheme.royalGradient.colors.last, alpha: 0.28) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : p.textSecondary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(Map<String, dynamic> place) {
    final rating = (place['rating'] as String).replaceAll('★', '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            rating,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceImage(Map<String, dynamic> place) {
    final String? imageUrl = place['imageUrl'];
    if (imageUrl == null || imageUrl.isEmpty) return _buildImageFallback(place);
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildImageFallback(place, loading: true),
      errorWidget: (context, url, error) => _buildImageFallback(place),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color, {bool expand = false}) {
    final p = context.palette;
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: p.tint(color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          if (expand) Expanded(child: text) else Flexible(child: text),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place, bool isDark) {
    final p = context.palette;
    final Color catColor = place['color'] as Color;
    final metroColor = isDark ? const Color(0xFF93C5FD) : _metroBlue;
    final feeColor = isDark ? const Color(0xFF6EE7B7) : _feeGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border.withValues(alpha: isDark ? 1 : 0.7)),
        boxShadow: p.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Header with Cached Network Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPlaceImage(place),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  // Category Chip
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.glow(catColor, alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(place['icon'] as IconData, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            place['category'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rating Badge
                  Positioned(top: 12, right: 12, child: _buildRatingBadge(place)),
                  // Name over photo
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                place['location'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600),
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
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place['description'],
                  style: TextStyle(
                    fontSize: 12.5,
                    color: p.textSecondary,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Metro Station Pill
                _buildInfoChip(Icons.subway_rounded, place['metroStation'], metroColor, expand: true),
                const SizedBox(height: 8),

                // Timings, duration and entry fee chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(Icons.access_time_rounded, place['timings'], p.textSecondary),
                    _buildInfoChip(Icons.timer_rounded, place['visitDuration'], AppTheme.brandViolet),
                    _buildInfoChip(Icons.currency_rupee_rounded, place['entryFee'], feeColor),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  children: [
                    // Plan Metro Route
                    Expanded(
                      child: _buildCompactGradientButton(
                        label: 'Metro Route',
                        icon: Icons.alt_route_rounded,
                        onPressed: () {
                          final resolved = AppConstants.resolveToMetroStation(place['name']);
                          context.push('/metro/route-finder?to=${Uri.encodeComponent(resolved)}');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Details Sheet
                    OutlinedButton.icon(
                      onPressed: () => _showPlaceDetails(place, isDark),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.textPrimary,
                        side: BorderSide(color: p.border, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

  /// Slightly shorter gradient CTA for use inside cards.
  Widget _buildCompactGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.sunsetGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.glow(AppTheme.sunsetGradient.colors.last, alpha: 0.3),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback(Map<String, dynamic> place, {bool loading = false}) {
    final Color color = place['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.15)!,
            Color.lerp(color, AppTheme.brandNight, 0.45)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -20,
            child: Icon(place['icon'] as IconData, size: 130, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Center(
            child: loading
                ? SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white.withValues(alpha: 0.85)),
                  )
                : Icon(place['icon'] as IconData, size: 56, color: Colors.white.withValues(alpha: 0.75)),
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
        'imageUrl': 'https://images.unsplash.com/photo-1598324789736-4861f89564a0?w=800&auto=format&fit=crop&q=80',
        'description': 'UNESCO World Heritage Mughal citadel built by Shah Jahan in 1638, hosting Independence Day address.',
        'location': 'Netaji Subhash Marg, Chandni Chowk, Old Delhi',
        'timings': '09:30 AM – 04:30 PM (Mon Closed)',
        'entryFee': '₹50 (Indians), ₹500 (Foreigners)',
        'rating': '4.5★',
        'category': 'Monuments',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFFDC2626),
        'metroStation': 'Lal Quila / Chandni Chowk (Yellow & Violet)',
        'bestTime': 'October to March',
        'visitDuration': '2-3 hours',
        'highlights': ['Diwan-i-Aam', 'Diwan-i-Khas', 'Sound & Light Show', 'Lahori Gate'],
      },
      {
        'name': 'India Gate',
        'imageUrl': 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800&auto=format&fit=crop&q=80',
        'description': 'Iconic 42-meter triumphal arch war memorial at Kartavya Path honoring 70,000 soldiers.',
        'location': 'Kartavya Path, New Delhi',
        'timings': 'Open 24 Hours',
        'entryFee': 'Free Entry',
        'rating': '4.6★',
        'category': 'Monuments',
        'icon': Icons.flag_rounded,
        'color': const Color(0xFFDC2626),
        'metroStation': 'Central Secretariat (Yellow & Violet Line)',
        'bestTime': 'Evening (05:00 PM – 09:00 PM)',
        'visitDuration': '1-2 hours',
        'highlights': ['National War Memorial', 'Evening Illumination', 'Boating at Canals'],
      },
      {
        'name': 'Qutub Minar',
        'imageUrl': 'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&auto=format&fit=crop&q=80',
        'description': 'World\'s tallest brick minaret (72.5m) and UNESCO World Heritage Site dating back to 1192 AD.',
        'location': 'Mehrauli, New Delhi',
        'timings': '07:00 AM – 05:00 PM',
        'entryFee': '₹40 (Indians), ₹600 (Foreigners)',
        'rating': '4.5★',
        'category': 'Monuments',
        'icon': Icons.architecture_rounded,
        'color': const Color(0xFFDC2626),
        'metroStation': 'Qutab Minar (Yellow Line)',
        'bestTime': 'Morning (08:00 AM – 11:00 AM)',
        'visitDuration': '2 hours',
        'highlights': ['Rustless Iron Pillar', 'Alai Minar', 'Quwwat-ul-Islam Mosque'],
      },
      {
        'name': 'Humayun\'s Tomb',
        'imageUrl': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=800&auto=format&fit=crop&q=80',
        'description': 'Magnificent Persian-style garden tomb built in 1570, the architectural precursor to the Taj Mahal.',
        'location': 'Mathura Road, Nizamuddin East',
        'timings': '06:00 AM – 06:00 PM',
        'entryFee': '₹40 (Indians), ₹600 (Foreigners)',
        'rating': '4.6★',
        'category': 'Monuments',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFFDC2626),
        'metroStation': 'JLN Stadium (Violet Line)',
        'bestTime': 'Golden Hour (04:00 PM – 06:00 PM)',
        'visitDuration': '2 hours',
        'highlights': ['Charbagh Persian Gardens', 'Isa Khan Tomb', 'Double Dome'],
      },

      // Markets
      {
        'name': 'Chandni Chowk',
        'imageUrl': 'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?w=800&auto=format&fit=crop&q=80',
        'description': 'Asia\'s largest wholesale bazaar with famous lanes like Paranthe Wali Gali, spice market and jewelry.',
        'location': 'Old Delhi',
        'timings': '10:00 AM – 08:30 PM (Sun Closed)',
        'entryFee': 'Free Entry',
        'rating': '4.3★',
        'category': 'Markets',
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFFEA580C),
        'metroStation': 'Chandni Chowk (Yellow Line)',
        'bestTime': 'Morning (11:00 AM – 03:00 PM)',
        'visitDuration': '3-4 hours',
        'highlights': ['Khari Baoli Spices', 'Paranthe Wali Gali', 'Kinari Bazaar'],
      },
      {
        'name': 'Connaught Place',
        'imageUrl': 'https://images.unsplash.com/photo-1597040663342-45b6af3d91a5?w=800&auto=format&fit=crop&q=80',
        'description': 'Colonial Georgian-style concentric circle shopping and dining capital hub of Delhi.',
        'location': 'Connaught Place, New Delhi',
        'timings': '10:00 AM – 11:00 PM',
        'entryFee': 'Free Entry',
        'rating': '4.4★',
        'category': 'Markets',
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFFEA580C),
        'metroStation': 'Rajiv Chowk (Yellow & Blue Line interchange)',
        'bestTime': 'Evening (05:00 PM – 10:00 PM)',
        'visitDuration': '2-3 hours',
        'highlights': ['Central Park', 'Palika Underground Bazaar', 'Heritage Cafes'],
      },
      {
        'name': 'Dilli Haat INA',
        'imageUrl': 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800&auto=format&fit=crop&q=80',
        'description': 'Open-air village craft bazaar with rotatory artisan stalls and regional food stalls from 28 states.',
        'location': 'Kidwai Nagar West, INA',
        'timings': '10:30 AM – 10:00 PM',
        'entryFee': '₹30 (Adults), ₹15 (Kids)',
        'rating': '4.4★',
        'category': 'Markets',
        'icon': Icons.storefront_rounded,
        'color': const Color(0xFFEA580C),
        'metroStation': 'Dilli Haat - INA (Yellow & Pink Line)',
        'bestTime': 'Evening (05:00 PM – 09:30 PM)',
        'visitDuration': '2-3 hours',
        'highlights': ['State Food Pavilions', 'Handmade Silk & Pottery', 'Folk Music'],
      },

      // Parks
      {
        'name': 'Lodhi Garden',
        'imageUrl': 'https://images.unsplash.com/photo-1592635196078-9fe3d54f2377?w=800&auto=format&fit=crop&q=80',
        'description': '90 acres of verdant lawns surrounding 15th-century Sayyid and Lodhi dynasty royal mausoleums.',
        'location': 'Lodhi Estate, New Delhi',
        'timings': '06:00 AM – 08:00 PM',
        'entryFee': 'Free Entry',
        'rating': '4.6★',
        'category': 'Parks',
        'icon': Icons.park_rounded,
        'color': const Color(0xFF10B981),
        'metroStation': 'Jor Bagh (Yellow Line)',
        'bestTime': 'Morning (06:30 AM – 09:30 AM)',
        'visitDuration': '1-2 hours',
        'highlights': ['Bara Gumbad', 'Sheesh Gumbad', 'Athpula 8-Pier Bridge'],
      },
      {
        'name': 'Sunder Nursery',
        'imageUrl': 'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=800&auto=format&fit=crop&q=80',
        'description': 'Delhi\'s premier heritage ecological park with restored Mughal pavilions, lakes and 300 tree species.',
        'location': 'Nizamuddin, New Delhi',
        'timings': '07:00 AM – 10:00 PM',
        'entryFee': '₹50 (Adults)',
        'rating': '4.7★',
        'category': 'Parks',
        'icon': Icons.forest_rounded,
        'color': const Color(0xFF10B981),
        'metroStation': 'JLN Stadium (Violet Line)',
        'bestTime': 'Weekend Farmers Market',
        'visitDuration': '2-3 hours',
        'highlights': ['Organic Sunday Market', 'Lakeside Amphitheatre', 'Botanical Trail'],
      },

      // Museums
      {
        'name': 'National Museum',
        'imageUrl': 'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=800&auto=format&fit=crop&q=80',
        'description': 'India\'s premier museum housing 200,000 artifacts from Indus Valley Civilization to modern era.',
        'location': 'Janpath, New Delhi',
        'timings': '10:00 AM – 06:00 PM (Mon Closed)',
        'entryFee': '₹20 (Indians), ₹650 (Foreigners)',
        'rating': '4.5★',
        'category': 'Museums',
        'icon': Icons.museum_rounded,
        'color': const Color(0xFF2563EB),
        'metroStation': 'Udyog Bhawan (Yellow Line)',
        'bestTime': 'Weekday mornings',
        'visitDuration': '3 hours',
        'highlights': ['Harappan Dancing Girl', 'Buddha Relics', 'Miniature Paintings'],
      },
      {
        'name': 'National Rail Museum',
        'imageUrl': 'https://images.unsplash.com/photo-1541427468627-a89a96e5ca1d?w=800&auto=format&fit=crop&q=80',
        'description': 'Expansive outdoor museum exhibiting historic vintage steam engines, royal carriages and toy train.',
        'location': 'Chanakyapuri, New Delhi',
        'timings': '10:00 AM – 05:00 PM (Mon Closed)',
        'entryFee': '₹50 (Adults), ₹10 (Kids)',
        'rating': '4.4★',
        'category': 'Museums',
        'icon': Icons.train_rounded,
        'color': const Color(0xFF2563EB),
        'metroStation': 'Durgabai Deshmukh South Campus (Pink Line)',
        'bestTime': 'Afternoon',
        'visitDuration': '2 hours',
        'highlights': ['Fairy Queen Steam Loco', 'Toy Train Ride', 'Saloon of Prince of Wales'],
      },

      // Religious
      {
        'name': 'Lotus Temple',
        'imageUrl': 'https://images.unsplash.com/photo-1585135497273-1a86b09fe70e?w=800&auto=format&fit=crop&q=80',
        'description': 'Award-winning marble lotus flower Baháʼí House of Worship welcoming individuals of all faiths.',
        'location': 'Bahapur, Kalkaji, New Delhi',
        'timings': '08:30 AM – 05:30 PM (Mon Closed)',
        'entryFee': 'Free Entry',
        'rating': '4.5★',
        'category': 'Religious',
        'icon': Icons.temple_buddhist_rounded,
        'color': const Color(0xFF9333EA),
        'metroStation': 'Kalkaji Mandir (Violet & Magenta Line)',
        'bestTime': 'Morning (09:00 AM – 11:30 AM)',
        'visitDuration': '1 hour',
        'highlights': ['Silent Meditation Hall', '27 Marble Petals', 'Pond Gardens'],
      },
      {
        'name': 'Akshardham Temple',
        'imageUrl': 'https://images.unsplash.com/photo-1605649487212-47bdab064df8?w=800&auto=format&fit=crop&q=80',
        'description': 'Colossal Hindu temple complex showcasing 10,000 years of Indian art, spirituality and boat ride.',
        'location': 'NH 24, Akshardham, New Delhi',
        'timings': '09:30 AM – 08:00 PM (Mon Closed)',
        'entryFee': 'Free Complex (₹250 exhibitions)',
        'rating': '4.7★',
        'category': 'Religious',
        'icon': Icons.temple_hindu_rounded,
        'color': const Color(0xFF9333EA),
        'metroStation': 'Akshardham (Blue Line)',
        'bestTime': 'Evening (04:00 PM – 08:30 PM)',
        'visitDuration': '3-4 hours',
        'highlights': ['Sahaj Anand Musical Fountain', 'Sanskruti Boat Ride', 'Stone Carvings'],
      },

      // Entertainment
      {
        'name': 'Cyber Hub Gurugram',
        'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&auto=format&fit=crop&q=80',
        'description': 'Vibrant social, culinary and nightlife promenade packed with premier bistros, breweries and events.',
        'location': 'DLF Phase 2, Gurugram',
        'timings': '11:00 AM – 01:00 AM',
        'entryFee': 'Free Entry',
        'rating': '4.5★',
        'category': 'Entertainment',
        'icon': Icons.celebration_rounded,
        'color': const Color(0xFFDB2777),
        'metroStation': 'Cyber City (Rapid Metro) / Sikanderpur (Yellow Line)',
        'bestTime': 'Evening & Night',
        'visitDuration': '3 hours',
        'highlights': ['Gourmet Dining', 'Live Amphitheater', 'Microbreweries'],
      },
    ];
  }

  void _showCategoryDetails(String category, bool isDark) {
    setState(() {
      _selectedCategory = category;
      _tabController.animateTo(1);
    });
  }

  void _showPlaceDetails(Map<String, dynamic> place, bool isDark) {
    final p = context.palette;
    final Color catColor = place['color'] as Color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero photo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(
                          height: 190,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildPlaceImage(place),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                                    stops: const [0.45, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 14,
                                bottom: 14,
                                child: TagPill(
                                  label: (place['category'] as String).toUpperCase(),
                                  color: catColor,
                                  icon: place['icon'] as IconData,
                                  onDark: true,
                                ),
                              ),
                              Positioned(top: 12, right: 12, child: _buildRatingBadge(place)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        place['name'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: p.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppCard(
                        color: p.cardAlt,
                        showBorder: false,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
                        child: Column(
                          children: [
                            _buildDetailRow('Nearest Metro', place['metroStation'], Icons.subway_rounded, AppTheme.metroBlue),
                            _buildDetailRow('Location', place['location'], Icons.location_on_rounded, AppTheme.brandRose),
                            _buildDetailRow('Timings', place['timings'], Icons.access_time_rounded, AppTheme.primaryColor),
                            _buildDetailRow('Entry Ticket', place['entryFee'], Icons.currency_rupee_rounded, AppTheme.successColor),
                            _buildDetailRow('Best Time', place['bestTime'], Icons.calendar_today_rounded, AppTheme.warningColor),
                            _buildDetailRow('Visit Duration', place['visitDuration'], Icons.timer_rounded, AppTheme.brandViolet),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Highlights & Attractions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (place['highlights'] as List<String>).map((highlight) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: p.tint(catColor),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: catColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 13, color: catColor),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    highlight,
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GradientButton(
                              label: 'Metro Route',
                              icon: Icons.alt_route_rounded,
                              onPressed: () {
                                Navigator.pop(context);
                                final resolved = AppConstants.resolveToMetroStation(place['name']);
                                context.push('/metro/route-finder?to=${Uri.encodeComponent(resolved)}');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openMaps(place['name']),
                              icon: const Icon(Icons.navigation_rounded, size: 18),
                              label: const Text('Google Maps', maxLines: 1, overflow: TextOverflow.ellipsis),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconBubble(icon: icon, color: color, size: 38, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: p.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
