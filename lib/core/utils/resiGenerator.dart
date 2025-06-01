import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptGenerator {
  static Future<String> generateReceiptPdfBase64({
    required String recipientName,
    required String recipientPhone,
    required String recipientAddress,
    required String senderName,
    required String senderPhone,
    required String senderAddress,
  }) async {
    final pdf = pw.Document();

    // Memisahkan alamat menjadi baris-baris terpisah
    List<String> formatMultiLineAddress(String address) {
      if (address.contains('(')) {
        // Jika ada tanda kurung, anggap itu adalah pemisah baris
        List<String> parts = [];
        int startPos = 0;

        for (int i = 0; i < address.length; i++) {
          if (address[i] == '(' || (i > 0 && address[i - 1] == ')')) {
            if (i > startPos) {
              parts.add(address.substring(startPos, i).trim());
              startPos = i;
            }
          }
        }

        // Tambahkan bagian terakhir jika ada
        if (startPos < address.length) {
          parts.add(address.substring(startPos).trim());
        }

        return parts;
      } else if (address.contains(',')) {
        // Jika ada koma, pisahkan berdasarkan koma
        return address.split(',').map((line) => line.trim()).toList();
      } else {
        // Jika tidak ada pemisah yang jelas, coba pisahkan berdasarkan spasi dan panjang
        List<String> words = address.split(' ');
        List<String> lines = [];
        String currentLine = '';

        for (String word in words) {
          if (currentLine.length + word.length > 25) {
            // Batasi panjang baris
            lines.add(currentLine.trim());
            currentLine = word;
          } else {
            currentLine += (currentLine.isEmpty ? '' : ' ') + word;
          }
        }

        if (currentLine.isNotEmpty) {
          lines.add(currentLine.trim());
        }

        return lines;
      }
    }

    // Parse alamat penerima dan pengirim
    List<String> recipientAddressLines =
        formatMultiLineAddress(recipientAddress);
    List<String> senderAddressLines = formatMultiLineAddress(senderAddress);

    // Ukuran yang diinginkan
    final boxWidth = 280.0;
    final boxHeight = 200.0;
    final fontSize = 16.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // Ubah ke ukuran A4
        margin: pw.EdgeInsets.zero, // Hilangkan margin halaman
        build: (pw.Context context) {
          return pw.Align(
            alignment: pw.Alignment.topLeft, // Konten di pojok kiri atas
            child: pw.Padding(
              padding:
                  pw.EdgeInsets.all(10), // Sedikit padding dari tepi kertas
              child: pw.Container(
                width: boxWidth,
                height: boxHeight * 2, // Total tinggi untuk kedua kotak
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.black),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    // Bagian Penerima dengan border dan tinggi tetap
                    pw.Container(
                      width: boxWidth,
                      height: boxHeight,
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom:
                              pw.BorderSide(width: 1, color: PdfColors.black),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text('Penerima:',
                              style: pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(height: 5),
                          pw.Text(recipientName.toUpperCase(),
                              style: pw.TextStyle(fontSize: fontSize)),
                          pw.Text(recipientPhone,
                              style: pw.TextStyle(fontSize: fontSize)),
                          ...recipientAddressLines.map((line) => pw.Text(line,
                              style: pw.TextStyle(fontSize: fontSize))),
                        ],
                      ),
                    ),

                    // Bagian Pengirim dengan tinggi tetap
                    pw.Container(
                      width: boxWidth,
                      height: boxHeight,
                      padding: pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text('Pengirim',
                              style: pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(height: 5),
                          pw.Text(senderName,
                              style: pw.TextStyle(fontSize: fontSize)),
                          pw.Text(senderPhone,
                              style: pw.TextStyle(fontSize: fontSize)),
                          ...senderAddressLines.map((line) => pw.Text(line,
                              style: pw.TextStyle(fontSize: fontSize))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    // Convert PDF to bytes
    final pdfBytes = await pdf.save();

    // Encode to base64
    final base64String = base64Encode(pdfBytes);

    return base64String;
  }
}
