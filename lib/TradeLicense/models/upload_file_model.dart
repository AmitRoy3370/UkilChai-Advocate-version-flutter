// lib/TradeLicense/models/upload_file_model.dart

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadFileModel {
  final String fileName;
  final Uint8List? bytes;
  final String? path;

  UploadFileModel({
    required this.fileName,
    this.bytes,
    this.path,
  });

  factory UploadFileModel.fromPlatformFile(PlatformFile file) {
    if (kIsWeb) {
      return UploadFileModel(
        fileName: file.name,
        bytes: file.bytes,
        path: null,
      );
    }
    return UploadFileModel(
      fileName: file.name,
      bytes: file.bytes,
      path: file.path,
    );
  }

  String get extension {
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return '';
  }
}