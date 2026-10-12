import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSignaturePage extends StatefulWidget {
  final String title;

  const AppSignaturePage({
    super.key,
    this.title = '手寫簽名', // 👈 預設通用標題
  });

  @override
  State<AppSignaturePage> createState() => _AppSignaturePageState();
}

class _AppSignaturePageState extends State<AppSignaturePage> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  static const Color _themePurple = Color(0xFF8C86FF);

  @override
  void initState() {
    super.initState();
    // 進入時強制切換成橫向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // 離開時還原成直向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  Future<void> _exportSignature() async {
    if (_strokes.isEmpty && _currentStroke.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const canvasSize = Size(600, 300);

    // 繪製白色底
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height), bgPaint);

    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0
      ..isAntiAlias = true;

    final allStrokes = [..._strokes];
    if (_currentStroke.isNotEmpty) {
      allStrokes.add(_currentStroke);
    }

    for (final stroke in allStrokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();

    if (mounted) {
      Navigator.pop(context, bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _themePurple,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        body: Column(
          children: [
            // 頂部導覽列
            Container(
              color: _themePurple,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 返回按鈕
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // 標題
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // 清空按鈕
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _clear,
                            child: const Text(
                              '清空簽名',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 下方畫布手勢繪圖區
            Expanded(
              child: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        setState(() {
                          _currentStroke = [details.localPosition];
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentStroke.add(details.localPosition);
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _strokes.add(List.from(_currentStroke));
                          _currentStroke.clear();
                        });
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                        ),
                        size: Size.infinite,
                      ),
                    ),

                    // 右下角「完成」按鈕
                    Positioned(
                      right: 24,
                      bottom: 16,
                      child: ElevatedButton(
                        onPressed: _exportSignature,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB5ACFE),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                        ),
                        child: const Text(
                          '完成',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    for (int i = 0; i < currentStroke.length - 1; i++) {
      canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}