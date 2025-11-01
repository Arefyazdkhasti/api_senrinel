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

  DebugLogEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    required this.baseUrl,
    this.requestData,
    this.queryParameters,
    this.statusCode,
    this.responseData,
    this.isError = false,
    this.errorMessage,
    this.duration,
  });
}
