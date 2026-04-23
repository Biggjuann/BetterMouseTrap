import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pre-warm Quicksand + Nunito font cache.
Future<void> initFonts() async {
  GoogleFonts.config.allowRuntimeFetching = true;
  await Future.wait<void>([
    GoogleFonts.pendingFonts([
      GoogleFonts.quicksand(fontWeight: FontWeight.w700),
      GoogleFonts.quicksand(fontWeight: FontWeight.w600),
      GoogleFonts.nunito(fontWeight: FontWeight.w400),
      GoogleFonts.nunito(fontWeight: FontWeight.w500),
      GoogleFonts.nunito(fontWeight: FontWeight.w700),
    ]),
  ]);
}

// ── Whiskers Color Palette ───────────────────────────────────────────

abstract class AppColors {
  // Surfaces
  static const Color bg          = Color(0xFFFAF5EB); // cream
  static const Color card        = Color(0xFFFFFFFF);
  static const Color hairline    = Color(0xFFEDE4FF); // lavender-tint divider

  // Ink
  static const Color ink         = Color(0xFF2B2140); // deep plum
  static const Color inkSoft     = Color(0xFF7A6E95); // muted

  // Primary (lavender)
  static const Color lav         = Color(0xFF8B5CF6);
  static const Color lavLight    = Color(0xFFEDE4FF);
  static const Color lavDark     = Color(0xFF6D4AC9);

  // Accents
  static const Color peach       = Color(0xFFFFD5BE);
  static const Color peachBg     = Color(0xFFFFE8D6);
  static const Color mint        = Color(0xFFB8E6C6);
  static const Color mintBg      = Color(0xFFE6F7EC);
  static const Color sun         = Color(0xFFFFD66B);
  static const Color sunBg       = Color(0xFFFFF4DC);
  static const Color pink        = Color(0xFFFFC2CF);
  static const Color pinkBg      = Color(0xFFFFE4E9);

  // Semantic
  static const Color success     = Color(0xFF2F8F52);
  static const Color warn        = Color(0xFFC77A00);
  static const Color danger      = Color(0xFFC04A4A);

  // ── Legacy aliases (keep old screens compiling) ──────────────────
  static const Color canvas      = card;
  static const Color surface     = card;
  static const Color cardWhite   = card;
  static const Color cream       = bg;
  static const Color graphite    = inkSoft;
  static const Color stone       = inkSoft;
  static const Color mist        = inkSoft;
  static const Color slateLight  = inkSoft;
  static const Color charcoal    = ink;
  static const Color rule        = hairline;
  static const Color border      = hairline;
  static const Color borderLight = hairline;
  static const Color borderPrimary5 = hairline;
  static const Color primary     = lav;
  static const Color accent      = lav;
  static const Color accentSoft  = lavLight;
  static const Color accentInk   = lavDark;
  static const Color amber       = lav;
  static const Color warm        = peach;
  static const Color warmSoft    = peachBg;
  static const Color coral       = peach;
  static const Color sunSoft     = sunBg;
  static const Color teal        = mint;
  static const Color error       = danger;
  static const Color warning     = warn;
  static const Color top         = lav;
  static const Color moonshot    = Color(0xFF9B72CF);
  static const Color upgrade     = Color(0xFF6BA3C9);
  static const Color adjacent    = Color(0xFFC9A45A);
  static const Color recurring   = Color(0xFFB88A7A);
  static const Color emeraldBg   = mintBg;
  static const Color emeraldText = success;
  static const Color blueBg      = lavLight;
  static const Color blueText    = lavDark;
  static const Color purpleBg    = lavLight;
  static const Color purpleText  = lavDark;
  // Dark mode stubs (app is light-only but keep so theme builder compiles)
  static const Color darkBase      = Color(0xFF1A1714);
  static const Color darkSurface   = Color(0xFF24201B);
  static const Color darkElevated  = Color(0xFF2E2923);
  static const Color darkOnSurface = Color(0xFFFAF5EB);
  static const Color darkMuted     = Color(0xFF7A6E95);
  static const Color darkBorder    = Color(0xFF3A342C);
  static const Color darkAmber     = Color(0xFF9FC0A8);
  static const Color darkTeal      = Color(0xFF3DCFCF);
}

// ── Spacing ──────────────────────────────────────────────────────────

abstract class AppSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double xxl  = 32;
  // Legacy alias: old `base` = 16 (same as new `lg`)
  static const double base = lg;
  // Legacy: old lg=20, xl=28, xxl=40
  static const double xxxl = 48;
}

// ── Radius ───────────────────────────────────────────────────────────

abstract class AppRadius {
  static const double xs   = 4;
  static const double sm   = 10;
  static const double md   = 16;
  static const double lg   = 22;
  static const double xl   = 28;
  static const double pill = 999;
}

// ── Duration ─────────────────────────────────────────────────────────

abstract class AppDuration {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast    = Duration(milliseconds: 180);
  static const Duration normal  = Duration(milliseconds: 320);
  static const Duration slow    = Duration(milliseconds: 500);
  static const Duration calm    = Duration(milliseconds: 700);
}

// ── Shadows ──────────────────────────────────────────────────────────

abstract class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F8B5CF6), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x598B5CF6), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  // Legacy getters
  static List<BoxShadow> get elevated => soft;
}

// ── Gradients ────────────────────────────────────────────────────────

abstract class AppGradients {
  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFFC4B5FD), AppColors.lav],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bg, AppColors.bg],
  );
  // Legacy stubs
  static const LinearGradient teal = hero;
  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1714), Color(0xFF201C17)],
  );
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x99000000)],
    stops: [0.4, 1.0],
  );
}

// ── Typography ───────────────────────────────────────────────────────
// Quicksand — display / headings (friendly, rounded)
// Nunito    — body / UI text (warm, very legible)

// Legacy font family constants (kept so inline TextStyle(fontFamily:...) still compiles)
const String fontDisplay = 'Quicksand';
const String fontSans    = 'Nunito';
const String fontMono    = 'Nunito';

abstract class AppText {
  // Display — Quicksand
  static TextStyle get display1 => GoogleFonts.quicksand(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.ink, height: 1.15);
  static TextStyle get display2 => GoogleFonts.quicksand(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.ink, height: 1.2);
  static TextStyle get display3 => GoogleFonts.quicksand(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.ink, height: 1.25);
  // Legacy alias: display4 was 22px serif in Studio
  static TextStyle get display4 => display2;

  // Section
  static TextStyle get sectionTitle => GoogleFonts.quicksand(
        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink);

  // Body — Nunito
  static TextStyle get bodyLg => GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.ink, height: 1.5);
  static TextStyle get body => GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: AppColors.ink, height: 1.5);
  static TextStyle get bodyBold => GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink);
  // Legacy aliases
  static TextStyle get bodySm  => body.copyWith(color: AppColors.inkSoft);
  static TextStyle get lede    => bodyLg.copyWith(color: AppColors.inkSoft);
  static TextStyle get label   => bodyBold.copyWith(fontSize: 14);
  static TextStyle get labelSm => bodyBold.copyWith(fontSize: 12);

  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkSoft);
  static TextStyle get tiny => GoogleFonts.nunito(
        fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkSoft);

  // Pill / badge
  static TextStyle get pill => GoogleFonts.nunito(
        fontSize: 11, fontWeight: FontWeight.w700);

  // Button
  static TextStyle get btnPrimary => GoogleFonts.quicksand(
        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white);
  static TextStyle get btnSoft => GoogleFonts.nunito(
        fontSize: 12, fontWeight: FontWeight.w700);

  // Legacy mono-style labels → map to Nunito caption
  static TextStyle get eyebrow  => GoogleFonts.nunito(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: AppColors.inkSoft, letterSpacing: 1.5);
  static TextStyle get monoMeta => eyebrow;
  static TextStyle get monoValue => GoogleFonts.nunito(
        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink);
}

// ── ThemeData ─────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.lav,
      onPrimary: Colors.white,
      secondary: AppColors.sun,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lav, width: 1.5),
      ),
      hintStyle: GoogleFonts.nunito(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lav,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lav,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.card,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill)),
        side: const BorderSide(color: AppColors.hairline, width: 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lavDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lavLight,
      labelStyle: GoogleFonts.nunito(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lavDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide.none,
      ),
      side: BorderSide.none,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
    ),
  );
}

/// Used by main.dart
ThemeData buildLightTheme() => buildAppTheme();

/// Dark theme — minimal, app is effectively light-only for iOS
ThemeData buildDarkTheme() {
  final t = buildAppTheme();
  return t.copyWith(
    scaffoldBackgroundColor: AppColors.darkBase,
    colorScheme: t.colorScheme.copyWith(
      surface: AppColors.darkBase,
      onSurface: AppColors.darkOnSurface,
    ),
  );
}
