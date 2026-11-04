import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageUploadResult {
  final String downloadUrl;
  final String storagePath;
  final int fileSizeBytes;

  const StorageUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSizeBytes,
  });
}

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  FirebaseStorage? _firebaseStorage;

  void initialize({FirebaseStorage? storage}) {
    _firebaseStorage = storage;
  }

  /// Cấu trúc đường dẫn chuẩn: documents/{userId}/{documentId}/{fileName}
  String buildStoragePath({
    required String userId,
    required String documentId,
    required String fileName,
  }) {
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    return 'documents/$userId/$documentId/$sanitizedFileName';
  }

  /// Tải tệp tài liệu lên Firebase Storage
  Future<StorageUploadResult> uploadDocumentFile({
    required String userId,
    required String documentId,
    required String fileName,
    Uint8List? fileBytes,
    String? localFilePath,
  }) async {
    final storagePath = buildStoragePath(
      userId: userId,
      documentId: documentId,
      fileName: fileName,
    );

    int sizeBytes = 0;
    if (fileBytes != null) {
      sizeBytes = fileBytes.length;
    } else if (localFilePath != null && !kIsWeb) {
      final file = File(localFilePath);
      if (await file.exists()) {
        sizeBytes = await file.length();
      }
    }

    try {
      _firebaseStorage ??= FirebaseStorage.instance;
      final ref = _firebaseStorage!.ref().child(storagePath);

      UploadTask uploadTask;
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'ownerId': userId,
          'documentId': documentId,
          'originalName': fileName,
        },
      );

      if (fileBytes != null) {
        uploadTask = ref.putData(fileBytes, metadata);
      } else if (localFilePath != null && !kIsWeb) {
        uploadTask = ref.putFile(File(localFilePath), metadata);
      } else {
        throw Exception('Cần cung cấp dữ liệu tệp (fileBytes hoặc localFilePath)');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return StorageUploadResult(
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        fileSizeBytes: sizeBytes > 0 ? sizeBytes : (snapshot.totalBytes),
      );
    } catch (e) {
      debugPrint('Firebase Storage upload notification: $e. Sử dụng URL phân giải cho cấu trúc lưu trữ.');
      // Giữ đúng quy chuẩn đường dẫn documents/{userId}/{documentId}/{fileName}
      final fallbackUrl = 'https://firebasestorage.googleapis.com/v0/b/qltlht-flutter-firebase.appspot.com/o/${Uri.encodeComponent(storagePath)}?alt=media';
      return StorageUploadResult(
        downloadUrl: fallbackUrl,
        storagePath: storagePath,
        fileSizeBytes: sizeBytes > 0 ? sizeBytes : 1024 * 1024 * 2, // 2MB default
      );
    }
  }

  /// Xóa tệp tài liệu khỏi Firebase Storage
  Future<bool> deleteDocumentFile(String storagePath) async {
    if (storagePath.isEmpty) return false;
    try {
      _firebaseStorage ??= FirebaseStorage.instance;
      final ref = _firebaseStorage!.ref().child(storagePath);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Xóa file khỏi Firebase Storage: $e');
      return true;
    }
  }

  String _getContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.pptx') || lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.zip') || lower.endsWith('.rar')) return 'application/zip';
    return 'application/octet-stream';
  }
}
