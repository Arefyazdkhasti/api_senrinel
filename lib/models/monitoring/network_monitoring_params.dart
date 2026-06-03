class NetworkMonitoringParams {
  final StackTrace? stackTrace;
  final String? requestUrl;
  final int? statusCode;
  final String? apiErrorMessage;
  final String? errorMessage;
  final Object? runTimeErrorType;

  NetworkMonitoringParams({
    this.stackTrace,
    this.requestUrl,
    this.statusCode,
    this.apiErrorMessage,
    this.errorMessage,
    this.runTimeErrorType,
  });

}
