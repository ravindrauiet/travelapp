import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Why the user's location couldn't be read.
enum LocationIssue { serviceOff, denied, deniedForever, unavailable }

class UserLocationResult {
  final Position? position;
  final LocationIssue? issue;

  const UserLocationResult.ok(Position this.position) : issue = null;
  const UserLocationResult.failed(LocationIssue this.issue) : position = null;

  bool get ok => position != null;

  String get message {
    switch (issue) {
      case LocationIssue.serviceOff:
        return 'Turn on location services to see buses near you.';
      case LocationIssue.denied:
        return 'Allow location access to see buses near you.';
      case LocationIssue.deniedForever:
        return 'Location access is blocked. Enable it for Metromate in Settings.';
      case LocationIssue.unavailable:
        return 'Couldn\'t get your location right now. Try again outdoors or in a moment.';
      case null:
        return '';
    }
  }

  /// Whether a "Open settings" button makes sense.
  bool get needsSettings => issue == LocationIssue.serviceOff || issue == LocationIssue.deniedForever;
}

/// One-shot location with clear failure reasons (unlike LocationProvider,
/// which silently falls back to central Delhi).
Future<UserLocationResult> getUserLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const UserLocationResult.failed(LocationIssue.serviceOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const UserLocationResult.failed(LocationIssue.deniedForever);
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      return const UserLocationResult.failed(LocationIssue.denied);
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      return UserLocationResult.ok(pos);
    } catch (_) {
      final last = kIsWeb ? null : await Geolocator.getLastKnownPosition();
      if (last != null) return UserLocationResult.ok(last);
      return const UserLocationResult.failed(LocationIssue.unavailable);
    }
  } catch (e) {
    debugPrint('getUserLocation: $e');
    return const UserLocationResult.failed(LocationIssue.unavailable);
  }
}

/// Opens the relevant system settings page for [issue].
Future<void> openLocationSettingsFor(LocationIssue? issue) async {
  if (issue == LocationIssue.serviceOff) {
    await Geolocator.openLocationSettings();
  } else {
    await Geolocator.openAppSettings();
  }
}
