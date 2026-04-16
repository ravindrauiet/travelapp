import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _error;

  // Live stream state
  StreamSubscription<Position>? _streamSub;
  bool _isStreaming = false;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  String? get error => _error;

  // ── One-shot fetch ──────────────────────────────────────────────────────────

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied.';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _getAddressFromPosition(_currentPosition!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Fallback to Delhi centre for web / simulator
      _currentPosition = Position(
        latitude: 28.6139,
        longitude: 77.2090,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      _currentAddress = 'Delhi, India';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Continuous stream ───────────────────────────────────────────────────────

  /// Start streaming position updates every time the user moves ≥15 m.
  Future<void> startLocationStream() async {
    if (_isStreaming) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Location services are disabled.';
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _error = 'Location permission denied.';
      notifyListeners();
      return;
    }

    _isStreaming = true;
    _error = null;
    notifyListeners();

    _streamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen(
      (pos) {
        _currentPosition = pos;
        notifyListeners();
        // Reverse-geocode occasionally (every ~100 m)
        _getAddressFromPosition(pos);
      },
      onError: (e) {
        _error = 'Location stream error: $e';
        _isStreaming = false;
        notifyListeners();
      },
    );
  }

  /// Stop the live stream.
  void stopLocationStream() {
    _streamSub?.cancel();
    _streamSub = null;
    _isStreaming = false;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _currentAddress =
            [p.street, p.subLocality, p.locality]
                .where((s) => s != null && s.isNotEmpty)
                .join(', ');
        notifyListeners();
      }
    } catch (_) {
      // Reverse geocoding is best-effort
    }
  }

  double? getDistanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
