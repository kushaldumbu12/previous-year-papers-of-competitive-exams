import 'dart:convert';
import 'dart:typed_data';

class PdfHelper {
  /// Generates a valid minimal standard PDF document with a clean title page
  static Uint8List createSamplePdfBytes({
    String title = 'Sample Exam Paper',
    String examName = 'Government Examination',
    String year = '2025',
  }) {
    // Valid minimal raw PDF byte stream with formatted text stream
    final contentText = 'BT /F1 20 Tf 50 750 Td ($title) Tj ET '
        'BT /F1 12 Tf 50 720 Td (Exam: $examName | Year: $year) Tj ET '
        'BT /F1 10 Tf 50 690 Td (This is an official examination document placeholder.) Tj ET '
        'BT /F1 10 Tf 50 670 Td (Uploaded via Admin Console. Ready for students to view.) Tj ET';

    final contentStream = '<< /Length ${contentText.length} >>\nstream\n$contentText\nendstream';

    final pdfString = '%PDF-1.4\n'
        '1 0 obj\n'
        '<< /Type /Catalog /Pages 2 0 R >>\n'
        'endobj\n'
        '2 0 obj\n'
        '<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n'
        'endobj\n'
        '3 0 obj\n'
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\n'
        'endobj\n'
        '4 0 obj\n'
        '$contentStream\n'
        'endobj\n'
        '5 0 obj\n'
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\n'
        'endobj\n'
        'xref\n'
        '0 6\n'
        '0000000000 65535 f \n'
        '0000000009 00000 n \n'
        '0000000058 00000 n \n'
        '0000000115 00000 n \n'
        '0000000244 00000 n \n'
        '0000000370 00000 n \n'
        'trailer\n'
        '<< /Size 6 /Root 1 0 R >>\n'
        'startxref\n'
        '450\n'
        '%%EOF';

    return Uint8List.fromList(utf8.encode(pdfString));
  }

  /// Generates a simple empty PDF byte array
  static Uint8List createEmptyPdfBytes() {
    return createSamplePdfBytes(title: 'Empty Document Placeholder');
  }
}
