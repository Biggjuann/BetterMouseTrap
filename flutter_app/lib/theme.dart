import 'package:flutter/material.dart';

// ── Design Tokens ───────────────────────────────────────────────────
//
// Design philosophy: "Warm Confidence"
//   Calm  → generous whitespace, slow intentional animations, deep dark mode
//   Canva → vibrant but controlled accents, clear hierarchy, skeleton loaders
//   Etsy  → warm cream surfaces, dark pill CTAs, handcraft warmth
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
  static const double pill = 999;
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
  // ─ Core brand
  static const Color amber = Color(0xFFD48500);       // primary brand amber
  static const Color teal = Color(0xFF1A8A8A);         // secondary accent (Canva/Etsy inspired)
  static const Color coral = Color(0xFFE8724A);        // warm accent for highlights

  // ─ Surfaces (Etsy-inspired warm cream)
  static const Color cream = Color(0xFFFAF8F5);        // scaffold background
  static const Color warmWhite = Color(0xFFFFF8F0);    // card surfaces
  static const Color softCream = Color(0xFFFFF1E0);    // container fill / banners
  static const Color cardWhite = Color(0xFFFFFFFF);     // elevated card

  // ─ Text
  static const Color ink = Color(0xFF1A1A1A);          // primary text (Etsy near-black)
  static const Color charcoal = Color(0xFF2D2926);     // secondary text (darkened for readability)
  static const Color stone = Color(0xFF574F47);        // tertiary text (darkened for readability)
  static const Color mist = Color(0xFF8A827A);         // placeholder / disabled (darkened for readability)

  // ─ Borders & dividers
  static const Color border = Color(0xFFE8E2DB);       // default border
  static const Color borderLight = Color(0xFFF0EBE5);  // subtle border

  // ─ Semantic
  static const Color success = Color(0xFF2E7D44);
  static const Color warning = Color(0xFFE8A020);
  static const Color error = Color(0xFFD93025);

  // ─ Dark mode (Calm-inspired deep navy)
  static const Color darkBase = Color(0xFF141820);     // scaffold
  static const Color darkSurface = Color(0xFF1C2230);  // card surfaces
  static const Color darkElevated = Color(0xFF252D3D); // elevated containers
  static const Color darkOnSurface = Color(0xFFE8E2DB);
  static const Color darkMuted = Color(0xFF8B92A0);
  static const Color darkBorder = Color(0xFF2E3648);
  static const Color darkAmber = Color(0xFFFFBE4D);
  static const Color darkTeal = Color(0xFF3DCFCF);
}

// ── Gradients ───────────────────────────────────────────────────────

abstract class AppGradients {
  // Hero gradient — used sparingly for the main CTA
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD48500),
      Color(0xFFE8A020),
      Color(0xFFEFB845),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Subtle page background
  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAF8F5),
      Color(0xFFF5F0EA),
    ],
  );

  // Dark mode background (Calm deep navy)
  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF141820),
      Color(0xFF1A1F2C),
    ],
  );

  // Teal accent gradient (for secondary hero moments)
  static const LinearGradient teal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A8A8A),
      Color(0xFF25A8A8),
    ],
  );

  // Success gradient
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF2E7D44), Color(0xFF3A9B56)],
  );

  // Card overlay for text legibility
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x40000000),
    ],
    stops: [0.5, 1.0],
  );
}

// ── Shadows ─────────────────────────────────────────────────────────

abstract class AppShadows {
  // Calm-inspired soft, minimal shadows
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
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

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.amber,
    brightness: Brightness.light,
  ).copyWith(
    surface: AppColors.cream,
    surfaceContainerLow: AppColors.warmWhite,
    primary: AppColors.ink,         // Etsy: dark primary CTAs
    secondary: AppColors.teal,
    tertiary: AppColors.coral,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.cream,

    // Typography — Calm's lighter weights, generous line-height
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.charcoal,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.charcoal,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.stone,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.stone,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.stone,
        letterSpacing: 0.3,
      ),
    ),

    // App Bar — clean, floating feel (Calm)
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.1,
      ),
      iconTheme: IconThemeData(color: AppColors.ink, size: 22),
    ),

    // Cards — warm white with subtle border (Etsy)
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.cardWhite,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),

    // Filled Buttons — dark pill (Etsy-inspired)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    // Elevated Buttons — dark pill
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    // Outlined Buttons — pill with subtle border
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Input Fields — warm filled (Etsy)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      hintStyle: const TextStyle(
        color: AppColors.mist,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: AppColors.stone,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Chips — warm cream fill (Etsy)
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      side: const BorderSide(color: AppColors.borderLight),
      backgroundColor: AppColors.warmWhite,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.charcoal,
      ),
    ),

    // Snack Bar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      backgroundColor: AppColors.ink,
    ),

    // Tab Bar — teal indicator
    tabBarTheme: const TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColors.teal,
      labelColor: AppColors.teal,
      unselectedLabelColor: AppColors.stone,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),

    // Bottom nav (if used later)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardWhite,
      indicatorColor: AppColors.softCream,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.amber,
    brightness: Brightness.dark,
  ).copyWith(
    surface: AppColors.darkBase,
    surfaceContainerLow: AppColors.darkSurface,
    primary: AppColors.darkAmber,
    secondary: AppColors.darkTeal,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkBase,

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.darkOnSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.darkOnSurface,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.darkOnSurface,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkOnSurface,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnSurface,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnSurface,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.darkOnSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.darkOnSurface,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.darkMuted,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnSurface,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.darkMuted,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.darkMuted,
        letterSpacing: 0.3,
      ),
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: AppColors.darkBase,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkOnSurface,
        letterSpacing: -0.1,
      ),
      iconTheme: IconThemeData(color: AppColors.darkOnSurface, size: 22),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      color: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.darkOnSurface,
        foregroundColor: AppColors.darkBase,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkOnSurface,
        foregroundColor: AppColors.darkBase,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkOnSurface,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkTeal,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.darkTeal, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.darkMuted),
      labelStyle: const TextStyle(color: AppColors.darkMuted),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      backgroundColor: AppColors.darkElevated,
    ),

    tabBarTheme: const TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColors.darkTeal,
      labelColor: AppColors.darkTeal,
      unselectedLabelColor: AppColors.darkMuted,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
    ),
  );
}
