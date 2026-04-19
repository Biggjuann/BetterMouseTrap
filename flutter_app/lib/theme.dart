import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Call once during app startup (before runApp) to license Google Fonts
/// for offline use and pre-warm the type system. Safe to call repeatedly.
Future<void> initFonts() async {
  GoogleFonts.config.allowRuntimeFetching = true;
  // Pre-cache the families we use so the first render is non-flashing.
  await Future.wait<void>([
    GoogleFonts.pendingFonts([
      GoogleFonts.fraunces(fontWeight: FontWeight.w400),
      GoogleFonts.fraunces(fontWeight: FontWeight.w500),
      GoogleFonts.fraunces(fontWeight: FontWeight.w600),
      GoogleFonts.fraunces(fontStyle: FontStyle.italic),
      GoogleFonts.inter(fontWeight: FontWeight.w400),
      GoogleFonts.inter(fontWeight: FontWeight.w500),
      GoogleFonts.inter(fontWeight: FontWeight.w600),
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w400),
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w500),
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600),
    ]),
  ]);
}

// ── Design Tokens — "Studio" direction ──────────────────────────────
//
// Soft Scandi / warm inventor's desk aesthetic. Canvas off-white, sage
// accent, Fraunces display for editorial headlines, Inter body, mono
// for metadata labels. Matches the redesign prototype.
//

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;
  static const double xxxl = 56;
}

abstract class AppRadius {
  static const double xs = 4;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 9999;
}

abstract class AppDuration {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration calm = Duration(milliseconds: 700);
}

// ── Colors — Studio palette ─────────────────────────────────────────

abstract class AppColors {
  // Surfaces
  static const Color bg         = Color(0xFFEFEAE0); // canvas / page
  static const Color canvas     = Color(0xFFF5F1E8); // card surface
  static const Color surface    = Color(0xFFFAF7F0); // subtle surface
  static const Color cardWhite  = Color(0xFFF5F1E8); // alias
  static const Color cream      = Color(0xFFEFEAE0); // alias for legacy

  // Ink / text
  static const Color ink        = Color(0xFF1F1C17); // primary text
  static const Color charcoal   = Color(0xFF1F1C17); // alias
  static const Color graphite   = Color(0xFF3A3632); // secondary
  static const Color stone      = Color(0xFF3A3632); // alias
  static const Color mist       = Color(0xFF8A8376); // tertiary
  static const Color slateLight = Color(0xFF8A8376); // alias

  // Hairlines
  static const Color hairline   = Color(0x141F1C16); // rules
  static const Color rule       = Color(0x141F1C16); // alias
  static const Color border     = Color(0x291F1C16);
  static const Color borderLight = Color(0x141F1C16);
  static const Color borderPrimary5 = Color(0x0D739E80);

  // Accent — Studio sage (primary)
  static const Color primary    = Color(0xFF5D7A6A); // sage
  static const Color amber      = Color(0xFF5D7A6A); // legacy alias → sage
  static const Color accent     = Color(0xFF5D7A6A);
  static const Color accentSoft = Color(0xFFE2E8DE); // soft sage wash
  static const Color accentInk  = Color(0xFF2F4537); // dark sage

  // Semantic accents (kept muted, studio-tonal)
  static const Color warm       = Color(0xFFC66B3D); // terracotta
  static const Color warmSoft   = Color(0xFFF3DDCB);
  static const Color sun        = Color(0xFFDEB75D); // mustard
  static const Color sunSoft    = Color(0xFFF1E4C3);
  static const Color teal       = Color(0xFF2A9D8F); // kept for compat
  static const Color coral      = Color(0xFFB86B3E); // alias of warm

  // Risk tiers — from tokens.jsx
  static const Color top        = Color(0xFF5D7A6A); // sage
  static const Color moonshot   = Color(0xFF6B4E89); // plum
  static const Color upgrade    = Color(0xFF3D6A8A); // dusty blue
  static const Color adjacent   = Color(0xFFB8924F); // goldenrod
  static const Color recurring  = Color(0xFF8A6A52); // clay

  // Semantic — risk.low / risk.med / risk.high
  static const Color success    = Color(0xFF5D7A6A);
  static const Color warning    = Color(0xFFC6943D);
  static const Color error      = Color(0xFFB8532F);

  // Legacy mode badges — mapped onto Studio palette
  static const Color emeraldBg   = Color(0xFFE3EDE4);
  static const Color emeraldText = Color(0xFF3F5F4A);
  static const Color blueBg      = Color(0xFFE3E8EE);
  static const Color blueText    = Color(0xFF445A78);
  static const Color purpleBg    = Color(0xFFEAE1EC);
  static const Color purpleText  = Color(0xFF6B4A6E);

  // Dark mode
  static const Color darkBase     = Color(0xFF1A1714);
  static const Color darkSurface  = Color(0xFF24201B);
  static const Color darkElevated = Color(0xFF2E2923);
  static const Color darkOnSurface = Color(0xFFEFEAE0);
  static const Color darkMuted    = Color(0xFF8A8376);
  static const Color darkBorder   = Color(0xFF3A342C);
  static const Color darkAmber    = Color(0xFF9FC0A8); // dark sage
  static const Color darkTeal     = Color(0xFF3DCFCF);
}

// ── Gradients ───────────────────────────────────────────────────────

abstract class AppGradients {
  // Kept as a gentle sage wash — no more heavy gold gradient
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF739E80),
      Color(0xFF8DB39A),
    ],
  );

  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.bg,
      AppColors.bg,
    ],
  );

  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1714),
      Color(0xFF201C17),
    ],
  );

  static const LinearGradient teal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF739E80),
      Color(0xFF8DB39A),
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

// ── Shadows — softer, editorial ─────────────────────────────────────

abstract class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF1F1C16).withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: const Color(0xFF1F1C16).withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: const Color(0xFF1F1C16).withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.20),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

// ── Typography ──────────────────────────────────────────────────────
//
// We use three families:
//   - Fraunces  → display headlines (with italic for callouts)
//   - Inter     → body, buttons, UI chrome
//   - JetBrains Mono → eyebrows, metadata, file Nº labels
//
// Declare these in pubspec.yaml (or via google_fonts package). Fallback
// to Manrope/system if not loaded.

const String fontDisplay = 'Fraunces';
const String fontSans    = 'Inter';
const String fontMono    = 'JetBrains Mono';
const String _fontFamily = fontSans;

TextStyle _display(double size, {FontWeight w = FontWeight.w400, bool italic = false, Color color = AppColors.ink, double letter = -0.8, double height = 1.05}) {
  return TextStyle(
    fontFamily: fontDisplay,
    fontSize: size,
    fontWeight: w,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    letterSpacing: letter,
    height: height,
  );
}

TextStyle _mono(double size, {Color color = AppColors.mist, double letter = 2, FontWeight w = FontWeight.w500}) {
  return TextStyle(
    fontFamily: fontMono,
    fontSize: size,
    fontWeight: w,
    color: color,
    letterSpacing: letter,
  );
}

abstract class AppText {
  // Display — Fraunces
  static TextStyle get display1 => _display(44, letter: -1.4, height: 1.0);
  static TextStyle get display2 => _display(36, letter: -1.2);
  static TextStyle get display3 => _display(28, letter: -0.8, height: 1.1);
  static TextStyle get display4 => _display(22, w: FontWeight.w500, letter: -0.4, height: 1.15);
  static TextStyle get displayItalic => _display(36, italic: true, letter: -1.2);

  // Body — Inter
  static const TextStyle bodyLg = TextStyle(fontFamily: fontSans, fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.ink, height: 1.5);
  static const TextStyle body   = TextStyle(fontFamily: fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink, height: 1.5);
  static const TextStyle bodySm = TextStyle(fontFamily: fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.graphite, height: 1.5);
  static const TextStyle lede   = TextStyle(fontFamily: fontSans, fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.graphite, height: 1.55);
  static const TextStyle caption = TextStyle(fontFamily: fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.graphite, height: 1.45);

  // UI labels — Inter
  static const TextStyle label  = TextStyle(fontFamily: fontSans, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.1);
  static const TextStyle labelSm = TextStyle(fontFamily: fontSans, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink);

  // Eyebrow — tiny caps metadata (mono)
  static TextStyle get eyebrow   => _mono(10, letter: 2, color: AppColors.mist);
  static TextStyle get monoMeta  => _mono(11, letter: 1, color: AppColors.mist);
  static TextStyle get monoValue => _mono(12, letter: 0.5, color: AppColors.ink, w: FontWeight.w600);
}

TextTheme _studioTextTheme(Color color) {
  return TextTheme(
    headlineLarge: _display(36, color: color, letter: -1.2),
    headlineMedium: _display(28, color: color, letter: -0.8, height: 1.1),
    headlineSmall: _display(22, w: FontWeight.w500, color: color, letter: -0.4, height: 1.15),
    titleLarge: TextStyle(fontFamily: fontSans, fontSize: 17, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.2, height: 1.35),
    titleMedium: TextStyle(fontFamily: fontSans, fontSize: 15, fontWeight: FontWeight.w600, color: color, height: 1.4),
    titleSmall: TextStyle(fontFamily: fontSans, fontSize: 13, fontWeight: FontWeight.w600, color: color, height: 1.4),
    bodyLarge: TextStyle(fontFamily: fontSans, fontSize: 15, fontWeight: FontWeight.w400, color: color, height: 1.55),
    bodyMedium: TextStyle(fontFamily: fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5),
    bodySmall: TextStyle(fontFamily: fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.5),
    labelLarge: TextStyle(fontFamily: fontSans, fontSize: 14, fontWeight: FontWeight.w600, color: color, letterSpacing: 0),
    labelMedium: TextStyle(fontFamily: fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: color, letterSpacing: 1.5),
    labelSmall: TextStyle(fontFamily: fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: color, letterSpacing: 2),
  );
}

// ── Theme builders ──────────────────────────────────────────────────

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    surface: AppColors.bg,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.graphite,
    outline: AppColors.border,
    outlineVariant: AppColors.hairline,
  );

  final textTheme = _studioTextTheme(AppColors.ink);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: textTheme,

    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: fontSans,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -0.2,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
    ),

    // Cards — Studio: canvas surface, hairline border, soft shadow
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.hairline),
      ),
      color: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),

    // Primary (filled) button — ink on canvas, rounded pill-ish
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.canvas,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.canvas,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.canvas,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: const BorderSide(color: AppColors.border, width: 1),
        textStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentInk,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Inputs — underline-less, hairline border on canvas
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.canvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
      hintStyle: const TextStyle(
        fontFamily: fontSans,
        color: AppColors.mist,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: const BorderSide(color: AppColors.hairline),
      ),
      side: const BorderSide(color: AppColors.hairline),
      backgroundColor: AppColors.canvas,
      labelStyle: const TextStyle(
        fontFamily: fontSans,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: fontSans,
        color: AppColors.canvas,
        fontSize: 14,
      ),
    ),

    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColors.ink,
      labelColor: AppColors.ink,
      unselectedLabelColor: AppColors.mist,
      labelStyle: const TextStyle(fontFamily: fontSans, fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontFamily: fontSans, fontSize: 13, fontWeight: FontWeight.w500),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.canvas,
      indicatorColor: AppColors.accentSoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: fontMono, fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.5),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.darkAmber,
    brightness: Brightness.dark,
    primary: AppColors.darkAmber,
    onPrimary: AppColors.darkBase,
    surface: AppColors.darkBase,
    onSurface: AppColors.darkOnSurface,
    onSurfaceVariant: AppColors.darkMuted,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorder,
  );

  final textTheme = _studioTextTheme(AppColors.darkOnSurface);

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
      titleTextStyle: const TextStyle(
        fontFamily: fontSans,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnSurface,
        letterSpacing: -0.2,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkOnSurface, size: 22),
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
        backgroundColor: AppColors.darkAmber,
        foregroundColor: AppColors.darkBase,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkAmber,
        foregroundColor: AppColors.darkBase,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkAmber,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: AppColors.darkAmber, width: 1.5),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      backgroundColor: AppColors.darkElevated,
    ),

    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppColors.darkAmber,
      labelColor: AppColors.darkAmber,
      unselectedLabelColor: AppColors.darkMuted,
      labelStyle: const TextStyle(fontFamily: fontSans, fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontFamily: fontSans, fontSize: 13, fontWeight: FontWeight.w500),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
    ),
  );
}

// ── Helper — keep legacy `_fontFamily` reference alive for any
//    straggler code still importing it.
// ignore: unused_element
const String legacyFontFamily = _fontFamily;
