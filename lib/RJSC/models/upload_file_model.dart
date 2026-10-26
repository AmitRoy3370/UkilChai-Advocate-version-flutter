// lib/RJSC/models/upload_file_model.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Universal file model — Web + Mobile compatible.
/// - Web    : bytes + mimeType (path = null)
/// - Mobile : path  + mimeType (bytes = optional)
class UploadFileModel {
  final String fileName;
  final Uint8List? bytes;   // Web + wherever available
  final String? path;       // Mobile/Desktop fallback

  /// ✅ File mime type (e.g. "application/pdf", "image/jpeg")
  /// Web এ directভাবে available না হলে extension থেকে derive করা হয়।
  final String mimeType;

  UploadFileModel({
    required this.fileName,
    this.bytes,
    this.path,
    String? mimeType,
  }) : mimeType = (mimeType == null || mimeType.isEmpty)
            ? _deriveMimeType(fileName)
            : mimeType;

  /// ✅ PlatformFile থেকে তৈরি — Web-safe
  factory UploadFileModel.fromPlatformFile(PlatformFile file) {
    if (kIsWeb) {
      // Web: path access করা যাবে না — শুধু bytes
      return UploadFileModel(
        fileName: file.name,
        bytes: file.bytes,
        path: null,
        mimeType: file.extension != null
            ? _mimeFromExtension(file.extension!)
            : null,
      );
    } else {
      // Mobile: path + bytes দুটোই থাকতে পারে
      return UploadFileModel(
        fileName: file.name,
        bytes: file.bytes,
        path: file.path,
        mimeType: file.extension != null
            ? _mimeFromExtension(file.extension!)
            : null,
      );
    }
  }

  /// Mobile-only constructor (dart:io File → path)
  factory UploadFileModel.fromPath(String filePath, String fileName) {
    return UploadFileModel(
      fileName: fileName,
      path: filePath,
    );
  }

  /// Extension (e.g. "pdf", "jpg")
  String get extension {
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return '';
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  static String _deriveMimeType(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return _mimeFromExtension(ext);
  }

  static String _mimeFromExtension(String ext) {
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