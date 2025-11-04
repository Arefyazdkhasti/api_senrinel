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

class _DebugOverlayWidgetState extends State<DebugOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final DebugLogController controller;
  Offset position = const Offset(0, 200);
  bool isExpanded = false;
  bool isRightSide = false;

  double get _overlayWidth => isExpanded ? 110 : 48;

  @override
  void initState() {
    super.initState();
    controller = Get.put(DebugLogController(), permanent: true);
  }

  void _stickToEdge(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? _overlayWidth;

    final isRight = position.dx > screenWidth / 2;
    final edgeX = isRight ? screenWidth - width : 0.0;

    setState(() {
      position = Offset(edgeX, position.dy);
      isRightSide = isRight;
    });
  }

  void _handleTap() {
    if (!isExpanded) {
      setState(() => isExpanded = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => isExpanded = false);
      });
    } else {
      controller.isLogPageOpened.value = true;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const DebugPage()))
          .then((_) {
            controller.isLogPageOpened.value = false;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.of(context).padding;
    final screenHeight = MediaQuery.of(context).size.height;

    return Obx(() {
      if (controller.isLogPageOpened.value) {
        return const SizedBox.shrink();
      }

      final errorCount = controller.logs.where((e) => e.isError).length;

      return Positioned(
        left: isRightSide ? null : position.dx,
        right: isRightSide ? 0 : null,
        top: position.dy.clamp(
          padding.top + 8,
          screenHeight - padding.bottom - 80,
        ),
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              position += details.delta;
            });
          },
          onPanEnd: (_) => _stickToEdge(context),
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: globalMarginAll * 2,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isRightSide ? 12 : 0),
                bottomLeft: Radius.circular(isRightSide ? 12 : 0),
                topRight: Radius.circular(isRightSide ? 0 : 12),
                bottomRight: Radius.circular(isRightSide ? 0 : 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isExpanded
                  ? Row(
                      key: const ValueKey('expanded'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRightSide)
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        Icon(Icons.bug_report, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${controller.logs.length}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
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
                        if (!isRightSide)
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                      ],
                    )
                  : Icon(
                      isRightSide
                          ? Icons.arrow_back_ios_new_rounded
                          : Icons.arrow_forward_ios_rounded,
                      key: const ValueKey('collapsed'),
                      size: 20,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      );
    });
  }
}
