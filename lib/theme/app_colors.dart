import 'package:flutter/material.dart';

/// Colours taken from the Android app's res/values/colors.xml and layouts, so both apps look the same.
class AppColors {
  AppColors._();

  // Login / primary
  static const Color accent = Color(0xFF2563EB); // login_accent
  static const Color textPrimary = Color(0xFF111827); // login_text_primary
  static const Color textSecondary = Color(0xFF4B5563); // login_text_secondary
  static const Color snackbar = Color(0xFF3B82F6); // login_snackbar_bg
  static const Color brandBlue = Color(0xFF4169E1); // carrot_orange (logo blue)

  // Slate palette used on the dashboard
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color tabBlue = Color(0xFF1D4ED8);
  static const Color chipBlue = Color(0xFF0066FF);
  static const Color aliceBlue = Color(0xFFF0F8FF);
  static const Color dividerGrey = Color(0xFFF0F0F0);
  static const Color badgeRed = Color(0xFFE31E24); // budget_red

  // Bottom navigation (nav_item_color_selector)
  static const Color navSelected = Color(0xFF1A1A1A);
  static const Color navUnselected = Color(0xFF8C8C8C);

  // Account / More tab
  static const Color accountBg = Color(0xFFFBFCFF);
  static const Color accountSubtitle = Color(0xFF6B7280);
  static const Color logoutBg = Color(0xFFFEF2F2);
  static const Color logoutText = Color(0xFFDC2626);
}

/// Web URLs used by the Android app (rest/Constants.kt).
class AppUrls {
  AppUrls._();
  static const String privacy = 'https://cars.garagge.in/privacy-policy';
  static const String terms = 'https://cars.garagge.in/terms-and-conditions';
  static const String newsWebBase = 'https://www.garragge.com';
}
