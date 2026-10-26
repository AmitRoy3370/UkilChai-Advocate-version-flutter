// lib/Trademark/screens/widgets/tm_step3_trademark_details.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/upload_file_model.dart';

class TmStep3TrademarkDetails extends StatelessWidget {
  final String? trademarkType;
  final List<String> trademarkTypes;
  final TextEditingController trademarkNameController;
  final TextEditingController classOfGoodsController;
  final TextEditingController organizationalNameController;
  final TextEditingController legalProtectionController;
  final TextEditingController nationWiseValidityController;
  final TextEditingController governmentFeeController;

  final List<UploadFileModel> documents;
  final ValueChanged<List<UploadFileModel>> onDocumentsChanged;

  final ValueChanged<String> onTrademarkTypeChanged;
  final ValueChanged<String> onTrademarkNameChanged;
  final ValueChanged<String> onClassOfGoodsChanged;
  final ValueChanged<String> onOrganizationalNameChanged;
  final ValueChanged<String> onLegalProtectionChanged;
  final ValueChanged<String> onNationWiseValidityChanged;
  final ValueChanged<String> onGovernmentFeeChanged;

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isEditMode;

  const TmStep3TrademarkDetails({
    super.key,
    required this.trademarkType,
    required this.trademarkTypes,
    required this.trademarkNameController,
    required this.classOfGoodsController,
    required this.organizationalNameController,
    required this.legalProtectionController,
    required this.nationWiseValidityController,
    required this.governmentFeeController,
    required this.documents,
    required this.onDocumentsChanged,
    required this.onTrademarkTypeChanged,
    required this.onTrademarkNameChanged,
    required this.onClassOfGoodsChanged,
    required this.onOrganizationalNameChanged,
    required this.onLegalProtectionChanged,
    required this.onNationWiseValidityChanged,
    required this.onGovernmentFeeChanged,
    required this.onBack,
    required this.onNext,
    this.isEditMode = false,
  });

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    final newFiles =
        result.files.map((f) => UploadFileModel.fromPlatformFile(f)).toList();
    onDocumentsChanged([...documents, ...newFiles]);
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
            const Text('Trademark Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _label('Trademark Type'),
            DropdownButtonFormField<String>(
              value: trademarkType,
              decoration: _dec('Select type'),
              items: trademarkTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onTrademarkTypeChanged(v ?? ''),
            ),
            const SizedBox(height: 14),

            _label('Trademark Name'),
            TextFormField(
              controller: trademarkNameController,
              decoration: _dec('Enter trademark name'),
              onChanged: onTrademarkNameChanged,
            ),
            const SizedBox(height: 14),

            _label('Class of Goods / Services'),
            TextFormField(
              controller: classOfGoodsController,
              decoration: _dec('e.g. Class 25'),
              onChanged: onClassOfGoodsChanged,
            ),
            const SizedBox(height: 14),

            _label('Organizational Name'),
            TextFormField(
              controller: organizationalNameController,
              decoration: _dec('Enter organization name'),
              onChanged: onOrganizationalNameChanged,
            ),
            const SizedBox(height: 14),

            _label('Legal Protection'),
            TextFormField(
              controller: legalProtectionController,
              decoration: _dec('e.g. Full'),
              onChanged: onLegalProtectionChanged,
            ),
            const SizedBox(height: 14),

            _label('Nation Wise Validity'),
            TextFormField(
              controller: nationWiseValidityController,
              decoration: _dec('e.g. Bangladesh'),
              onChanged: onNationWiseValidityChanged,
            ),
            const SizedBox(height: 14),

            _label('Government Fee'),
            TextFormField(
              controller: governmentFeeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('Enter fee amount'),
              onChanged: onGovernmentFeeChanged,
            ),

            const SizedBox(height: 20),
            const Text('Upload Logo (if any)',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            if (documents.isEmpty)
              InkWell(
                onTap: () => _pick(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
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
                          size: 40, color: Color(0xFF6A1B9A)),
                      SizedBox(height: 8),
                      Text('Upload File (JPG, PNG, PDF)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Max size 2MB',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
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
              label: const Text('Add More Document'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(color: Color(0xFF6A1B9A)),
                foregroundColor: const Color(0xFF6A1B9A),
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
                      backgroundColor: const Color(0xFF6A1B9A),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
        ),
      );

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