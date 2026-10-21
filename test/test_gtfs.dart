import 'package:http/http.dart' as http;
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

void main() async {
  try {
    print('Fetching Delhi OTD live feed...');
    final response = await http.get(Uri.parse(
      'https://otd.delhi.gov.in/api/realtime/VehiclePositions.pb?key=7brhWCYIy6TT0nCAXxWIvXoPCU56Lzox',
    )).timeout(const Duration(seconds: 15));
    print('Status: ${response.statusCode}, bytes: ${response.bodyBytes.length}');
    if (response.statusCode == 200) {
      final feed = FeedMessage.fromBuffer(response.bodyBytes);
      print('Header timestamp: ${feed.header.timestamp}');
      print('Total live vehicles in feed: ${feed.entity.length}');
      if (feed.entity.isNotEmpty) {
        final sample = feed.entity.first.vehicle;
        print('Sample vehicle: id=${sample.vehicle.id}, route=${sample.trip.routeId}, pos=(${sample.position.latitude}, ${sample.position.longitude}), speed=${sample.position.speed}');
      }
    }
  } catch (e, stack) {
    print('Error: $e\n$stack');
  }
}
