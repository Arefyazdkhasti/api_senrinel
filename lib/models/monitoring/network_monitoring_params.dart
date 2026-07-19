class NetworkMonitoringParams {
  final StackTrace? stackTrace;

  /// Request information
  final String? requestUrl;
  final String? requestMethod;

  /// HTTP response information
  final int? statusCode;
  final String? apiErrorMessage;

  /// General error information
  final String? errorMessage;
  final Object? runTimeErrorType;

  /// Dio-specific diagnostic information
  final String? dioExceptionType;
  final String? dioMessage;
  final String? dioUnderlyingError;

  NetworkMonitoringParams({
    this.stackTrace,
    this.requestUrl,
    this.requestMethod,
    this.statusCode,
    this.apiErrorMessage,
    this.errorMessage,
    this.runTimeErrorType,
    this.dioExceptionType,
    this.dioMessage,
    this.dioUnderlyingError,
  });
}
