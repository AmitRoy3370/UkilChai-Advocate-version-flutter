// lib/Copyright/screens/widgets/step4_edit_documents.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import '../../models/upload_file_model.dart';
import '../../../Auth/AuthService.dart';
import '../../../RJSC/screens/rjsc_attachment_viewer.dart';

class Step4EditDocuments extends StatelessWidget {
  /// নতুন (locally picked) documents
  final List<UploadFileModel> documents;

  /// Existing document URLs / attachment IDs (from backend)
  final List<String> existingDocumentUrls;

  final ValueChanged<List<UploadFileModel>> onDocumentsChanged;
  final ValueChanged<List<String>> onExistingUrlsChanged;

  final VoidCallback onBack;
  final VoidCallback onNext;

  const Step4EditDocuments({
    super.key,
    required this.documents,
    required this.existingDocumentUrls,
    required this.onDocumentsChanged,
    required this.onExistingUrlsChanged,
    required this.onBack,
    required this.onNext,
  });

  // ============================================================
  // PICK
  // ✅ FIXED: withData: true + safe logging + error handling
  // ============================================================
Future<void> _pick(BuildContext context) async {
  debugPrint('');
  debugPrint('╔═══════════════════════════════════════════');
  debugPrint('║ 🎯 PICK START');
  debugPrint('╚═══════════════════════════════════════════');

  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null) {
      debugPrint('⚠️ Pick cancelled — result is null');
      return;
    }

    debugPrint('✅ Pick result received');
    debugPrint('   files count: ${result.files.length}');

    if (result.files.isEmpty) {
      debugPrint('⚠️ No files selected');
      return;
    }

    // ✅ Inspect every picked file
    for (int i = 0; i < result.files.length; i++) {
      final f = result.files[i];
      debugPrint('');
      debugPrint('━━━ File #${i + 1} of ${result.files.length} ━━━');
      debugPrint('   name: "${f.name}"');
      debugPrint('   extension: "${f.extension}"');
      debugPrint('   size: ${f.size} bytes');
      debugPrint('   sizeMB: ${(f.size / 1024 / 1024).toStringAsFixed(2)} MB');
      debugPrint('   bytes: ${f.bytes?.length ?? "null"}');
      debugPrint('   bytes.isEmpty: ${f.bytes?.isEmpty ?? "N/A"}');
      if (!kIsWeb) {
        debugPrint('   path: "${f.path}"');
      } else {
        debugPrint('   path: SKIPPED (web)');
      }
    }

    debugPrint('');
    debugPrint('🔨 Mapping to UploadFileModel...');

    final newFiles = result.files.map((f) {
      debugPrint('   → Mapping: ${f.name}');
      return UploadFileModel.fromPlatformFile(f);
    }).toList();

    debugPrint('✅ Mapped ${newFiles.length} files');

    // ✅ Filter invalid
    debugPrint('');
    debugPrint('🔍 Filtering invalid files...');
    final validFiles = newFiles.where((f) {
      final hasBytes = f.bytes != null && f.bytes!.isNotEmpty;
      final hasPath = f.path != null && f.path!.isNotEmpty;
      if (!hasBytes && !hasPath) {
        debugPrint('❌ INVALID: ${f.fileName} — no bytes, no path');
        return false;
      }
      debugPrint('✅ VALID: ${f.fileName} (bytes:${hasBytes}, path:${hasPath})');
      return true;
    }).toList();

    debugPrint('');
    debugPrint('📊 Valid: ${validFiles.length} / Total: ${newFiles.length}');

    onDocumentsChanged([...documents, ...validFiles]);

    debugPrint('✅ Documents updated in state');
    debugPrint('   total now: ${documents.length + validFiles.length}');
  } catch (e, stack) {
    debugPrint('❌ PICK ERROR: $e');
    debugPrint('Stack: $stack');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  debugPrint('╔═══════════════════════════════════════════');
  debugPrint('║ 🎯 PICK END');
  debugPrint('╚═══════════════════════════════════════════');
  debugPrint('');
}

  // ============================================================
  // REMOVE
  // ============================================================
  void _removeNew(int index) {
    final updated = [...documents]..removeAt(index);
    onDocumentsChanged(updated);
  }

  void _removeExisting(int index) {
    final updated = [...existingDocumentUrls]..removeAt(index);
    onExistingUrlsChanged(updated);
  }

  // ============================================================
  // VIEWER
  // ============================================================
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
            title: const Text(
              'Document Viewer',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          body: RJSCAttachmentViewer(
            attachmentId: attachmentId,
            jwtToken: token,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segs = uri.pathSegments;
      if (segs.isEmpty) return 'document';
      return Uri.decodeComponent(segs.last);
    } catch (_) {
      return 'document';
    }
  }

  bool _isPdf(String s) {
    final lower = s.toLowerCase();
    return lower.contains('.pdf') || lower.contains('/pdf');
  }

  bool _isImage(String s) {
    final lower = s.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('image/');
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final hasAny = documents.isNotEmpty || existingDocumentUrls.isNotEmpty;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Documents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Add new documents or remove existing ones',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // -------- Existing documents --------
            if (existingDocumentUrls.isNotEmpty) ...[
              const Text(
                'Existing Documents',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A3FBF),
                ),
              ),
              const SizedBox(height: 8),
              ...existingDocumentUrls.asMap().entries.map((e) {
                return _existingTile(
                  context,
                  attachmentId: e.value,
                  name: _fileNameFromUrl(e.value),
                  onTap: () => _openViewer(context, e.value),
                  onRemove: () => _removeExisting(e.key),
                );
              }),
              const SizedBox(height: 16),
            ],

            // -------- New documents --------
            if (documents.isNotEmpty) ...[
              const Text(
                'New Documents to Upload',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              ...documents.asMap().entries.map((e) {
                return _newTile(
                  context,
                  doc: e.value,
                  onRemove: () => _removeNew(e.key),
                );
              }),
              const SizedBox(height: 16),
            ],

            // -------- Empty state --------
            if (!hasAny)
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
                        size: 40, color: Color(0xFF1A3FBF)),
                    SizedBox(height: 8),
                    Text('No documents yet',
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
                side: const BorderSide(color: Color(0xFF1A3FBF)),
                foregroundColor: const Color(0xFF1A3FBF),
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
                      backgroundColor: const Color(0xFF1A3FBF),
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

  // ============================================================
  // EXISTING TILE (tappable → viewer)
  // ============================================================
  Widget _existingTile(
    BuildContext context, {
    required String attachmentId,
    required String name,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final isPdf = _isPdf(name) || _isPdf(attachmentId);
    final isImage = !isPdf && (_isImage(name) || _isImage(attachmentId));

    IconData icon = Icons.insert_drive_file;
    Color iconColor = Colors.grey;
    Color bgColor = Colors.grey.shade100;

    if (isPdf) {
      icon = Icons.picture_as_pdf;
      iconColor = Colors.red;
      bgColor = Colors.red.shade50;
    } else if (isImage) {
      icon = Icons.image;
      iconColor = Colors.blue;
      bgColor = Colors.blue.shade50;
    }

    return Material(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
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
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Already uploaded',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.visibility_outlined,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Text(
                          'View',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon:
                    const Icon(Icons.close, size: 18, color: Colors.red),
                tooltip: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NEW TILE
  // ============================================================
  Widget _newTile(
    BuildContext context, {
    required UploadFileModel doc,
    required VoidCallback onRemove,
  }) {
    final isImage = ['jpg', 'jpeg', 'png'].contains(doc.extension);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                Text(
                  doc.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700),
                  ),
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