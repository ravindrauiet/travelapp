import 'dart:math';

/// Accurate Delhi Metro Fare Calculator based on official DMRC rates
/// Effective August 25, 2025
class AccurateFareCalculator {
  // Official DMRC Fare Slabs (Normal Days - Monday to Saturday)
  static const Map<String, int> normalDayFares = {
    '0-2': 11,    // 0-2 km: ₹11
    '2-5': 21,    // 2-5 km: ₹21
    '5-12': 32,   // 5-12 km: ₹32
    '12-21': 43,  // 12-21 km: ₹43
    '21-32': 54,  // 21-32 km: ₹54
    '32+': 64,    // Beyond 32 km: ₹64
  };

  // Official DMRC Fare Slabs (Discounted Days - Sundays & National Holidays)
  static const Map<String, int> holidayFares = {
    '0-2': 11,    // 0-2 km: ₹11 (no discount)
    '2-5': 11,    // 2-5 km: ₹11 (discounted from ₹21)
    '5-12': 21,   // 5-12 km: ₹21 (discounted from ₹32)
    '12-21': 32,  // 12-21 km: ₹32 (discounted from ₹43)
    '21-32': 43,  // 21-32 km: ₹43 (discounted from ₹54)
    '32+': 54,    // Beyond 32 km: ₹54 (discounted from ₹64)
  };

  // Airport Express Line fare range (premium service)
  static const int aelMinFare = 50;
  static const int aelMaxFare = 70;

  // Maximum Permissible Time (MPT) based on fare
  static const Map<String, int> mptLimits = {
    'short': 65,   // Fare ₹11 & ₹21: 65 minutes
    'mid': 100,    // Fare ₹32 & ₹43: 100 minutes
    'long': 180,   // Fare ₹54 & ₹64: 180 minutes
  };

  // Smart card discounts
  static const double smartCardDiscount = 0.10; // 10% standard discount
  static const double offPeakDiscount = 0.10;   // Additional 10% off-peak discount

  /// Calculate distance between two GPS coordinates using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get fare slab based on distance
  static String _getFareSlab(double distance) {
    if (distance <= 2) return '0-2';
    if (distance <= 5) return '2-5';
    if (distance <= 12) return '5-12';
    if (distance <= 21) return '12-21';
    if (distance <= 32) return '21-32';
    return '32+';
  }

  /// Calculate base fare for normal days
  static int calculateNormalDayFare(double distance) {
    String slab = _getFareSlab(distance);
    return normalDayFares[slab] ?? 64;
  }

  /// Calculate base fare for holiday days
  static int calculateHolidayFare(double distance) {
    String slab = _getFareSlab(distance);
    return holidayFares[slab] ?? 54;
  }

  /// Calculate Airport Express Line fare
  static int calculateAELFare(double distance) {
    // AEL has premium pricing, generally between ₹50-₹70
    if (distance <= 5) return aelMinFare;
    if (distance <= 15) return 60;
    return aelMaxFare;
  }

  /// Check if current time is off-peak hours
  static bool isOffPeakHour(DateTime time) {
    int hour = time.hour;
    // Off-peak: before 8:00 AM, between 12:00 PM-5:00 PM, after 9:00 PM
    return hour < 8 || (hour >= 12 && hour < 17) || hour >= 21;
  }

  /// Check if current date is a holiday (Sunday or national holiday)
  static bool isHoliday(DateTime date) {
    // Sunday check
    if (date.weekday == DateTime.sunday) return true;
    
    // National holidays (simplified - you can expand this list)
    List<DateTime> nationalHolidays = [
      DateTime(date.year, 1, 26), // Republic Day
      DateTime(date.year, 8, 15), // Independence Day
      DateTime(date.year, 10, 2), // Gandhi Jayanti
      DateTime(date.year, 12, 25), // Christmas
    ];
    
    return nationalHolidays.any((holiday) => 
        holiday.year == date.year && 
        holiday.month == date.month && 
        holiday.day == date.day);
  }

  /// Calculate both smart card and ticket prices
  static FareComparisonResult calculateFareComparison({
    required double distance,
    required DateTime travelTime,
    required bool isAirportExpress,
  }) {
    int baseFare;
    
    if (isAirportExpress) {
      baseFare = calculateAELFare(distance);
    } else if (isHoliday(travelTime)) {
      baseFare = calculateHolidayFare(distance);
    } else {
      baseFare = calculateNormalDayFare(distance);
    }

    // Calculate smart card fare with discounts
    double smartCardSavings = baseFare * smartCardDiscount;
    int smartCardFare = (baseFare - smartCardSavings).round();
    
    // Apply off-peak discount if applicable
    double offPeakSavings = 0;
    if (isOffPeakHour(travelTime)) {
      offPeakSavings = smartCardFare * offPeakDiscount;
      smartCardFare = (smartCardFare - offPeakSavings).round();
    }

    // Calculate MPT
    int mpt = _getMPT(baseFare);

    return FareComparisonResult(
      baseFare: baseFare,
      smartCardFare: smartCardFare,
      ticketFare: baseFare,
      smartCardSavings: baseFare * smartCardDiscount,
      offPeakSavings: offPeakSavings,
      totalSavings: (baseFare * smartCardDiscount) + offPeakSavings,
      mpt: mpt,
      isOffPeak: isOffPeakHour(travelTime),
      isHoliday: isHoliday(travelTime),
    );
  }

  /// Calculate final fare with all discounts applied
  static FareCalculationResult calculateFare({
    required double distance,
    required DateTime travelTime,
    required bool isSmartCard,
    required bool isAirportExpress,
  }) {
    int baseFare;
    
    if (isAirportExpress) {
      baseFare = calculateAELFare(distance);
    } else if (isHoliday(travelTime)) {
      baseFare = calculateHolidayFare(distance);
    } else {
      baseFare = calculateNormalDayFare(distance);
    }

    // Apply smart card discount
    double smartCardSavings = 0;
    if (isSmartCard) {
      smartCardSavings = baseFare * smartCardDiscount;
      baseFare = (baseFare - smartCardSavings).round();
    }

    // Apply off-peak discount
    double offPeakSavings = 0;
    if (isSmartCard && isOffPeakHour(travelTime)) {
      offPeakSavings = baseFare * offPeakDiscount;
      baseFare = (baseFare - offPeakSavings).round();
    }

    // Calculate MPT
    int mpt = _getMPT(baseFare);
    
    return FareCalculationResult(
      baseFare: baseFare,
      smartCardSavings: smartCardSavings,
      offPeakSavings: offPeakSavings,
      totalSavings: smartCardSavings + offPeakSavings,
      finalFare: baseFare,
      mpt: mpt,
      isOffPeak: isOffPeakHour(travelTime),
      isHoliday: isHoliday(travelTime),
    );
  }

  /// Get Maximum Permissible Time based on fare
  static int _getMPT(int fare) {
    if (fare <= 21) return mptLimits['short']!;  // ₹11 & ₹21: 65 minutes
    if (fare <= 43) return mptLimits['mid']!;    // ₹32 & ₹43: 100 minutes
    return mptLimits['long']!;                   // ₹54 & ₹64: 180 minutes
  }

  /// Calculate penalty for overstaying
  static int calculatePenalty(int overstayMinutes) {
    int penaltyHours = (overstayMinutes / 60).ceil();
    int penalty = penaltyHours * 10; // ₹10 per hour
    return min(penalty, 50); // Maximum penalty ₹50
  }

  /// Check if journey time exceeds MPT
  static bool exceedsMPT(int journeyTimeMinutes, int mpt) {
    return journeyTimeMinutes > mpt;
  }
}

/// Result of fare calculation
class FareCalculationResult {
  final int baseFare;
  final double smartCardSavings;
  final double offPeakSavings;
  final double totalSavings;
  final int finalFare;
  final int mpt;
  final bool isOffPeak;
  final bool isHoliday;

  FareCalculationResult({
    required this.baseFare,
    required this.smartCardSavings,
    required this.offPeakSavings,
    required this.totalSavings,
    required this.finalFare,
    required this.mpt,
    required this.isOffPeak,
    required this.isHoliday,
  });

  @override
  String toString() {
    return 'FareCalculationResult(baseFare: $baseFare, finalFare: $finalFare, mpt: $mpt, isOffPeak: $isOffPeak, isHoliday: $isHoliday)';
  }
}

class FareComparisonResult {
  final int baseFare;
  final int smartCardFare;
  final int ticketFare;
  final double smartCardSavings;
  final double offPeakSavings;
  final double totalSavings;
  final int mpt;
  final bool isOffPeak;
  final bool isHoliday;

  FareComparisonResult({
    required this.baseFare,
    required this.smartCardFare,
    required this.ticketFare,
    required this.smartCardSavings,
    required this.offPeakSavings,
    required this.totalSavings,
    required this.mpt,
    required this.isOffPeak,
    required this.isHoliday,
  });

  @override
  String toString() {
    return 'FareComparisonResult(baseFare: $baseFare, smartCardFare: $smartCardFare, ticketFare: $ticketFare, totalSavings: $totalSavings, mpt: $mpt, isOffPeak: $isOffPeak, isHoliday: $isHoliday)';
  }
}
