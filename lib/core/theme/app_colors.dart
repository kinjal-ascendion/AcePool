import 'package:flutter/material.dart';

/// Single source of truth for every color used in the app. Swap a value
/// here to re-theme every screen that references it.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF1B8A3F);
  static const Color accentBlue = Color(0xFF2D6CDF);
  static const Color scheduleButtonColor = Color(0xFF111317);
  static const Color toggleActiveBlack = Color(0xFF1D1D1D);
  static const Color bottomNavActive = Color(0xFF2E8B57);

  // ── Backgrounds ────────────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFFF9FAFA);
  static const Color toggleBackground = Color(0xFFFEFEFE);
  static const Color darkBg = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color chatBubbleMe = Color(0xFFE8F5E9);

  // ── Misc custom ────────────────────────────────────────────────────
  static const Color placeholderGrey = Color(0xFFAAAAAA);

  // ── Base ───────────────────────────────────────────────────────────
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color transparent = Colors.transparent;

  // ── Black alpha scale (text/dividers) ─────────────────────────────
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color black45 = Colors.black45;
  static const Color black38 = Colors.black38;
  static const Color black26 = Colors.black26;
  static const Color black12 = Colors.black12;

  // ── Grey scale ─────────────────────────────────────────────────────
  static const Color grey = Colors.grey;
  static final Color grey50 = Colors.grey.shade50;
  static final Color grey100 = Colors.grey.shade100;
  static final Color grey200 = Colors.grey.shade200;
  static final Color grey300 = Colors.grey.shade300;
  static final Color grey400 = Colors.grey.shade400;
  static final Color grey500 = Colors.grey.shade500;
  static final Color grey600 = Colors.grey.shade600;
  static final Color grey700 = Colors.grey.shade700;
  static final Color grey800 = Colors.grey.shade800;

  // ── Red scale (errors/destructive) ─────────────────────────────────
  static const Color red = Colors.red;
  static const Color redAccent = Colors.redAccent;
  static final Color red50 = Colors.red.shade50;
  static final Color red300 = Colors.red.shade300;
  static final Color red400 = Colors.red.shade400;
  static final Color red600 = Colors.red.shade600;

  // ── Green scale (Material, distinct from brand primaryGreen) ──────
  static const Color green = Colors.green;
  static final Color green50 = Colors.green.shade50;
  static final Color green700 = Colors.green.shade700;

  // ── Blue scale ──────────────────────────────────────────────────────
  static const Color blue = Colors.blue;
  static const Color lightBlue = Colors.lightBlue;
  static final Color blue50 = Colors.blue.shade50;
  static final Color blue100 = Colors.blue.shade100;

  // ── Orange / purple (one-off accents) ──────────────────────────────
  static const Color orange = Colors.orange;
  static final Color orange400 = Colors.orange.shade400;
  static const Color purple = Colors.purple;
}
