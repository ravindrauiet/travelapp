/// GTFS (General Transit Feed Specification) data models
/// These models represent the raw GTFS data structure

class GTFSAgency {
  final String agencyId;
  final String agencyName;
  final String? agencyUrl;
  final String? agencyTimezone;
  final String? agencyLang;
  final String? agencyPhone;
  final String? agencyFareUrl;
  final String? agencyEmail;

  GTFSAgency({
    required this.agencyId,
    required this.agencyName,
    this.agencyUrl,
    this.agencyTimezone,
    this.agencyLang,
    this.agencyPhone,
    this.agencyFareUrl,
    this.agencyEmail,
  });

  factory GTFSAgency.fromCsv(Map<String, String> csvRow) {
    return GTFSAgency(
      agencyId: csvRow['agency_id'] ?? '',
      agencyName: csvRow['agency_name'] ?? '',
      agencyUrl: csvRow['agency_url'],
      agencyTimezone: csvRow['agency_timezone'],
      agencyLang: csvRow['agency_lang'],
      agencyPhone: csvRow['agency_phone'],
      agencyFareUrl: csvRow['agency_fare_url'],
      agencyEmail: csvRow['agency_email'],
    );
  }
}

class GTFSStop {
  final String stopId;
  final String? stopCode;
  final String stopName;
  final String? stopDesc;
  final double stopLat;
  final double stopLon;
  final int? wheelchairBoarding;

  GTFSStop({
    required this.stopId,
    this.stopCode,
    required this.stopName,
    this.stopDesc,
    required this.stopLat,
    required this.stopLon,
    this.wheelchairBoarding,
  });

  factory GTFSStop.fromCsv(Map<String, String> csvRow) {
    return GTFSStop(
      stopId: csvRow['stop_id'] ?? '',
      stopCode: csvRow['stop_code'],
      stopName: csvRow['stop_name'] ?? '',
      stopDesc: csvRow['stop_desc'],
      stopLat: double.tryParse(csvRow['stop_lat'] ?? '0') ?? 0.0,
      stopLon: double.tryParse(csvRow['stop_lon'] ?? '0') ?? 0.0,
      wheelchairBoarding: int.tryParse(csvRow['wheelchair_boarding'] ?? '0'),
    );
  }
}

class GTFSRoute {
  final String routeId;
  final String? agencyId;
  final String? routeShortName;
  final String routeLongName;
  final String? routeDesc;
  final int? routeType;
  final String? routeUrl;
  final String? routeColor;
  final String? routeTextColor;
  final int? routeSortOrder;
  final int? continuousPickup;
  final int? continuousDropOff;

  GTFSRoute({
    required this.routeId,
    this.agencyId,
    this.routeShortName,
    required this.routeLongName,
    this.routeDesc,
    this.routeType,
    this.routeUrl,
    this.routeColor,
    this.routeTextColor,
    this.routeSortOrder,
    this.continuousPickup,
    this.continuousDropOff,
  });

  factory GTFSRoute.fromCsv(Map<String, String> csvRow) {
    return GTFSRoute(
      routeId: csvRow['route_id'] ?? '',
      agencyId: csvRow['agency_id'],
      routeShortName: csvRow['route_short_name'],
      routeLongName: csvRow['route_long_name'] ?? '',
      routeDesc: csvRow['route_desc'],
      routeType: int.tryParse(csvRow['route_type'] ?? '0'),
      routeUrl: csvRow['route_url'],
      routeColor: csvRow['route_color'],
      routeTextColor: csvRow['route_text_color'],
      routeSortOrder: int.tryParse(csvRow['route_sort_order'] ?? '0'),
      continuousPickup: int.tryParse(csvRow['continuous_pickup'] ?? '0'),
      continuousDropOff: int.tryParse(csvRow['continuous_drop_off'] ?? '0'),
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

  GTFSTrip({
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

  factory GTFSTrip.fromCsv(Map<String, String> csvRow) {
    return GTFSTrip(
      routeId: csvRow['route_id'] ?? '',
      serviceId: csvRow['service_id'] ?? '',
      tripId: csvRow['trip_id'] ?? '',
      tripHeadsign: csvRow['trip_headsign'],
      tripShortName: csvRow['trip_short_name'],
      directionId: int.tryParse(csvRow['direction_id'] ?? '0'),
      blockId: csvRow['block_id'],
      shapeId: csvRow['shape_id'],
      wheelchairAccessible: int.tryParse(csvRow['wheelchair_accessible'] ?? '0'),
      bikesAllowed: int.tryParse(csvRow['bikes_allowed'] ?? '0'),
    );
  }
}

class GTFSStopTime {
  final String tripId;
  final String arrivalTime;
  final String departureTime;
  final String stopId;
  final int stopSequence;
  final String? stopHeadsign;
  final int? pickupType;
  final int? dropOffType;
  final double? shapeDistTraveled;
  final int? timepoint;
  final int? continuousPickup;
  final int? continuousDropOff;

  GTFSStopTime({
    required this.tripId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopId,
    required this.stopSequence,
    this.stopHeadsign,
    this.pickupType,
    this.dropOffType,
    this.shapeDistTraveled,
    this.timepoint,
    this.continuousPickup,
    this.continuousDropOff,
  });

  factory GTFSStopTime.fromCsv(Map<String, String> csvRow) {
    return GTFSStopTime(
      tripId: csvRow['trip_id'] ?? '',
      arrivalTime: csvRow['arrival_time'] ?? '',
      departureTime: csvRow['departure_time'] ?? '',
      stopId: csvRow['stop_id'] ?? '',
      stopSequence: int.tryParse(csvRow['stop_sequence'] ?? '0') ?? 0,
      stopHeadsign: csvRow['stop_headsign'],
      pickupType: int.tryParse(csvRow['pickup_type'] ?? '0'),
      dropOffType: int.tryParse(csvRow['drop_off_type'] ?? '0'),
      shapeDistTraveled: double.tryParse(csvRow['shape_dist_traveled'] ?? '0'),
      timepoint: int.tryParse(csvRow['timepoint'] ?? '0'),
      continuousPickup: int.tryParse(csvRow['continuous_pickup'] ?? '0'),
      continuousDropOff: int.tryParse(csvRow['continuous_drop_off'] ?? '0'),
    );
  }
}

class GTFSCalendar {
  final String serviceId;
  final int monday;
  final int tuesday;
  final int wednesday;
  final int thursday;
  final int friday;
  final int saturday;
  final int sunday;
  final String startDate;
  final String endDate;

  GTFSCalendar({
    required this.serviceId,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.startDate,
    required this.endDate,
  });

  factory GTFSCalendar.fromCsv(Map<String, String> csvRow) {
    return GTFSCalendar(
      serviceId: csvRow['service_id'] ?? '',
      monday: int.tryParse(csvRow['monday'] ?? '0') ?? 0,
      tuesday: int.tryParse(csvRow['tuesday'] ?? '0') ?? 0,
      wednesday: int.tryParse(csvRow['wednesday'] ?? '0') ?? 0,
      thursday: int.tryParse(csvRow['thursday'] ?? '0') ?? 0,
      friday: int.tryParse(csvRow['friday'] ?? '0') ?? 0,
      saturday: int.tryParse(csvRow['saturday'] ?? '0') ?? 0,
      sunday: int.tryParse(csvRow['sunday'] ?? '0') ?? 0,
      startDate: csvRow['start_date'] ?? '',
      endDate: csvRow['end_date'] ?? '',
    );
  }
}

class GTFSShape {
  final String shapeId;
  final double shapePtLat;
  final double shapePtLon;
  final int shapePtSequence;
  final double? shapeDistTraveled;

  GTFSShape({
    required this.shapeId,
    required this.shapePtLat,
    required this.shapePtLon,
    required this.shapePtSequence,
    this.shapeDistTraveled,
  });

  factory GTFSShape.fromCsv(Map<String, String> csvRow) {
    return GTFSShape(
      shapeId: csvRow['shape_id'] ?? '',
      shapePtLat: double.tryParse(csvRow['shape_pt_lat'] ?? '0') ?? 0.0,
      shapePtLon: double.tryParse(csvRow['shape_pt_lon'] ?? '0') ?? 0.0,
      shapePtSequence: int.tryParse(csvRow['shape_pt_sequence'] ?? '0') ?? 0,
      shapeDistTraveled: double.tryParse(csvRow['shape_dist_traveled'] ?? '0'),
    );
  }
}

class GTFSVehiclePosition {
  final String vehicleId;
  final String tripId;
  final String routeId;
  final double latitude;
  final double longitude;
  final double? bearing;
  final double? speed;
  final int timestamp;
  final String? occupancyStatus;
  final int? congestionLevel;
  final String? currentStatus;
  final int? directionId;
  final double? odometer;

  GTFSVehiclePosition({
    required this.vehicleId,
    required this.tripId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.bearing,
    this.speed,
    required this.timestamp,
    this.occupancyStatus,
    this.congestionLevel,
    this.currentStatus,
    this.directionId,
    this.odometer,
  });

  factory GTFSVehiclePosition.fromJson(Map<String, dynamic> json) {
    return GTFSVehiclePosition(
      vehicleId: json['vehicleId'] ?? '',
      tripId: json['tripId'] ?? '',
      routeId: json['routeId'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      bearing: (json['bearing'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: json['timestamp'] ?? 0,
      occupancyStatus: json['occupancyStatus'],
      congestionLevel: json['congestionLevel'],
      currentStatus: json['currentStatus'],
      directionId: json['directionId'],
      odometer: (json['odometer'] as num?)?.toDouble(),
    );
  }
}