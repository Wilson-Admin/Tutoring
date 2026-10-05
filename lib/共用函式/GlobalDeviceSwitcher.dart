import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';
import 'package:tutoring/main.dart';

/// 📱 Debug 模式彈出所有可切換的裝置選單
/// 📱 Debug 模式彈出所有可切換的裝置選單
void showGlobalDevicePreviewSheet([BuildContext? context]) {
  final controller = DevicePreview.maybeController;
  if (controller == null) return;

  final navContext = navigatorKey.currentContext ?? context;
  if (navContext == null) return;

  // 1. 取得實體硬體真實螢幕的 MediaQueryData，避免彈出選單受虛擬縮放影響
  final realView = WidgetsBinding.instance.platformDispatcher.views.first;
  final realMediaQuery = MediaQueryData.fromView(realView);

  showModalBottomSheet(
    context: navContext,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return MediaQuery(
        data: realMediaQuery.copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '全域螢幕切換',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          // 👈 還原裝置（文字按鈕，點擊即回復實體機原始比例並關閉 Sheet）
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text(
                              '還原裝置',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              await controller.reset(); // 恢復原生無模擬狀態
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: DevicePresets.all.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final preset = DevicePresets.all[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              preset.name.toLowerCase().contains('ipad') ||
                                  preset.name.toLowerCase().contains('tablet')
                                  ? Icons.tablet_mac
                                  : Icons.phone_iphone,
                              color: Colors.black54,
                            ),
                            title: Text(
                              preset.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            onTap: () async {
                              await controller.applyPreset(preset);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}

/// 🎯 全域懸浮球 Widget（鎖定實體真實設備比例）
class GlobalDeviceSwitcherOverlay extends StatefulWidget {
  final Widget child;
  const GlobalDeviceSwitcherOverlay({super.key, required this.child});

  @override
  State<GlobalDeviceSwitcherOverlay> createState() => _GlobalDeviceSwitcherOverlayState();
}

class _GlobalDeviceSwitcherOverlayState extends State<GlobalDeviceSwitcherOverlay> {
  double _right = 16.0;
  double _bottom = 100.0;

  @override
  Widget build(BuildContext context) {
    final realView = WidgetsBinding.instance.platformDispatcher.views.first;
    final realMediaQuery = MediaQueryData.fromView(realView);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned(
            right: _right,
            bottom: _bottom,
            child: MediaQuery(
              data: realMediaQuery.copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _right -= details.delta.dx;
                    _bottom -= details.delta.dy;
                  });
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showGlobalDevicePreviewSheet(),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.amber, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.devices, color: Colors.amber, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '裝置切換',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}