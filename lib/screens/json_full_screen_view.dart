import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../global_configs.dart';
import '../widgets/json_tree_view.dart';
import '../widgets/pretty_json_view.dart';

class JsonFullScreenView extends StatelessWidget {
  final dynamic data;
  final bool showPretty;

  const JsonFullScreenView({
    super.key,
    required this.data,
    this.showPretty = true,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(!showPretty ? 'Tree View' : 'Pretty JSON'),
          actions: [
            if (showPretty)
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy JSON',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: data));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON copied to clipboard')),
                  );
                },
              ),
          ],
        ),
        body: Container(
          padding: globalMarginAll * 4,
          child: showPretty
              ? SelectableText.rich(
                  PrettyJsonView.colorize(data),
                  style: const TextStyle(fontSize: 13),
                )
              : JsonTreeView(data: data),
        ),
      ),
    );
  }
}

// /// A full-screen JSON viewer page that can display either a tree view
// /// or pretty JSON format. Used for large payloads or zoomed-in content.
// class JsonFullScreenView extends StatelessWidget {
//   final dynamic data;
//   final bool showPretty;

//   const JsonFullScreenView({
//     super.key,
//     required this.data,
//     this.showPretty = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.ltr,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         appBar: AppBar(
//           backgroundColor: Colors.grey[900],
//           title: Text(,
//               style: const TextStyle(color: Colors.amberAccent)),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.copy),
//               tooltip: 'Copy JSON',
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(text: data));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('JSON copied to clipboard')),
//                 );
//               },
//             ),
//             IconButton(
//               icon: Icon(
//                 showPretty ? Icons.account_tree : Icons.format_align_left,
//                 color: Colors.amberAccent,
//               ),
//               tooltip: showPretty ? 'Tree View' : 'Pretty JSON',
//               onPressed: () {},
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(8),
//           child: _buildContent(),
//         ),
//       ),
//     );
//   }

//   Widget _buildContent() {
//     if (showPretty) {
//       return SelectableText.rich(
//         PrettyJsonView.colorize(data),
//         style: const TextStyle(fontSize: 13),
//       );
//     }
//     return SingleChildScrollView(
//       child: JsonTreeView(data: data),
//     );
//   }
// }
