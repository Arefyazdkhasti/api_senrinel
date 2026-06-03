# Optional Auth Retry Policy for `api_sentinel`

## Goal

Add a built-in, optional retry policy for unauthorized (`401`) responses so SDK consumers can:

- run a single refresh flow when multiple requests fail concurrently
- queue all failed requests while refresh is in progress
- replay each queued request once after a successful refresh
- fall back to app-level unauthorized handling when refresh fails

This behavior should be **opt-in** and backward compatible.

---

## Current Gap

`ApiService` currently supports:

- `unauthorizedStatusCode`
- `onUnauthorizedCallBack`

But it does not provide:

- request replay
- single-flight refresh coordination
- queueing for concurrent `401`s
- loop guards to avoid recursive refresh/retry

---

## Proposed API Additions

## 1) Add auth retry config in `ApiService.init(...)`

```dart
Future<void> init({
  required String baseUrl,
  bool needToShowLog = false,
  bool needToLogRequests = false,

  int? unauthorizedStatusCode = 401,
  void Function()? onUnauthorizedCallBack,

  // NEW (optional)
  bool enableAuthRetry = false,
  Future<bool> Function()? onRefreshToken,
  int maxUnauthorizedRetries = 1,
  bool Function(RequestOptions options)? shouldRetryUnauthorizedRequest,
  bool Function(RequestOptions options)? isRefreshRequest,
  Duration? refreshWaitTimeout,
})
```

### Notes

- `enableAuthRetry` defaults to `false` for backward compatibility.
- `onRefreshToken` is required when `enableAuthRetry == true`.
- `maxUnauthorizedRetries` should usually be `1`.
- `shouldRetryUnauthorizedRequest` lets apps skip retry for non-idempotent or custom endpoints.
- `isRefreshRequest` prevents recursive retry of refresh endpoint itself.
- `refreshWaitTimeout` prevents requests from waiting forever if refresh hangs.

---

## 2) Add per-request override in `request(...)`

```dart
Future<void> request({
  required HttpMethod method,
  required String url,
  dynamic data,
  Map<String, dynamic>? queryParameters,
  Options? options,
  Map<String, String>? headers,
  CancelToken? cancelToken,
  void Function(int, int)? onSendProgress,
  void Function(int, int)? onReceiveProgress,
  required void Function(DioException) onCatchDioException,
  required void Function(dynamic) onCatchException,
  required void Function(Response) onSuccess,

  // NEW (optional)
  bool? retryOnUnauthorized,
})
```

- If `retryOnUnauthorized == null`, use global policy.
- `false` skips auth-retry for this request.

---

## Internal Design

## State in `ApiService`

```dart
Completer<bool>? _refreshCompleter; // single-flight refresh
```

No explicit queue list is required if each failed request awaits `_refreshCompleter.future`.

## Flow

1. Execute request normally.
2. If response error is not unauthorized -> return original error.
3. If unauthorized and retry is allowed:
   - if refresh is already running, await it.
   - else start refresh (`_refreshCompleter = Completer<bool>()`).
4. If refresh succeeds:
   - rebuild headers (fresh token from caller-provided headers strategy or options mutator)
   - replay original request once
5. If refresh fails:
   - call `onUnauthorizedCallBack` once (best effort dedupe)
   - return original/appropriate auth error to caller

---

## Pseudocode

```dart
Future<void> request(...) async {
  final first = await _performRequest(...);

  if (!is401(first.error) || !canRetryThisRequest(...)) {
    return dispatch(first);
  }

  if (cancelToken?.isCancelled == true) {
    return dispatch(first);
  }

  final refreshed = await _refreshSingleFlight();

  if (!refreshed) {
    onUnauthorizedCallBack?.call();
    return dispatch(first);
  }

  final replay = await _performRequest(
    ...same request...,
    headers: _rebuildHeadersWithFreshAuth(headers),
  );

  return dispatch(replay);
}
```

---

## Recommended Guards

- Do **not** retry refresh endpoint itself.
- Do not retry if request was canceled.
- Retry at most once per request (or `maxUnauthorizedRetries`).
- Respect per-request `retryOnUnauthorized=false`.
- Only retry for protected requests (e.g. requests with `Authorization` header).
- Timeout waiting for refresh (`refreshWaitTimeout`) and fail safely.

---

## Edge Cases to Handle

## 1) 3+ concurrent 401 requests
- Expected: one refresh call, all others await same future, all replay once.

## 2) Refresh fails (401/403/network)
- Expected: no replay, unauthorized callback triggered, callers receive error.

## 3) Refresh succeeds but replay still returns 401
- Expected: no second refresh loop if max retries reached; return error and optionally trigger callback.

## 4) Polling endpoints
- Poll request can use retry policy automatically.
- If replay still fails, caller should stop polling to avoid infinite loops/spam.

## 5) Non-idempotent endpoints
- Keep default retry optional or endpoint-filtered.
- Encourage idempotency keys for POST where replay is allowed.

## 6) Logout during refresh
- If app logs out while refresh is in flight, complete refresh as failed and reject queued retries.

## 7) App startup race
- Requests fired before auth state is ready should either:
  - skip auth retry, or
  - fail fast with clear error until auth is initialized.

## 8) Stale header replay
- Rebuild auth headers just before replay, don’t reuse stale Authorization string.

---

## Testing Plan

## Unit Tests

- `401` + refresh success => replay success.
- `401` + refresh fail => no replay.
- 3 concurrent `401`s => refresh called exactly once.
- refresh request itself `401` => no recursion.
- canceled request => no replay.
- `retryOnUnauthorized=false` => no refresh call.

## Integration Tests

- protected GET with expired token
- protected POST with idempotency key
- long-running polling request with token expiry mid-flow

---

## Migration / Backward Compatibility

- Default behavior remains unchanged (`enableAuthRetry=false`).
- Existing apps can continue using `onUnauthorizedCallBack`.
- New behavior activates only when config is explicitly provided.

---

## Example Consumer Usage

```dart
ApiService.instance.init(
  baseUrl: baseUrl,
  needToLogRequests: true,
  unauthorizedStatusCode: 401,
  onUnauthorizedCallBack: () => handleSessionExpired(),
  enableAuthRetry: true,
  onRefreshToken: () async {
    // app-level token refresh logic
    return await authController.refreshAccessToken();
  },
  maxUnauthorizedRetries: 1,
  isRefreshRequest: (options) => options.path.contains('/auth/refresh'),
  shouldRetryUnauthorizedRequest: (options) {
    // skip retry for some endpoints if needed
    return true;
  },
);
```

---

## Suggested Implementation Steps in `api_sentinel`

1. Extend `init(...)` with optional retry policy parameters.
2. Add private single-flight refresh coordinator (`_refreshCompleter`).
3. Refactor `request(...)` internals to support:
   - first attempt
   - unauthorized decision
   - await/start refresh
   - one replay
4. Add helper methods:
   - `_isUnauthorized(DioException)`
   - `_canRetryUnauthorized(...)`
   - `_refreshSingleFlight()`
   - `_cloneOrRebuildOptionsForReplay(...)`
5. Add tests for concurrency + recursion prevention.
6. Update README with opt-in usage and caveats.

---

## Caveats

- SDK cannot universally guarantee safe replay for all POSTs; app should use idempotency keys.
- Retry policy should remain opt-in to avoid surprising behavior in existing clients.

