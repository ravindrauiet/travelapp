import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/weather_provider.dart';
import '../../models/weather_data.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';

class ProfessionalWeatherScreen extends StatefulWidget {
  const ProfessionalWeatherScreen({super.key});

  @override
  State<ProfessionalWeatherScreen> createState() => _ProfessionalWeatherScreenState();
}

class _ProfessionalWeatherScreenState extends State<ProfessionalWeatherScreen> {
  // CPCB India AQI bands: (upper bound, label, colour)
  static const _aqiBands = <(int, String, Color)>[
    (50, 'Good', Color(0xFF10B981)),
    (100, 'Satisfactory', Color(0xFF84CC16)),
    (200, 'Moderate', Color(0xFFF59E0B)),
    (300, 'Poor', Color(0xFFF97316)),
    (400, 'Very Poor', Color(0xFFEF4444)),
    (500, 'Severe', Color(0xFF9F1239)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadWeather();
    });
  }

  // ── Sky gradient that follows the time of day ────────────────────────────

  LinearGradient get _skyGradient {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 8) {
      // Dawn
      return const LinearGradient(
        colors: [Color(0xFF6D28D9), Color(0xFFF472B6), Color(0xFFFFB86B)],
        stops: [0.0, 0.6, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (h >= 8 && h < 16) {
      // Day
      return const LinearGradient(
        colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
        stops: [0.0, 0.6, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (h >= 16 && h < 19) {
      // Sunset
      return const LinearGradient(
        colors: [AppTheme.brandViolet, AppTheme.brandRose, Color(0xFFFF8A3D)],
        stops: [0.0, 0.6, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Night
    return AppTheme.heroGradient;
  }

  String get _timeOfDayLabel {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 8) return 'Early morning';
    if (h >= 8 && h < 12) return 'Morning';
    if (h >= 12 && h < 16) return 'Afternoon';
    if (h >= 16 && h < 19) return 'Evening';
    return 'Tonight';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        drawer: isTablet
            ? null
            : const AppDrawer(
                title: 'Weather & AQI',
                subtitle: 'Delhi NCR Commute Conditions',
              ),
        body: Consumer<WeatherProvider>(
          builder: (context, weatherProvider, child) {
            final w = weatherProvider.currentWeather;
            final hasData = !weatherProvider.isLoading && weatherProvider.error == null && w != null;

            return RefreshIndicator(
              onRefresh: () async {
                await weatherProvider.loadWeather();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, hasData ? w : null, showMenu: !isTablet),
                    if (weatherProvider.isLoading)
                      _buildLoading(context)
                    else if (weatherProvider.error != null)
                      EmptyState(
                        title: 'Couldn\'t load the weather',
                        message: weatherProvider.error!,
                        action: GradientButton(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          gradient: AppTheme.oceanGradient,
                          expand: false,
                          onPressed: () {
                            weatherProvider.clearError();
                            weatherProvider.loadWeather();
                          },
                        ),
                      )
                    else if (w == null)
                      const EmptyState(
                        title: 'No weather data yet',
                        message: 'Pull down to refresh and fetch the latest Delhi NCR conditions.',
                      )
                    else ...[
                      const SizedBox(height: 22),
                      _buildAirQuality(context, w),
                      const SizedBox(height: 26),
                      const SectionHeader(
                        title: 'Atmospheric metrics',
                        subtitle: 'What the air feels like on your commute',
                      ),
                      const SizedBox(height: 12),
                      _buildWeatherDetails(w),
                      if (weatherProvider.forecast.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        const SectionHeader(
                          title: '7-day commute forecast',
                          subtitle: 'Plan your week of travel',
                        ),
                        const SizedBox(height: 12),
                        _buildForecast(context, weatherProvider.forecast),
                      ],
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 4),
      ),
    );
  }

  // ── Header with big temperature hero ─────────────────────────────────────

  Widget _buildHeader(BuildContext context, WeatherData? weather, {required bool showMenu}) {
    return GradientHeader(
      title: weather?.location ?? 'Weather & Air Quality',
      subtitle: weather == null
          ? 'Delhi NCR commute conditions'
          : '$_timeOfDayLabel • Updated ${DateFormat('h:mm a').format(weather.lastUpdated)}',
      gradient: _skyGradient,
      leading: showMenu
          ? Builder(
              builder: (ctx) => HeaderIconButton(
                icon: Icons.menu_rounded,
                tooltip: 'Menu',
                onTap: () => Scaffold.maybeOf(ctx)?.openDrawer(),
              ),
            )
          : null,
      actions: [
        HeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh Weather',
          onTap: () {
            context.read<WeatherProvider>().loadWeather();
          },
        ),
      ],
      bottom: weather == null ? null : _buildTemperatureHero(weather),
    );
  }

  Widget _buildTemperatureHero(WeatherData weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature.round()}',
                          style: const TextStyle(
                            fontSize: 84,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -4,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            '°C',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weather.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Feels like ${weather.feelsLike.round()}°C',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.04)],
                ),
              ),
              child: Icon(
                _getWeatherIcon(weather.description),
                color: _isNight && !_isCloudy(weather.description) ? const Color(0xFFFDE68A) : Colors.white,
                size: 60,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _buildQuickStat('Humidity', '${weather.humidity.round()}%', Icons.water_drop_rounded),
            const SizedBox(width: 10),
            _buildQuickStat('Wind', '${weather.windSpeed.round()} km/h', Icons.air_rounded),
            const SizedBox(width: 10),
            _buildQuickStat('Pressure', '${weather.pressure} hPa', Icons.compress_rounded),
          ],
        ),
      ],
    );
  }

  bool get _isNight {
    final h = DateTime.now().hour;
    return h >= 19 || h < 5;
  }

  bool _isCloudy(String d) {
    final desc = d.toLowerCase();
    return desc.contains('cloud') || desc.contains('rain') || desc.contains('overcast');
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 3.5, color: AppTheme.infoColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Checking the Delhi sky…',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── AQI gauge card ───────────────────────────────────────────────────────

  Widget _buildAirQuality(BuildContext context, WeatherData weather) {
    final p = context.palette;
    final aqi = weather.airQuality.aqi;
    final aqiColor = _parseColor(weather.airQuality.color);

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.air_rounded, color: AppTheme.successColor, size: 40, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Air Quality Index',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                    Text(
                      'Official CPCB India standard',
                      style: TextStyle(fontSize: 12, color: p.textTertiary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              TagPill(label: 'LIVE', color: aqiColor, icon: Icons.circle),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 240,
              height: 140,
              child: CustomPaint(
                painter: _AqiGaugePainter(
                  value: aqi.toDouble(),
                  bands: _aqiBands,
                  trackColor: p.border,
                  needleColor: p.textPrimary,
                ),
                child: Align(
                  alignment: const Alignment(0, 0.75),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$aqi',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: aqiColor,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weather.airQuality.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: aqiColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.cardAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INDIA CPCB SCALE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.textTertiary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < _aqiBands.length; i++)
                      _buildBandChip(
                        context,
                        '${i == 0 ? 0 : _aqiBands[i - 1].$1 + 1}–${_aqiBands[i].$1}',
                        _aqiBands[i].$2,
                        _aqiBands[i].$3,
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

  Widget _buildBandChip(BuildContext context, String range, String label, Color color) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            '$range $label',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Metrics grid ─────────────────────────────────────────────────────────

  Widget _buildWeatherDetails(WeatherData weather) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${weather.pressure} hPa',
                  label: 'Pressure (norm 1005–1015)',
                  icon: Icons.compress_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: '${weather.visibility} km',
                  label: 'Visibility',
                  icon: Icons.visibility_rounded,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${weather.uvIndex.round()}',
                  label: 'UV index (Moderate)',
                  icon: Icons.wb_sunny_outlined,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: '${weather.feelsLike.round()}°C',
                  label: 'Feels like',
                  icon: Icons.thermostat_rounded,
                  color: AppTheme.brandRose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Forecast cards ───────────────────────────────────────────────────────

  Widget _buildForecast(BuildContext context, List<WeatherForecast> forecast) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: forecast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _buildForecastItem(context, forecast[i], isToday: i == 0),
      ),
    );
  }

  Widget _buildForecastItem(BuildContext context, WeatherForecast day, {required bool isToday}) {
    final p = context.palette;
    final fg = isToday ? Colors.white : p.textPrimary;
    final fgSoft = isToday ? Colors.white.withValues(alpha: 0.78) : p.textTertiary;
    final iconColor = isToday ? Colors.white : _forecastIconColor(day.description);

    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isToday ? null : p.card,
        gradient: isToday ? _skyGradient : null,
        borderRadius: BorderRadius.circular(22),
        border: isToday ? null : Border.all(color: p.border.withValues(alpha: p.isDark ? 1 : 0.7)),
        boxShadow: isToday ? AppTheme.glow(_skyGradient.colors[1], alpha: 0.3) : p.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(day.date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
          ),
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isToday ? Colors.white.withValues(alpha: 0.2) : p.tint(iconColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getWeatherIcon(day.description), color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            day.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: fgSoft, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${day.maxTemp.round()}°',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg, height: 1.0),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${day.minTemp.round()}°',
                  maxLines: 1,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fgSoft, height: 1.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _forecastIconColor(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('rain') || desc.contains('shower')) return AppTheme.infoColor;
    if (desc.contains('cloud') || desc.contains('overcast')) return AppTheme.primaryColor;
    if (desc.contains('haze') || desc.contains('fog') || desc.contains('mist')) return AppTheme.metroGrey;
    return AppTheme.warningColor;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    return DateFormat('EEE, d MMM').format(date);
  }

  IconData _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('sun') || desc.contains('clear')) {
      return Icons.wb_sunny_rounded;
    } else if (desc.contains('cloud') || desc.contains('overcast')) {
      return Icons.wb_cloudy_rounded;
    } else if (desc.contains('rain') || desc.contains('shower')) {
      return Icons.grain_rounded;
    } else if (desc.contains('haze') || desc.contains('fog') || desc.contains('mist')) {
      return Icons.blur_on_rounded;
    } else {
      return Icons.wb_sunny_rounded;
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFF59E0B);
    }
  }
}

/// Semicircular AQI gauge with CPCB colour bands and a needle marker.
class _AqiGaugePainter extends CustomPainter {
  final double value;
  final List<(int, String, Color)> bands;
  final Color trackColor;
  final Color needleColor;

  _AqiGaugePainter({
    required this.value,
    required this.bands,
    required this.trackColor,
    required this.needleColor,
  });

  static const double _max = 500;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final radius = math.min(size.width / 2, size.height) - stroke / 2 - 2;
    final center = Offset(size.width / 2, size.height - 6);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Colour bands
    var start = 0.0;
    const gap = 0.025;
    for (final band in bands) {
      final end = band.$1.toDouble();
      final a0 = math.pi + (start / _max) * math.pi;
      final sweep = ((end - start) / _max) * math.pi;
      canvas.drawArc(
        rect,
        a0 + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..color = band.$3
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start = end;
    }

    // Marker
    final clamped = value.clamp(0, _max).toDouble();
    final angle = math.pi + (clamped / _max) * math.pi;
    final markerPos = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(markerPos, stroke / 2 + 5, Paint()..color = Colors.black.withValues(alpha: 0.15));
    canvas.drawCircle(markerPos, stroke / 2 + 4, Paint()..color = Colors.white);
    canvas.drawCircle(markerPos, stroke / 2 - 1, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _AqiGaugePainter old) =>
      old.value != value || old.trackColor != trackColor || old.needleColor != needleColor;
}
