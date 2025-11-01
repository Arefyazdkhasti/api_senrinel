import 'package:get/get.dart';

import '../../models/debug_log_entry.dart';

class DebugLogController extends GetxController {
  /// All logs (unfiltered)
  final _allLogs = <DebugLogEntry>[].obs;

  /// Currently displayed logs (filtered or not)
  final logs = <DebugLogEntry>[].obs;

  /// Current search/filter query
  final _filterQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_filterQuery, (_) => _applyFilter());
  }

  /// Add a new log entry (and auto-limit to 200)
  void addLog(DebugLogEntry entry) {
    _allLogs.insert(0, entry);
    if (_allLogs.length > 200) _allLogs.removeLast();
    _applyFilter();
  }

  /// Clear all logs
  void clearLogs() {
    _allLogs.clear();
    logs.clear();
  }

  /// Update an existing log entry by ID
  void updateLog(String id, DebugLogEntry updated) {
    final index = _allLogs.indexWhere((e) => e.id == id);
    if (index != -1) {
      _allLogs[index] = updated;
      _applyFilter();
    }
  }

  /// Apply text-based filter (search)
  void filterLogs(String query) {
    _filterQuery.value = query.trim().toLowerCase();
  }

  /// Internal function to refresh the filtered list
  void _applyFilter() {
    final q = _filterQuery.value;
    if (q.isEmpty) {
      logs.assignAll(_allLogs);
      return;
    }

    logs.assignAll(
      _allLogs.where((log) {
        final text = [
          log.url,
          log.method,
          log.statusCode?.toString(),
          log.requestData?.toString(),
          log.responseData?.toString(),
          log.errorMessage,
        ].join(' ').toLowerCase();

        return text.contains(q);
      }),
    );
  }
}
