import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const obsidian = Color(0xFF080A0D);
  static const charcoal = Color(0xFF11151A);
  static const graphite = Color(0xFF171D23);
  static const panel = Color(0xFF1C242B);
  static const line = Color(0xFF2B373E);
  static const emerald = Color(0xFF71F5B1);
  static const emeraldDeep = Color(0xFF1BAA72);
  static const cyan = Color(0xFF7BE9FF);
  static const ivory = Color(0xFFF3F7F4);
  static const mist = Color(0xFFA5B1B4);
  static const muted = Color(0xFF66757A);
  static const danger = Color(0xFFFF6B78);
  static const amber = Color(0xFFFFCA72);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final text = GoogleFonts.tajawalTextTheme(base.textTheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.obsidian,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.charcoal,
      primary: AppColors.emerald,
      secondary: AppColors.cyan,
      error: AppColors.danger,
    ),
    textTheme: text.apply(bodyColor: AppColors.ivory, displayColor: AppColors.ivory),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    cardTheme: CardThemeData(
      color: AppColors.panel.withOpacity(.72),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.graphite,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    ),
  );
}
