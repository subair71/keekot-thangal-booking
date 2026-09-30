import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/visit_clock.dart';
import '../../booking/domain/booking_models.dart';

class BookingExport {
  static const headers = [
    'Visit date (IST)',
    'Booking reference',
    'Visitor name',
    'Address',
    'Mobile (masked)',
    'Time slot (IST)',
    'Visitors',
    'Status',
    'Token numbers',
  ];

  static List<List<String>> rows(String day, List<VisitBooking> bookings) {
    final selected = bookings.where((b) => b.visitDate == day).toList()
      ..sort((a, b) {
        final time = a.startAt.compareTo(b.startAt);
        if (time != 0) return time;
        final token = (a.tokenStart ?? 2147483647).compareTo(
          b.tokenStart ?? 2147483647,
        );
        return token == 0 ? a.reference.compareTo(b.reference) : token;
      });
    return selected
        .map(
          (b) => [
            b.visitDate,
            b.reference,
            b.visitorName,
            b.visitorAddress,
            b.phoneMasked,
            '${b.startTime} - ${b.endTime}',
            '${b.visitors}',
            b.status,
            b.tokenLabel,
          ],
        )
        .toList();
  }

  static String xml(String value) => value
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static Uint8List excel(String day, List<VisitBooking> bookings) {
    final data = [headers, ...rows(day, bookings)];
    final sheet = StringBuffer(
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols><col min="1" max="1" width="18" customWidth="1"/><col min="2" max="2" width="34" customWidth="1"/><col min="3" max="3" width="28" customWidth="1"/><col min="4" max="4" width="48" customWidth="1"/><col min="5" max="6" width="24" customWidth="1"/><col min="7" max="9" width="16" customWidth="1"/></cols><sheetData>''',
    );
    for (var r = 0; r < data.length; r++) {
      sheet.write('<row r="${r + 1}">');
      for (var c = 0; c < headers.length; c++) {
        final ref = '${String.fromCharCode(65 + c)}${r + 1}';
        if (r > 0 && c == 6) {
          sheet.write('<c r="$ref" s="0"><v>${data[r][c]}</v></c>');
        } else {
          // Inline strings prevent spreadsheet formula execution in visitor input.
          sheet.write(
            '<c r="$ref" s="${r == 0 ? 1 : 0}" t="inlineStr"><is><t xml:space="preserve">${xml(data[r][c])}</t></is></c>',
          );
        }
      }
      sheet.write('</row>');
    }
    sheet.write(
      '</sheetData><autoFilter ref="A1:I${data.length}"/></worksheet>',
    );
    final files = <String, String>{
      '[Content_Types].xml':
          '''<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>''',
      '_rels/.rels':
          '''<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>''',
      'xl/workbook.xml':
          '''<?xml version="1.0"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Bookings $day" sheetId="1" r:id="rId1"/></sheets></workbook>''',
      'xl/_rels/workbook.xml.rels':
          '''<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>''',
      'xl/styles.xml':
          '''<?xml version="1.0"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts><fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF123F35"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf></cellXfs></styleSheet>''',
      'xl/worksheets/sheet1.xml': sheet.toString(),
    };
    final archive = Archive();
    for (final entry in files.entries) {
      final bytes = utf8.encode(entry.value);
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<Uint8List> pdf(String day, List<VisitBooking> bookings) async {
    final data = rows(day, bookings);
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans.ttf'),
    );
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        maxPages: 1000,
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Keekkott Thangal - Daily bookings',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${VisitClock.dayLabel(day)} | India Standard Time | ${data.length} bookings | All statuses',
              ),
            ],
          ),
        ),
        footer: (c) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${c.pageNumber} of ${c.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (_) => [
          if (data.isEmpty)
            pw.Text('No bookings for this date.')
          else
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#123F35'),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(5),
              cellAlignments: {
                for (var i = 0; i < headers.length; i++)
                  i: pw.Alignment.topLeft,
              },
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(1.7),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(2.5),
                4: pw.FlexColumnWidth(1.3),
                5: pw.FlexColumnWidth(1),
                6: pw.FlexColumnWidth(.6),
                7: pw.FlexColumnWidth(1),
                8: pw.FlexColumnWidth(.8),
              },
            ),
        ],
      ),
    );
    return doc.save();
  }
}
