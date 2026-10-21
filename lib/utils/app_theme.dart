import 'package:flutter/material.dart';

class AppTheme {
  static const String fontFamily = 'Jakarta';

  // Brand Palette — "Delhi Dusk": deep indigo night sky, violet glow, saffron sunset
  static const Color brandNight = Color(0xFF1E1B4B); // Indigo 950
  static const Color brandIndigo = Color(0xFF4338CA); // Indigo 700
  static const Color brandViolet = Color(0xFF7C3AED); // Violet 600
  static const Color brandSaffron = Color(0xFFFF7A1A); // Saffron
  static const Color brandRose = Color(0xFFF43F5E); // Rose

  static const Color primaryColor = Color(0xFF4F46E5); // Vibrant Indigo
  static const Color secondaryColor = brandViolet;
  static const Color accentColor = Color(0xFFFF6B35); // Saffron Coral
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF0EA5E9);
  static const Color successColor = Color(0xFF10B981);

  // Background & Surface (lavender-tinted so the app never reads as flat white)
  static const Color backgroundColor = Color(0xFFF3F4FB);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFEEF0FF);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F1235);
  static const Color textSecondary = Color(0xFF4B5173);
  static const Color textTertiary = Color(0xFF9096B4);
  static const Color dividerColor = Color(0xFFE4E6F2);

  // Dark palette
  static const Color darkBackground = Color(0xFF0B0D1F);
  static const Color darkSurface = Color(0xFF15183A);
  static const Color darkCard = Color(0xFF1A1E45);
  static const Color darkBorder = Color(0xFF2A2F5E);
  static const Color darkTextPrimary = Color(0xFFF5F6FF);
  static const Color darkTextSecondary = Color(0xFFC3C7E6);
  static const Color darkTextTertiary = Color(0xFF8A90B8);

  // Metro Line Colors (authentic Delhi Metro colours)
  static const Color metroBlue = Color(0xFF1D4ED8);
  static const Color metroRed = Color(0xFFDC2626);
  static const Color metroYellow = Color(0xFFF59E0B);
  static const Color metroGreen = Color(0xFF16A34A);
  static const Color metroViolet = Color(0xFF7C3AED);
  static const Color metroPink = Color(0xFFDB2777);
  static const Color metroMagenta = Color(0xFFC026D3);
  static const Color metroPurple = Color(0xFF9333EA);
  static const Color metroOrange = Color(0xFFEA580C);
  static const Color metroGrey = Color(0xFF64748B);
  static const Color metroAqua = Color(0xFF06B6D4);
  static const Color metroRapid = Color(0xFF0EA5E9);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [brandNight, brandIndigo, brandViolet],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF8A3D), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient transitGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF0369A1), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient royalGradient = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFFC026D3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: brandNight.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: brandNight.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get accentShadow => [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double alpha = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBackground : backgroundColor;
    final surface = isDark ? darkSurface : surfaceColor;
    final card = isDark ? darkCard : cardColor;
    final border = isDark ? darkBorder : dividerColor;
    final tPrimary = isDark ? darkTextPrimary : textPrimary;
    final tSecondary = isDark ? darkTextSecondary : textSecondary;
    final tTertiary = isDark ? darkTextTertiary : textTertiary;
    final primary = isDark ? const Color(0xFF818CF8) : primaryColor;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      tertiary: brandViolet,
      surface: surface,
      onSurface: tPrimary,
      error: errorColor,
      outline: border,
      outlineVariant: border,
    );

    TextStyle t(double size, FontWeight w, Color c, [double? h, double? ls]) =>
        TextStyle(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

    final shape16 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkSurface : brandIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? accentColor : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: shape16,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? accentColor : primaryColor,
          foregroundColor: Colors.white,
          shape: shape16,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : primaryColor,
          side: BorderSide(color: isDark ? darkBorder : primaryColor, width: 1.5),
          shape: shape16,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFFA5B4FC) : primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border.withValues(alpha: isDark ? 1 : 0.7)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkCard : surfaceTint,
        selectedColor: primary.withValues(alpha: 0.18),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: tPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard : const Color(0xFFF7F8FD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: tTertiary),
        labelStyle: TextStyle(color: tSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkCard : brandNight,
        contentTextStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: accentColor,
        labelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      listTileTheme: ListTileThemeData(iconColor: primary, textColor: tPrimary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: isDark ? accentColor : primaryColor,
        unselectedItemColor: tTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      textTheme: TextTheme(
        displaySmall: t(34, FontWeight.w800, tPrimary, 1.15, -0.8),
        headlineLarge: t(30, FontWeight.w800, tPrimary, 1.2, -0.6),
        headlineMedium: t(26, FontWeight.w800, tPrimary, 1.25, -0.5),
        headlineSmall: t(22, FontWeight.w700, tPrimary, 1.3, -0.3),
        titleLarge: t(19, FontWeight.w700, tPrimary, 1.35, -0.2),
        titleMedium: t(16, FontWeight.w700, tPrimary, 1.4),
        titleSmall: t(14, FontWeight.w600, tPrimary, 1.4),
        bodyLarge: t(16, FontWeight.w400, tSecondary, 1.5),
        bodyMedium: t(14, FontWeight.w400, tSecondary, 1.5),
        bodySmall: t(12, FontWeight.w400, tTertiary, 1.4),
        labelLarge: t(14, FontWeight.w700, tPrimary),
        labelMedium: t(12, FontWeight.w600, tSecondary),
        labelSmall: t(10, FontWeight.w600, tTertiary, null, 0.4),
      ),
    );
  }
}
