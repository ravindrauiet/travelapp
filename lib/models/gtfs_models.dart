// GTFS (General Transit Feed Specification) Models for Delhi Bus Services
// Based on: https://gtfs.org/documentation/schedule/reference/

class GTFSAgency {
  final String agencyId;
  final String agencyName;
  final String agencyUrl;
  final String agencyTimezone;
  final String? agencyLang;
  final String? agencyPhone;
  final String? agencyFareUrl;
  final String? agencyEmail;

  const GTFSAgency({
    required this.agencyId,
    required this.agencyName,
    required this.agencyUrl,
    required this.agencyTimezone,
    this.agencyLang,
    this.agencyPhone,
    this.agencyFareUrl,
    this.agencyEmail,
  });

  factory GTFSAgency.fromCsv(Map<String, String> row) {
    return GTFSAgency(
      agencyId: row['agency_id'] ?? '',
      agencyName: row['agency_name'] ?? '',
      agencyUrl: row['agency_url'] ?? '',
      agencyTimezone: row['agency_timezone'] ?? 'Asia/Kolkata',
      agencyLang: row['agency_lang'],
      agencyPhone: row['agency_phone'],
      agencyFareUrl: row['agency_fare_url'],
      agencyEmail: row['agency_email'],
    );
  }
}

class GTFSStop {
  final String stopId;
  final String stopCode;
  final String stopName;
  final String? stopDesc;
  final double stopLat;
  final double stopLon;
  final String? zoneId;
  final String? stopUrl;
  final int? locationType;
  final String? parentStation;
  final String? stopTimezone;
  final int? wheelchairBoarding;
  final String? levelId;
  final String? platformCode;

  const GTFSStop({
    required this.stopId,
    required this.stopCode,
    required this.stopName,
    this.stopDesc,
    required this.stopLat,
    required this.stopLon,
    this.zoneId,
    this.stopUrl,
    this.locationType,
    this.parentStation,
    this.stopTimezone,
    this.wheelchairBoarding,
    this.levelId,
    this.platformCode,
  });

  factory GTFSStop.fromCsv(Map<String, String> row) {
    return GTFSStop(
      stopId: row['stop_id'] ?? '',
      stopCode: row['stop_code'] ?? '',
      stopName: row['stop_name'] ?? '',
      stopDesc: row['stop_desc'],
      stopLat: double.tryParse(row['stop_lat'] ?? '0') ?? 0.0,
      stopLon: double.tryParse(row['stop_lon'] ?? '0') ?? 0.0,
      zoneId: row['zone_id'],
      stopUrl: row['stop_url'],
      locationType: int.tryParse(row['location_type'] ?? '0'),
      parentStation: row['parent_station'],
      stopTimezone: row['stop_timezone'],
      wheelchairBoarding: int.tryParse(row['wheelchair_boarding'] ?? '0'),
      levelId: row['level_id'],
      platformCode: row['platform_code'],
    );
  }
}

class GTFSRoute {
  final String routeId;
  final String agencyId;
  final String routeShortName;
  final String routeLongName;
  final String? routeDesc;
  final int routeType;
  final String? routeUrl;
  final String? routeColor;
  final String? routeTextColor;
  final int? routeSortOrder;
  final String? continuousPickup;
  final String? continuousDropOff;
  final String? networkId;

  const GTFSRoute({
    required this.routeId,
    required this.agencyId,
    required this.routeShortName,
    required this.routeLongName,
    this.routeDesc,
    required this.routeType,
    this.routeUrl,
    this.routeColor,
    this.routeTextColor,
    this.routeSortOrder,
    this.continuousPickup,
    this.continuousDropOff,
    this.networkId,
  });

  factory GTFSRoute.fromCsv(Map<String, String> row) {
    return GTFSRoute(
      routeId: row['route_id'] ?? '',
      agencyId: row['agency_id'] ?? '',
      routeShortName: row['route_short_name'] ?? '',
      routeLongName: row['route_long_name'] ?? '',
      routeDesc: row['route_desc'],
      routeType: int.tryParse(row['route_type'] ?? '3') ?? 3, // 3 = Bus
      routeUrl: row['route_url'],
      routeColor: row['route_color'],
      routeTextColor: row['route_text_color'],
      routeSortOrder: int.tryParse(row['route_sort_order'] ?? '0'),
      continuousPickup: row['continuous_pickup'],
      continuousDropOff: row['continuous_drop_off'],
      networkId: row['network_id'],
    );
  }
}

class GTFSTrip {
  final String routeId;
  final String serviceId;
  final String tripId;
  final String? tripHeadsign;
  final String? tripShortName;
  final int? directionId;
  final String? blockId;
  final String? shapeId;
  final int? wheelchairAccessible;
  final int? bikesAllowed;

  const GTFSTrip({
    required this.routeId,
    required this.serviceId,
    required this.tripId,
    this.tripHeadsign,
    this.tripShortName,
    this.directionId,
    this.blockId,
    this.shapeId,
    this.wheelchairAccessible,
    this.bikesAllowed,
  });

  factory GTFSTrip.fromCsv(Map<String, String> row) {
    return GTFSTrip(
      routeId: row['route_id'] ?? '',
      serviceId: row['service_id'] ?? '',
      tripId: row['trip_id'] ?? '',
      tripHeadsign: row['trip_headsign'],
      tripShortName: row['trip_short_name'],
      directionId: int.tryParse(row['direction_id'] ?? '0'),
      blockId: row['block_id'],
      shapeId: row['shape_id'],
      wheelchairAccessible: int.tryParse(row['wheelchair_accessible'] ?? '0'),
      bikesAllowed: int.tryParse(row['bikes_allowed'] ?? '0'),
    );
  }
}

class GTFSStopTime {
  final String tripId;
  final String arrivalTime;
  final String departureTime;
  final String stopId;
  final int? stopSequence;
  final String? stopHeadsign;
  final int? pickupType;
  final int? dropOffType;
  final double? continuousPickup;
  final double? continuousDropOff;
  final double? shapeDistTraveled;
  final int? timepoint;

  const GTFSStopTime({
    required this.tripId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopId,
    this.stopSequence,
    this.stopHeadsign,
    this.pickupType,
    this.dropOffType,
    this.continuousPickup,
    this.continuousDropOff,
    this.shapeDistTraveled,
    this.timepoint,
  });

  factory GTFSStopTime.fromCsv(Map<String, String> row) {
    return GTFSStopTime(
      tripId: row['trip_id'] ?? '',
      arrivalTime: row['arrival_time'] ?? '',
      departureTime: row['departure_time'] ?? '',
      stopId: row['stop_id'] ?? '',
      stopSequence: int.tryParse(row['stop_sequence'] ?? '0'),
      stopHeadsign: row['stop_headsign'],
      pickupType: int.tryParse(row['pickup_type'] ?? '0'),
      dropOffType: int.tryParse(row['drop_off_type'] ?? '0'),
      continuousPickup: double.tryParse(row['continuous_pickup'] ?? '0'),
      continuousDropOff: double.tryParse(row['continuous_drop_off'] ?? '0'),
      shapeDistTraveled: double.tryParse(row['shape_dist_traveled'] ?? '0'),
      timepoint: int.tryParse(row['timepoint'] ?? '0'),
    );
  }
}

class GTFSVehiclePosition {
  final String vehicleId;
  final String tripId;
  final String routeId;
  final int? directionId;
  final double latitude;
  final double longitude;
  final double? bearing;
  final double? odometer;
  final double? speed;
  final int? currentStatus;
  final int? congestionLevel;
  final int? occupancyStatus;
  final DateTime timestamp;

  const GTFSVehiclePosition({
    required this.vehicleId,
    required this.tripId,
    required this.routeId,
    this.directionId,
    required this.latitude,
    required this.longitude,
    this.bearing,
    this.odometer,
    this.speed,
    this.currentStatus,
    this.congestionLevel,
    this.occupancyStatus,
    required this.timestamp,
  });

  factory GTFSVehiclePosition.fromJson(Map<String, dynamic> json) {
    return GTFSVehiclePosition(
      vehicleId: json['vehicle']['id'] ?? '',
      tripId: json['trip']['trip_id'] ?? '',
      routeId: json['trip']['route_id'] ?? '',
      directionId: json['trip']['direction_id'],
      latitude: (json['position']['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['position']['longitude'] as num?)?.toDouble() ?? 0.0,
      bearing: (json['position']['bearing'] as num?)?.toDouble(),
      odometer: (json['position']['odometer'] as num?)?.toDouble(),
      speed: (json['position']['speed'] as num?)?.toDouble(),
      currentStatus: json['current_status'],
      congestionLevel: json['congestion_level'],
      occupancyStatus: json['occupancy_status'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class GTFSRealTimeResponse {
  final String header;
  final List<GTFSVehiclePosition> entities;

  const GTFSRealTimeResponse({
    required this.header,
    required this.entities,
  });

  factory GTFSRealTimeResponse.fromJson(Map<String, dynamic> json) {
    final entities = (json['entity'] as List<dynamic>?)
        ?.map((e) => GTFSVehiclePosition.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return GTFSRealTimeResponse(
      header: json['header']['gtfs_realtime_version'] ?? '',
      entities: entities,
    );
  }
}



