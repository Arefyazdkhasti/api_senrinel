// Dart imports:

// Flutter imports:
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

// Package imports:
import 'package:base32/base32.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:otp/otp.dart';

import '../res/release_config.dart';

// Project imports:

/// Controls TOTP-based access to the Debug Overlay in release builds.
class AccessController extends GetxController {
  final RxBool _isDebugFeaturesAccessible = false.obs;

  RxBool get isDebugFeaturesAccessible => _isDebugFeaturesAccessible;

  static const String _secretKey = 'debug_overlay_totp_secret';
  static const String _issuer = 'Bahoosh';
  static const String _accountName = 'Debug-Log-Access';
  static const int _digits = 6;
  static const int _period = 30;

  String? _cachedSecret;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Initializes TOTP: generates secret if missing, logs QR-compatible URI.
  /// Embedded secrets from `--dart-define` are used in release mode or when
  /// both parts are provided (so local testing matches CI/release builds).
  Future<String?> initialize() async {
    if (kReleaseMode || ReleaseConfig.hasEmbeddedSecret) {
      log('TOTP secret (embedded via dart-define, release=$kReleaseMode)');
      _cachedSecret = ReleaseConfig.totpSecret;
    } else {
      _cachedSecret ??= await _storage.read(key: _secretKey);

      if (_cachedSecret == null) {
        _cachedSecret = _generateBase32Secret();
        await _storage.write(key: _secretKey, value: _cachedSecret!);
        final uri = _buildOtpAuthUri(_cachedSecret!);
        log(
          'Debug Overlay TOTP setup complete!\n'
          'Scan this URI in Google Authenticator:\n$uri',
        );
      } else {
        log('Debug Overlay TOTP secret already exists. => $_cachedSecret');
      }
    }
    return _cachedSecret;
  }

  String _generateBase32Secret({int byteLength = 16}) {
    final random = math.Random.secure();
    final bytes = Uint8List(byteLength);
    for (int i = 0; i < byteLength; i++) {
      bytes[i] = random.nextInt(256);
    }
    // Base32.encode returns uppercase with padding; remove '='
    return base32.encode(bytes).replaceAll('=', '');
  }

  String _buildOtpAuthUri(String secretBase32) {
    // Label format: 'Issuer:AccountName'
    const label = '$_issuer:$_accountName';
    // URL-encode label (spaces, colons, etc.)
    final encodedLabel = Uri.encodeComponent(label);

    final params = {
      'secret': secretBase32,
      'issuer': _issuer,
      'algorithm': 'SHA1',
      'digits': '$_digits',
      'period': '$_period',
    };

    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return 'otpauth://totp/$encodedLabel?$query';
  }

  Future<String?> _resolveSecret() async {
    if (_cachedSecret != null) return _cachedSecret;

    if (kReleaseMode || ReleaseConfig.hasEmbeddedSecret) {
      return ReleaseConfig.totpSecret;
    }

    return _storage.read(key: _secretKey);
  }

  /// Validates TOTP code with ±1 time window (90-second tolerance).
  Future<bool> validateCode(String inputCode) async {
    final secret = (await _resolveSecret())?.toUpperCase();

    if (secret == null || secret.isEmpty) {
      log('No TOTP secret found.');
      return false;
    }

    final cleanCode = inputCode.trim();
    if (cleanCode.length != _digits || !RegExp(r'^\d+$').hasMatch(cleanCode)) {
      log('Invalid code format: $cleanCode');
      return false;
    }

    // Use milliseconds since epoch (most otp packages expect ms)
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // check -1, 0, +1 windows
    for (int offset = -1; offset <= 1; offset++) {
      final testTimeMs = nowMs + (offset * _period * 1000);
      final expected = OTP.generateTOTPCodeString(
        secret,
        testTimeMs, // milliseconds
        interval: _period,
        length: _digits,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      log('offset=$offset, testTimeMs=$testTimeMs, expected=$expected');
      if (_constantTimeEquals(expected, cleanCode)) {
        log('TOTP valid (offset $offset)');
        return true;
      }
    }

    log('TOTP code invalid. Current nowMs=$nowMs, entered=$cleanCode');
    return false;
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// (Optional) Reset secret — useful for testing or revocation.
  Future<void> resetSecret() async {
    await _storage.delete(key: _secretKey);
    _cachedSecret = null;
    log('Debug Overlay TOTP secret reset.');
  }

  void enableDebugFeatures() {
    // make debug overlay accessible
    isDebugFeaturesAccessible.value = true;
  }
}
