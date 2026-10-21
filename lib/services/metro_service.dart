import 'package:flutter/foundation.dart';
import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'accurate_fare_calculator.dart';
import 'gtfs_graph_service.dart';

/// Why a route search did not return a route.
enum RouteFailure { sameStation, stationNotFound, noRoute, dataUnavailable }

class RouteSearchException implements Exception {
  final RouteFailure reason;
  final String message;
  const RouteSearchException(this.reason, this.message);
  @override
  String toString() => message;
}

class MetroService {
  static List<MetroStation>? _stations;

  Future<List<MetroStation>> getStations() async {
    if (_stations != null && _stations!.isNotEmpty) return _stations!;
    _stations = await GTFSGraphService.getStations();
    return _stations!;
  }

  /// DMRC does not publish a public real-time service-status API, so the app
  /// has no live disruption feed. Returns an empty list (the Live Updates
  /// screen shows typical/static service information instead).
  Future<List<MetroUpdate>> getLiveUpdates() async => const [];

  /// Fastest route between two stations (GTFS graph + Dijkstra).
  ///
  /// Throws [RouteSearchException] with a user-friendly message when the
  /// stations are the same, unknown, or not connected.
  Future<List<MetroRoute>> findRoute(String fromStation, String toStation,
      {DateTime? travelTime}) async {
    final List<MetroRoute> routes;
    try {
      final from = await GTFSGraphService.resolveStationName(fromStation);
      final to = await GTFSGraphService.resolveStationName(toStation);
      if (from == null) {
        throw RouteSearchException(
            RouteFailure.stationNotFound, 'We couldn\'t find a metro station called "$fromStation".');
      }
      if (to == null) {
        throw RouteSearchException(
            RouteFailure.stationNotFound, 'We couldn\'t find a metro station called "$toStation".');
      }
      if (from == to) {
        throw const RouteSearchException(RouteFailure.sameStation,
            'Starting point and destination are the same station. Pick a different destination.');
      }
      routes = await GTFSGraphService.findRoute(
        fromName: from,
        toName: to,
        travelTime: travelTime ?? DateTime.now(),
        isSmartCard: false,
      );
    } on RouteSearchException {
      rethrow;
    } on StationNotFoundException catch (e) {
      throw RouteSearchException(
          RouteFailure.stationNotFound, 'We couldn\'t find a metro station called "${e.name}".');
    } catch (e) {
      debugPrint('MetroService.findRoute failed: $e');
      throw const RouteSearchException(
          RouteFailure.dataUnavailable, 'Metro network data could not be loaded. Please try again.');
    }
    if (routes.isEmpty) {
      throw RouteSearchException(RouteFailure.noRoute,
          'No metro connection found between $fromStation and $toStation.');
    }
    return routes;
  }

  /// Fare between two stations, computed from the same route the route
  /// finder shows (track distance along the fastest route, one ticket per
  /// fare system). Returns null when no route exists.
  Future<Map<String, dynamic>?> calculateFare(String fromStation, String toStation,
      {DateTime? travelTime}) async {
    final when = travelTime ?? DateTime.now();
    final routes = await findRoute(fromStation, toStation, travelTime: when);
    final route = routes.first;
    final token = route.totalFare.round();
    final card = (route.smartCardFare ?? route.totalFare).round();
    final dmrcLeg = route.fareLegs.where((l) => l.system == FareSystem.dmrc);
    final mptFare = dmrcLeg.isNotEmpty ? dmrcLeg.first.tokenFare : token;

    return {
      'fromStation': route.fromStation,
      'toStation': route.toStation,
      'baseFare': token,
      'ticketFare': token,
      'smartCardFare': card,
      'totalSavings': (token - card).toDouble(),
      'mpt': AccurateFareCalculator.mptForFare(mptFare),
      'isOffPeak': AccurateFareCalculator.isOffPeakHour(when),
      'isHoliday': AccurateFareCalculator.isHoliday(when),
      'distanceKm': route.distanceKm,
      'stations': route.totalStations,
      'interchanges': route.interchangeStations.length,
      'travelMinutes': route.totalTime,
      'fareLegs': route.fareLegs,
      'approximate': route.fareIsApproximate,
    };
  }

  List<MetroStation> findNearestStations(double latitude, double longitude, {int limit = 5}) {
    if (_stations == null) return [];
    final withDistance = _stations!
        .map((s) => MapEntry(
            s, AccurateFareCalculator.calculateDistance(latitude, longitude, s.latitude, s.longitude)))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return withDistance.take(limit).map((e) => e.key).toList();
  }
}
