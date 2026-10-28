import '../../../core/localization/app_language.dart';
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
    scrollable: true,
    title: const AppText('Scan visitor pass'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppText(
            'Point the camera at the QR code. A valid pass confirms the visit automatically.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: (MediaQuery.sizeOf(context).width - 88).clamp(180.0, 420.0),
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: AppText(
                        'Camera unavailable. Allow camera access in your browser settings and try again, or close this scanner and paste the QR token.',
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
        child: const AppText('Close scanner'),
      ),
    ],
  );
}
