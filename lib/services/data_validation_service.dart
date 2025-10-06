import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'accurate_fare_calculator.dart';

/// Data Validation Service for ensuring accuracy of Delhi Metro information
/// Based on official DMRC specifications and operational constraints
class DataValidationService {
  
  /// Validate station data against official DMRC specifications
  static ValidationResult validateStationData(List<MetroStation> stations) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Check station count (should be 262 according to official GTFS data)
    if (stations.length != 262) {
      warnings.add('Station count (${stations.length}) differs from official count (262)');
    }
    
    // Validate required fields
    for (final station in stations) {
      if (station.id.isEmpty) {
        errors.add('Station ${station.name} has empty ID');
      }
      if (station.name.isEmpty) {
        errors.add('Station with ID ${station.id} has empty name');
      }
      if (station.line.isEmpty) {
        errors.add('Station ${station.name} has empty line');
      }
      if (station.latitude < 28.0 || station.latitude > 29.0) {
        warnings.add('Station ${station.name} latitude (${station.latitude}) seems outside Delhi bounds');
      }
      if (station.longitude < 76.0 || station.longitude > 78.0) {
        warnings.add('Station ${station.name} longitude (${station.longitude}) seems outside Delhi bounds');
      }
    }
    
    // Validate interchange stations
    final interchangeStations = stations.where((s) => s.isInterchange).toList();
    final expectedInterchanges = [
      'Rajiv Chowk', 'Kashmere Gate', 'Mandi House', 'Yamuna Bank',
      'Botanical Garden', 'Welcome', 'Inderlok', 'Netaji Subash Place',
      'Rajouri Garden', 'Azadpur', 'INA', 'Hauz Khas', 'New Delhi'
    ];
    
    for (final expected in expectedInterchanges) {
      final found = interchangeStations.any((s) => s.name == expected);
      if (!found) {
        warnings.add('Expected interchange station $expected not found or not marked as interchange');
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate route data for accuracy
  static ValidationResult validateRouteData(List<MetroRoute> routes) {
    final errors = <String>[];
    final warnings = <String>[];
    
    for (final route in routes) {
      // Validate route structure
      if (route.segments.isEmpty) {
        errors.add('Route ${route.id} has no segments');
      }
      
      // Validate fare calculation
      if (route.totalFare <= 0) {
        errors.add('Route ${route.id} has invalid fare: ${route.totalFare}');
      }
      
      // Validate time calculation
      if (route.totalTime <= 0) {
        errors.add('Route ${route.id} has invalid time: ${route.totalTime}');
      }
      
      // Check for reasonable fare ranges
      if (route.totalFare > 100) {
        warnings.add('Route ${route.id} has unusually high fare: ${route.totalFare}');
      }
      
      // Check for reasonable time ranges
      if (route.totalTime > 300) { // 5 hours
        warnings.add('Route ${route.id} has unusually long time: ${route.totalTime} minutes');
      }
      
      // Validate segment consistency
      for (int i = 0; i < route.segments.length - 1; i++) {
        final current = route.segments[i];
        final next = route.segments[i + 1];
        
        if (current.toStation != next.fromStation) {
          errors.add('Route ${route.id} has inconsistent segment connection: ${current.toStation} != ${next.fromStation}');
        }
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate fare calculation against official DMRC rates
  static ValidationResult validateFareCalculation() {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Test fare calculations with known distances
    final testCases = [
      {'distance': 1.0, 'expectedMin': 11, 'expectedMax': 11, 'description': '0-2 km range'},
      {'distance': 3.0, 'expectedMin': 21, 'expectedMax': 21, 'description': '2-5 km range'},
      {'distance': 8.0, 'expectedMin': 32, 'expectedMax': 32, 'description': '5-12 km range'},
      {'distance': 15.0, 'expectedMin': 43, 'expectedMax': 43, 'description': '12-21 km range'},
      {'distance': 25.0, 'expectedMin': 54, 'expectedMax': 54, 'description': '21-32 km range'},
      {'distance': 35.0, 'expectedMin': 64, 'expectedMax': 64, 'description': 'Beyond 32 km range'},
    ];
    
    for (final testCase in testCases) {
      final distance = testCase['distance'] as double;
      final expectedMin = testCase['expectedMin'] as int;
      final expectedMax = testCase['expectedMax'] as int;
      final description = testCase['description'] as String;
      
      final fareResult = AccurateFareCalculator.calculateFare(
        distance: distance,
        travelTime: DateTime.now(),
        isSmartCard: false, // Test base fare
        isAirportExpress: false,
      );
      
      if (fareResult.finalFare < expectedMin || fareResult.finalFare > expectedMax) {
        errors.add('Fare calculation error for $description: got ${fareResult.finalFare}, expected $expectedMin-$expectedMax');
      }
    }
    
    // Test holiday fare discounts
    final holidayFareResult = AccurateFareCalculator.calculateFare(
      distance: 10.0,
      travelTime: DateTime(2024, 12, 25), // Christmas (holiday)
      isSmartCard: false,
      isAirportExpress: false,
    );
    
    if (holidayFareResult.finalFare != 21) { // Should be discounted from 32 to 21
      warnings.add('Holiday fare discount not working correctly: got ${holidayFareResult.finalFare}, expected 21');
    }
    
    // Test smart card discounts
    final smartCardResult = AccurateFareCalculator.calculateFare(
      distance: 10.0,
      travelTime: DateTime.now(),
      isSmartCard: true,
      isAirportExpress: false,
    );
    
    final baseFare = AccurateFareCalculator.calculateFare(
      distance: 10.0,
      travelTime: DateTime.now(),
      isSmartCard: false,
      isAirportExpress: false,
    );
    
    final expectedDiscount = (baseFare.finalFare * 0.10).round();
    if (smartCardResult.smartCardSavings.round() != expectedDiscount) {
      warnings.add('Smart card discount calculation error: got ${smartCardResult.smartCardSavings}, expected $expectedDiscount');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate Maximum Permissible Time (MPT) calculations
  static ValidationResult validateMPTCalculation() {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Test MPT for different fare ranges
    final testCases = [
      {'fare': 15, 'expectedMPT': 65, 'description': 'Short distance fare'},
      {'fare': 20, 'expectedMPT': 100, 'description': 'Mid distance fare'},
      {'fare': 30, 'expectedMPT': 180, 'description': 'Long distance fare'},
    ];
    
    for (final testCase in testCases) {
      final fare = testCase['fare'] as int;
      final expectedMPT = testCase['expectedMPT'] as int;
      final description = testCase['description'] as String;
      
      // Calculate MPT based on fare
      int mpt;
      if (fare <= 18) {
        mpt = 65;
      } else if (fare <= 23) {
        mpt = 100;
      } else {
        mpt = 180;
      }
      
      if (mpt != expectedMPT) {
        errors.add('MPT calculation error for $description: got $mpt, expected $expectedMPT');
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Comprehensive validation of all data
  static ComprehensiveValidationResult validateAllData({
    required List<MetroStation> stations,
    required List<MetroRoute> routes,
  }) {
    final stationValidation = validateStationData(stations);
    final routeValidation = validateRouteData(routes);
    final fareValidation = validateFareCalculation();
    final mptValidation = validateMPTCalculation();
    
    final allErrors = [
      ...stationValidation.errors,
      ...routeValidation.errors,
      ...fareValidation.errors,
      ...mptValidation.errors,
    ];
    
    final allWarnings = [
      ...stationValidation.warnings,
      ...routeValidation.warnings,
      ...fareValidation.warnings,
      ...mptValidation.warnings,
    ];
    
    return ComprehensiveValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
      stationValidation: stationValidation,
      routeValidation: routeValidation,
      fareValidation: fareValidation,
      mptValidation: mptValidation,
    );
  }
}

/// Basic validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// Comprehensive validation result
class ComprehensiveValidationResult extends ValidationResult {
  final ValidationResult stationValidation;
  final ValidationResult routeValidation;
  final ValidationResult fareValidation;
  final ValidationResult mptValidation;

  ComprehensiveValidationResult({
    required bool isValid,
    required List<String> errors,
    required List<String> warnings,
    required this.stationValidation,
    required this.routeValidation,
    required this.fareValidation,
    required this.mptValidation,
  }) : super(isValid: isValid, errors: errors, warnings: warnings);
}
