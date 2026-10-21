import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles all local push notifications for the station tracker.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Notification IDs
  static const int _idApproaching = 1001;
  static const int _idArrived = 1002;
  static const int _idRouteUpdate = 1003;

  // Channel IDs
  static const String _channelId = 'metromate_tracker';
  static const String _channelName = 'Station Tracker';
  static const String _channelDesc =
      'Alerts when you approach or arrive at metro stations';

  /// Call once from main() before runApp().
  static Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Request notification permission on Android 13+ / iOS.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService.requestPermission error: $e');
    }
    return false;
  }

  /// Show "Approaching [station]" notification.
  static Future<void> showApproachingStation(
      String stationName, int distanceMetres) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.show(
        _idApproaching,
        '🚇 Approaching Station',
        '$stationName · ${distanceMetres}m away (~${(distanceMetres / 80).ceil()} min walk)',
        _buildDetails(color: 0xFFFF9800),
      );
    } catch (e) {
      debugPrint('NotificationService.showApproachingStation error: $e');
    }
  }

  /// Show "Arrived at [station]" notification.
  static Future<void> showArrivedAtStation(String stationName) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.show(
        _idArrived,
        '✅ Arrived at Station',
        'You are at $stationName',
        _buildDetails(color: 0xFF4CAF50, ongoing: false),
      );
    } catch (e) {
      debugPrint('NotificationService.showArrivedAtStation error: $e');
    }
  }

  /// Show route progress update.
  static Future<void> showRouteProgress({
    required String currentStation,
    required String nextStation,
    required int remainingStations,
  }) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.show(
        _idRouteUpdate,
        '🗺️ Route Update — $currentStation',
        'Next: $nextStation · $remainingStations station${remainingStations == 1 ? '' : 's'} remaining',
        _buildDetails(color: 0xFF1976D2),
      );
    } catch (e) {
      debugPrint('NotificationService.showRouteProgress error: $e');
    }
  }

  /// "Change here" alert at an interchange on the followed route.
  static Future<void> showInterchangeAlert(String stationName, String changeTo) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.show(
        _idRouteUpdate,
        '🔁 Change at $stationName',
        'Get off here and change to $changeTo',
        _buildDetails(color: 0xFFFF9800),
      );
    } catch (e) {
      debugPrint('NotificationService.showInterchangeAlert error: $e');
    }
  }

  /// One stop before the destination.
  static Future<void> showDestinationNext(String destination) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.show(
        _idRouteUpdate,
        '🔔 Next stop: $destination',
        'Get ready to get off at the next station',
        _buildDetails(color: 0xFFFF9800),
      );
    } catch (e) {
      debugPrint('NotificationService.showDestinationNext error: $e');
    }
  }

  /// Destination reached — tracking stops automatically.
  static Future<void> showDestinationReached(String destination) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.show(
        _idArrived,
        '✅ You have arrived at $destination',
        'Journey complete — GPS tracking has been turned off',
        _buildDetails(color: 0xFF4CAF50),
      );
    } catch (e) {
      debugPrint('NotificationService.showDestinationReached error: $e');
    }
  }

  /// Cancel all active notifications.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService.cancelAll error: $e');
    }
  }

  static NotificationDetails _buildDetails({
    required int color,
    bool ongoing = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        color: Color(color),
        ongoing: ongoing,
        autoCancel: true,
        icon: '@drawable/ic_notification',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );
  }
}
