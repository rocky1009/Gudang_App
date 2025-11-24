import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class PdfService {
  static String _formatCurrency(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  static String _getPaymentTypeText(String paymentType) {
    switch (paymentType) {
      case '1':
        return 'Tunai';
      case '2':
        return 'Transfer';
      case '3':
        return 'Kredit';
      default:
        return 'Unknown';
    }
  }

  static String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Selesai';
      case 2:
        return 'Diproses';
      default:
        return 'Unknown';
    }
  }

  // Generate Sales Invoice (Detailed)
  static Future<Uint8List> generateInvoice(Map<String, dynamic> salesData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INVOICE PENJUALAN',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Victoria Mebel',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Jl. Andalas No.38-40',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Telp: (0411) 3634028',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Customer and Date Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Kepada:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      salesData['customer_name'] ?? 'Unknown Customer',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    if (salesData['customer_kontak'] != null &&
                        salesData['customer_kontak'].toString().isNotEmpty) ...[
                      pw.Text(
                        'Telp: ${salesData['customer_kontak']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                    if (salesData['customer_alamat'] != null &&
                        salesData['customer_alamat'].toString().isNotEmpty) ...[
                      pw.SizedBox(
                        width: 200,
                        child: pw.Text(
                          salesData['customer_alamat'],
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Tanggal: ${salesData['sales_date'] ?? '-'}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Pembayaran: ${_getPaymentTypeText(salesData['sales_payment']?.toString() ?? '1')}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Status: ${_getStatusText(salesData['sales_status'] ?? 1)}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'No',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Barang',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Gudang',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Jumlah',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Harga',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Subtotal',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                // Items
                if (salesData['sale_items'] != null)
                  ...(salesData['sale_items'] as List).asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${index + 1}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item['barang_nama'] ?? '-'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item['gudang_nama'] ?? '-'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${item['sale_items_amount'] ?? 0}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            _formatCurrency(item['sale_value'] ?? 0),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            _formatCurrency((item['sale_items_amount'] ?? 0) * (item['sale_value'] ?? 0)),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
              ],
            ),
            pw.SizedBox(height: 16),

            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 2),
                    color: PdfColors.grey200,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        _formatCurrency(salesData['sales_total'] ?? 0),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 48),

            // Footer signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Penerima'),
                    pw.SizedBox(height: 60),
                    pw.Text('(_______________)'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Hormat Kami'),
                    pw.SizedBox(height: 60),
                    pw.Text('(_______________)'),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Generate Sales Receipt (Simple/Compact)
  static Future<Uint8List> generateReceipt(Map<String, dynamic> salesData) async {
    final pdf = pw.Document();
    
    // Extract last 3 digits of sales_id
    final salesId = salesData['sales_id'] ?? '';
    final last3Digits = salesId.length >= 3 ? salesId.substring(salesId.length - 3) : salesId;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'STRUK PENJUALAN',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Victoria Mebel',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Jl. Andalas No.38-40',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Telp: (0411) 3634028',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Receipt Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No:'),
                  pw.Text(last3Digits),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:'),
                  pw.Text(salesData['sales_date'] ?? '-'),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer:'),
                  pw.Text(salesData['customer_name'] ?? '-'),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pembayaran:'),
                  pw.Text(_getPaymentTypeText(salesData['sales_payment']?.toString() ?? '1')),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Items
              ...((salesData['sale_items'] as List?) ?? []).map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item['barang_nama'] ?? '-',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '  ${item['sale_items_amount']} x ${_formatCurrency(item['sale_value'] ?? 0)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          _formatCurrency((item['sale_items_amount'] ?? 0) * (item['sale_value'] ?? 0)),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                  ],
                );
              }).toList(),

              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  pw.Text(
                    _formatCurrency(salesData['sales_total'] ?? 0),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Terima Kasih',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper function to generate receipt filename
  static String generateReceiptFilename(Map<String, dynamic> salesData) {
    // Get customer name and remove spaces
    final customerName = (salesData['customer_name'] ?? 'Customer')
        .toString()
        .replaceAll(' ', '');
    
    // Get sales_id and extract last 3 digits
    final salesId = salesData['sales_id'] ?? '';
    final last3Digits = salesId.length >= 3 ? salesId.substring(salesId.length - 3) : salesId;
    
    // Get date and format as YYMMDD
    final salesDate = salesData['sales_date'] ?? '';
    String formattedDate = '';
    
    if (salesDate.isNotEmpty) {
      try {
        // Parse date format YYYY-MM-DD
        final parts = salesDate.split('-');
        if (parts.length == 3) {
          final year = parts[0].substring(2); // Last 2 digits of year
          final month = parts[1];
          final day = parts[2];
          formattedDate = '$year$month$day';
        }
      } catch (e) {
        formattedDate = 'date';
      }
    }
    
    // Combine: Struk_CustomerName_YYMMDDXXX
    return 'Struk_${customerName}_$formattedDate$last3Digits.pdf';
  }

  // Helper function to generate invoice filename
  static String generateInvoiceFilename(Map<String, dynamic> salesData) {
    // Get customer name and remove spaces
    final customerName = (salesData['customer_name'] ?? 'Customer')
        .toString()
        .replaceAll(' ', '');
    
    // Get sales_id and extract last 3 digits
    final salesId = salesData['sales_id'] ?? '';
    final last3Digits = salesId.length >= 3 ? salesId.substring(salesId.length - 3) : salesId;
    
    // Get date and format as YYMMDD
    final salesDate = salesData['sales_date'] ?? '';
    String formattedDate = '';
    
    if (salesDate.isNotEmpty) {
      try {
        // Parse date format YYYY-MM-DD
        final parts = salesDate.split('-');
        if (parts.length == 3) {
          final year = parts[0].substring(2); // Last 2 digits of year
          final month = parts[1];
          final day = parts[2];
          formattedDate = '$year$month$day';
        }
      } catch (e) {
        formattedDate = 'date';
      }
    }
    
    // Combine: Invoice_CustomerName_YYMMDDXXX
    return 'Invoice_${customerName}_$formattedDate$last3Digits.pdf';
  }

  // Print or Save PDF
  static Future<void> printPdf(Uint8List pdfBytes, String filename) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: filename,
    );
  }

  // Share PDF (for mobile devices) - Updated to use sharePdf with better error handling
  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    try {
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      // If sharePdf fails, try using layoutPdf which opens print/share dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: filename,
      );
    }
  }
}
