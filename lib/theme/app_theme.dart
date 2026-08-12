import 'package:flutter/material.dart';

class AppTheme {

  // *************** MODO CLARO ÍNDIGO ***************

  static const Color indigo = Color(0xFF4338CA);
  static const Color indigoClaro = Color(0xFFE7E5FB);

  static const Color fondoClaro = Color(0xFFF5F6FA);
  static const Color superficieClara = Color(0xFFFFFFFF);

  static const Color textoClaro = Color(0xFF1E1B2E);
  static const Color textoSecundarioClaro = Color(0xFF6B7280);

  static const Color bordeClaro = Color(0xFFE2E4EA);

  static const Color exitoClaro = Color(0xFF059669);
  static const Color alertaClaro = Color(0xFFD97706);

  // *************** MODO OSCURO DORADO ***************

  static const Color fondoOscuro = Color(0xFF12141C);
  static const Color superficieOscura = Color(0xFF1B1E29);

  static const Color oro = Color(0xFFD4A62A);
  static const Color oroClaro = Color(0x29D4A62A);

  static const Color textoOscuro = Color(0xFFF2F1ED);
  static const Color textoSecundarioOscuro = Color(0xFF9A9AA6);

  static const Color bordeOscuro = Color(0x38D4A62A);

  static const Color exitoOscuro = Color(0xFF34D399);
  static const Color alertaOscuro = Color(0xFFF59E0B);

  // *************** MODO CLARO ***************

  static ThemeData get claro {
    final ColorScheme esquema =
        ColorScheme.fromSeed(
          seedColor: indigo,
          brightness: Brightness.light,
        ).copyWith(
          primary: indigo,
          onPrimary: Colors.white,
          primaryContainer: indigoClaro,
          onPrimaryContainer: textoClaro,

          secondary: indigo,
          onSecondary: Colors.white,

          tertiary: exitoClaro,
          onTertiary: Colors.white,

          surface: superficieClara,
          onSurface: textoClaro,
          surfaceContainer: superficieClara,
          surfaceContainerHighest: indigoClaro,
          onSurfaceVariant: textoSecundarioClaro,

          outline: bordeClaro,
          outlineVariant: bordeClaro,

          error: const Color(0xFFDC2626),
          onError: Colors.white,

          surfaceTint: Colors.transparent,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondoClaro,

      appBarTheme: const AppBarTheme(
        backgroundColor: indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: superficieClara,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficieClara,
        labelStyle: const TextStyle(color: textoSecundarioClaro),
        hintStyle: const TextStyle(color: textoSecundarioClaro),
        prefixIconColor: indigo,
        suffixIconColor: textoSecundarioClaro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: bordeClaro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: bordeClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: indigo, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: indigo,
        foregroundColor: Colors.white,
      ),

      dividerColor: bordeClaro,

      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: textoClaro,
        displayColor: textoClaro,
      ),
    );
  }

  // *************** MODO OSCURO ***************

  static ThemeData get oscuro {
    final ColorScheme esquema =
        ColorScheme.fromSeed(
          seedColor: oro,
          brightness: Brightness.dark,
        ).copyWith(
          primary: oro,
          onPrimary: fondoOscuro,
          primaryContainer: oroClaro,
          onPrimaryContainer: textoOscuro,

          secondary: oro,
          onSecondary: fondoOscuro,

          tertiary: exitoOscuro,
          onTertiary: fondoOscuro,

          surface: superficieOscura,
          onSurface: textoOscuro,
          surfaceContainer: superficieOscura,
          surfaceContainerHighest: const Color(0xFF242837),
          onSurfaceVariant: textoSecundarioOscuro,

          outline: bordeOscuro,
          outlineVariant: bordeOscuro,

          error: const Color(0xFFF87171),
          onError: fondoOscuro,

          surfaceTint: Colors.transparent,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondoOscuro,

      appBarTheme: const AppBarTheme(
        backgroundColor: superficieOscura,
        foregroundColor: textoOscuro,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textoOscuro,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: oro),
      ),

      cardTheme: CardThemeData(
        color: superficieOscura,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: bordeOscuro),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficieOscura,
        labelStyle: const TextStyle(color: textoSecundarioOscuro),
        hintStyle: const TextStyle(color: textoSecundarioOscuro),
        prefixIconColor: oro,
        suffixIconColor: textoSecundarioOscuro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bordeOscuro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bordeOscuro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oro, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: oro,
          foregroundColor: fondoOscuro,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: oro,
        foregroundColor: fondoOscuro,
      ),

      dividerColor: bordeOscuro,

      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: textoOscuro,
        displayColor: textoOscuro,
      ),
    );
  }

  // *************** COLORES SEMÁNTICOS ***************

  static Color exito(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? exitoOscuro
        : exitoClaro;
  }

  static Color alerta(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? alertaOscuro
        : alertaClaro;
  }
}
