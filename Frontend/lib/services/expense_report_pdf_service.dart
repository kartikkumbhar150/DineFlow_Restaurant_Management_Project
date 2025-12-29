import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';


class ExpenseReportPdfGenerator {
  static Future<Uint8List> _generatePdf(
      List<dynamic> items,
      double totalExpense,
      DateTimeRange range,
      ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                "Expense Report",
                style: pw.TextStyle(font: boldFont, fontSize: 22),
              ),
            ),
            pw.Center(
              child: pw.Text(
                "${range.start.toIso8601String().split('T')[0]} to "
                    "${range.end.toIso8601String().split('T')[0]}",
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),

            pw.Text(
              "Total Expense: ₹${totalExpense.toStringAsFixed(2)}",
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.SizedBox(height: 12),

            pw.TableHelper.fromTextArray(
              headers: ['#', 'Item', 'Qty', 'Unit', 'Price', 'Date'],
              headerStyle: pw.TextStyle(font: boldFont),
              cellStyle: pw.TextStyle(font: font),
              data: List.generate(items.length, (i) {
                final item = items[i];
                return [
                  (i + 1).toString(),
                  item['itemName'],
                  item['quantity'].toString(),
                  item['unit'],
                  item['price'].toString(),
                  item['date'],
                ];
              }),
              border: pw.TableBorder.all(width: 0.2),
              headerDecoration:
              const pw.BoxDecoration(color: PdfColors.grey300),
            ),

            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                "Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}",
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndShare(
      List<dynamic> items,
      double totalExpense,
      DateTimeRange range,
      ) async {
    final bytes = await _generatePdf(items, totalExpense, range);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
      'expense-report-${range.start}-${range.end}.pdf',
    );
  }
}
