import 'package:flutter/material.dart';

// ── Design Tokens ───────────────────────────────────────────────────
//
// Theme: "Warm Confidence" — Stitch-generated Manrope + Gold design system
//

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

abstract class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 9999;
}

abstract class AppDuration {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration calm = Duration(milliseconds: 700);
}

// ── Colors ──────────────────────────────────────────────────────────

abstract class AppColors {
  // ─ Core brand (Stitch palette)
  static const Color primary = Color(0xFFD4A954);
  static const Color amber = Color(0xFFD4A954);    // alias
  static const Color teal = Color(0xFF2A9D8F);
  static const Color coral = Color(0xFFE8724A);

  // ─ Surfaces
  static const Color cream = Color(0xFFF8F7F6);
  static const Color warmWhite = Color(0xFFFFF9F0);
  static const Color softCream = Color(0xFFFFF1E0);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // ─ Text
  static const Color ink = Color(0xFF3D2E1F);
  static const Color charcoal = Color(0xFF1D1B16);
  static const Color stone = Color(0xFF4C4639);
  static const Color mist = Color(0xFF7D7667);
  static const Color slateLight = Color(0xFF94A3B8); // Stitch section headers

  // ─ Borders
  static const Color border = Color(0xFFCEC6B4);
  static const Color borderLight = Color(0xFFE8E2D5);
  static const Color borderPrimary5 = Color(0x0DD4A954); // primary at 5%

  // ─ Semantic / Risk (Stitch risk colors)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ─ Badge backgrounds (Stitch mode badges)
  static const Color emeraldBg = Color(0xFFECFDF5);
  static const Color emeraldText = Color(0xFF059669);
  static const Color blueBg = Color(0xFFEFF6FF);
  static const Color blueText = Color(0xFF2563EB);
  static const Color purpleBg = Color(0xFFFAF5FF);
  static const Color purpleText = Color(0xFF9333EA);

  // ─ Dark mode
  static const Color darkBase = Color(0xFF1F1B13);
  static const Color darkSurface = Color(0xFF2A2419);
  static const Color darkElevated = Color(0xFF352E22);
  static const Color darkOnSurface = Color(0xFFE8E2DB);
  static const Color darkMuted = Color(0xFF8B8272);
  static const Color darkBorder = Color(0xFF3D3526);
  static const Color darkAmber = Color(0xFFE8C06A);
  static const Color darkTeal = Color(0xFF3DCFCF);
}

// ── Gradients ───────────────────────────────────────────────────────

abstract class AppGradients {
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4A954),
      Color(0xFFE8BC6A),
      Color(0xFFEFCB80),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8F7F6),
      Color(0xFFF3F0EC),
    ],
  );

  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1F1B13),
      Color(0xFF252015),
    ],
  );

  static const LinearGradient teal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A9D8F),
      Color(0xFF35B3A4),
    ],
  );

  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x99000000),
    ],
    stops: [0.4, 1.0],
  );
}

// ── Shadows ─────────────────────────────────────────────────────────

abstract class AppShadows {
  // Stitch: box-shadow: 0 4px 20px -2px rgba(212,169,84,0.15)
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFFD4A954).withValues(alpha: 0.10),
      blurRadius: 12,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: const Color(0xFFD4A954).withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: const Color(0xFFD4A954).withValues(alpha: 0.30),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

// ── Theme ───────────────────────────────────────────────────────────

const String _fontFamily = 'Manrope';

TextTheme _manropeTextTheme(TextTheme base) {
  return base.apply(fontFamily: _fontFamily);
}

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.ink,
    outline: AppColors.border,
    outlineVariant: AppColors.borderLight,
  );

  final textTheme = _manropeTextTheme(const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      height: 1.35,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  ));

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: textTheme,

    // App Bar — Stitch: sticky bg/80 + backdrop-blur
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.1,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary, size: 24),
    ),

    // Cards — Stitch: white bg, border primary/5, rounded-lg, warm shadow
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.05)),
      ),
      color: AppColors.cardWhite,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),

    // Filled Buttons — Stitch: bg-primary, white text, rounded-xl, shadow
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        textStyle: TextStyle(fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // Elevated Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        elevation: 0,
        textStyle: TextStyle(fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // Outlined Buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
        textStyle: TextStyle(fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: TextStyle(fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // Input Fields — Stitch: white bg, border primary/10, rounded-xl
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: TextStyle(fontFamily: _fontFamily,
        color: AppColors.ink.withValues(alpha: 0.3),
        fontSize: 16,
      ),
    ),

    // Chips — Stitch: pill shape, primary tint
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
    ),

    // Snack Bar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      backgroundColor: AppColors.ink.withValues(alpha: 0.9),
    ),

    // Tab Bar — Stitch: primary indicator, bold selected
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.slateLight,
      labelStyle: TextStyle(fontFamily: _fontFamily,fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: _fontFamily,fontSize: 14, fontWeight: FontWeight.w600),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.primary.withValues(alpha: 0.1),
      thickness: 1,
    ),

    // Bottom nav
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontFamily: _fontFamily,fontSize: 10, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.darkAmber,
    onPrimary: AppColors.darkBase,
    surface: AppColors.darkBase,
    onSurface: AppColors.darkOnSurface,
    onSurfaceVariant: AppColors.darkMuted,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorder,
  );

  final textTheme = _manropeTextTheme(const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      height: 1.35,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  ));

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkBase,
    textTheme: textTheme,

    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.darkBase,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkOnSurface,
        letterSpacing: -0.1,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkAmber, size: 24),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.05)),
      ),
      color: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.darkAmber,
        foregroundColor: AppColors.darkBase,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        textStyle: TextStyle(fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkAmber,
        foregroundColor: AppColors.darkBase,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkAmber,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkAmber,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: const BorderSide(color: AppColors.darkAmber, width: 2),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      backgroundColor: AppColors.darkElevated,
    ),

    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColors.darkAmber,
      labelColor: AppColors.darkAmber,
      unselectedLabelColor: AppColors.darkMuted,
      labelStyle: TextStyle(fontFamily: _fontFamily,fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: _fontFamily,fontSize: 14, fontWeight: FontWeight.w600),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
    ),
  );
}
