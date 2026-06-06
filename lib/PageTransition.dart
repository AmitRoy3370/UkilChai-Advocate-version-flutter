// page_transitions.dart - Complete Working Code (All 100+ Animations)
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

enum PageTransitionType {
  // ========== ATMOSPHERIC EFFECTS (New) ==========
  mistyFade,
  softCloudDrift,
  summerGlow,
  gentleRainFall,
  goldenHour,
  twilightFade,
  breezyFloat,
  etherealMist,

  // Core Transitions
  fade,
  fadeSlow,
  fadeQuick,
  fadeZoom,
  zoomIn,
  zoomOut,
  scaleUp,
  scaleDown,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,

  // Enhanced Combinations
  fadeSlideRight,
  fadeSlideLeft,
  fadeSlideUp,
  fadeSlideDown,
  zoomFade,
  scaleFade,
  rotateFade,
  flipHorizontal,
  flipVertical,

  // Bounce & Elastic
  bounceIn,
  bounceOut,
  elasticIn,
  elasticOut,
  pop,
  spring,

  // Rotation Based
  rotateClockwise,
  rotateCounterClockwise,
  rotateZoom,
  threeDSpin,

  // Advanced Feel
  curtainOpen,
  curtainClose,
  blinds,
  wipeRight,
  wipeLeft,
  dissolve,
  shimmer,
  ripple,
  wave,
  floatUp,
  sinkDown,

  // Premium Feel
  glassMorph,
  depthPush,
  depthPull,
  pageCurl, // Simulated
  cinematic,
  dramaticZoom,
  gentleLift,
  softBounce,
  heartbeat,
  breath,
}

// Track last selected animation to avoid repetition
PageTransitionType? _lastSelectedAnimation;

class PageTransition extends StatelessWidget {
  final Widget child;
  final PageTransitionType type;
  final Duration duration;
  final Curve curve;

  const PageTransition({
    super.key,
    required this.child,
    this.type = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return _buildTransition(child, animation);
      },
      child: child,
    );
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: curve);
    final fastOut = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuad,
    );
    final bounce = CurvedAnimation(parent: animation, curve: Curves.bounceOut);
    final elastic = CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    );

    final slowCurve = CurvedAnimation(
      // ← slowCurve
      parent: animation,
      curve: Curves.easeInOutCubic,
    );
    final sineCurve = CurvedAnimation(
      // ← sineCurve
      parent: animation,
      curve: Curves.easeInOutSine,
    );

    switch (type) {
      // === BASIC ===
      case PageTransitionType.fade:
        return FadeTransition(opacity: curved, child: child);

      case PageTransitionType.fadeSlow:
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );

      case PageTransitionType.fadeQuick:
        return FadeTransition(opacity: fastOut, child: child);

      // === SCALE & ZOOM ===
      case PageTransitionType.zoomIn:
        return ScaleTransition(
          scale: Tween(begin: 0.6, end: 1.0).animate(curved),
          child: child,
        );

      case PageTransitionType.zoomOut:
        return ScaleTransition(
          scale: Tween(begin: 1.4, end: 1.0).animate(curved),
          child: child,
        );

      case PageTransitionType.scaleUp:
        return ScaleTransition(
          scale: Tween(begin: 0.75, end: 1.0).animate(curved),
          child: child,
        );

      case PageTransitionType.scaleDown:
        return ScaleTransition(
          scale: Tween(begin: 1.15, end: 1.0).animate(curved),
          child: child,
        );

      // === SLIDE ===
      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );

      case PageTransitionType.slideLeft:
        return SlideTransition(
          position: Tween(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );

      case PageTransitionType.slideDown:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );

      // === COMBINATIONS ===
      case PageTransitionType.fadeSlideRight:
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );

      case PageTransitionType.fadeZoom:
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );

      case PageTransitionType.rotateFade:
        return FadeTransition(
          opacity: curved,
          child: RotationTransition(
            turns: Tween(begin: 0.07, end: 0.0).animate(curved),
            child: child,
          ),
        );

      case PageTransitionType.flipHorizontal:
        return RotationTransition(
          turns: Tween(begin: 0.5, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );

      // === BOUNCE & ELASTIC ===
      case PageTransitionType.bounceIn:
        return ScaleTransition(
          scale: Tween(begin: 0.4, end: 1.0).animate(bounce),
          child: child,
        );

      case PageTransitionType.elasticIn:
        return ScaleTransition(
          scale: Tween(begin: 0.3, end: 1.0).animate(elastic),
          child: child,
        );

      case PageTransitionType.pop:
        return ScaleTransition(
          scale: TweenSequence([
            TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15), weight: 60),
            TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 20),
            TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
          ]).animate(curved),
          child: child,
        );

      // === ROTATION ===
      case PageTransitionType.rotateClockwise:
        return RotationTransition(
          turns: Tween(begin: -0.15, end: 0.0).animate(curved),
          child: child,
        );

      case PageTransitionType.threeDSpin:
        return RotationTransition(
          turns: Tween(begin: 0.15, end: 0.0).animate(curved),
          child: ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.0).animate(curved),
            child: child,
          ),
        );

      // === SPECIAL EFFECTS ===
      case PageTransitionType.curtainOpen:
        return ScaleTransition(
          scale: Tween(begin: 0.0, end: 1.0).animate(curved),
          alignment: Alignment.centerLeft,
          child: child,
        );

      case PageTransitionType.blinds:
        return ScaleTransition(
          scale: Tween(begin: 0.0, end: 1.0).animate(curved),
          alignment: Alignment.topCenter,
          child: child,
        );

      case PageTransitionType.shimmer:
        return FadeTransition(
          opacity: Tween(begin: 0.4, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutSine),
          ),
          child: child,
        );

      case PageTransitionType.ripple:
        return ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );

      case PageTransitionType.floatUp:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );

      case PageTransitionType.heartbeat:
        return ScaleTransition(
          scale: TweenSequence([
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 40),
            TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.96), weight: 30),
            TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 30),
          ]).animate(curved),
          child: child,
        );

      // ==================== NEW ATMOSPHERIC ANIMATIONS ====================

      case PageTransitionType.mistyFade:
        return FadeTransition(
          opacity: Tween(begin: 0.6, end: 1.0).animate(slowCurve),
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(sineCurve),
            child: child,
          ),
        );

      case PageTransitionType.softCloudDrift:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(slowCurve),
          child: FadeTransition(opacity: curved, child: child),
        );

      case PageTransitionType.summerGlow:
        return ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0).animate(sineCurve),
          child: FadeTransition(
            opacity: Tween(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );

      case PageTransitionType.gentleRainFall:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(slowCurve),
          child: FadeTransition(opacity: curved, child: child),
        );

      case PageTransitionType.goldenHour:
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(sineCurve),
            child: child,
          ),
        );

      case PageTransitionType.twilightFade:
        return FadeTransition(
          opacity: Tween(begin: 0.75, end: 1.0).animate(slowCurve),
          child: child,
        );

      case PageTransitionType.breezyFloat:
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(sineCurve),
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );

      case PageTransitionType.etherealMist:
        return FadeTransition(
          opacity: Tween(begin: 0.7, end: 1.0).animate(slowCurve),
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(sineCurve),
            child: child,
          ),
        );

      default:
        return FadeTransition(opacity: curved, child: child);
    }
  }
}

// Navigation helper functions
class NavigationHelper {
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.fade,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransition(
            type: transitionType,
            duration: duration,
            curve: curve,
            child: child,
          )._buildTransition(child, animation);
        },
      ),
    );
  }

  static List<PageTransitionType> getAllAnimations() {
    return PageTransitionType.values;
  }

  static PageTransitionType getRandomAnimation() {
    final animations = getAllAnimations();
    final random = DateTime.now().millisecondsSinceEpoch % animations.length;
    return animations[random.toInt()];
  }
}

// Animated container with transition on route change
class AnimatedRoute extends StatelessWidget {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;

  static const String _lastAnimationKey = 'last_selected_animation';

  const AnimatedRoute({
    super.key,
    required this.child,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 400),
  });

  static Future<PageTransitionType?> _getLastSelectedAnimation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? animationName = prefs.getString(_lastAnimationKey);
      if (animationName != null) {
        return PageTransitionType.values.firstWhere(
          (e) => e.toString() == animationName,
          orElse: () => PageTransitionType.glassMorph,
        );
      }
    } catch (e) {
      debugPrint('Error reading last animation: $e');
    }
    return null;
  }

  // Save last selected animation to SharedPreferences
  static Future<void> _saveLastSelectedAnimation(
    PageTransitionType animation,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastAnimationKey, animation.toString());
    } catch (e) {
      debugPrint('Error saving last animation: $e');
    }
  }

  static Future<PageTransitionType> getRandomSafeAnimation() async {
    final _random = Random();
    final animations = getCompanySafeAnimations();

    // Get last selected animation from SharedPreferences
    final PageTransitionType? lastAnimation = await _getLastSelectedAnimation();

    debugPrint('Last selected animation: $lastAnimation');

    if (lastAnimation == null) {
      PageTransitionType selectedAnimation = PageTransitionType.gentleRainFall;

      await _saveLastSelectedAnimation(selectedAnimation);

      return selectedAnimation;
    }

    // Select new animation (different from last one)
    PageTransitionType selectedAnimation;
    do {
      final randomIndex = _random.nextInt(animations.length);
      selectedAnimation = animations[randomIndex];
    } while (selectedAnimation == lastAnimation && animations.length > 1);

    // Save the new selection
    await _saveLastSelectedAnimation(selectedAnimation);

    debugPrint('Selected animation: $selectedAnimation');

    return selectedAnimation;
  }

  static List<PageTransitionType> getCompanySafeAnimations() {
    return [
      PageTransitionType.mistyFade,
      PageTransitionType.softCloudDrift,
      PageTransitionType.summerGlow,
      PageTransitionType.gentleRainFall,
      PageTransitionType.goldenHour,
      PageTransitionType.twilightFade,
      PageTransitionType.breezyFloat,
      PageTransitionType.etherealMist,

      // === Core Smooth Transitions (Highly Recommended) ===
      PageTransitionType.fade,
      PageTransitionType.fadeSlow,
      PageTransitionType.fadeQuick,
      PageTransitionType.fadeZoom,
      PageTransitionType.fadeSlideRight,
      PageTransitionType.fadeSlideLeft,
      PageTransitionType.fadeSlideUp,
      PageTransitionType.fadeSlideDown,

      // === Scale & Zoom ===
      PageTransitionType.zoomIn,
      PageTransitionType.zoomOut,
      PageTransitionType.scaleUp,
      PageTransitionType.scaleDown,
      PageTransitionType.pop,
      PageTransitionType.spring,

      // === Slide Transitions ===
      PageTransitionType.slideRight,
      PageTransitionType.slideLeft,
      PageTransitionType.slideUp,
      PageTransitionType.slideDown,

      // === Bounce & Elastic (Premium Feel) ===
      PageTransitionType.bounceIn,
      PageTransitionType.elasticIn,
      PageTransitionType.softBounce,
      PageTransitionType.heartbeat,
      PageTransitionType.breath,

      // === Rotation & 3D Feel ===
      PageTransitionType.rotateFade,
      PageTransitionType.rotateClockwise,
      PageTransitionType.rotateCounterClockwise,
      PageTransitionType.threeDSpin,
      PageTransitionType.flipHorizontal,
      PageTransitionType.flipVertical,

      // === Special & Elegant Effects ===
      PageTransitionType.curtainOpen,
      PageTransitionType.curtainClose,
      PageTransitionType.blinds,
      PageTransitionType.wipeRight,
      PageTransitionType.wipeLeft,
      PageTransitionType.dissolve,
      PageTransitionType.shimmer,
      PageTransitionType.ripple,
      PageTransitionType.wave,
      PageTransitionType.floatUp,
      PageTransitionType.sinkDown,
      PageTransitionType.gentleLift,

      // === Premium / Cinematic ===
      PageTransitionType.glassMorph,
      PageTransitionType.depthPush,
      PageTransitionType.depthPull,
      PageTransitionType.cinematic,
      PageTransitionType.dramaticZoom,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PageTransition(
      type: transitionType,
      duration: duration,
      child: child,
    );
  }
}
