import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../global_configs.dart';
import '../controllers/api_service.dart';
import '../controllers/debug_overlay/debug_log_controller.dart';
import '../widgets/json_tree_view.dart';
import '../widgets/pretty_json_view.dart';
import 'json_full_screen_view.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final controller = Get.find<DebugLogController>();
  bool showPrettyJson = true;

  final searchController = TextEditingController();
  final searchFocus = FocusNode();

  Widget methodType(HttpMethod method) {
    var theme = Theme.of(context);
    Color methodColor;

    switch (method) {
      case HttpMethod.get:
        methodColor = Colors.blue;
      case HttpMethod.post:
        methodColor = Colors.yellow;
      case HttpMethod.put:
        methodColor = Colors.orange;
      case HttpMethod.patch:
        methodColor = Colors.orange;
      case HttpMethod.delete:
        methodColor = Colors.red;
      default:
        methodColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: methodColor.withValues(alpha: 0.3),
        border: Border.all(color: methodColor),
        borderRadius: globalBorderRadius * 2,
      ),
      padding: symmetricMargin * 2,
      child: Text(method.name.toUpperCase(), style: theme.textTheme.bodySmall),
    );
  }

  Widget requestStatusCode(int statusCode) {
    var theme = Theme.of(context);
    Color statusColor;

    switch (statusCode) {
      case >= 200 && < 300:
        statusColor = Colors.green.shade600; // Success
        break;
      case >= 300 && < 400:
        statusColor = Colors.blue.shade600; // Redirect
        break;
      case >= 400 && < 500:
        statusColor = Colors.orange.shade700; // Client error
        break;
      case >= 500 && < 600:
        statusColor = Colors.red.shade700; // Server error
        break;
      default:
        statusColor = Colors.grey.shade500; // Unknown or null
    }

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: globalBorderRadius * 2,
        border: Border.all(color: statusColor),
      ),
      padding: symmetricMargin * 2,
      child: Text(statusCode.toString(), style: theme.textTheme.bodySmall),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.resetFilters(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('API Debug Logs'),
          forceMaterialTransparency: true,
          actions: [
            IconButton(
              icon: Icon(
                showPrettyJson ? Icons.account_tree : Icons.format_align_left,
              ),
              tooltip: showPrettyJson ? 'Tree View' : 'Pretty JSON',
              onPressed: () => setState(() => showPrettyJson = !showPrettyJson),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: controller.clearLogs,
            ),
          ],
        ),
        body: Obx(() {
          return Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: globalMargin * 3,
                child: SearchInputCustomTextField(
                  searchTextEditingController: searchController,
                  search: (query) => controller.setSearch(query),
                  searchFocus: searchFocus,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: globalMargin * 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDropdownWrapper(
                        child: DropdownButton<String>(
                          value: controller.selectedMethod.value.isEmpty
                              ? null
                              : controller.selectedMethod.value,
                          hint: const Text('Method'),
                          underline: const SizedBox(),
                          icon: const SizedBox(),
                          items:
                              ['ALL', 'GET', 'POST', 'PATCH', 'PUT', 'DELETE']
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            controller.setMethod(value);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdownWrapper(
                        child: DropdownButton<LogStatusFilter>(
                          value: controller.statusFilter.value,
                          underline: const SizedBox(),
                          icon: const SizedBox(),
                          items: LogStatusFilter.values
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.name),
                                ),
                              )
                              .toList(),
                          onChanged: (filter) {
                            controller.setStatusFilter(filter);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: controller.logs.isEmpty
                    ? const Center(child: Text('No logs found!'))
                    : ListView.separated(
                        itemCount: controller.logs.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final log = controller.logs[index];
                          return ExpansionTile(
                            backgroundColor: Colors.transparent,
                            collapsedBackgroundColor: Colors.transparent,
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    methodType(log.method),
                                    const SizedBox(width: 8),
                                    requestStatusCode(log.statusCode ?? 0),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log.url.replaceAll(log.baseUrl, ''),
                                        style: TextStyle(
                                          color: log.isError
                                              ? Colors.red
                                              : (log.statusCode != null &&
                                                        log.statusCode! >= 400
                                                    ? Colors.orange
                                                    : Colors.green),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateTime.now().difference(log.timestamp).inSeconds}s ago',
                                        ),
                                        Text(
                                          ' | Duration: ${log.duration?.inMilliseconds ?? 0}ms',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    (log
                                                                .duration
                                                                ?.inMilliseconds ??
                                                            0) >
                                                        3000
                                                    ? Colors.red
                                                    : Colors.grey,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            children: [
                              if (log.requestData != null)
                                _buildSection('Request', log.requestData),
                              _buildSection('Response', log.responseData),
                              if (log.errorMessage != null)
                                _buildSection('Error', log.errorMessage),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSection(String title, dynamic content) {
    return Container(
      width: double.infinity,
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8),
      child: JsonViewerWidget(
        data: content,
        title: title,
        showPretty: showPrettyJson,
      ),
    );
  }
}

/// A widget that displays JSON data with consistent styling and scrolling.
/// Supports both structured (tree) and formatted (pretty) views.
class JsonViewerWidget extends StatelessWidget {
  final dynamic data;
  final String title;
  final bool showPretty;

  const JsonViewerWidget({
    super.key,
    required this.data,
    required this.title,
    this.showPretty = false,
  });

  @override
  Widget build(BuildContext context) {
    final jsonData = _parseJsonData(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: _buildViewer(jsonData, context),
        ),
      ],
    );
  }

  Widget _buildViewer(dynamic jsonData, BuildContext context) {
    if (jsonData == null) return _buildNullViewer();

    if (showPretty) return PrettyJsonView(jsonData);

    if (jsonData is Map || jsonData is List) {
      return Stack(
        children: [
          _buildStructuredJsonViewer(jsonData),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        JsonFullScreenView(data: jsonData, showPretty: false),
                  ),
                );
              },
              icon: const Icon(Icons.zoom_out_map, size: 20),
            ),
          ),
        ],
      );
    }

    return _buildFallbackViewer(jsonData);
  }

  Widget _buildNullViewer() => Padding(
    padding: globalMargin * 2,
    child: const Text(
      'null',
      style: TextStyle(
        color: Colors.grey,
        fontStyle: FontStyle.italic,
        fontSize: 11,
      ),
    ),
  );

  Widget _buildStructuredJsonViewer(dynamic jsonData) => SingleChildScrollView(
    padding: const EdgeInsets.all(8),
    child: JsonTreeView(data: jsonData),
  );

  Widget _buildFallbackViewer(dynamic data) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      data.toString(),
      style: const TextStyle(
        fontFamily: 'monospace',
        color: Colors.white,
        fontSize: 11,
      ),
    ),
  );

  dynamic _parseJsonData(dynamic data) {
    if (data is String && _looksLikeJson(data)) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  bool _looksLikeJson(String data) {
    final trimmed = data.trim();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}

class SearchInputCustomTextField extends StatefulWidget {
  final TextEditingController searchTextEditingController;
  final FocusNode searchFocus;
  final Function(String) search;

  const SearchInputCustomTextField({
    super.key,
    required this.searchTextEditingController,
    required this.searchFocus,
    required this.search,
  });

  @override
  State<SearchInputCustomTextField> createState() =>
      _SearchInputCustomTextFieldState();
}

class _SearchInputCustomTextFieldState
    extends State<SearchInputCustomTextField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.searchTextEditingController;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: theme.colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        focusNode: widget.searchFocus,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: 'Search logs...',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  splashRadius: 18,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    widget.search('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {}); // refresh suffix icon visibility
          widget.search(value);
        },
      ),
    );
  }
}

Widget _buildDropdownWrapper({required Widget child}) {
  return Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      // color: Colors.grey.shade900.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey.shade400.withValues(alpha: 0.8),
        width: 1,
      ),
    ),
    child: child,
  );
}
