class ReleaseConfig {
  static const _p1 = String.fromEnvironment('TOTP_SECRET_PART1');
  static const _p2 = String.fromEnvironment('TOTP_SECRET_PART2');

  /// True when both secret parts were passed via `--dart-define`.
  static bool get hasEmbeddedSecret => _p1.isNotEmpty && _p2.isNotEmpty;

  static String get totpSecret => '$_p1$_p2';
}
