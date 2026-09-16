import 'exception_monitoring_params.dart';

typedef ExceptionMonitoringFunctionType =
    void Function(ExceptionMonitoringParams params);

class ExceptionMonitoringFunction {
  final ExceptionMonitoringFunctionType function;

  ExceptionMonitoringFunction({required this.function});

  void call(ExceptionMonitoringParams params) {
    function(params);
  }
}
