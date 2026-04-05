import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A utility class containing predefined Roboto text styles
/// for consistent typography throughout the app.
class AppTextStyles {
  // Headings
  static TextStyle get heading1 => GoogleFonts.roboto(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );

  static TextStyle get heading2 => GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );

  static TextStyle get heading3 => GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      );

  // Body text
  static TextStyle get bodyLarge => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.black87,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.black54,
        height: 1.3,
      );

  // Button text
  static TextStyle get buttonText => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );

  static TextStyle get buttonTextSmall => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );

  // Caption and labels
  static TextStyle get caption => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.grey[600],
      );

  static TextStyle get label => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      );

  // Special styles
  static TextStyle get subtitle => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.black54,
        height: 1.3,
      );

  // Error text
  static TextStyle get error => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.red[600],
      );

  // Success text
  static TextStyle get success => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Colors.green[600],
      );

  // Utility methods for custom colors
  static TextStyle heading1WithColor(Color color) => heading1.copyWith(color: color);
  static TextStyle heading2WithColor(Color color) => heading2.copyWith(color: color);
  static TextStyle heading3WithColor(Color color) => heading3.copyWith(color: color);
  static TextStyle bodyLargeWithColor(Color color) => bodyLarge.copyWith(color: color);
  static TextStyle bodyMediumWithColor(Color color) => bodyMedium.copyWith(color: color);
  static TextStyle bodySmallWithColor(Color color) => bodySmall.copyWith(color: color);
}

/// Extension methods to easily apply Roboto fonts to existing TextStyle
extension RobotoTextStyleExtension on TextStyle {
  TextStyle get roboto => GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        shadows: shadows,
      );
}