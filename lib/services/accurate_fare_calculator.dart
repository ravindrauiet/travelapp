import 'dart:math';
import '../models/metro_route.dart';

/// Delhi Metro fare rules based on the official DMRC tariff effective
/// 25 August 2025.
///
/// * Normal days (Mon–Sat): 0–2 km ₹11, 2–5 ₹21, 5–12 ₹32, 12–21 ₹43,
///   21–32 ₹54, >32 ₹64.
/// * Sundays & national holidays (26 Jan, 15 Aug, 2 Oct):
///   ₹11 / 11 / 21 / 32 / 43 / 54.
/// * Smart Card: 10% off every journey, a further 10% of the fare off during
///   off-peak hours (before 08:00, 12:00–17:00, after 21:00).
/// * Airport Express, Aqua Line (NMRC) and Rapid Metro Gurugram are separate
///   fare systems — see [MetroFare.quote].
class AccurateFareCalculator {
  // Official DMRC Fare Slabs (Normal Days - Monday to Saturday)
  static const Map<String, int> normalDayFares = {
    '0-2': 11,
    '2-5': 21,
    '5-12': 32,
    '12-21': 43,
    '21-32': 54,
    '32+': 64,
  };

  // Official DMRC Fare Slabs (Sundays & National Holidays)
  static const Map<String, int> holidayFares = {
    '0-2': 11,
    '2-5': 11,
    '5-12': 21,
    '12-21': 32,
    '21-32': 43,
    '32+': 54,
  };

  // Airport Express Line fares (separate ticket from the DMRC network).
  // Approximation of the station-to-station AEL tariff (Aug 2025 revision):
  // NDLS–Shivaji Stadium ₹21, –Dhaula Kuan ₹32, –Aerocity ₹54,
  // –IGI Airport / Dwarka Sector 21 / Yashobhoomi ₹64.
  static const int aelMinFare = 21;
  static const int aelMaxFare = 64;

  // Maximum Permissible Time (MPT) based on fare
  static const Map<String, int> mptLimits = {
    'short': 65, // Fare ₹11 & ₹21: 65 minutes
    'mid': 100, // Fare ₹32 & ₹43: 100 minutes
    'long': 180, // Fare ₹54 & ₹64: 180 minutes
  };

  // Smart card discounts (both expressed as a fraction of the token fare)
  static const double smartCardDiscount = 0.10; // every journey
  static const double offPeakDiscount = 0.10; // additional, off-peak only

  /// Great-circle distance in km (Haversine).
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) => degrees * (pi / 180);

  static String _getFareSlab(double distance) {
    if (distance <= 2) return '0-2';
    if (distance <= 5) return '2-5';
    if (distance <= 12) return '5-12';
    if (distance <= 21) return '12-21';
    if (distance <= 32) return '21-32';
    return '32+';
  }

  /// Token fare on a normal day.
  static int calculateNormalDayFare(double distance) =>
      normalDayFares[_getFareSlab(distance)] ?? 64;

  /// Token fare on Sundays / national holidays.
  static int calculateHolidayFare(double distance) =>
      holidayFares[_getFareSlab(distance)] ?? 54;

  /// Airport Express token fare (approximate station tariff by distance).
  static int calculateAELFare(double distance) {
    if (distance <= 3.5) return aelMinFare;
    if (distance <= 9.5) return 32;
    if (distance <= 16.5) return 54;
    return aelMaxFare;
  }

  /// Off-peak: before 08:00, 12:00–17:00 and after 21:00.
  static bool isOffPeakHour(DateTime time) {
    final hour = time.hour;
    return hour < 8 || (hour >= 12 && hour < 17) || hour >= 21;
  }

  /// Sunday or a national holiday on which DMRC charges the Sunday table.
  static bool isHoliday(DateTime date) {
    if (date.weekday == DateTime.sunday) return true;
    const nationalHolidays = [
      (1, 26), // Republic Day
      (8, 15), // Independence Day
      (10, 2), // Gandhi Jayanti
    ];
    return nationalHolidays.any((h) => h.$1 == date.month && h.$2 == date.day);
  }

  /// Smart card fare for a DMRC token fare.
  static int smartCardFareFor(int tokenFare, DateTime travelTime) {
    final discount = smartCardDiscount + (isOffPeakHour(travelTime) ? offPeakDiscount : 0);
    return (tokenFare * (1 - discount)).round();
  }

  /// Token and smart card fare for one DMRC (or AEL) journey of [distance] km.
  static FareComparisonResult calculateFareComparison({
    required double distance,
    required DateTime travelTime,
    required bool isAirportExpress,
  }) {
    final holiday = isHoliday(travelTime);
    final offPeak = isOffPeakHour(travelTime);
    final int baseFare = isAirportExpress
        ? calculateAELFare(distance)
        : holiday
            ? calculateHolidayFare(distance)
            : calculateNormalDayFare(distance);

    final smartCardSavings = baseFare * smartCardDiscount;
    // Off-peak bonus is a DMRC-network benefit; AEL gets the flat 10%.
    final offPeakSavings = (!isAirportExpress && offPeak) ? baseFare * offPeakDiscount : 0.0;
    final smartCardFare = (baseFare - smartCardSavings - offPeakSavings).round();

    return FareComparisonResult(
      baseFare: baseFare,
      smartCardFare: smartCardFare,
      ticketFare: baseFare,
      smartCardSavings: smartCardSavings,
      offPeakSavings: offPeakSavings,
      totalSavings: (baseFare - smartCardFare).toDouble(),
      mpt: _getMPT(baseFare),
      isOffPeak: offPeak,
      isHoliday: holiday,
    );
  }

  /// Final fare for one ticket type (kept for legacy callers).
  static FareCalculationResult calculateFare({
    required double distance,
    required DateTime travelTime,
    required bool isSmartCard,
    required bool isAirportExpress,
  }) {
    final c = calculateFareComparison(
      distance: distance,
      travelTime: travelTime,
      isAirportExpress: isAirportExpress,
    );
    final finalFare = isSmartCard ? c.smartCardFare : c.ticketFare;
    final cardSavings = isSmartCard ? c.smartCardSavings : 0.0;
    final offPeakSavings = isSmartCard ? c.offPeakSavings : 0.0;
    return FareCalculationResult(
      baseFare: finalFare,
      smartCardSavings: cardSavings,
      offPeakSavings: offPeakSavings,
      totalSavings: cardSavings + offPeakSavings,
      finalFare: finalFare,
      mpt: _getMPT(c.ticketFare),
      isOffPeak: c.isOffPeak,
      isHoliday: c.isHoliday,
    );
  }

  /// Maximum Permissible Time based on the token fare.
  static int mptForFare(int fare) => _getMPT(fare);

  static int _getMPT(int fare) {
    if (fare <= 21) return mptLimits['short']!;
    if (fare <= 43) return mptLimits['mid']!;
    return mptLimits['long']!;
  }

  /// Penalty for overstaying: ₹10 per hour, max ₹50.
  static int calculatePenalty(int overstayMinutes) {
    final penaltyHours = (overstayMinutes / 60).ceil();
    return min(penaltyHours * 10, 50);
  }

  static bool exceedsMPT(int journeyTimeMinutes, int mpt) => journeyTimeMinutes > mpt;
}

/// A fare quote for one ticket on one fare system.
class FareQuote {
  final FareSystem system;
  final int tokenFare;
  final int smartCardFare;
  final bool isOffPeak;
  final bool isHoliday;

  /// True when the tariff used is an estimate (non-DMRC systems).
  final bool approximate;

  const FareQuote({
    required this.system,
    required this.tokenFare,
    required this.smartCardFare,
    required this.isOffPeak,
    required this.isHoliday,
    required this.approximate,
  });
}

/// Fare rules per fare system.
class MetroFare {
  /// Noida Metro (Aqua Line) distance slabs.
  static int nmrcFare(double km) {
    if (km <= 2) return 10;
    if (km <= 4) return 15;
    if (km <= 6) return 20;
    if (km <= 9) return 25;
    if (km <= 12) return 30;
    if (km <= 15) return 35;
    if (km <= 18) return 40;
    if (km <= 21) return 45;
    return 50;
  }

  /// Rapid Metro Gurugram (approximate).
  static int rapidMetroFare(double km) => km <= 4 ? 20 : 30;

  static FareQuote quote({
    required FareSystem system,
    required double distanceKm,
    required DateTime when,
    String? fromStation,
    String? toStation,
  }) {
    final offPeak = AccurateFareCalculator.isOffPeakHour(when);
    final holiday = AccurateFareCalculator.isHoliday(when);
    switch (system) {
      case FareSystem.dmrc:
        final r = AccurateFareCalculator.calculateFareComparison(
          distance: distanceKm,
          travelTime: when,
          isAirportExpress: false,
        );
        return FareQuote(
          system: system,
          tokenFare: r.ticketFare,
          smartCardFare: r.smartCardFare,
          isOffPeak: offPeak,
          isHoliday: holiday,
          approximate: false,
        );
      case FareSystem.airportExpress:
        final t = AccurateFareCalculator.calculateAELFare(distanceKm);
        return FareQuote(
          system: system,
          tokenFare: t,
          smartCardFare: (t * 0.9).round(),
          isOffPeak: offPeak,
          isHoliday: holiday,
          approximate: true,
        );
      case FareSystem.nmrc:
        final t = nmrcFare(distanceKm);
        return FareQuote(
          system: system,
          tokenFare: t,
          smartCardFare: (t * 0.9).round(),
          isOffPeak: offPeak,
          isHoliday: holiday,
          approximate: true,
        );
      case FareSystem.rapidMetro:
        final t = rapidMetroFare(distanceKm);
        return FareQuote(
          system: system,
          tokenFare: t,
          smartCardFare: (t * 0.9).round(),
          isOffPeak: offPeak,
          isHoliday: holiday,
          approximate: true,
        );
    }
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
