// lib/RJSC/models/upload_file_model.dart

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class UploadFileModel {
  final String fileName;
  final Uint8List? bytes;
  final String? path;
  final String mimeType;

  UploadFileModel({
    required this.fileName,
    this.bytes,
    this.path,
    String? mimeType,
  }) : mimeType = (mimeType == null || mimeType.isEmpty)
            ? _deriveMimeType(fileName)
            : mimeType {
    // ✅ Print on construction
    debugPrint('═══════════════════════════════════════════');
    debugPrint('📦 UploadFileModel CONSTRUCTED');
    debugPrint('   fileName: $fileName');
    debugPrint('   mimeType: $this.mimeType');
    debugPrint('   bytes: ${bytes?.length ?? "null"} (isEmpty: ${bytes?.isEmpty ?? "N/A"})');
    debugPrint('   path: ${path ?? "null"}');
    debugPrint('   kIsWeb: $kIsWeb');
    debugPrint('   extension getter: "$extension"');
    debugPrint('═══════════════════════════════════════════');
  }

  factory UploadFileModel.fromPlatformFile(PlatformFile file) {
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🏭 FACTORY: fromPlatformFile');
    debugPrint('   file.name: "${file.name}"');
    debugPrint('   file.extension: "${file.extension}"');
    debugPrint('   file.size: ${file.size} bytes');
    debugPrint('   file.bytes: ${file.bytes?.length ?? "null"}');
    debugPrint('   file.bytes.isEmpty: ${file.bytes?.isEmpty ?? "N/A"}');
    debugPrint('   kIsWeb: $kIsWeb');

    if (!kIsWeb) {
      debugPrint('   file.path: "${file.path}"');
    } else {
      debugPrint('   file.path: SKIPPED (web)');
    }

    final mime = file.extension != null
        ? _mimeFromExtension(file.extension!)
        : null;
    debugPrint('   derived mimeType: "$mime"');

    if (kIsWeb) {
      debugPrint('   → Creating with bytes only');
      debugPrint('═══════════════════════════════════════════');
      return UploadFileModel(
        fileName: file.name,
        bytes: file.bytes,
        path: null,
        mimeType: mime,
      );
    } else {
      debugPrint('   → Creating with bytes + path');
      debugPrint('═══════════════════════════════════════════');
      return UploadFileModel(
        fileName: file.name,
        bytes: file.bytes,
        path: file.path,
        mimeType: mime,
      );
    }
  }

  factory UploadFileModel.fromPath(String filePath, String fileName) {
    debugPrint('🏭 FACTORY: fromPath');
    debugPrint('   filePath: $filePath');
    debugPrint('   fileName: $fileName');
    return UploadFileModel(
      fileName: fileName,
      path: filePath,
    );
  }

  String get extension {
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return '';
  }

  static String _deriveMimeType(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return _mimeFromExtension(ext);
  }

  static String _mimeFromExtension(String ext) {
    debugPrint('🔧 _mimeFromExtension("$ext")');
    final mime = _mimeFromExtensionImpl(ext);
    debugPrint('   → "$mime"');
    return mime;
  }

  static String _mimeFromExtensionImpl(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}