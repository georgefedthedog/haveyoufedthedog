import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide colour tokens. Pulled from the personality-redesign mockups.
///
/// Use these via the active `ColorScheme` (e.g. `scheme.primary`) wherever
/// possible. Constants here exist for cases the M3 scheme can't express
/// (the streak warm-orange accent, the "all done" mint pair).
class AppColors {
  AppColors._();

  // Light palette
  static const cream = Color(0xFFFAF3E8); // surface
  static const card = Color(0xFFFFFFFF); // surfaceContainer
  static const cardSubtle = Color(0xFFFFF7EC); // surfaceContainerHigh
  static const violet = Color(0xFF6B4FE0); // primary
  static const violetSoft = Color(0xFFE8E4FF); // primaryContainer
  static const onViolet = Color(0xFFFFFFFF);
  static const onVioletSoft = Color(0xFF3A2A8C);
  static const mint = Color(0xFF4FBF85); // tertiary / "done"
  static const mintSoft = Color(0xFFDCF4E5);
  static const onMintSoft = Color(0xFF1F5A3A);
  static const ink = Color(0xFF2A2530); // onSurface
  static const inkSoft = Color(0xFF6A6373); // onSurfaceVariant
  static const outline = Color(0xFFE0D8CB); // soft warm outline

  // Personality accents (used where the M3 scheme isn't expressive enough).
  static const streakOrange = Color(0xFFF0884A);
  static const streakOrangeSoft = Color(0xFFFFE5D2);

  // Pastel "stage" backgrounds for character heros — pick by character id.
  // Soft enough to keep contrast on the violet primary.
  static const stageMint = Color(0xFFD8F0E2);
  static const stageLavender = Color(0xFFE6E2F5);
  static const stagePeach = Color(0xFFFCE3D2);
  static const stageSky = Color(0xFFD9EBF4);
  static const stageCream = Color(0xFFFBEFD8);
}

ThemeData get lightTheme => _build(_lightScheme, Brightness.light);
ThemeData get darkTheme => _build(_darkScheme, Brightness.dark);

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.violet,
  onPrimary: AppColors.onViolet,
  primaryContainer: AppColors.violetSoft,
  onPrimaryContainer: AppColors.onVioletSoft,
  secondary: AppColors.violet,
  onSecondary: AppColors.onViolet,
  secondaryContainer: AppColors.violetSoft,
  onSecondaryContainer: AppColors.onVioletSoft,
  tertiary: AppColors.mint,
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: AppColors.mintSoft,
  onTertiaryContainer: AppColors.onMintSoft,
  error: Color(0xFFD0533F),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFADCD4),
  onErrorContainer: Color(0xFF7A2516),
  surface: AppColors.cream,
  onSurface: AppColors.ink,
  surfaceContainerLowest: Color(0xFFFFFCF6),
  surfaceContainerLow: Color(0xFFFEF8EF),
  surfaceContainer: AppColors.card,
  surfaceContainerHigh: AppColors.cardSubtle,
  surfaceContainerHighest: Color(0xFFF4ECDF),
  onSurfaceVariant: AppColors.inkSoft,
  outline: AppColors.outline,
  outlineVariant: Color(0xFFEFE7DA),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2A2530),
  onInverseSurface: AppColors.cream,
  inversePrimary: Color(0xFFC9BCFF),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFC9BCFF),
  onPrimary: Color(0xFF2C1F66),
  primaryContainer: Color(0xFF453391),
  onPrimaryContainer: Color(0xFFE5DEFF),
  secondary: Color(0xFFC9BCFF),
  onSecondary: Color(0xFF2C1F66),
  secondaryContainer: Color(0xFF453391),
  onSecondaryContainer: Color(0xFFE5DEFF),
  tertiary: Color(0xFF7FD8A8),
  onTertiary: Color(0xFF0E3A21),
  tertiaryContainer: Color(0xFF1E5538),
  onTertiaryContainer: Color(0xFFCDF1D9),
  error: Color(0xFFFFB4A6),
  onError: Color(0xFF690000),
  errorContainer: Color(0xFF8C1D0D),
  onErrorContainer: Color(0xFFFFDAD3),
  surface: Color(0xFF1A1620),
  onSurface: Color(0xFFEDE6DA),
  surfaceContainerLowest: Color(0xFF14111A),
  surfaceContainerLow: Color(0xFF1F1B27),
  surfaceContainer: Color(0xFF24202C),
  surfaceContainerHigh: Color(0xFF2F2A39),
  surfaceContainerHighest: Color(0xFF3A3445),
  onSurfaceVariant: Color(0xFFB5ADB9),
  outline: Color(0xFF4F4856),
  outlineVariant: Color(0xFF35303A),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFEDE6DA),
  onInverseSurface: Color(0xFF1A1620),
  inversePrimary: AppColors.violet,
);

ThemeData _build(ColorScheme scheme, Brightness brightness) {
  final defaults = ThemeData(brightness: brightness).textTheme;
  final body = GoogleFonts.plusJakartaSansTextTheme(defaults);
  // Two-font system: a display face carries the big moments — household
  // name, "All done!", screen titles — while Plus Jakarta Sans stays the
  // workhorse for body/label/title text.
  final display = GoogleFonts.knewaveTextTheme(defaults);
  // Only the headline tier gets the display face. The display* slots stay
  // on the body font — Material components use them for big *numerals*
  // (the time picker's hour/minute digits), where brush lettering reads
  // badly.
  final textTheme = body
      .copyWith(
        headlineLarge: display.headlineLarge,
        headlineMedium: display.headlineMedium,
        headlineSmall: display.headlineSmall,
      )
      .apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // Transparent so every page shows the AppBackdrop gradient installed
    // in MaterialApp.builder.
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      // Matches headlineMedium (the household name on home) so every
      // screen title reads at the same display size.
      titleTextStyle: GoogleFonts.knewave(
        color: scheme.onSurface,
        fontSize: 28,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: scheme.outline),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: const StadiumBorder(),
      extendedTextStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: GoogleFonts.plusJakartaSans(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 24,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
