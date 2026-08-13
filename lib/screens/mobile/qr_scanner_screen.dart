import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../state/app_store.dart';
import 'child_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late final MobileScannerController? _controller;
  bool _isDesktop = false;
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (!_isDesktop) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _processCode(String code) {
    if (_scanned) return;
    _scanned = true;
    _controller?.stop();

    final store = AppScope.of(context);
    final child = store.children.where((c) => c.qrCode == code).firstOrNull;

    if (child != null) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChildDetailScreen(childId: child.id)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Không tìm thấy trẻ với mã: $code')),
            ],
          ),
          backgroundColor: const Color(0xFFB42318),
          action: SnackBarAction(
            label: 'Quét lại',
            textColor: Colors.white,
            onPressed: () {
              _scanned = false;
              _controller?.start();
            },
          ),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _scanned = false;
          _controller?.start();
        }
      });
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    _processCode(barcode.rawValue!);
  }

  void _showManualInputDialog() {
    final controller = TextEditingController(text: 'CH-QR-0001');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập mã QR thủ công'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Mã QR (Ví dụ: CH-QR-0001)',
            prefixIcon: Icon(Icons.qr_code_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _processCode(controller.text.trim());
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét mã QR thẻ y tế', style: TextStyle(color: Colors.white)),
        actions: [
          if (!_isDesktop) ...[
            IconButton(
              icon: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _torchOn ? Colors.yellow : Colors.white,
              ),
              tooltip: 'Đèn flash',
              onPressed: () {
                _controller?.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
              tooltip: 'Đổi camera',
              onPressed: () => _controller?.switchCamera(),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (_isDesktop)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF18794E), size: 72),
                    const SizedBox(height: 16),
                    const Text(
                      'Mô phỏng máy quét QR (Desktop Windows)',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trên Android/iOS/Web, camera thực tế sẽ được bật.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _processCode('CH-QR-0001'),
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: const Text('Quét thử mã CH-QR-0001'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF18794E)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      label: const Text('Nhập mã thủ công', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30)),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            MobileScanner(
              controller: _controller!,
              onDetect: _handleDetection,
            ),
            _ScannerOverlay(),
          ],

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withAlpha(220), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isDesktop) ...[
                    const Icon(Icons.qr_code_2_rounded, color: Colors.white70, size: 36),
                    const SizedBox(height: 10),
                    const Text(
                      'Đưa mã QR thẻ y tế của trẻ vào khung',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hệ thống sẽ tự động nhận dạng và mở hồ sơ',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.keyboard_outlined, color: Colors.white70),
                      label: const Text('Nhập mã thủ công', style: TextStyle(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scanSize = MediaQuery.sizeOf(context).width * 0.65;
    return CustomPaint(
      painter: _OverlayPainter(scanSize: scanSize),
      child: SizedBox.expand(
        child: Center(
          child: SizedBox(
            width: scanSize,
            height: scanSize,
            child: const Stack(
              children: [
                Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
                Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
                Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
                Positioned(bottom: 0, right: 0, child: _Corner(top: false, left: false)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter({required this.scanSize});
  final double scanSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(160);
    final center = Offset(size.width / 2, size.height / 2);
    final halfScan = scanSize / 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, center.dy - halfScan), paint);
    canvas.drawRect(Rect.fromLTWH(0, center.dy + halfScan, size.width, size.height - center.dy - halfScan), paint);
    canvas.drawRect(Rect.fromLTWH(0, center.dy - halfScan, center.dx - halfScan, scanSize), paint);
    canvas.drawRect(Rect.fromLTWH(center.dx + halfScan, center.dy - halfScan, size.width - center.dx - halfScan, scanSize), paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => false;
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _CornerPainter(top: top, left: left)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.top, required this.left});
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF18794E)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final h = size.height;
    final w = size.width;

    if (top && left) {
      canvas.drawLine(Offset(0, h), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
    } else if (top && !left) {
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (!top && left) {
      canvas.drawLine(const Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(w, h), Offset(0, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
