# API Sentinel — Example App

Demonstrates `ApiService`, secret-knock debug access, TOTP verification, and the gated debug overlay.

## Run (debug — auto-generated TOTP secret)

```bash
cd example
flutter pub get
flutter run
```

On first launch, check the console for an `otpauth://` URI and scan it with Google Authenticator. Perform the secret knock on **"Secret Knock Detector"** (double-tap → long-press), enter the 6-digit code, and the debug overlay appears.

## Run with embedded TOTP secret (matches release builds)

Split your Base32 secret into two parts:

```bash
flutter run \
  --dart-define=TOTP_SECRET_PART1="FIRST_HALF" \
  --dart-define=TOTP_SECRET_PART2="SECOND_HALF"
```

Register the **combined** secret in your authenticator app.

## What to look at

| File | What it shows |
| --- | --- |
| `lib/main.dart` | `AccessController` registration, `SecretKnockDetector`, `TotoSecretSection` dialog, gated `DebugOverlayWidget` |
| Parent `README.md` | Full integration guide for consuming apps |
