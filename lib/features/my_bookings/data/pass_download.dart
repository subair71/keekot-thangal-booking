import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/visit_clock.dart';
import '../../booking/domain/booking_models.dart';

class PassDownload {
  static Future<Uint8List> bytes(VisitBooking booking) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans.ttf'),
    );
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'KEEKKOTT SAYYID ATTAKOYA THANGAL MAQAM',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#13382D'),
              ),
            ),
            pw.Text('Chavakkad, Kerala | Visitor pass'),
            pw.SizedBox(height: 10),
            pw.Text(booking.status.toUpperCase()),
            pw.SizedBox(height: 8),
            pw.Text('Valid for the date and slot below only.'),
            pw.SizedBox(height: 8),
            pw.Text(
              booking.reference,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text(VisitClock.dayLabel(booking.visitDate)),
            pw.Text(
              '${VisitClock.timeLabel(booking.startTime)} - ${VisitClock.timeLabel(booking.endTime)} (India time)',
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Token number: ${booking.tokenLabel}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              booking.visitorName,
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 8),
            pw.Text('${booking.visitors} visitor(s)'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Visitor Phone Number: ${booking.visitorPhoneDisplay}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            if (booking.bookedByLabel.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                'Booked by: ${booking.bookedByLabel}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: booking.qrToken,
                width: 112,
                height: 112,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Show this pass to entry staff. Keep this QR private. Entry staff verify current booking status when you arrive.',
              style: const pw.TextStyle(fontSize: 9),
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
