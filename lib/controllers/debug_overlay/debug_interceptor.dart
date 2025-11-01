import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../../models/debug_log_entry.dart';
import '../api_service.dart';
import 'debug_log_controller.dart';

class DebugInterceptor extends Interceptor {
  final _controller = Get.find<DebugLogController>();
  final _pendingLogs = <String, DebugLogEntry>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = _generateId();
    options.extra['debug_id'] = id;

    final entry = DebugLogEntry(
      id: id,
      timestamp: DateTime.now(),
      method: stringToHttpMethod(options.method.toLowerCase()),
      url: options.uri.toString(),
      baseUrl: options.baseUrl,
      requestData: _toMap(options.data),
      queryParameters: options.queryParameters,
    );

    _pendingLogs[id] = entry;
    _controller.addLog(entry);
    handler.next(options);
  }

  @override
  void onResponse(dio.Response response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra['debug_id'];
    final entry = _pendingLogs.remove(id);

    if (entry != null) {
      final updated = DebugLogEntry(
        id: entry.id,
        timestamp: entry.timestamp,
        method: entry.method,
        url: entry.url,
        baseUrl: entry.baseUrl,
        requestData: entry.requestData,
        queryParameters: entry.queryParameters,
        statusCode: response.statusCode,
        responseData: response.data,
        duration: DateTime.now().difference(entry.timestamp),
      );
      _controller.updateLog(entry.id, updated);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.requestOptions.extra['debug_id'];
    final entry = _pendingLogs.remove(id);

    if (entry != null) {
      final updated = DebugLogEntry(
        id: entry.id,
        timestamp: entry.timestamp,
        method: entry.method,
        url: entry.url,
        baseUrl: entry.baseUrl,
        requestData: entry.requestData,
        queryParameters: entry.queryParameters,
        statusCode: err.response?.statusCode,
        isError: true,
        errorMessage: err.message,
        responseData: err.response?.data,
        duration: DateTime.now().difference(entry.timestamp),
      );
      _controller.updateLog(entry.id, updated);
    }
    handler.next(err);
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    try {
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {'raw': data.toString()};
    }
  }
}
