// lib/vat/screens/widgets/vat_document_upload_tile.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class VatDocumentUploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? fileName;         // existing (already-uploaded) file's name
  final Uint8List? localBytes;    // newly picked file (not yet uploaded)
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;  // tap to open RJSC viewer

  const VatDocumentUploadTile({
    super.key,
    required this.title,
    this.subtitle = 'Upload (PDF/JPG/PNG)',
    this.fileName,
    this.localBytes,
    required this.onPick,
    this.onRemove,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = (fileName != null && fileName!.isNotEmpty) ||
        localBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: hasFile ? onPreview ?? onPick : onPick,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasFile ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasFile ? Colors.green.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasFile ? Icons.check_circle : Icons.upload_file,
                  color: hasFile ? Colors.green : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasFile
                            ? (localBytes != null
                                ? 'New file selected'
                                : (fileName ?? 'Uploaded'))
                            : subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasFile
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                          fontWeight:
                              hasFile ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasFile && localBytes != null)
                        Text(
                          '${(localBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasFile && onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onRemove,
                    color: Colors.red.shade400,
                    tooltip: 'Remove',
                  )
                else
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.blue.shade400,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}