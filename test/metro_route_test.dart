import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:metromate/models/metro_route.dart';
import 'package:metromate/services/accurate_fare_calculator.dart';
import 'package:metromate/services/gtfs_graph_service.dart';
import 'package:metromate/services/metro_service.dart';

/// A weekday, peak-hour moment (Tue 21 Oct 2025, 09:30) so fares are the
/// normal-day token fares and no off-peak card discount applies.
final _weekdayPeak = DateTime(2025, 10, 21, 9, 30);

Future<MetroRoute> _route(String from, String to, {DateTime? when}) async {
  final routes = await GTFSGraphService.findRoute(
    fromName: from,
    toName: to,
    travelTime: when ?? _weekdayPeak,
    isSmartCard: false,
  );
  expect(routes, isNotEmpty, reason: 'no route $from → $to');
  return routes.first;
}

/// Ordered GTFS line sequences (display names) used to verify contiguity.
late Map<String, List<List<String>>> _lineSequences;

String _describe(MetroRoute r) {
  final b = StringBuffer('${r.fromStation} → ${r.toStation}: ${r.totalTime} min, '
      '${r.totalStations} stops, ${r.distanceKm} km, ₹${r.totalFare.toStringAsFixed(0)}'
      ' (card ₹${r.smartCardFare?.toStringAsFixed(0)})\n');
  for (final s in r.segments) {
    b.writeln('   [${s.line}] ${s.fromStation} → ${s.toStation} '
        '(${s.stationsCount} stops, ${s.timeMinutes} min)');
  }
  b.write('   changes: ${r.interchangeStations}');
  return b.toString();
}

/// Every leg must be a contiguous run of stations on that line.
void _expectContiguous(MetroRoute r) {
  for (final seg in r.segments) {
    if (seg.line == GTFSGraphService.walkLine) continue;
    final stations = [seg.fromStation, ...seg.intermediateStations, seg.toStation];
    final seqs = _lineSequences[seg.line];
    expect(seqs, isNotNull, reason: 'unknown line ${seg.line}');
    final ok = seqs!.any((seq) {
      for (int start = 0; start < seq.length; start++) {
        if (seq[start] != stations.first) continue;
        // forward
        if (start + stations.length <= seq.length &&
            List.generate(stations.length, (i) => seq[start + i]).join('|') == stations.join('|')) {
          return true;
        }
        // backward
        if (start - stations.length + 1 >= 0 &&
            List.generate(stations.length, (i) => seq[start - i]).join('|') == stations.join('|')) {
          return true;
        }
      }
      return false;
    });
    expect(ok, isTrue, reason: 'leg not contiguous on ${seg.line}: $stations');
    expect(seg.stationsCount, stations.length - 1);
  }
  // consecutive legs must connect (same station, or a walk leg bridges them)
  for (int i = 0; i < r.segments.length - 1; i++) {
    final a = r.segments[i];
    final b = r.segments[i + 1];
    if (a.line == GTFSGraphService.walkLine || b.line == GTFSGraphService.walkLine) {
      expect(a.toStation, b.fromStation);
      continue;
    }
    expect(a.toStation == b.fromStation || r.interchangeStations.any((x) => x.contains(b.fromStation)),
        isTrue,
        reason: 'legs do not connect: ${a.toStation} / ${b.fromStation}');
  }
  expect(r.segments.first.fromStation, r.fromStation);
  expect(r.segments.last.toStation, r.toStation);
  expect(r.totalStations,
      r.segments.fold<int>(0, (s, x) => s + x.stationsCount));
}

List<String> _lines(MetroRoute r) =>
    r.segments.where((s) => s.line != GTFSGraphService.walkLine).map((s) => s.line).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Read the bundled GTFS straight from disk (fast, no asset bundle needed).
    GTFSGraphService.assetLoader = (path) => File(path).readAsString();
    GTFSGraphService.reset();
    await GTFSGraphService.getStations();
    _lineSequences = await _buildLineSequences();
  });

  group('station data', () {
    test('loads all GTFS stations with interchanges', () async {
      final stations = await GTFSGraphService.getStations();
      expect(stations.length, greaterThan(250));
      final names = stations.map((s) => s.name).toSet();
      expect(names.length, stations.length, reason: 'duplicate station names');
      expect(names, contains('Millennium City Centre Gurugram'));
      expect(names, isNot(contains('Sikanderpur (Rapid Metro)')),
          reason: 'Rapid Metro Sikanderpur is merged with the Yellow Line station');
      final rc = stations.firstWhere((s) => s.name == 'Rajiv Chowk');
      expect(rc.isInterchange, isTrue);
      expect(rc.interchangeLines, containsAll(['Yellow Line', 'Blue Line']));
      final dw14 = stations.firstWhere((s) => s.name == 'Dwarka Sector 14');
      expect(dw14.isInterchange, isFalse, reason: 'branch patterns are not interchanges');
      final kg = stations.firstWhere((s) => s.name == 'Kashmere Gate');
      expect(kg.interchangeLines, containsAll(['Red Line', 'Yellow Line', 'Violet Line']));
    });

    test('resolves common spellings and aliases', () {
      const cases = {
        'Noida Sec 18': 'Noida Sector 18',
        'Noida Sec -18': 'Noida Sector 18',
        'IGI Airport T3': 'IGI Airport',
        'Huda City Centre': 'Millennium City Centre Gurugram',
        'Janak Puri West': 'Janakpuri West',
        'Jorbagh': 'Jor Bagh',
        'JLN Stadium': 'Jawaharlal Nehru Stadium',
        'Dwarka Sector - 21': 'Dwarka Sector 21',
        'Netaji Subash Place': 'Netaji Subhash Place',
        'Terminal 1-IGI Airport': 'Terminal 1-IGI Airport',
        'Cyber City': 'Cyber City (Rapid Metro)',
        'Sikanderpur (Rapid Metro)': 'Sikanderpur',
        'rajiv chowk': 'Rajiv Chowk',
        'Dwarka': 'Dwarka',
        'Kashmiri Gate': 'Kashmere Gate',
      };
      cases.forEach((input, expected) {
        expect(GTFSGraphService.resolveStationNameSync(input), expected, reason: input);
      });
      expect(GTFSGraphService.resolveStationNameSync('Nowhere Junction XYZ'), isNull);
    });
  });

  group('route finder — real pairs', () {
    test('same line: Rajiv Chowk → Hauz Khas (Yellow)', () async {
      final r = await _route('Rajiv Chowk', 'Hauz Khas');
      _expectContiguous(r);
      expect(_lines(r), ['Yellow Line']);
      expect(r.interchangeStations, isEmpty);
      expect(r.totalStations, 9);
      expect(r.totalTime, inInclusiveRange(15, 28));
      expect(r.distanceKm, inInclusiveRange(10, 13));
      expect(r.totalFare, 32);
    });

    test('same line, long: Dwarka Sector 21 → Noida City Centre (Blue)', () async {
      final r = await _route('Dwarka Sector 21', 'Noida City Centre');
      _expectContiguous(r);
      expect(_lines(r), ['Blue Line']);
      expect(r.totalStations, 43);
      expect(r.totalTime, inInclusiveRange(80, 110));
      expect(r.totalFare, 64);
    });

    test('Airport Express: Kashmere Gate → IGI Airport T3', () async {
      final r = await _route('Kashmere Gate', 'IGI Airport T3');
      _expectContiguous(r);
      expect(_lines(r), ['Yellow Line', 'Airport Express']);
      expect(r.interchangeStations, ['New Delhi']);
      expect(r.segments.first.stationsCount, 3);
      expect(r.segments.last.stationsCount, 4);
      expect(r.totalTime, inInclusiveRange(25, 45));
      // DMRC Yellow ticket (≈ 4.8 km → ₹21) + separate AEL ticket (₹64)
      expect(r.fareLegs.length, 2);
      expect(r.fareLegs.first.system, FareSystem.dmrc);
      expect(r.fareLegs.first.tokenFare, 21);
      expect(r.fareLegs.last.system, FareSystem.airportExpress);
      expect(r.fareLegs.last.tokenFare, 64);
      expect(r.totalFare, 85);
    });

    test('Magenta: Botanical Garden → Janakpuri West', () async {
      // GTFS timetable: Magenta 24 stops ≈ 67 min, Blue 28 stops ≈ 66 min —
      // either direct train is correct; never a route with changes.
      final r = await _route('Botanical Garden', 'Janakpuri West');
      _expectContiguous(r);
      expect(r.interchangeStations, isEmpty);
      expect(_lines(r).single, anyOf('Magenta Line', 'Blue Line'));
      expect(r.totalTime, inInclusiveRange(55, 75));
      // Magenta-only leg is valid and has 24 stops
      final m = await _route('Botanical Garden', 'Okhla NSIC');
      expect(_lines(m), ['Magenta Line']);
      expect(m.totalStations, 7);
    });

    test('Yellow end to end: Samaypur Badli → Millennium City Centre', () async {
      for (final to in ['HUDA City Centre', 'Millennium City Centre Gurugram']) {
        final r = await _route('Samaypur Badli', to);
        _expectContiguous(r);
        expect(_lines(r), ['Yellow Line']);
        expect(r.totalStations, 36);
        expect(r.totalTime, inInclusiveRange(70, 100));
        expect(r.distanceKm, greaterThan(50));
        expect(r.totalFare, 64);
      }
    });

    test('one interchange: Rajiv Chowk → Botanical Garden is Blue direct', () async {
      final r = await _route('Rajiv Chowk', 'Botanical Garden');
      _expectContiguous(r);
      expect(_lines(r), ['Blue Line']);
    });

    test('one interchange: Kashmere Gate → Lajpat Nagar (Violet direct)', () async {
      final r = await _route('Kashmere Gate', 'Lajpat Nagar');
      _expectContiguous(r);
      expect(_lines(r), ['Violet Line']);
    });

    test('one interchange: Hauz Khas → Noida Sector 18 via Botanical Garden', () async {
      final r = await _route('Hauz Khas', 'Noida Sec 18');
      _expectContiguous(r);
      expect(_lines(r), ['Magenta Line', 'Blue Line']);
      expect(r.interchangeStations, ['Botanical Garden']);
    });

    test('two interchanges: Rithala → Kalkaji Mandir', () async {
      final r = await _route('Rithala', 'Kalkaji Mandir');
      _expectContiguous(r);
      expect(r.interchangeStations.length, inInclusiveRange(1, 2));
      expect(r.totalTime, lessThan(90));
    });

    test('two interchanges: Dhansa Bus Stand (Grey) → Rajiv Chowk', () async {
      final r = await _route('Dhansa Bus Stand', 'Rajiv Chowk');
      _expectContiguous(r);
      expect(_lines(r), ['Grey Line', 'Blue Line']);
      expect(r.interchangeStations, ['Dwarka']);
    });

    test('Pink line pair: Majlis Park → Lajpat Nagar', () async {
      final r = await _route('Majlis Park', 'Lajpat Nagar');
      _expectContiguous(r);
      expect(_lines(r).first, anyOf('Pink Line', 'Yellow Line'));
      expect(r.totalTime, lessThan(75));
    });

    test('Pink line direct: Mayur Vihar-I → Anand Vihar', () async {
      final r = await _route('Mayur Vihar-I', 'Anand Vihar');
      _expectContiguous(r);
      expect(_lines(r), ['Pink Line']);
      expect(r.totalStations, 6);
    });

    test('Rapid Metro: Rajiv Chowk → Cyber City via Sikanderpur', () async {
      final r = await _route('Rajiv Chowk', 'Gurugram Cyber City');
      _expectContiguous(r);
      expect(_lines(r), ['Yellow Line', 'Rapid Metro']);
      expect(r.interchangeStations, ['Sikanderpur']);
      expect(r.fareLegs.map((l) => l.system), [FareSystem.dmrc, FareSystem.rapidMetro]);
    });

    test('Grey line: Dwarka → Najafgarh', () async {
      final r = await _route('Dwarka', 'Najafgarh');
      _expectContiguous(r);
      expect(_lines(r), ['Grey Line']);
      expect(r.totalStations, 2);
    });

    test('Aqua via walkway: Rajiv Chowk → Noida Sector 142', () async {
      final r = await _route('Rajiv Chowk', 'Noida Sector 142');
      _expectContiguous(r);
      expect(_lines(r), ['Blue Line', 'Aqua Line']);
      expect(r.segments.map((s) => s.line), contains(GTFSGraphService.walkLine));
      expect(r.interchangeStations, ['Noida Sector 52 → Noida Sector 51']);
      expect(r.fareLegs.map((l) => l.system), [FareSystem.dmrc, FareSystem.nmrc]);
    });

    test('Blue branch change at Yamuna Bank: Noida City Centre → Vaishali', () async {
      final r = await _route('Noida City Centre', 'Vaishali');
      _expectContiguous(r);
      expect(r.interchangeStations, ['Yamuna Bank']);
    });

    test('Blue through service: Dwarka Sector 21 → Vaishali has no change', () async {
      final r = await _route('Dwarka Sector 21', 'Vaishali');
      _expectContiguous(r);
      expect(r.interchangeStations, isEmpty);
    });

    test('Green branch change at Ashok Park Main: Inderlok → Kirti Nagar', () async {
      final r = await _route('Inderlok', 'Kirti Nagar');
      _expectContiguous(r);
      expect(r.interchangeStations, isNotEmpty);
    });

    test('Airport Express to Yashobhoomi', () async {
      final r = await _route('New Delhi', 'Yashobhoomi Dwarka Sector 25');
      _expectContiguous(r);
      expect(_lines(r), ['Airport Express']);
      expect(r.totalStations, 6);
    });

    test('same station and unknown station', () async {
      final same = await GTFSGraphService.findRoute(
          fromName: 'Rajiv Chowk', toName: 'rajiv chowk', travelTime: _weekdayPeak, isSmartCard: false);
      expect(same, isEmpty);
      expect(
          () => GTFSGraphService.findRoute(
              fromName: 'Atlantis', toName: 'Rajiv Chowk', travelTime: _weekdayPeak, isSmartCard: false),
          throwsA(isA<StationNotFoundException>()));
      final svc = MetroService();
      await expectLater(svc.findRoute('Rajiv Chowk', 'Rajiv Chowk'),
          throwsA(isA<RouteSearchException>().having((e) => e.reason, 'reason', RouteFailure.sameStation)));
      await expectLater(svc.findRoute('Atlantis', 'Rajiv Chowk'),
          throwsA(isA<RouteSearchException>().having((e) => e.reason, 'reason', RouteFailure.stationNotFound)));
    });

    test('sanity sweep: many random pairs are contiguous and plausible', () async {
      final all = await GTFSGraphService.getStations();
      final byName = {for (final s in all) s.name: s};
      final stations = all.map((s) => s.name).toList()..sort();
      var checked = 0;
      for (int i = 0; i < stations.length; i += 7) {
        for (int j = 3; j < stations.length; j += 23) {
          if (stations[i] == stations[j]) continue;
          final r = await _route(stations[i], stations[j]);
          _expectContiguous(r);
          expect(r.interchangeStations.length, lessThanOrEqualTo(4), reason: _describe(r));
          expect(r.totalTime, inInclusiveRange(1, 200), reason: _describe(r));
          // no absurd detours: track distance ≤ 2.8× straight line + 8 km (network geometry,
          // e.g. Faridabad → Greater Noida must go via Kalkaji & Botanical Garden)
          final f = byName[r.fromStation]!, t = byName[r.toStation]!;
          final straight = AccurateFareCalculator.calculateDistance(
              f.latitude, f.longitude, t.latitude, t.longitude);
          expect(r.distanceKm, lessThanOrEqualTo(straight * 2.8 + 8), reason: _describe(r));
          checked++;
        }
      }
      expect(checked, greaterThan(300));
    });
  });

  group('fares', () {
    test('DMRC slabs — normal days and Sundays/holidays', () {
      final normal = {1.0: 11, 2.0: 11, 2.1: 21, 5.0: 21, 7.0: 32, 12.0: 32, 15.0: 43, 21.0: 43, 25.0: 54, 32.0: 54, 40.0: 64};
      final sunday = {1.0: 11, 3.0: 11, 7.0: 21, 15.0: 32, 25.0: 43, 40.0: 54};
      normal.forEach((km, fare) => expect(AccurateFareCalculator.calculateNormalDayFare(km), fare, reason: '$km km'));
      sunday.forEach((km, fare) => expect(AccurateFareCalculator.calculateHolidayFare(km), fare, reason: '$km km'));

      final sun = DateTime(2025, 10, 19, 10); // Sunday
      final r = AccurateFareCalculator.calculateFareComparison(distance: 15, travelTime: sun, isAirportExpress: false);
      expect(r.isHoliday, isTrue);
      expect(r.ticketFare, 32);
      expect(AccurateFareCalculator.isHoliday(DateTime(2025, 8, 15)), isTrue);
      expect(AccurateFareCalculator.isHoliday(DateTime(2025, 12, 25)), isFalse);
    });

    test('smart card 10% off, 20% in off-peak hours', () {
      final peak = AccurateFareCalculator.calculateFareComparison(
          distance: 15, travelTime: DateTime(2025, 10, 21, 9), isAirportExpress: false);
      expect(peak.ticketFare, 43);
      expect(peak.isOffPeak, isFalse);
      expect(peak.smartCardFare, 39); // 43 × 0.9 = 38.7
      final off = AccurateFareCalculator.calculateFareComparison(
          distance: 15, travelTime: DateTime(2025, 10, 21, 14), isAirportExpress: false);
      expect(off.isOffPeak, isTrue);
      expect(off.smartCardFare, 34); // 43 × 0.8 = 34.4
      for (final h in [6, 7, 12, 16, 21, 22]) {
        expect(AccurateFareCalculator.isOffPeakHour(DateTime(2025, 10, 21, h)), isTrue, reason: '$h h');
      }
      for (final h in [8, 9, 11, 17, 20]) {
        expect(AccurateFareCalculator.isOffPeakHour(DateTime(2025, 10, 21, h)), isFalse, reason: '$h h');
      }
    });

    test('fare uses total journey distance, not per leg', () async {
      // Dwarka → Rajiv Chowk + Yellow to Hauz Khas: one DMRC ticket
      final r = await _route('Dwarka Sector 21', 'Hauz Khas');
      expect(r.fareLegs.length, 1);
      expect(r.totalFare, AccurateFareCalculator.calculateNormalDayFare(r.distanceKm).toDouble());
    });

    test('fare calculator matches route finder for the same pair', () async {
      final svc = MetroService();
      const pairs = [
        ['Rajiv Chowk', 'Hauz Khas'],
        ['Dwarka Sector 21', 'Noida City Centre'],
        ['Kashmere Gate', 'IGI Airport'],
        ['Botanical Garden', 'Janakpuri West'],
        ['Samaypur Badli', 'Millennium City Centre Gurugram'],
        ['Majlis Park', 'Lajpat Nagar'],
        ['Rajiv Chowk', 'Cyber City'],
      ];
      for (final p in pairs) {
        final routes = await svc.findRoute(p[0], p[1], travelTime: _weekdayPeak);
        final fare = await svc.calculateFare(p[0], p[1], travelTime: _weekdayPeak);
        expect(fare, isNotNull);
        expect(fare!['ticketFare'], routes.first.totalFare.round(), reason: p.join(' → '));
        expect(fare['smartCardFare'], routes.first.smartCardFare!.round(), reason: p.join(' → '));
        expect(fare['distanceKm'], routes.first.distanceKm);
      }
    });

    test('Sunday fare from the route', () async {
      final r = await _route('Rajiv Chowk', 'Hauz Khas', when: DateTime(2025, 10, 19, 10));
      expect(r.totalFare, 21);
    });
  });
}

/// Builds ordered station sequences per line from the GTFS trips (display
/// names), independent of the graph code under test.
Future<Map<String, List<List<String>>>> _buildLineSequences() async {
  final stations = await GTFSGraphService.getStations();
  final byId = {for (final s in stations) s.id: s.name};
  byId['148'] = byId['68']!; // merged Rapid Metro Sikanderpur
  final routes = File('assets/gtfs_data/routes.txt').readAsLinesSync().skip(1);
  final routeLine = <String, String>{};
  for (final l in routes) {
    final p = l.split(',');
    if (p.length < 4) continue;
    final u = p[3].toUpperCase();
    final line = u.startsWith('RED_')
        ? 'Red Line'
        : u.startsWith('YELLOW_')
            ? 'Yellow Line'
            : u.startsWith('BLUE_')
                ? 'Blue Line'
                : u.startsWith('GREEN_')
                    ? 'Green Line'
                    : u.startsWith('GRAY_')
                        ? 'Grey Line'
                        : u.startsWith('VIOLET_')
                            ? 'Violet Line'
                            : u.startsWith('PINK_')
                                ? 'Pink Line'
                                : u.startsWith('MAGENTA_')
                                    ? 'Magenta Line'
                                    : u.startsWith('AQUA_')
                                        ? 'Aqua Line'
                                        : u.contains('AIRPORT')
                                            ? 'Airport Express'
                                            : 'Rapid Metro';
    routeLine[p[0]] = line;
  }
  final tripRoute = <String, String>{};
  for (final l in File('assets/gtfs_data/trips.txt').readAsLinesSync().skip(1)) {
    final p = l.split(',');
    if (p.length > 2) tripRoute[p[2]] = p[0];
  }
  final seen = <String, Set<String>>{};
  final trips = <String, List<(int, String)>>{};
  for (final l in File('assets/gtfs_data/stop_times.txt').readAsLinesSync().skip(1)) {
    final p = l.split(',');
    if (p.length < 5) continue;
    trips.putIfAbsent(p[0], () => []).add((int.parse(p[4]), p[3]));
  }
  final out = <String, List<List<String>>>{};
  trips.forEach((trip, list) {
    final line = routeLine[tripRoute[trip]];
    if (line == null) return;
    list.sort((a, b) => a.$1.compareTo(b.$1));
    final names = <String>[];
    for (final (_, id) in list) {
      final n = byId[id];
      if (n == null) continue;
      if (names.isNotEmpty && names.last == n) continue;
      names.add(n);
    }
    final key = names.join('|');
    if (seen.putIfAbsent(line, () => {}).add(key)) {
      out.putIfAbsent(line, () => []).add(names);
    }
  });
  // Aqua Line trains run through Noida Sector 142 although the GTFS splits
  // the line into two routes — add the joined sequence.
  final aqua = out['Aqua Line']!;
  final north = aqua.firstWhere((s) => s.first == 'Noida Sector 51');
  final south = aqua.firstWhere((s) => s.first == 'Noida Sector 142' && s.last == 'Depot Station');
  aqua.add([...north, ...south.skip(1)]);
  // AEL extension (not in GTFS)
  out['Airport Express']!.add([
    'New Delhi', 'Shivaji Stadium', 'Dhaula Kuan', 'Delhi Aerocity', 'IGI Airport',
    'Dwarka Sector 21', 'Yashobhoomi Dwarka Sector 25',
  ]);
  return out;
}
