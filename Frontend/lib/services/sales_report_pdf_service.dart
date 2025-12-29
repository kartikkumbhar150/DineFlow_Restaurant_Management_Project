import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// === PDF Generator for Sales Report ===
class SalesReportPdfGenerator {
  static Future<Uint8List> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final indianFormat = NumberFormat.decimalPattern("en_IN");

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "Sales Report",
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 22,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  "${data['startDate']} to ${data['endDate']}",
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),

              // --- Summary Metrics ---
              pw.Text(
                "Summary",
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(width: 0.2, color: PdfColors.grey400),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                },
                children: [
                  _row(
                    "Total Sales",
                    "₹${indianFormat.format(data['totalSales'])}",
                    font,
                    boldFont,
                  ),
                  _row(
                    "Total Invoices",
                    "${data['invoiceCount']}",
                    font,
                    boldFont,
                  ),
                  _row(
                    "Average Invoice",
                    "₹${indianFormat.format(data['averageInvoiceValue'])}",
                    font,
                    boldFont,
                  ),

                  // ✅ ADDED BACKEND FIELDS (ONLY ADDITION)
                  _row(
                    "Total GST",
                    "₹${indianFormat.format(data['totalGst'])}",
                    font,
                    boldFont,
                  ),
                  _row(
                    "Total Invoice Amount",
                    "₹${indianFormat.format(data['totalInvoiceValue'])}",
                    font,
                    boldFont,
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // --- Most Selling Items ---
              pw.Text(
                "Items Sold",
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Item Name', 'Total Quantity'],
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 12),
                cellStyle: pw.TextStyle(font: font, fontSize: 11),
                data: List.generate(
                  (data['mostSellingItems'] as List).length,
                      (i) => [
                    (i + 1).toString(),
                    data['mostSellingItems'][i]['itemName'],
                    data['mostSellingItems'][i]['totalQuantity'].toString(),
                  ],
                ),
                border: pw.TableBorder.all(
                  width: 0.2,
                  color: PdfColors.grey400,
                ),
                headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  "Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}",
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _row(
      String label,
      String value,
      pw.Font font,
      pw.Font boldFont,
      ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 11),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
        ),
      ],
    );
  }

  static Future<void> generateAndShare(Map<String, dynamic> data) async {
    final pdfBytes = await _generatePdf(data);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
      'sales-report-${data["startDate"]}-${data["endDate"]}.pdf',
    );
  }

  static Future<void> generateAndPrint(Map<String, dynamic> data) async {
    await Printing.layoutPdf(
      onLayout: (format) => _generatePdf(data),
    );
  }
}
