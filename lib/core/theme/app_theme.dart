import 'package:flutter/material.dart';

/// Paleta y estilos de componentes compartidos por toda la app. Un solo
/// lugar para el "look" de PetTracker en vez de temas inline por pantalla.
///
/// A diferencia de la versión anterior (`ColorScheme.fromSeed`, tonal
/// automático), esta paleta está armada a mano — colores cálidos/terracota
/// más profundos que el seed genérico, pensados junto con la tipografía
/// Baloo2/Nunito para que la app se sienta "hecha a mano" en vez de
/// Material por defecto. Ver el concepto de diseño para el criterio de
/// cada color (oklch original → hex acá abajo).
abstract final class AppTheme {
  /// Terracota — el primario de la app, también usado fuera de ThemeData
  /// (p. ej. los markers de cluster en el mapa).
  static const seed = Color(0xFFC65029);

  static const _lightInk = Color(0xFF291C15);
  static const _lightInkSoft = Color(0xFF5C4840);
  static const _lightPaper = Color(0xFFFAF2EA);
  static const _lightPaperCard = Color(0xFFFFFBF7);
  static const _lightPrimary = Color(0xFFC65029);
  static const _lightPrimaryDeep = Color(0xFF9A2B19);
  static const _lightPrimaryTint = Color(0xFFFDE1D5);
  static const _lightLine = Color(0xFFE3D4CB);

  static const _darkInk = Color(0xFFF4E9E1);
  static const _darkInkSoft = Color(0xFFB5A89F);
  static const _darkBg = Color(0xFF1C100C);
  static const _darkSurface = Color(0xFF291B17);
  static const _darkSurfaceHi = Color(0xFF392A24);
  static const _darkPrimary = Color(0xFFE4744B);
  static const _darkPrimaryTint = Color(0xFF472215);
  static const _darkLine = Color(0xFF41352F);

  /// Estados de reporte (lost/stray/found) — versión cálida, más profunda
  /// que el rojo/naranja/verde estándar de Material. Vive acá (no en
  /// status_style.dart) para que ambos temas y esa extension compartan una
  /// sola fuente de verdad.
  static const statusLost = Color(0xFFBD3936);
  static const statusStray = Color(0xFFCF6F19);
  static const statusFound = Color(0xFF397949);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            brightness: Brightness.dark,
            primary: _darkPrimary,
            onPrimary: _darkBg,
            primaryContainer: _darkPrimaryTint,
            onPrimaryContainer: _darkPrimary,
            secondary: _darkPrimary,
            onSecondary: _darkBg,
            surface: _darkBg,
            onSurface: _darkInk,
            surfaceContainerLowest: _darkBg,
            surfaceContainerLow: _darkSurface,
            surfaceContainer: _darkSurface,
            surfaceContainerHigh: _darkSurfaceHi,
            surfaceContainerHighest: _darkSurfaceHi,
            onSurfaceVariant: _darkInkSoft,
            outline: _darkLine,
            outlineVariant: _darkLine,
            error: Color(0xFFE0776F),
            onError: _darkBg,
          )
        : const ColorScheme.light(
            brightness: Brightness.light,
            primary: _lightPrimary,
            onPrimary: Colors.white,
            primaryContainer: _lightPrimaryTint,
            onPrimaryContainer: _lightPrimaryDeep,
            secondary: _lightPrimaryDeep,
            onSecondary: Colors.white,
            surface: _lightPaper,
            onSurface: _lightInk,
            surfaceContainerLowest: _lightPaper,
            surfaceContainerLow: _lightPaperCard,
            surfaceContainer: _lightPaperCard,
            surfaceContainerHigh: Color(0xFFF3E7DD),
            surfaceContainerHighest: Color(0xFFF3E7DD),
            onSurfaceVariant: _lightInkSoft,
            outline: _lightLine,
            outlineVariant: _lightLine,
            error: statusLost,
            onError: Colors.white,
          );

    final textTheme = _textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      fontFamily: 'Nunito',
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontFamily: 'Baloo2',
          color: colorScheme.onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimaryContainer,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.6 : 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: colorScheme.primary, width: 1.75),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, space: 32),
    );
  }

  /// Baloo2 (redondeada, con carácter) para títulos; Nunito para el resto —
  /// mismo criterio que el concepto de diseño.
  static TextTheme _textTheme(ColorScheme colorScheme) {
    const display = 'Baloo2';
    const body = 'Nunito';

    TextStyle base(String family, double size, FontWeight weight, {double? letterSpacing, Color? color}) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color ?? colorScheme.onSurface,
      );
    }

    return TextTheme(
      displayLarge: base(display, 40, FontWeight.w800, letterSpacing: -0.5),
      displayMedium: base(display, 32, FontWeight.w800, letterSpacing: -0.4),
      displaySmall: base(display, 28, FontWeight.w700, letterSpacing: -0.3),
      headlineLarge: base(display, 26, FontWeight.w700, letterSpacing: -0.3),
      headlineMedium: base(display, 23, FontWeight.w700, letterSpacing: -0.2),
      headlineSmall: base(display, 21, FontWeight.w700, letterSpacing: -0.2),
      titleLarge: base(display, 19, FontWeight.w700),
      titleMedium: base(display, 16, FontWeight.w600),
      titleSmall: base(display, 14.5, FontWeight.w600),
      bodyLarge: base(body, 16, FontWeight.w400),
      bodyMedium: base(body, 14, FontWeight.w400),
      bodySmall: base(body, 12.5, FontWeight.w400, color: colorScheme.onSurfaceVariant),
      labelLarge: base(body, 14, FontWeight.w800),
      labelMedium: base(body, 12, FontWeight.w700),
      labelSmall: base(body, 11, FontWeight.w700, color: colorScheme.onSurfaceVariant),
    );
  }
}
