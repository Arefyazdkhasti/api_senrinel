// lib/widgets/secret_knock_detector.dart

// Dart imports:
import 'dart:async';
import 'dart:developer';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A stealthy gesture detector for secret debug access
///
/// Default pattern: Triple long-press (press-hold → release → press-hold → release → press-hold)
///
/// Custom patterns:
/// - `knockPattern = [Tap, Tap, LongPress]` → "Shave and a Haircut"
/// - `knockPattern = [LongPress, Tap, LongPress]` → "Morse Code SOS"
class SecretKnockDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onSecretKnock;
  final Duration resetTimeout;
  final List<KnockType> knockPattern;
  final bool enabled;

  const SecretKnockDetector({
    super.key,
    required this.child,
    required this.onSecretKnock,
    this.resetTimeout = const Duration(seconds: 2),
    this.knockPattern = const [
      KnockType.longPress,
      KnockType.longPress,
      KnockType.longPress,
    ],
    this.enabled = true,
  });

  @override
  State<SecretKnockDetector> createState() => _SecretKnockDetectorState();
}

class _SecretKnockDetectorState extends State<SecretKnockDetector> {
  int _currentStep = 0;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _resetSequence() {
    log(' SECRET KNOCK: 🔄 SecretKnock: Sequence reset');

    _currentStep = 0;
    _resetTimer?.cancel();
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer(widget.resetTimeout, _resetSequence);
  }

  void _handleKnock(KnockType type) {
    if (!widget.enabled) {
      log(' SECRET KNOCK: 🔒 SecretKnock: Disabled, ignoring knock');
      return;
    }

    if (_currentStep >= widget.knockPattern.length) {
      log(' SECRET KNOCK: ⚠️ SecretKnock: Pattern already completed');
      return;
    }

    // Validate sequence
    if (widget.knockPattern[_currentStep] == type) {
      _currentStep++;

      log(
        '✅ SecretKnock: Step $_currentStep/${widget.knockPattern.length} correct',
      );

      // Success!
      if (_currentStep == widget.knockPattern.length) {
        log(
          ' SECRET KNOCK: 🎉 SecretKnock: Pattern completed! Triggering callback',
        );

        _resetSequence();
        _vibrateSuccess();
        widget.onSecretKnock();
        return;
      }

      // Start reset timer for next step
      _startResetTimer();
    } else {
      // Invalid sequence - reset
      log(
        '❌ SecretKnock: Wrong step, expected ${widget.knockPattern[_currentStep]}, got $type. Resetting.',
      );
      _resetSequence();
    }
  }

  void _vibrateSuccess() {
    if (kIsWeb) return;

    // Subtle haptic feedback
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        HapticFeedback.lightImpact();
        break;
      case TargetPlatform.android:
        HapticFeedback.vibrate();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap detection
      onTapDown: (_) {
        if (widget.knockPattern.contains(KnockType.tap)) {
          log(' SECRET KNOCK: 🔘 SecretKnock: Tap detected');
          _handleKnock(KnockType.tap);
        }
      },

      // Long press detection
      onLongPressStart: (_) {
        if (widget.knockPattern.contains(KnockType.longPress)) {
          log(' SECRET KNOCK: ⏱️ SecretKnock: Long press started');
          _handleKnock(KnockType.longPress);
        }
      },
      onLongPressEnd: (_) {
        log(' SECRET KNOCK: ⏱️ SecretKnock: Long press ended');
      },
      onLongPressCancel: () {
        log(' SECRET KNOCK: ⏱️ SecretKnock: Long press cancelled');
      },

      // Double tap for alternative access (optional)
      onDoubleTap: () {
        // Optional: Double-tap as fallback for accessibility
        // Only if pattern includes doubleTap
        if (widget.knockPattern.contains(KnockType.doubleTap)) {
          log(' SECRET KNOCK: ⏸️ SecretKnock: Double tap detected');
          _handleKnock(KnockType.doubleTap);
        }
      },

      child: widget.child,
    );
  }
}

/// Types of "knocks" in the secret sequence
enum KnockType { tap, longPress, doubleTap }

/// Predefined secret patterns
class SecretPatterns {
  /// Triple long-press (default)
  static const tripleLongPress = [
    KnockType.longPress,
    KnockType.longPress,
    KnockType.longPress,
  ];

  /// "Shave and a Haircut" (tap-tap-hold)
  static const shaveAndHaircut = [
    KnockType.tap,
    KnockType.tap,
    KnockType.longPress,
  ];

  /// Morse Code SOS (· · · — — — · · ·)
  static const morseSOS = [
    KnockType.tap,
    KnockType.tap,
    KnockType.tap,
    KnockType.longPress,
    KnockType.longPress,
    KnockType.longPress,
    KnockType.tap,
    KnockType.tap,
    KnockType.tap,
  ];

  /// Double-tap + long-press (for accessibility)
  static const accessible = [KnockType.doubleTap, KnockType.longPress];
}
