// lib/Tin/screens/widgets/tin_step3_edit_docs.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import '../../../../Auth/AuthService.dart';
import '../../models/upload_file_model.dart';
import '../../../../RJSC/screens/rjsc_attachment_viewer.dart';

class TinStep3EditDocs extends StatelessWidget {
  final List<UploadFileModel> documents;
  final List<String> existingDocumentIds;
  final ValueChanged<List<UploadFileModel>> onDocumentsChanged;
  final ValueChanged<List<String>> onExistingIdsChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const TinStep3EditDocs({
    super.key,
    required this.documents,
    required this.existingDocumentIds,
    required this.onDocumentsChanged,
    required this.onExistingIdsChanged,
    required this.onBack,
    required this.onNext,
  });

  Future<void> _pick(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.isEmpty) return;

      final newFiles = result.files
          .map((f) => UploadFileModel.fromPlatformFile(f))
          .toList();
      onDocumentsChanged([...documents, ...newFiles]);
    } catch (e) {
      debugPrint('❌ File pick error: $e');
    }
  }

  Future<void> _openViewer(BuildContext context, String attachmentId) async {
    final token = await AuthService.getToken() ?? '';
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black87,
          appBar: AppBar(
            backgroundColor: Colors.black87,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Document Viewer',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          body: RJSCAttachmentViewer(
            attachmentId: attachmentId,
            jwtToken: token,
          ),
        ),
      ),
    );
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
            const Text('Manage Documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Add new or remove existing documents',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 16),

            if (existingDocumentIds.isNotEmpty) ...[
              const Text('Existing Documents',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E7A3A))),
              const SizedBox(height: 8),
              ...existingDocumentIds.asMap().entries.map((e) {
                return _existingTile(
                  context,
                  index: e.key + 1,
                  id: e.value,
                  onView: () => _openViewer(context, e.value),
                  onRemove: () {
                    final updated = [...existingDocumentIds]..removeAt(e.key);
                    onExistingIdsChanged(updated);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],

            if (documents.isNotEmpty) ...[
              const Text('New Documents',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32))),
              const SizedBox(height: 8),
              ...documents.asMap().entries.map((e) {
                return _newTile(
                  index: e.key,
                  doc: e.value,
                  onRemove: () {
                    final updated = [...documents]..removeAt(e.key);
                    onDocumentsChanged(updated);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],

            if (existingDocumentIds.isEmpty && documents.isEmpty)
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
                    Icon(Icons.folder_open_outlined,
                        size: 40, color: Color(0xFF1E7A3A)),
                    SizedBox(height: 8),
                    Text('No documents',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pick(context),
              icon: const Icon(Icons.add),
              label: const Text('Add New Document'),
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

  Widget _existingTile(
    BuildContext context, {
    required int index,
    required String id,
    required VoidCallback onView,
    required VoidCallback onRemove,
  }) {
    final isPdf = id.toLowerCase().contains('pdf');
    return Material(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: isPdf ? Colors.red : Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Document $index',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Tap to view',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newTile({
    required int index,
    required UploadFileModel doc,
    required VoidCallback onRemove,
  }) {
    final isImage = ['jpg', 'jpeg', 'png'].contains(doc.extension);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('New',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }
}