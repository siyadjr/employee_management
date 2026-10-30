import 'package:flutter/material.dart';

/// Centralized color palette for the application.
/// Avoid using hardcoded Color(0x...) or direct Colors.* throughout widget files.
class AppColors {
  // Brand & Theme Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Slate Blue
  static const Color primaryDark = Color(0xFF1E293B);
  static const Color accent = Color(0xFF0284C7); // Vibrant Sky Blue
  static const Color surface = Color(0xFFF8FAFC);
  static const Color card = Colors.white;

  // Status & Feedback Colors
  static const Color success = Color(0xFF059669); // Forest Emerald
  static const Color successLight = Color(0xFFF0FDF4); // green.shade50
  static const Color successBorder = Color(0xFFBBF7D0); // green.shade200
  static const Color successText = Color(0xFF166534); // green.shade800
  static const Color successTextDark = Color(0xFF14532D); // green.shade900

  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningLight = Color(0xFFFFFBEB); // amber.shade50
  static const Color warningBorder = Color(0xFFFDE68A); // amber.shade200
  static const Color warningText = Color(0xFFB45309); // amber.shade700
  static const Color warningTextDark = Color(0xFF78350F); // amber.shade900

  static const Color error = Color(0xFFDC2626); // Crimson
  static const Color errorLight = Color(0xFFFEF2F2); // red.shade50
  static const Color errorBorder = Color(0xFFFECACA); // red.shade200
  static const Color errorText = Color(0xFF991B1B); // red.shade800
  static const Color errorTextDark = Color(0xFF7F1D1D); // red.shade900

  static const Color info = Color(0xFF2563EB); // Blue
  static const Color infoLight = Color(0xFFEFF6FF); // blue.shade50
  static const Color infoText = Color(0xFF1D4ED8); // blue.shade700

  // Category / Accents
  static const Color indigo = Colors.indigo;
  static const Color deepPurple = Colors.deepPurple;
  static const Color teal = Colors.teal;
  static const Color orange = Colors.orange;
  static const Color amber = Colors.amber;

  // Neutrals
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569); // grey.shade600
  static const Color textMuted = Color(0xFF64748B); // grey.shade500
  static const Color borderLight = Color(0xFFE2E8F0); // grey.shade300
  static const Color divider = Color(0xFFE2E8F0);
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
}
