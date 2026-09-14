import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/visit_clock.dart';
import '../../booking/domain/booking_models.dart';

class PassDownload {
  static Future<Uint8List> bytes(VisitBooking booking) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'KEEKOT THANGAL',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#064E3B'),
              ),
            ),
            pw.Text('Chavakkad, Kerala | Visitor pass'),
            pw.SizedBox(height: 24),
            pw.Text(booking.status.toUpperCase()),
            pw.SizedBox(height: 8),
            pw.Text(
              booking.reference,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(VisitClock.dayLabel(booking.visitDate)),
            pw.Text(
              '${VisitClock.timeLabel(booking.startTime)} - ${VisitClock.timeLabel(booking.endTime)} (India time)',
            ),
            pw.SizedBox(height: 8),
            pw.Text('${booking.visitors} visitor(s)'),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: booking.qrToken,
                width: 160,
                height: 160,
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Show this pass to entry staff. Keep this QR private. Entry staff verify current booking status when you arrive.',
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static Future<void> download(VisitBooking booking) async => Printing.sharePdf(
    bytes: await bytes(booking),
    filename: '${booking.reference}.pdf',
  );
}
