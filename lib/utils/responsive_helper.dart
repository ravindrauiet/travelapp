import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static bool isSmallTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isSmallTablet(context)) return 3;
    if (isLargeTablet(context)) return 4;
    return 5; // Desktop
  }

  static double getGridChildAspectRatio(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isSmallTablet(context)) return 1.1;
    if (isLargeTablet(context)) return 1.2;
    return 1.3; // Desktop
  }

  static double getCardPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 18.0;
    return 20.0; // Desktop
  }

  static double getSectionSpacing(BuildContext context) {
    if (isMobile(context)) return 32.0;
    if (isTablet(context)) return 40.0;
    return 48.0; // Desktop
  }

  static double getGridSpacing(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    return 24.0; // Desktop
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(20);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
  }

  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200; // Max width for very large screens
    }
    return double.infinity;
  }

  static bool shouldShowSidebar(BuildContext context) {
    return isLargeTablet(context) || isDesktop(context);
  }

  static int getWelcomeStatsCount(BuildContext context) {
    if (isMobile(context)) return 3;
    if (isSmallTablet(context)) return 4;
    return 5; // Large tablet and desktop
  }
}
