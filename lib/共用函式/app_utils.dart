import 'package:flutter/widgets.dart';

/// 判斷當前裝置是否為平板（最短邊 >= 600 視為平板）
bool get isTablet {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final data = MediaQueryData.fromView(view);
  return data.size.shortestSide >= 600;
}