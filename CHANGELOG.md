# Changelog

## 2.0.0

Major release: gated debug access with secret knock gestures and TOTP verification.

**New features:**

- `SecretKnockDetector` — wrap any widget to listen for a configurable tap/long-press pattern and trigger a callback.
- `SecretPatterns` — predefined knock sequences (`accessible`, `tripleLongPress`, `shaveAndHaircut`, `morseSOS`).
- `AccessController` — GetX controller that manages TOTP setup, validation, and `isDebugFeaturesAccessible` state.
- `TotoSecretSection` — ready-made 6-digit OTP input wired to `AccessController`.
- Release builds (and debug builds with `--dart-define`) support split TOTP secrets via `TOTP_SECRET_PART1` and `TOTP_SECRET_PART2`.

**Integration notes:**

- Register `AccessController` once with `Get.put(..., tag: AllControllerKeys.accessControllerKey)`.
- Place `SecretKnockDetector` on a discreet UI element; show `TotoSecretSection` in a dialog/sheet on knock.
- Gate `DebugOverlayWidget` behind `accessController.isDebugFeaturesAccessible` so logs stay hidden until TOTP succeeds.

## 1.1.2

Add curl command generation and copy support in the debug overlay.

**Enhancements:**

- Generate a curl command for every logged request, built after interceptors and headers are applied so cookies, auth, and `content-length` are included.
- Copy curl to clipboard from the debug log list, with the button disabled when no curl was captured.
- View request and response headers in the debug log detail tabs.

## 1.1.1

Add `dioExceptionType`, `dioMessage` and `dioUnderlyingError` to NetworkMonitoringParams 

## 1.1.0

Fix `ApiService` singleton initialization and add support for multiple configured instances.

**Breaking changes:**

- `ApiService.instance` now throws a `StateError` when accessed before `ApiService.init()` instead of returning an uninitialized instance.
- Renamed `needIntitialGlobalInstance` to `needInitialGlobalInstance` in `ApiService.init()`.

**Enhancements:**

- `ApiService.init()` returns the configured service instance, so callers can keep and use dedicated instances when `needInitialGlobalInstance` is `false`.
- Export `NetworkMonitoringParams` and `NetworkMonitoringFunction` from the main library entry point.

**Fixes:**

- Prevent subtle runtime bugs from using an uninitialized `ApiService` via the `instance` getter.

## 1.0.0

Add optional network monitoring integration to API service and make error handling more flexible.

New Features:

Introduce a pluggable networkMonitoringFunction callback in ApiService to capture details of network-related exceptions.
Add NetworkMonitoringParams model to standardize data passed to network monitoring integrations.
Enhancements:

Allow ApiService request success handlers to be async for more flexible post-response processing.
Extend handleErrorMessage to accept an optional error key override when parsing API error responses.


## 0.0.8

- Add `needToLogRequests` for adding request to the DebugLogController

## 0.0.7

- Added support for `Unauthorized Flow` handling

## 0.0.6

- Change `CookieJar` into nullable instead of late


## 0.0.5

- Added cookie management support in API service using persistent storage for session handling.
- Introduced configurable logging via `needToShowLog` flag in the init method in ApiService.

# 0.0.4

- Add header option to api service

# 0.0.3

- Add Filter for log pages
- Add attach to side draggable and expandable overlay
- Not showing overlay in debug page

# 0.0.2

Format code for pub.dev

## 0.0.1

**Initial release of the package**

- Introduced a **centralized API service** with:
    - Unified `GET`, `POST`, `PUT`, `PATCH`, and `DELETE` request handling
    - Built-in **error catching** (`DioException` & general exceptions)
    - Custom **success and failure callbacks**

- Added a **floating draggable debug overlay** for real-time API inspection
    - View logs, request bodies, and responses directly in-app
    - Includes **JSON tree view** and **color-highlighted JSON viewer**
    - Expandable to a **full-screen log viewer**

- Added **log filtering** (by method, status, or keyword)

- Example project demonstrating integration with a **public REST API**