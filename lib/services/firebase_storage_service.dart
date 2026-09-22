import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/pdf_helper.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads raw PDF bytes to Firebase Storage and returns the public download URL
  Future<String> uploadPdfBytes({
    required String examId,
    required String year,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final cleanExamId = examId.trim().toLowerCase();
    final cleanYear = year.trim();
    final safeFileName = fileName.trim().replaceAll(' ', '_');
    final storagePath = 'materials/$cleanExamId/$cleanYear/$safeFileName';

    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(
      contentType: 'application/pdf',
      customMetadata: {
        'examId': cleanExamId,
        'year': cleanYear,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = await ref.putData(bytes, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Uploads a generated empty sample PDF placeholder
  Future<String> uploadEmptyPdfPlaceholder({
    required String examId,
    required String year,
    required String title,
  }) async {
    final fileName = '${title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_')}_empty.pdf';
    final sampleBytes = PdfHelper.createSamplePdfBytes(
      title: title,
      examName: examId.toUpperCase(),
      year: year,
    );

    return uploadPdfBytes(
      examId: examId,
      year: year,
      fileName: fileName,
      bytes: sampleBytes,
    );
  }

  /// Deletes a file from Firebase Storage given its download URL
  Future<void> deleteFileByUrl(String fileUrl) async {
    if (fileUrl.isEmpty || !fileUrl.contains('firebasestorage.googleapis.com')) {
      return;
    }
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      // Ignored if already deleted or invalid reference
    }
  }
}
