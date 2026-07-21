import '../controllers/api_service.dart';

class DebugLogEntry {
  final String id;
  final DateTime timestamp;
  final HttpMethod method;
  final String url;
  final String baseUrl;
  final Map<String, dynamic>? requestData;
  final Map<String, dynamic>? queryParameters;
  final int? statusCode;
  final dynamic responseData;
  final bool isError;
  final String? errorMessage;
  final Duration? duration;
  final String curl;
  final Map<String, dynamic>? requestHeaders;
  final Map<String, dynamic>? responseHeaders;

  DebugLogEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    required this.baseUrl,
    required this.curl,
    this.requestData,
    this.queryParameters,
    this.statusCode,
    this.responseData,
    this.isError = false,
    this.errorMessage,
    this.duration,
    this.requestHeaders,
    this.responseHeaders,
  });
}
