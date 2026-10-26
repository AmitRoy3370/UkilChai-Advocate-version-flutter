// lib/Tin/screens/widgets/tin_step3_upload_docs.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import '../../models/upload_file_model.dart';

class TinStep3UploadDocs extends StatelessWidget {
  final List<UploadFileModel> documents;
  final ValueChanged<List<UploadFileModel>> onDocumentsChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const TinStep3UploadDocs({
    super.key,
    required this.documents,
    required this.onDocumentsChanged,
    required this.onBack,
    required this.onNext,
  });

  Future<void> _pick(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true, // ✅ Multi-device compatible
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) return;

      final newFiles = result.files.map((f) {
        debugPrint('📁 Picked: ${f.name} | bytes=${f.bytes?.length}');
        if (!kIsWeb) debugPrint('   path=${f.path}');
        return UploadFileModel.fromPlatformFile(f);
      }).toList();

      final validFiles = newFiles.where((f) {
        final hasBytes = f.bytes != null && f.bytes!.isNotEmpty;
        final hasPath = f.path != null && f.path!.isNotEmpty;
        return hasBytes || hasPath;
      }).toList();

      onDocumentsChanged([...documents, ...validFiles]);
    } catch (e) {
      debugPrint('❌ File pick error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _remove(int index) {
    final updated = [...documents]..removeAt(index);
    onDocumentsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('NID Front, NID Back, Passport Size Photo etc.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 16),

            if (documents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.cloud_upload_outlined,
                        size: 40, color: Color(0xFF1E7A3A)),
                    SizedBox(height: 8),
                    Text('Tap to upload documents',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              ...documents.asMap().entries.map((e) {
                return _docTile(e.key, e.value);
              }),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pick(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Document'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: Color(0xFF1E7A3A)),
                foregroundColor: const Color(0xFF1E7A3A),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E7A3A),
                      minimumSize: const Size(0, 46),
                    ),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _docTile(int index, UploadFileModel doc) {
    final isImage = ['jpg', 'jpeg', 'png'].contains(doc.extension);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isImage ? Colors.blue.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isImage ? Icons.image : Icons.picture_as_pdf,
              color: isImage ? Colors.blue : Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(doc.extension.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _remove(index),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }
}