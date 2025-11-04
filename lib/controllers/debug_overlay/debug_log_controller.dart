import 'package:get/get.dart';

import '../../models/debug_log_entry.dart';

enum LogStatusFilter {
  all,
  success, // 2xx
  clientError, // 4xx
  serverError, // 5xx
  errorOnly, // has error message
}

class DebugLogController extends GetxController {
  /// Raw logs (always contains all)
  final _allLogs = <DebugLogEntry>[].obs;

  /// Filtered visible logs
  final logs = <DebugLogEntry>[].obs;

  /// Search and filter states
  final searchQuery = ''.obs;
  final selectedMethod = ''.obs; // empty = all
  final statusFilter = LogStatusFilter.all.obs;

  /// Is Log Page opened
  /// used to show/hide floating overlay widget
  final RxBool isLogPageOpened = false.obs;

  @override
  void onInit() {
    super.onInit();
    everAll([searchQuery, selectedMethod, statusFilter], (_) => _applyFilter());
  }

  // ──────────────────────────────────────────────
  // CRUD LOGS
  // ──────────────────────────────────────────────

  void addLog(DebugLogEntry entry) {
    _allLogs.insert(0, entry);
    if (_allLogs.length > 200) _allLogs.removeLast();
    _applyFilter();
  }

  void updateLog(String id, DebugLogEntry updated) {
    final index = _allLogs.indexWhere((e) => e.id == id);
    if (index != -1) {
      _allLogs[index] = updated;
      _applyFilter();
    }
  }

  void clearLogs() {
    _allLogs.clear();
    logs.clear();
  }

  // ──────────────────────────────────────────────
  // FILTER CONTROLS
  // ──────────────────────────────────────────────

  void setSearch(String query) =>
      searchQuery.value = query.trim().toLowerCase();
  void setMethod(String? method) =>
      selectedMethod.value = method?.toUpperCase() ?? '';
  void setStatusFilter(LogStatusFilter? filter) =>
      statusFilter.value = filter ?? LogStatusFilter.all;

  void resetFilters() {
    searchQuery.value = '';
    selectedMethod.value = '';
    statusFilter.value = LogStatusFilter.all;
  }

  // ──────────────────────────────────────────────
  // INTERNAL FILTER LOGIC
  // ──────────────────────────────────────────────

  void _applyFilter() {
    final query = searchQuery.value;
    final method = selectedMethod.value;
    final status = statusFilter.value;

    final filtered = _allLogs.where((log) {
      // Text match
      final searchable = [
        log.url,
        log.method,
        log.statusCode?.toString(),
        log.requestData?.toString(),
        log.responseData?.toString(),
        log.errorMessage,
      ].join(' ').toLowerCase();

      if (query.isNotEmpty && !searchable.contains(query)) return false;

      // Method filter
      if (method.isNotEmpty &&
          method != 'ALL' &&
          log.method.name.toUpperCase() != method) {
        return false;
      }

      // Status filter
      if (!_matchStatusFilter(log, status)) return false;

      return true;
    }).toList();

    logs.assignAll(filtered);
  }

  bool _matchStatusFilter(DebugLogEntry log, LogStatusFilter filter) {
    final code = log.statusCode ?? 0;

    switch (filter) {
      case LogStatusFilter.all:
        return true;
      case LogStatusFilter.success:
        return code >= 200 && code < 300;
      case LogStatusFilter.clientError:
        return code >= 400 && code < 500;
      case LogStatusFilter.serverError:
        return code >= 500;
      case LogStatusFilter.errorOnly:
        return log.isError || log.errorMessage != null;
    }
  }
}
