import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:get/get.dart';

import 'debug_overlay/debug_interceptor.dart';
import 'debug_overlay/debug_log_controller.dart';

// Enumeration to represent HTTP request methods.
enum HttpMethod { get, post, put, delete, patch, unknown }

HttpMethod stringToHttpMethod(String? method) {
  switch (method) {
    case 'get':
      return HttpMethod.get;
    case 'post':
      return HttpMethod.post;
    case 'put':
      return HttpMethod.put;
    case 'delete':
      return HttpMethod.delete;
    case 'patch':
      return HttpMethod.patch;
    default:
      return HttpMethod.unknown;
  }
}

class ApiService {
  late Dio _dio;
  CookieJar? _cookieJar;

  ApiService._internal();

  static final ApiService instance = ApiService._internal();

  // ──────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────

  /// Must be called once before using [request].
  /// Example:
  /// ```dart
  /// ApiService.instance.init(baseUrl: "https://api.example.com");
  /// ```
  Future<void> init({
    required String baseUrl,
    bool needToShowLog = false,
    void Function(int statusCode)? onStatusCodeHandle,
  }) async {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
        sendTimeout: const Duration(milliseconds: 30000),
      ),
    );

    // Handle cookie from server
    if (!kIsWeb) {
      // In mobile device
      Directory dir = await getApplicationSupportDirectory();
      final cookiePath = '${dir.path}/cookies';

      _cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));

      if (_cookieJar != null) {
        _dio.interceptors.add(CookieManager(_cookieJar!));
      }
    } else {
      // In web PWA
      // Cookies are handled by the browser on web.
      // !IMPORTANT: You should use `withCredentials` in web when needed.
      // Example:
      // options: Options(
      //   extra: {if (kIsWeb) 'withCredentials': true},
      // ),
      _cookieJar = CookieJar();
    }

    if (!kReleaseMode) {
      if (!Get.isRegistered<DebugLogController>()) {
        Get.put(DebugLogController(), permanent: true);
      }
      _dio.interceptors.add(DebugInterceptor());
    }

    if (needToShowLog) {
      _dio.interceptors.add(
        dio.LogInterceptor(
          requestHeader: true,
          responseHeader: true,
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final statusCode = e.response?.statusCode;

          if (statusCode != null) {
            onStatusCodeHandle?.call(statusCode);
          }
          return handler.next(e);
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MAIN REQUEST METHOD
  // ──────────────────────────────────────────────

  /*
  * Makes an HTTP request with various options.
  *
  * The [method] parameter specifies the HTTP method (get, post, put, delete).
  * The [url] parameter is the relative URL for the specific API endpoint.
  * The [data] parameter contains the request payload for methods like POST and PUT.
  * The [queryParameters] parameter contains additional query parameters for the request.
  * The [authToken] parameter is an optional authentication token for securing requests.
  * The [options] parameter allows for customization of request options.
  * The [cancelToken] parameter is used to cancel an ongoing request.
  * The [onSendProgress] and [onReceiveProgress] parameters are callbacks for tracking progress.
  *
  * Throws a [DioError] if the request fails.
  * */

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
    required void Function(dio.Response) onSuccess,
  }) async {
    dio.Response response;

    Options? defaultOptions;
    //set base option for request if not provided
    if (options != null) {
      defaultOptions = options;
    } else {
      Map<String, String> customHeaders = headers ?? {};

      defaultOptions = Options(headers: customHeaders);
    }
    try {
      // Perform the request based on the specified HTTP method.
      switch (method) {
        // Perform a GET request using Dio with provided parameters.
        case HttpMethod.get:
          response = await _dio.get(
            url,
            data: data,
            options: defaultOptions,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.post:
          // Perform a POST request using Dio with provided parameters.
          response = await _dio.post(
            url,
            data: data,
            queryParameters: queryParameters,
            options: defaultOptions,
            onSendProgress: onSendProgress,
            cancelToken: cancelToken,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.patch:
          // Perform a PATCH request using Dio with provided parameters.
          response = await _dio.patch(
            url,
            data: data,
            queryParameters: queryParameters,
            options: defaultOptions,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.put:
          // Perform a PUT request using Dio with provided parameters.
          response = await _dio.put(
            url,
            data: data,
            queryParameters: queryParameters,
            options: defaultOptions,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpMethod.delete:
          // Perform a DELETE request using Dio with provided parameters.
          response = await _dio.delete(
            url,
            data: data,
            options: defaultOptions,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
          );
          break;
        default:
          throw Exception('Unknown method');
      }
      onSuccess(response);
    } on DioException catch (e) {
      onCatchDioException(e);
    } catch (e) {
      onCatchException(e);
    }
  }

  /// Clears all cookies stored by Dio.
  ///
  /// This method clears cookies from the current [_cookieJar].
  /// On non-web platforms with [PersistCookieJar], this clears both
  /// in-memory cookies and cookies persisted on disk.
  ///
  /// Use this when you need to:
  /// - Log out a user
  /// - Reset authentication/session state
  /// - Ensure no stale cookies are reused
  Future<void> clearCookies() async {
    await _cookieJar?.deleteAll();
  }

  /// Retrieves cookies for a specific request URL.
  ///
  /// This method loads all cookies that match the given [url]
  /// from the current [_cookieJar]. These cookies are the ones
  /// that would be sent automatically with a request to this URL.
  ///
  /// Parameters:
  /// - [url]: The target endpoint used to filter relevant cookies.
  ///
  /// Returns:
  /// - A list of [Cookie] objects associated with the provided URL.
  ///
  /// Notes:
  /// - This does not trigger a network request.
  /// - Useful for debugging or manually inspecting session state.
  /// - Works only on non-web platforms when using Dio with CookieJar.
  ///
  /// Example:
  /// ```dart
  /// final cookies = await getCookies("https://example.com");
  /// for (final cookie in cookies) {
  ///   print("${cookie.name}: ${cookie.value}");
  /// }
  /// ```
  Future<List<Cookie>> getCookies(String url) async {
    return await _cookieJar?.loadForRequest(Uri.parse(url)) ?? [];
  }
}
