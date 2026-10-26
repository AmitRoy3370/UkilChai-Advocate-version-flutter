// color_chooser.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorChooser {
  static final Random _random = Random();

  static const String _lastBgKey = 'last_background_key';

  // ========== PROFESSIONAL COLORS (Advocate / Legal Theme) ==========
  static const Color primaryPurple = Color(0xFF6B4EFF);
  static const Color primaryNavy = Color(0xFF1E2A5E);
  static const Color primaryDeepPurple = Color(0xFF4C1D95);
  static const Color secondaryTeal = Color(0xFF14B8A6);
  static const Color legalNavy = Color(0xFF0F172A);
  static const Color legalGold = Color(0xFFD4AF37);

  // Solid Backgrounds
  static final List<Color> _solidBgs = [
    Color(0xFFFFFFFF),     // White
    Color(0xFFF8FAFC),     // Light Blueish
    Color(0xFFF9F5EB),     // Warm Cream
    Color(0xFFF1F5F9),     // Light Slate
    legalNavy,
    primaryNavy,
    Color(0xFF1E2937),     // Slate Dark
  ];

  // Gradient Backgrounds
  static final List<List<Color>> _gradientBgs = [
    [Color(0xFF6B4EFF), Color(0xFF4A3AFF)],
    [Color(0xFF1E2A5E), Color(0xFF334155)],
    [Color(0xFF0F172A), Color(0xFF1E40AF)],
    [Color(0xFF14B8A6), Color(0xFF0F766E)],
    [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    [Color(0xFFD4AF37), Color(0xFFCA8A04)],
    [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    [Color(0xFF334155), Color(0xFF475569)],
  ];

  // ==================== MAIN METHOD YOU REQUESTED ====================

  /// Returns both Screen Background and Suitable Text Color at the same time
  /// Prevents same background repeating consecutively
  static Future<ScreenColorPair> getScreenColorPair() async {
    final lastKey = await _getLastBackgroundKey();
    final bool useGradient = _random.nextBool(); // 50% gradient

    dynamic background;
    Color textColor;

    int attempts = 0;
    do {
      if (useGradient) {
        background = _gradientBgs[_random.nextInt(_gradientBgs.length)];
      } else {
        background = _solidBgs[_random.nextInt(_solidBgs.length)];
      }
      attempts++;
    } while (_isSameAsLast(lastKey, background) && attempts < 10);

    // Save current background
    await _saveLastBackgroundKey(background);

    // Get best text color for contrast
    textColor = _getBestTextColor(background);

    return ScreenColorPair(
      background: background,
      textColor: textColor,
      isGradient: useGradient,
    );
  }

  // ==================== HELPER METHODS ====================

  static bool _isSameAsLast(String? lastKey, dynamic current) {
    if (lastKey == null) return false;
    if (current is Color) {
      return lastKey == current.value.toString();
    } else if (current is List<Color>) {
      return lastKey == current.map((c) => c.value).join(',');
    }
    return false;
  }

  static Future<String?> _getLastBackgroundKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastBgKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveLastBackgroundKey(dynamic bg) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String key = bg is Color
          ? bg.value.toString()
          : (bg is List<Color> ? bg.map((c) => c.value).join(',') : '');
      await prefs.setString(_lastBgKey, key);
    } catch (_) {}
  }

  static Color _getBestTextColor(dynamic bg) {
    double luminance = 0.5;

    if (bg is Color) {
      luminance = bg.computeLuminance();
    } else if (bg is List<Color> && bg.isNotEmpty) {
      luminance = bg.map((c) => c.computeLuminance()).reduce((a, b) => a + b) / bg.length;
    }

    return luminance > 0.55
        ? const Color(0xFF111827)     // Dark text
        : const Color(0xFFF3F4F6);    // Light text
  }

  // Extra helpers
  static Color getRandomPrimaryColor() {
    final colors = [primaryPurple, primaryNavy, primaryDeepPurple, secondaryTeal, legalGold];
    return colors[_random.nextInt(colors.length)];
  }
}

// ====================== MODEL CLASS ======================
class ScreenColorPair {
  final dynamic background;     // Color or List<Color>
  final Color textColor;
  final bool isGradient;

  ScreenColorPair({
    required this.background,
    required this.textColor,
    this.isGradient = false,
  });

  /// Ready to use BoxDecoration
  BoxDecoration get boxDecoration {
    if (isGradient && background is List<Color>) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: background as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else {
      return BoxDecoration(
        color: background as Color,
      );
    }
  }
}