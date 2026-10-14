import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Closing this dialog disposes the camera before verifying the pass.
class PassScannerDialog extends StatefulWidget {
  const PassScannerDialog({super.key});

  @override
  State<PassScannerDialog> createState() => _PassScannerDialogState();
}

class _PassScannerDialogState extends State<PassScannerDialog> {
  final controller = MobileScannerController(
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );
  bool captured = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Scan visitor pass'),
    content: SizedBox(
      width: 420,
      height: (MediaQuery.sizeOf(context).height * 0.65)
          .clamp(180.0, 480.0)
          .toDouble(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Point the camera at the QR code. A valid pass confirms the visit automatically.',
          ),
          const SizedBox(height: 16),
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (captured || !mounted) return;
                    for (final barcode in capture.barcodes) {
                      final value = barcode.rawValue?.trim();
                      if (value == null || value.isEmpty) continue;
                      captured = true;
                      Navigator.of(context).pop(value);
                      break;
                    }
                  },
                  errorBuilder: (context, error) => const ColoredBox(
                    color: Color(0xFFF2F5F3),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Camera unavailable. Allow camera access in your browser settings and try again, or close this scanner and paste the QR token.',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close scanner'),
      ),
    ],
  );
}
