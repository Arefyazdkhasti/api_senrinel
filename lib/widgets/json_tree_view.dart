import 'package:flutter/material.dart';

/// A collapsible tree-style viewer for JSON data (Map or List).
/// Works recursively with expandable nodes.
class JsonTreeView extends StatelessWidget {
  final dynamic data;
  final int depth;

  const JsonTreeView({super.key, required this.data, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return _buildValue('null', Colors.grey);
    } else if (data is Map<String, dynamic>) {
      return _buildMap(context, data);
    } else if (data is List) {
      return _buildList(context, data);
    } else {
      return _buildValue(data);
    }
  }

  /// Displays a Map (object)
  Widget _buildMap(BuildContext context, Map<String, dynamic> map) {
    if (map.isEmpty) return _buildValue('{}', Colors.grey);

    return ListView(
      shrinkWrap: true,
      children: map.entries.map((e) {
        return JsonNodeTile(keyText: e.key, value: e.value, depth: depth);
      }).toList(),
    );
  }

  /// Displays a List (array)
  Widget _buildList(BuildContext context, List list) {
    if (list.isEmpty) return _buildValue('[]', Colors.grey);

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        list.length,
        (i) => JsonNodeTile(
          keyText: i.toString(),
          value: list[i],
          depth: depth,
          isListItem: true,
        ),
      ),
    );
  }

  Widget _buildValue(dynamic value, [Color color = Colors.white]) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 2, bottom: 2),
      child: Text(
        value.toString(),
        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color),
      ),
    );
  }
}

/// Represents one node in the tree.
class JsonNodeTile extends StatefulWidget {
  final String keyText;
  final dynamic value;
  final int depth;
  final bool isListItem;

  const JsonNodeTile({
    super.key,
    required this.keyText,
    required this.value,
    required this.depth,
    this.isListItem = false,
  });

  @override
  State<JsonNodeTile> createState() => _JsonNodeTileState();
}

class _JsonNodeTileState extends State<JsonNodeTile> {
  bool expanded = false;

  bool get isExpandable =>
      widget.value is Map<String, dynamic> || widget.value is List;

  @override
  Widget build(BuildContext context) {
    final indent = widget.depth * 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: isExpandable
              ? () => setState(() => expanded = !expanded)
              : null,
          child: Padding(
            padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isExpandable)
                  Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 14,
                    color: Colors.amberAccent,
                  )
                else
                  const SizedBox(width: 14),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: widget.isListItem
                              ? '[${widget.keyText}]'
                              : '"${widget.keyText}"',
                          style: const TextStyle(color: Colors.amberAccent),
                        ),
                        const TextSpan(text: ': '),
                        if (!isExpandable)
                          TextSpan(
                            text: _formatSimpleValue(widget.value),
                            style: const TextStyle(
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded && isExpandable)
          JsonTreeView(data: widget.value, depth: widget.depth + 1),
      ],
    );
  }

  String _formatSimpleValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    return value.toString();
  }
}
