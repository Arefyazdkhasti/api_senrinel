import 'network_monitoring_params.dart';

typedef NetworkMonitoringFunctionType =
    void Function(NetworkMonitoringParams params);

class NetworkMonitoringFunction {
  final NetworkMonitoringFunctionType function;

  NetworkMonitoringFunction({required this.function});

  void call(NetworkMonitoringParams params) {
    function(params);
  }
}
