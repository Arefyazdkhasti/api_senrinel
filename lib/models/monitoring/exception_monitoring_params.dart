class ExceptionMonitoringParams {
  /// The caught runtime exception (parsing, casting, model conversion, etc.).
  final Object exception;

  /// Stack trace captured with the exception.
  final StackTrace stackTrace;

  /// Relative or absolute request URL being processed when the error occurred.
  final String? requestUrl;

  /// String representation of [exception], for convenience when reporting.
  final String? errorMessage;

  ExceptionMonitoringParams({
    required this.exception,
    required this.stackTrace,
    this.requestUrl,
    this.errorMessage,
  });
}
