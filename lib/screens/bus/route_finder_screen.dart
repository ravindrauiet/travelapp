import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/bus_network.dart';
import '../../providers/bus_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/ui_kit.dart';
import 'bus_ui.dart';

class BusRouteFinderScreen extends StatefulWidget {
  const BusRouteFinderScreen({
    super.key,
    this.initialFrom,
    this.initialTo,
  });

  final String? initialFrom;
  final String? initialTo;

  @override
  State<BusRouteFinderScreen> createState() => _BusRouteFinderScreenState();
}

enum _Field { from, to }

class _BusRouteFinderScreenState extends State<BusRouteFinderScreen> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();

  BusPlace? _from;
  BusPlace? _to;
  String? _fromNote; // e.g. "Nearest stop · 350 m"

  _Field? _activeField;
  List<BusPlace> _suggestions = const [];
  Timer? _debounce;
  Timer? _blurTimer;

  List<BusJourney>? _journeys;
  bool _isSearching = false;
  bool _isLocating = false;
  String? _message;
  DateTime _searchedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialFrom ?? '');
    _toController = TextEditingController(text: widget.initialTo ?? '');
    _fromFocus.addListener(() => _onFocus(_Field.from, _fromFocus));
    _toFocus.addListener(() => _onFocus(_Field.to, _toFocus));

    final bus = context.read<BusProvider>();
    bus.loadRecentSearches();
    bus.ensureLoaded().then((_) {
      if (!mounted || !bus.isReady) return;
      if ((widget.initialFrom ?? '').isNotEmpty) _from = bus.resolvePlace(widget.initialFrom!);
      if ((widget.initialTo ?? '').isNotEmpty) _to = bus.resolvePlace(widget.initialTo!);
      if (_from != null) _fromController.text = _from!.name;
      if (_to != null) _toController.text = _to!.name;
      setState(() {});
      if (_from != null && _to != null) _search();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _blurTimer?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  // ── Input handling ────────────────────────────────────────────────────────

  void _onFocus(_Field field, FocusNode node) {
    if (node.hasFocus) {
      setState(() => _activeField = field);
      _updateSuggestions(field == _Field.from ? _fromController.text : _toController.text);
    } else {
      // Close suggestions once neither field is focused. The delay lets a tap
      // on a suggestion (which can blur the field first on web) still land.
      _blurTimer?.cancel();
      _blurTimer = Timer(const Duration(milliseconds: 250), () {
        if (!mounted || _fromFocus.hasFocus || _toFocus.hasFocus || _activeField == null) return;
        setState(() => _activeField = null);
      });
    }
  }

  void _onChanged(_Field field, String text) {
    setState(() {
      if (field == _Field.from) {
        if (_from?.name != text) {
          _from = null;
          _fromNote = null;
        }
      } else if (_to?.name != text) {
        _to = null;
      }
      _activeField = field;
      _message = null;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () => _updateSuggestions(text));
  }

  void _updateSuggestions(String text) {
    if (!mounted) return;
    final bus = context.read<BusProvider>();
    setState(() => _suggestions = text.trim().isEmpty ? const [] : bus.suggestPlaces(text));
  }

  void _pick(BusPlace place) {
    final field = _activeField ?? (_from == null ? _Field.from : _Field.to);
    setState(() {
      if (field == _Field.from) {
        _from = place;
        _fromNote = null;
        _fromController.text = place.name;
      } else {
        _to = place;
        _toController.text = place.name;
      }
      _suggestions = const [];
      _journeys = null;
      _message = null;
    });
    if (field == _Field.from && _to == null) {
      _toFocus.requestFocus();
    } else if (_from != null && _to != null) {
      _search();
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _activeField = null);
    }
  }

  void _swap() {
    setState(() {
      final t = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = t;
      final p = _from;
      _from = _to;
      _to = p;
      _fromNote = null;
      _journeys = null;
      _message = null;
    });
    if (_from != null && _to != null) _search();
  }

  Future<void> _useMyLocation() async {
    final bus = context.read<BusProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLocating = true);
    final (pos, issue) = await locateUser(context);
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (pos == null) {
      final i = issue ?? LocationIssue.unavailable;
      messenger.showSnackBar(SnackBar(
        content: Text(i.message),
        action: i.settingsLabel == null
            ? null
            : SnackBarAction(label: 'Settings', onPressed: i.openSettings),
      ));
      return;
    }
    await bus.ensureLoaded();
    if (!mounted) return;
    final near = bus.nearbyStops(pos.latitude, pos.longitude, limit: 1, maxKm: 2);
    if (near.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No bus stop found within 2 km of you')));
      return;
    }
    final n = near.first;
    setState(() {
      _from = n.place;
      _fromController.text = n.place.name;
      _fromNote = 'Nearest stop · ${formatDistance(n.distanceKm)} · ${n.walkMinutes} min walk';
      _suggestions = const [];
      _journeys = null;
    });
    if (_to != null) {
      _search();
    } else {
      _toFocus.requestFocus();
    }
  }

  bool get _canSearch =>
      _fromController.text.trim().isNotEmpty && _toController.text.trim().isNotEmpty && !_isSearching;

  Future<void> _search() async {
    final bus = context.read<BusProvider>();
    FocusScope.of(context).unfocus();
    await bus.ensureLoaded();
    if (!mounted || !bus.isReady) return;

    final from = _from ?? bus.resolvePlace(_fromController.text);
    final to = _to ?? bus.resolvePlace(_toController.text);
    if (from == null || to == null) {
      final missing = from == null ? _fromController.text.trim() : _toController.text.trim();
      setState(() {
        _activeField = null;
        _suggestions = const [];
        _journeys = null;
        _message = 'No bus stop matches "$missing". Start typing and pick a stop from the list.';
      });
      return;
    }
    if (from == to) {
      setState(() {
        _activeField = null;
        _journeys = null;
        _message = 'From and To are the same stop. Pick a different destination.';
      });
      return;
    }

    setState(() {
      _from = from;
      _to = to;
      _fromController.text = from.name;
      _toController.text = to.name;
      _activeField = null;
      _suggestions = const [];
      _message = null;
      _isSearching = true;
    });

    final journeys = await bus.findJourneys(from, to);
    if (!mounted) return;
    setState(() {
      _journeys = journeys;
      _isSearching = false;
      _searchedAt = DateTime.now();
    });
    bus.addRecentSearch(from.name, to.name);
  }

  void _runRecent(BusRecentSearch r) {
    final bus = context.read<BusProvider>();
    setState(() {
      _from = bus.resolvePlace(r.from);
      _to = bus.resolvePlace(r.to);
      _fromController.text = _from?.name ?? r.from;
      _toController.text = _to?.name ?? r.to;
      _fromNote = null;
    });
    _search();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bus = context.watch<BusProvider>();
    final showSuggestions = _activeField != null && _suggestions.isNotEmpty;
    final journeys = _journeys;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverToBoxAdapter(
                child: GradientHeader(
                  title: 'Bus Route Finder',
                  subtitle: 'Direct & one-change DTC and cluster buses',
                  icon: Icons.alt_route_rounded,
                  gradient: AppTheme.emeraldGradient,
                  illustration: 'assets/images/illus_bus.svg',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputCard(bus),
                      const SizedBox(height: 16),
                      if (!bus.isReady)
                        BusNetworkStatusView(bus: bus)
                      else if (showSuggestions)
                        _buildSuggestions()
                      else if (_isSearching)
                        const BusLoadingView(message: 'Finding the best buses…')
                      else if (_message != null)
                        _buildMessage(_message!)
                      else if (journeys == null) ...[
                        _buildRecent(bus),
                        _buildPopularChips(bus),
                      ] else if (journeys.isEmpty)
                        _buildEmptyResults()
                      else
                        _buildResultsHeader(journeys.length),
                    ],
                  ),
                ),
              ),
              if (bus.isReady && !showSuggestions && !_isSearching && _message == null && journeys != null && journeys.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _JourneyCard(
                        journey: journeys[index],
                        now: _searchedAt,
                        best: index == 0,
                        onTap: () => context.push('/bus/journey', extra: journeys[index]),
                      ),
                      childCount: journeys.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
      ),
    );
  }

  // ── Input card ────────────────────────────────────────────────────────────

  Widget _buildInputCard(BusProvider bus) {
    final p = context.palette;
    final fieldStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary);
    const pad = EdgeInsets.fromLTRB(14, 14, 56, 14);

    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.commute_rounded, color: busGreen, size: 36, radius: 11),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Plan Bus Trip',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                ),
              ),
              const TagPill(label: 'DTC & CLUSTER', color: busGreen),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  TextField(
                    key: const ValueKey('bus-from'),
                    controller: _fromController,
                    focusNode: _fromFocus,
                    style: fieldStyle,
                    textInputAction: TextInputAction.next,
                    onChanged: (t) => _onChanged(_Field.from, t),
                    onSubmitted: (_) => _toFocus.requestFocus(),
                    decoration: busFieldDecoration(
                      context,
                      label: 'FROM',
                      hint: 'Bus stop, e.g. Kashmere Gate',
                      icon: Icons.trip_origin_rounded,
                      contentPadding: pad,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('bus-to'),
                    controller: _toController,
                    focusNode: _toFocus,
                    style: fieldStyle,
                    textInputAction: TextInputAction.search,
                    onChanged: (t) => _onChanged(_Field.to, t),
                    onSubmitted: (_) => _canSearch ? _search() : null,
                    decoration: busFieldDecoration(
                      context,
                      label: 'TO',
                      hint: 'Bus stop, e.g. Nehru Place',
                      icon: Icons.location_on_rounded,
                      iconColor: AppTheme.brandRose,
                      contentPadding: pad,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.glow(busGreen, alpha: 0.22),
                    ),
                    child: Material(
                      color: p.card,
                      shape: CircleBorder(side: BorderSide(color: p.border)),
                      child: InkWell(
                        onTap: _swap,
                        customBorder: const CircleBorder(),
                        child: const Tooltip(
                          message: 'Swap',
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.swap_vert_rounded, size: 20, color: busGreen),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: _isLocating ? null : _useMyLocation,
                style: TextButton.styleFrom(
                  foregroundColor: busGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamily),
                ),
                icon: _isLocating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: busGreen))
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: Text(_isLocating ? 'Locating…' : 'Use my location'),
              ),
              const SizedBox(width: 6),
              if (_fromNote != null)
                Expanded(
                  child: Text(
                    _fromNote!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GradientButton(
            label: 'Search Bus Routes',
            icon: Icons.search_rounded,
            gradient: AppTheme.emeraldGradient,
            onPressed: _canSearch && bus.isReady ? _search : null,
          ),
        ],
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildSuggestions() {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
            child: Text(
              _activeField == _Field.from ? 'PICK STARTING STOP' : 'PICK DESTINATION STOP',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8),
            ),
          ),
          for (final place in _suggestions) BusPlaceTile(place: place, onTap: () => _pick(place)),
        ],
      ),
    );
  }

  Widget _buildMessage(String text) {
    final p = context.palette;
    return AppCard(
      child: Row(
        children: [
          const IconBubble(icon: Icons.search_off_rounded, color: AppTheme.warningColor, size: 36, radius: 11),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildRecent(BusProvider bus) {
    final recent = bus.recentSearches;
    if (recent.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'RECENT SEARCHES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8),
                ),
              ),
              TextButton(
                onPressed: bus.clearRecentSearches,
                style: TextButton.styleFrom(
                  foregroundColor: p.textTertiary,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final r in recent)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.history_rounded, color: p.textTertiary, size: 20),
                    title: Text(
                      '${r.from}  →  ${r.to}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove',
                      icon: Icon(Icons.close_rounded, size: 18, color: p.textTertiary),
                      onPressed: () => bus.removeRecentSearch(r),
                    ),
                    onTap: () => _runRecent(r),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularChips(BusProvider bus) {
    final p = context.palette;
    final stops = bus.busiestPlaces(limit: 10);
    if (stops.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUSIEST STOPS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stops.map((stop) {
            return Material(
              color: p.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: p.border),
              ),
              child: InkWell(
                onTap: () {
                  setState(() => _activeField = _from == null ? _Field.from : _Field.to);
                  _pick(stop);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: p.tint(busGreen), shape: BoxShape.circle),
                        child: const Icon(Icons.directions_bus_filled_rounded, size: 11, color: busGreen),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          stop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${bus.routeCountAt(stop)}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Number = bus routes serving the stop',
          style: TextStyle(fontSize: 11, color: p.textTertiary),
        ),
      ],
    );
  }

  Widget _buildEmptyResults() {
    return const Center(
      child: EmptyState(
        title: 'No bus connection found',
        message: 'No direct or one-change bus links these stops in the timetable. '
            'Try a bigger stop nearby, like a terminal or depot.',
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.directions_bus_rounded, color: busGreen, size: 34, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count bus option${count == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.textPrimary, letterSpacing: -0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const ScheduledNote(text: 'Travel times and next buses are approximate, from the timetable — not live.'),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Journey card ────────────────────────────────────────────────────────────

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.journey, required this.now, required this.onTap, this.best = false});

  final BusJourney journey;
  final DateTime now;
  final VoidCallback onTap;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bus = context.read<BusProvider>();
    final first = journey.legs.first;
    final last = journey.legs.last;
    final next = bus.network.nextArrivals(first.line, first.fromIndex, now, count: 1);

    return AppCard(
      margin: const EdgeInsets.only(top: 12),
      padding: EdgeInsets.zero,
      radius: 22,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.tint(busGreen),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < journey.legs.length; i++) ...[
                        if (i > 0) Icon(Icons.chevron_right_rounded, size: 18, color: p.textTertiary),
                        BusNumberBadge(journey.legs[i].line.number),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TagPill(
                  label: journey.isDirect ? 'DIRECT' : '1 CHANGE',
                  color: journey.isDirect ? busGreen : AppTheme.warningColor,
                  icon: journey.isDirect ? Icons.check_circle_rounded : Icons.transfer_within_a_station_rounded,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          '~${formatDuration(journey.totalMinutes)}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.textPrimary, letterSpacing: -0.5),
                        ),
                        if (best) const TagPill(label: 'BEST', color: AppTheme.primaryColor),
                      ],
                    ),
                    Text(
                      'Non-AC ₹${journey.fareNonAc} · AC ₹${journey.fareAc}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: busGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _endpoint(context, 'BOARD AT', first.boardStop.name, busGreen),
                if (!journey.isDirect) ...[
                  const SizedBox(height: 8),
                  _endpoint(
                    context,
                    'CHANGE AT',
                    journey.transferWalkMeters > 0
                        ? '${first.alightStop.name} → walk ${journey.transferWalkMeters} m'
                        : first.alightStop.name,
                    AppTheme.warningColor,
                  ),
                ],
                const SizedBox(height: 8),
                _endpoint(context, 'GET OFF AT', last.alightStop.name, AppTheme.brandRose),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    BusInfoPill(Icons.straighten_rounded, formatDistance(journey.distanceKm), AppTheme.accentColor),
                    BusInfoPill(Icons.place_rounded, '${journey.totalStops} stops', AppTheme.brandViolet),
                    if (next.isNotEmpty)
                      BusInfoPill(
                        Icons.schedule_rounded,
                        'Next ${first.line.number} ~${formatClock(next.first.time)} (${relativeTime(next.first.time, now)})',
                        AppTheme.primaryColor,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const PinkTicketNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _endpoint(BuildContext context, String label, String value, Color dot) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.5, height: 1.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.textPrimary),
          ),
        ),
      ],
    );
  }
}
