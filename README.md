# 🛰️ API Sentinel

**A structured, developer-friendly networking and debugging layer for Flutter.**  
`api_sentinel` provides a clean and consistent way to handle API requests, error mapping, and runtime debugging through an on-screen overlay.

---

## ✨ Features

✅ Unified API call interface via `ApiService.instance.request()`  
✅ Customizable callbacks for success, Dio exceptions, and general exceptions  
✅ Centralized error handling and message parsing  
✅ Floating on-screen debug overlay to visualize requests  
✅ Generate curl commands for every request
✅ Copy generated curl with a single tap
✅ View request headers
✅ View response headers
✅ Built with `dio` and `get` (GetX) for lightweight reactivity  
✅ Supports Android, iOS, and Web  
✅ Built-in Unauthorized detection with callback (unauthorized status code, customizable unauthorized callback)
✅ Optional network monitoring callback with structured error params  
✅ Secret knock gesture to reveal a hidden debug entry point  
✅ TOTP-gated access to the debug overlay in release builds

---

## 📦 Installation

Add this line to your `pubspec.yaml`:

```yaml
dependencies:
  api_sentinel: ^2.0.0
```

Then run:

```bash
flutter pub get
```

---

## 🧠 Architecture Overview

The library is built around three core layers:

| Layer            | Description                                                                             |
| ---------------- | --------------------------------------------------------------------------------------- |
| **ApiService**   | Handles all HTTP requests (GET, POST, PUT, PATCH, DELETE) through Dio.                  |
| **ErrorHandler** | Converts all errors (network, timeout, response, etc.) into readable `Failure` objects. |
| **DebugOverlay** | Shows all ongoing and past requests on top of your UI during runtime (toggleable).      |
| **SecretKncock and Totp Flow** | Trigger via custom secret knock and accept Authenticator secret 6 digit codes.      |
---

## ⚙️ Usage

### 1️⃣ Initialize the Service

```dart
ApiService.instance.init(
  baseUrl: 'YOUR_BASE_URL',
  needToShowLog: false,
  needToLogRequests: false,
  unauthorizedStatusCode: 401,
  onUnauthorizedCallBack: () {
    // Handle session expiration or redirect to login.
  },
  networkMonitoringFunction: (params) {
    print('Request URL: ${params.requestUrl}');
    print('Status Code: ${params.statusCode}');
    print('API Error: ${params.apiErrorMessage}');
    print('Runtime Error: ${params.runTimeErrorType}');
  }
);
```

---

### 2️⃣ Monitor Network Failures

`networkMonitoringFunction` receives a `NetworkMonitoringParams` object whenever a request fails with either a `DioException` or another runtime exception.

```dart
class NetworkMonitoringParams {
  final StackTrace? stackTrace;
  final String? requestUrl;
  final int? statusCode;
  final String? apiErrorMessage;
  final String? errorMessage;
  final Object? runTimeErrorType;
}
```

Use it to capture the request URL, HTTP status code, parsed API error message, raw error text, and the original runtime error object in one place.

---

### 3️⃣ Make a Request

Each request is wrapped with `ApiService.instance.request()`
This ensures that error handling, logging, and overlay integration all happen automatically.

```dart
await ApiService.instance.request(
  method: HttpMethod.get,
  url: 'SOME_REQUEST',
  onSuccess: (response) {
    print('✅ Success: ${response.data}');
  },
  onCatchDioException: (error) {
    print('❌ Dio Error: ${handleErrorMessage(error)}');
  },
  onCatchException: (error) {
    print('💥 Exception: ${handleErrorMessage(error)}');
  },
);
```

This pattern applies to **any HTTP method** — just change the `method` and `url`.

---

### 4️⃣ Supported HTTP Methods

You can use all standard HTTP verbs through the `HttpMethod` enum:

```dart
enum HttpMethod { get, post, put, patch, delete }
```

---

## 🧩 Error Architecture

| Error Type         | Source          | Failure Example             |
| ------------------ | --------------- | --------------------------- |
| Connection Timeout | Dio             | `(-1) Connection timed out` |
| Bad Request        | HTTP 400        | `Bad Request`               |
| Unauthorized       | HTTP 401        | `Unauthorized access`       |
| Forbidden          | HTTP 403        | `Access denied`             |
| Not Found          | HTTP 404        | `Resource not found`        |
| Server Error       | HTTP 500        | `Internal server error`     |
| Cancelled          | Dio CancelToken | `Request cancelled`         |
| Unknown            | Fallback        | `Something went wrong`      |

---

## 🔐 Secret Knock & TOTP-Gated Debug Access (v2.0.0)

In release builds, the debug overlay should stay hidden until an authorized user proves access. API Sentinel provides a **secret knock** gesture detector, a **TOTP** verification flow, and an **`AccessController`** that unlocks the log overlay after a valid code.

### Flow overview

```
User performs knock pattern on a widget
        ↓
SecretKnockDetector fires onSecretKnock
        ↓
You show TotoSecretSection (dialog, bottom sheet, etc.)
        ↓
User enters 6-digit TOTP from authenticator app
        ↓
AccessController.validateCode() succeeds
        ↓
AccessController.enableDebugFeatures() → isDebugFeaturesAccessible = true
        ↓
DebugOverlayWidget becomes visible
```

### 1️⃣ Register `AccessController`

Register the controller **once** near the root of your app (before any widget that needs it):

```dart
import 'package:api_sentinel/api_sentinel.dart';
import 'package:get/get.dart';

class _MyAppState extends State<MyApp> {
  final AccessController accessController = Get.put(
    AccessController(),
    tag: AllControllerKeys.accessControllerKey,
  );

  // ...
}
```

| Symbol | Role |
| --- | --- |
| `AccessController` | Holds TOTP secret, validates codes, exposes `isDebugFeaturesAccessible` |
| `AllControllerKeys.accessControllerKey` | Stable GetX tag so `TotoSecretSection` can `Get.find` the same instance |

**Key APIs**

| Method / property | Description |
| --- | --- |
| `initialize()` | Loads or generates the TOTP secret. Call early (e.g. when the OTP UI opens). |
| `validateCode(String code)` | Returns `true` when the 6-digit code matches (±1 time window). |
| `enableDebugFeatures()` | Sets `isDebugFeaturesAccessible` to `true`. |
| `isDebugFeaturesAccessible` | Reactive `RxBool` — gate the overlay behind this. |
| `resetSecret()` | Clears the dev-only secure-storage secret (debug builds without dart-define). |

### 2️⃣ Wrap a widget with `SecretKnockDetector`

Pick **one** knock pattern for your app and use it consistently. The example uses `SecretPatterns.accessible` (double-tap, then long-press):

```dart
SecretKnockDetector(
  knockPattern: SecretPatterns.accessible,
  onSecretKnock: () {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: const TotoSecretSection(),
      ),
    );
  },
  child: const Text('App title'), // any widget — title, logo, version label, etc.
)
```

**Available patterns** (`SecretPatterns`):

| Pattern | Gesture |
| --- | --- |
| `accessible` | Double-tap → long-press |
| `tripleLongPress` | Long-press × 3 |
| `shaveAndHaircut` | Tap → tap → long-press |
| `morseSOS` | Tap×3 → long-press×3 → tap×3 |

You can also pass a custom `List<KnockType>` to `knockPattern`. Steps must be completed within `resetTimeout` (default 2 seconds between steps).

### 3️⃣ Show `TotoSecretSection` on knock

`TotoSecretSection` is a pre-built OTP field. It finds `AccessController` by tag, calls `initialize()` on mount, validates on submit, and calls `enableDebugFeatures()` on success.

Use it wherever you like — dialog, bottom sheet, or full-screen route:

```dart
onSecretKnock: () {
  showModalBottomSheet(
    context: context,
    builder: (_) => const Padding(
      padding: EdgeInsets.all(24),
      child: TotoSecretSection(),
    ),
  );
},
```

You can also build your own UI and call `accessController.validateCode(code)` directly.

### 4️⃣ Gate `DebugOverlayWidget` behind access

Only show the floating log button after TOTP succeeds:

```dart
Stack(
  children: [
    const MyHomePage(),
    Obx(() {
      if (!accessController.isDebugFeaturesAccessible.value) {
        return const SizedBox.shrink();
      }
      return const DebugOverlayWidget();
    }),
  ],
)
```

In **debug builds** without dart-defines, the first run logs an `otpauth://` URI to the console — scan it with Google Authenticator. In **release builds**, the secret comes from dart-define (see below).

### 5️⃣ Pass the TOTP secret with `--dart-define`

For release (and local testing that matches release), split your Base32 secret into two parts so neither half is useful alone:

```bash
flutter build apk --release \
  --dart-define=TOTP_SECRET_PART1="FIRST_HALF_OF_BASE32_SECRET" \
  --dart-define=TOTP_SECRET_PART2="SECOND_HALF_OF_BASE32_SECRET"
```

The app concatenates both parts at compile time: `TOTP_SECRET_PART1 + TOTP_SECRET_PART2`.

**Local run with embedded secret:**

```bash
flutter run --release \
  --dart-define=TOTP_SECRET_PART1="JBSWY3DPEHPK3PXP" \
  --dart-define=TOTP_SECRET_PART2="GEZDGNBVGY3TQOJQ"
```

> **Important:** Register the **full combined secret** in your authenticator app, not each part separately.

**CI / Xcode / Gradle**

Add the same defines to your build pipeline:

```yaml
# GitHub Actions example
- run: flutter build ipa --release
    --dart-define=TOTP_SECRET_PART1=${{ secrets.TOTP_PART1 }}
    --dart-define=TOTP_SECRET_PART2=${{ secrets.TOTP_PART2 }}
```

| Build mode | Secret source |
| --- | --- |
| Release | `TOTP_SECRET_PART1` + `TOTP_SECRET_PART2` (required) |
| Debug + dart-define | Same embedded secret (for testing release behaviour) |
| Debug, no dart-define | Auto-generated secret stored in secure storage; URI printed to console |

### Full integration example

See [`example/lib/main.dart`](./example/lib/main.dart) for a working setup with `SecretKnockDetector`, `TotoSecretSection`, `AccessController`, and `DebugOverlayWidget`.

---

## 🧰 Debug Overlay


### 🧊 Floating Draggable Widget

A persistent, draggable button gives quick access to real-time logs. In production, gate it behind `AccessController.isDebugFeaturesAccessible` (see [Secret Knock & TOTP](#-secret-knock--totp-gated-debug-access-v200)).

```dart
Stack(
  children: [
    const MyHomePage(),
    Obx(() {
      if (!accessController.isDebugFeaturesAccessible.value) {
        return const SizedBox.shrink();
      }
      return const DebugOverlayWidget();
    }),
  ],
)
```

Inside, you’ll see:

* A real-time log list for each request
* Search and filter by method/status code
* Tap any log to expand request/response JSON
* Toggle between **Tree View** and **Pretty JSON**
* Click to **expand full-screen**
* View request headers
* View response headers
* Generate a curl command from the request
* Copy the generated curl to the clipboard


### 🌳 JSON Tree Viewer

Displays structured hierarchical JSON for nested inspection.

### 🎨 Pretty JSON Viewer

Shows syntax-colored formatted JSON text.

### 🖥 Full-Screen View

Click the expand icon (🔍) in the corner to open the full JSON view for better readability.


Whenever your app performs an API call through `ApiService`, it will appear in a floating overlay with:

* Method type (GET/POST/PUT/PATCH/DELETE)
* Status code
* Response time
* Response preview
* Request headers
* Response headers
* Generated curl command with one-tap copy


<p align="center">
  <img src="images/draggable_widget.png" width="30.8%" />
  <img src="images/request_logs.png" width="31%" />
  <img src="images/request_details.png" width="30.9%" />
</p>

---

## 🧪 Example Project

A complete example app is included under the [`example/`](./example) directory.

**Debug mode** (auto-generated TOTP secret printed to console):

```bash
cd example
flutter run
```

**With embedded TOTP secret** (same as release):

```bash
cd example
flutter run \
  --dart-define=TOTP_SECRET_PART1="YOUR_PART_1" \
  --dart-define=TOTP_SECRET_PART2="YOUR_PART_2"
```

The example demonstrates:

* API calls via `ApiService` (GET, POST, PUT, PATCH, DELETE)
* `SecretKnockDetector` with `SecretPatterns.accessible`
* `TotoSecretSection` shown in a dialog after the knock
* `DebugOverlayWidget` gated behind `AccessController.isDebugFeaturesAccessible`

---

## 📚 License

MIT License © 2025
Developed and maintained by [Aref Yazdkhasti](https://github.com/Arefyazdkhasti/api_senrinel)

---

## 💬 Contribution

Contributions are welcome!
If you’d like to improve the debugging UI, extend the `ErrorHandler`, or support additional APIs, open a PR or issue.

---

## 🧭 Future Plans

* [ ] Response caching layer
* [ ] Retry strategy for failed requests and 401 unauthenticated request
* [ ] Filterable API session logs

---

> **API Sentinel** — Because understanding your API should be as clear as your code.
