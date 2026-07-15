import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fernecito_brand.dart';

/// Colores y tipografía Baloo2 alineados con Fernecito Locales.
class OwnerTheme {
  OwnerTheme._();

  static const violeta = Color(0xFF7829CE);
  static const violetaMarca = FernecitoBrand.violetaLogo;
  static const fondo = Color(0xFFF8F7FC);
  static const superficie = Colors.white;
  static const borde = Color(0xFFEDECF5);
  static const texto = Color(0xFF1C1B22);
  static const textoSecundario = Color(0xFF6B7280);

  static TextStyle baloo({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.baloo2(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? texto,
      height: height,
    );
  }

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: violetaMarca,
      brightness: Brightness.light,
      primary: violetaMarca,
      surface: superficie,
      surfaceContainer: fondo,
    );

    // Inter como fuente base (evita subrayado amarillo de Baloo en web en widgets M3).
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: texto,
      displayColor: texto,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: fondo,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baloo(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: texto,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borde),
        ),
        color: superficie,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: baloo(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: baloo(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: baloo(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficie,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textoSecundario),
        hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textoSecundario),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: violetaMarca, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: baloo(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
