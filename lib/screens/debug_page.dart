import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/api_service.dart';
import '../controllers/debug_overlay/debug_log_controller.dart';
import '../global_configs.dart';
import '../widgets/json_tree_view.dart';
import '../widgets/search_input_field.dart';
import 'json_full_screen_view.dart';
import '../widgets/pretty_json_view.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  bool showPrettyJson = true;

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

  final controller = Get.find<DebugLogController>();

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('API Debug Logs'),
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
        bottomSheet: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          child: SearchInputCustomTextField(
            searchTextEditingController: TextEditingController(),
            search: controller.filterLogs,
            searchFocus: FocusNode(),
          ),
        ),
        body: Obx(() {
          return controller.logs.isEmpty
              ? const Center(child: Text('No logs found!'))
              : ListView.separated(
                  itemCount: controller.logs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = controller.logs[index];
                    return ExpansionTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              methodType(log.method),
                              const SizedBox(width: 8),
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
                              requestStatusCode(log.statusCode ?? 0),
                              const SizedBox(width: 8),
                              Text(
                                '${DateTime.now().difference(log.timestamp).inSeconds}s ago',
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '| Duration: ${log.duration?.inMilliseconds ?? 0}ms',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      (log.duration?.inMilliseconds ?? 0) > 3000
                                      ? Colors.red
                                      : Colors.grey,
                                ),
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
