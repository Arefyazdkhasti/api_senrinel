import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';

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
  void init({required String baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
        sendTimeout: const Duration(milliseconds: 30000),
      ),
    );

    if (!kReleaseMode) {
      if (!Get.isRegistered<DebugLogController>()) {
        Get.put(DebugLogController(), permanent: true);
      }
      _dio.interceptors.add(DebugInterceptor());
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
}
