import 'dart:convert';

import 'package:flutter/material.dart';

import '../screens/json_full_screen_view.dart';

/// Displays syntax-highlighted pretty JSON text.
class PrettyJsonView extends StatelessWidget {
  final dynamic jsonObj;
  const PrettyJsonView(this.jsonObj, {super.key});

  @override
  Widget build(BuildContext context) {
    final formatted = _formatJson(jsonObj);
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          scrollDirection: Axis.horizontal,
          child: SelectableText.rich(
            colorize(formatted),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JsonFullScreenView(data: formatted),
                ),
              );
            },
            icon: const Icon(Icons.zoom_out_map, size: 20),
          ),
        ),
      ],
    );
  }

  String _formatJson(dynamic data) {
    try {
      if (data is String) {
        final parsed = jsonDecode(data);
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(parsed);
      }
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  static TextSpan colorize(String json) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'("[^"]*")|(\b\d+(\.\d+)?\b)|(true|false|null)',
      caseSensitive: false,
    );
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(json)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: json.substring(lastMatchEnd, match.start)));
      }

      final str = match.group(1);
      final num = match.group(2);
      final boolOrNull = match.group(4);

      if (str != null) {
        spans.add(
          TextSpan(
            text: str,
            style: const TextStyle(color: Colors.greenAccent),
          ),
        );
      } else if (num != null) {
        spans.add(
          TextSpan(
            text: num,
            style: const TextStyle(color: Colors.orangeAccent),
          ),
        );
      } else if (boolOrNull != null) {
        spans.add(
          TextSpan(
            text: boolOrNull,
            style: const TextStyle(color: Colors.purpleAccent),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < json.length) {
      spans.add(TextSpan(text: json.substring(lastMatchEnd)));
    }

    return TextSpan(children: spans);
  }
}
