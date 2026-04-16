import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentRoute {
  final String from;
  final String to;
  final DateTime searchedAt;

  const RecentRoute({
    required this.from,
    required this.to,
    required this.searchedAt,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'searchedAt': searchedAt.toIso8601String(),
      };

  factory RecentRoute.fromJson(Map<String, dynamic> json) => RecentRoute(
        from: json['from'] as String,
        to: json['to'] as String,
        searchedAt: DateTime.parse(json['searchedAt'] as String),
      );
}

class RecentRoutesService {
  static const _key = 'recent_metro_routes';
  static const _maxCount = 5;

  static List<RecentRoute> _cache = [];
  static bool _loaded = false;

  /// Load from SharedPreferences (call once on app start or lazily).
  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      _cache = raw
          .map((s) {
            try {
              return RecentRoute.fromJson(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<RecentRoute>()
          .toList();
    } catch (_) {
      _cache = [];
    }
    _loaded = true;
  }

  /// Returns up to 5 most-recent routes, newest first.
  static Future<List<RecentRoute>> getAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  /// Adds a new search (or moves it to the top if duplicate).
  static Future<void> add(String from, String to) async {
    await _ensureLoaded();

    // Remove existing entry with same from/to (case-insensitive)
    _cache.removeWhere((r) =>
        r.from.toLowerCase() == from.toLowerCase() &&
        r.to.toLowerCase() == to.toLowerCase());

    // Prepend newest
    _cache.insert(0, RecentRoute(from: from, to: to, searchedAt: DateTime.now()));

    // Keep only 5
    if (_cache.length > _maxCount) {
      _cache = _cache.sublist(0, _maxCount);
    }

    await _persist();
  }

  /// Remove a single entry.
  static Future<void> remove(RecentRoute route) async {
    await _ensureLoaded();
    _cache.removeWhere((r) =>
        r.from == route.from &&
        r.to == route.to &&
        r.searchedAt == route.searchedAt);
    await _persist();
  }

  /// Clear all saved routes.
  static Future<void> clear() async {
    _cache = [];
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _cache.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_key, raw);
    } catch (_) {}
  }
}
