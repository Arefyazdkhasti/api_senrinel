import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../global_configs.dart';
import '../controllers/debug_overlay/debug_log_controller.dart';
import '../screens/debug_page.dart';

class DebugOverlayWidget extends StatefulWidget {
  const DebugOverlayWidget({super.key});

  @override
  State<DebugOverlayWidget> createState() => _DebugOverlayWidgetState();
}

class _DebugOverlayWidgetState extends State<DebugOverlayWidget> {
  Offset position = const Offset(20, 200);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put<DebugLogController>(DebugLogController());
    var theme = Theme.of(context);

    return Obx(() {
      final errorCount = controller.logs.where((e) => e.isError).length;
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() => position += details.delta);
          },
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DebugPage()));
          },
          child: Container(
            padding: globalMarginAll * 2,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: globalBorderRadius * 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bug_report,
                  color: theme.colorScheme.surface,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${controller.logs.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.surface,
                  ),
                ),
                if (errorCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($errorCount⚠️)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
