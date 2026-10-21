import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:metromate/services/gtfs_graph_service.dart';
import 'package:metromate/utils/app_constants.dart';

/// Every station name the UI can hand to the route finder must resolve to a
/// real GTFS station (and, for line lists, to a station on that line).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, List<String>> linesByStation;

  setUpAll(() async {
    GTFSGraphService.assetLoader = (path) => File(path).readAsString();
    GTFSGraphService.reset();
    final stations = await GTFSGraphService.getStations();
    linesByStation = {for (final s in stations) s.name: s.interchangeLines};
  });

  String? resolveForRouteFinder(String uiName) =>
      GTFSGraphService.resolveStationNameSync(AppConstants.resolveToMetroStation(uiName));

  test('every station in DelhiMetroNetwork line lists resolves on its own line', () {
    final problems = <String>[];
    for (final line in DelhiMetroNetwork.allLines) {
      final lineName = switch (line.code) {
        'BLUE_BRANCH' => 'Blue Line',
        _ => line.name,
      };
      for (final station in line.stations) {
        final resolved = resolveForRouteFinder(station);
        if (resolved == null) {
          problems.add('${line.name}: "$station" not found');
          continue;
        }
        final lines = linesByStation[resolved]!;
        if (!lines.contains(lineName)) {
          problems.add('${line.name}: "$station" → "$resolved" which is on $lines');
        }
      }
      expect(line.stations.length, line.stationCount, reason: '${line.name} stationCount');
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('interchange keys refer to stations of that line', () {
    final problems = <String>[
      for (final line in DelhiMetroNetwork.allLines)
        for (final key in line.interchanges.keys)
          if (!line.stations.contains(key)) '${line.name}: "$key"',
    ];
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('landmark map targets are real stations', () {
    final problems = <String>[];
    AppConstants.landmarkToMetroStation.forEach((landmark, station) {
      if (GTFSGraphService.resolveStationNameSync(station) == null) {
        problems.add('$landmark → $station');
      }
    });
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('home trending chips resolve to the expected stations', () {
    const expected = {
      'Rajiv Chowk': 'Rajiv Chowk',
      'IGI Airport T3': 'IGI Airport',
      'India Gate': 'Central Secretariat',
      'Hauz Khas': 'Hauz Khas',
      'Chandni Chowk': 'Chandni Chowk',
      'Kashmere Gate': 'Kashmere Gate',
      'Noida Sec 18': 'Noida Sector 18',
      'Gurugram Cyber City': 'Cyber City (Rapid Metro)',
    };
    expected.forEach((chip, station) {
      expect(resolveForRouteFinder(chip), station, reason: chip);
    });
  });

  test('tourist spots resolve to their documented metro station', () {
    // place['name'] → station named in place['metroStation'] of
    // lib/screens/city/enhanced_tourist_spots_screen.dart
    const expected = {
      'Red Fort': 'Lal Quila',
      'India Gate': 'Central Secretariat',
      'Qutub Minar': 'Qutab Minar',
      "Humayun's Tomb": 'Jawaharlal Nehru Stadium',
      'Chandni Chowk': 'Chandni Chowk',
      'Connaught Place': 'Rajiv Chowk',
      'Dilli Haat INA': 'Dilli Haat - INA',
      'Lodhi Garden': 'Jor Bagh',
      'Sunder Nursery': 'Jawaharlal Nehru Stadium',
      'National Museum': 'Udyog Bhawan',
      'National Rail Museum': 'Durgabai Deshmukh South Campus',
      'Lotus Temple': 'Kalkaji Mandir',
      'Akshardham Temple': 'Akshardham',
      'Cyber Hub Gurugram': 'Cyber City (Rapid Metro)',
    };
    expected.forEach((place, station) {
      expect(resolveForRouteFinder(place), station, reason: place);
    });
  });

  test('station names are not hijacked by landmark substrings', () {
    expect(AppConstants.resolveToMetroStation('Terminal 1-IGI Airport'), 'Terminal 1-IGI Airport');
    expect(resolveForRouteFinder('Terminal 1-IGI Airport'), 'Terminal 1-IGI Airport');
    expect(AppConstants.resolveToMetroStation('Hauz Khas'), 'Hauz Khas');
    expect(AppConstants.resolveToMetroStation('Red Fort, Old Delhi'), 'Lal Quila');
  });
}
