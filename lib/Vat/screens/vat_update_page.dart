// lib/vat/screens/vat_update_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../models/vat_model.dart';
import '../service/vat_service.dart';
import 'widgets/vat_step_indicator.dart';
import 'widgets/vat_document_upload_tile.dart';
import '../../RJSC/screens/rjsc_attachment_viewer.dart';

/// Simple holder for a locally-picked file.
/// Platform-agnostic: uses bytes, never path.
class _PickedFile {
  final String name;
  final Uint8List bytes;
  const _PickedFile({required this.name, required this.bytes});
}

class VatUpdatePage extends StatefulWidget {
  final VatModel vat;

  const VatUpdatePage({super.key, required this.vat});

  @override
  State<VatUpdatePage> createState() => _VatUpdatePageState();
}

class _VatUpdatePageState extends State<VatUpdatePage> {
  int _currentStep = 1;
  static const int _totalSteps = 4;

  // ============ Controllers ============
  final _businessNameCtrl = TextEditingController();
  final _tradeLicenseNoCtrl = TextEditingController();
  final _tinNoCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mainProductCtrl = TextEditingController();

  String? _natureOfBusiness;
  String? _annualTurnOverRange;
  int? _numberOfEmployees;

  // ============ Documents ============
  final List<String> _existingAttachmentIds = [];

  /// Newly picked files, keyed by a unique label.
  /// Stores {name, bytes} only — no file paths (web-safe).
  final Map<String, _PickedFile> _newDocuments = {};

  bool _submitting = false;
  String? _userId;

  // ---- Original values (for change detection) ----
  late final String _origBusinessName;
  late final String _origTradeLicenseNo;
  late final String _origTinNo;
  late final String _origAddress;
  late final String _origMainProduct;
  late final String? _origNature;
  late final String? _origTurnover;
  late final int? _origEmployees;
  late final List<String> _origAttachmentIds;

  static const List<String> _natureOptions = [
    'Trading',
    'Manufacturing',
    'Service',
    'Import & Export',
    'Construction',
    'Agriculture',
    'Other',
  ];

  static const List<String> _turnoverRanges = [
    'Below 5,00,000',
    '5,00,000 - 10,00,000',
    '10,00,000 - 25,00,000',
    '25,00,000 - 50,00,000',
    'Above 50,00,000',
  ];

  static const List<int> _employeeRanges = [1, 5, 10, 25, 50, 100, 250];

  @override
  void initState() {
    super.initState();
    _prefill(widget.vat);
    _loadUser();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _tradeLicenseNoCtrl.dispose();
    _tinNoCtrl.dispose();
    _addressCtrl.dispose();
    _mainProductCtrl.dispose();
    super.dispose();
  }

  void _prefill(VatModel v) {
    _businessNameCtrl.text = v.buisnessName;
    _tradeLicenseNoCtrl.text = v.tradeLicenseNo;
    _tinNoCtrl.text = v.tinNo;
    _addressCtrl.text = v.adress;
    _mainProductCtrl.text = v.mainProduct;

    _natureOfBusiness =
        _natureOptions.contains(v.natureOfBuisness) ? v.natureOfBuisness : null;
    _annualTurnOverRange =
        _turnoverRanges.contains(v.annualTurnOver) ? v.annualTurnOver : null;
    _numberOfEmployees = v.numberOfEmployee > 0 ? v.numberOfEmployee : null;

    _existingAttachmentIds
      ..clear()
      ..addAll(v.documents);

    _origBusinessName = v.buisnessName;
    _origTradeLicenseNo = v.tradeLicenseNo;
    _origTinNo = v.tinNo;
    _origAddress = v.adress;
    _origMainProduct = v.mainProduct;
    _origNature = _natureOfBusiness;
    _origTurnover = _annualTurnOverRange;
    _origEmployees = _numberOfEmployees;
    _origAttachmentIds = List<String>.from(v.documents);
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ??
          prefs.getString('userId') ??
          prefs.getString('_id');
    });
  }

  // ============ Change detection ============
  bool get _hasAnyChange {
    if (_businessNameCtrl.text != _origBusinessName) return true;
    if (_tradeLicenseNoCtrl.text != _origTradeLicenseNo) return true;
    if (_tinNoCtrl.text != _origTinNo) return true;
    if (_addressCtrl.text != _origAddress) return true;
    if (_mainProductCtrl.text != _origMainProduct) return true;
    if (_natureOfBusiness != _origNature) return true;
    if (_annualTurnOverRange != _origTurnover) return true;
    if (_numberOfEmployees != _origEmployees) return true;
    if (_newDocuments.isNotEmpty) return true;
    if (_existingAttachmentIds.length != _origAttachmentIds.length) {
      return true;
    }
    for (final id in _existingAttachmentIds) {
      if (!_origAttachmentIds.contains(id)) return true;
    }
    return false;
  }

  // ============ Pick new file (Web + Mobile Safe) ============
  Future<void> _pickNewFile({String? slotLabel}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true, // ✅ forces bytes on web
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _snack('Could not read file bytes', true);
        return;
      }

      final key =
          '${slotLabel ?? "file"}__${DateTime.now().microsecondsSinceEpoch}';

      setState(() {
        _newDocuments[key] = _PickedFile(name: file.name, bytes: bytes);
      });
    } catch (e) {
      _snack('Failed to pick file: $e', true);
    }
  }

  void _removeNewFile(String key) {
    setState(() {
      _newDocuments.remove(key);
    });
  }

  void _removeExistingFile(String id) {
    setState(() {
      _existingAttachmentIds.remove(id);
    });
  }

  // ============ Validation ============
  bool _validateStep(int step) {
    switch (step) {
      case 1:
        if (_businessNameCtrl.text.trim().isEmpty) {
          _snack('Business Name is required', true);
          return false;
        }
        if (_tradeLicenseNoCtrl.text.trim().isEmpty) {
          _snack('Trade License No. is required', true);
          return false;
        }
        if (_tinNoCtrl.text.trim().isEmpty) {
          _snack('TIN No. is required', true);
          return false;
        }
        if (_addressCtrl.text.trim().isEmpty) {
          _snack('Business Address is required', true);
          return false;
        }
        return true;

      case 2:
        if (_natureOfBusiness == null) {
          _snack('Nature of Business is required', true);
          return false;
        }
        if (_annualTurnOverRange == null) {
          _snack('Annual Turnover is required', true);
          return false;
        }
        if (_mainProductCtrl.text.trim().isEmpty) {
          _snack('Main Product / Service is required', true);
          return false;
        }
        if (_numberOfEmployees == null) {
          _snack('Number of Employees is required', true);
          return false;
        }
        return true;

      case 3:
        if (_existingAttachmentIds.isEmpty && _newDocuments.isEmpty) {
          _snack('Please keep or upload at least one document', true);
          return false;
        }
        return true;

      case 4:
        return true;

      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  // ============ Build MultipartFiles ============
  List<http.MultipartFile> _buildMultipartFiles() {
    final files = <http.MultipartFile>[];
    _newDocuments.forEach((key, picked) {
      files.add(VatService.multipartFromBytes(
        field: 'documents',
        bytes: picked.bytes,
        fileName: picked.name,
      ));
    });
    return files;
  }

  // ============ Submit ============
  Future<void> _submit() async {
    if (_userId == null || _userId!.isEmpty) {
      _snack('User not logged in', true);
      return;
    }

    if (!_hasAnyChange) {
      _snack('No changes to update');
      return;
    }

    setState(() => _submitting = true);

    try {
      final attachmentsJson = _existingAttachmentIds.isNotEmpty
          ? '[${_existingAttachmentIds.map((e) => '"$e"').join(',')}]'
          : null;

      await VatService.updateVatWithFiles(
        id: widget.vat.id!,
        userId: _userId!,
        adress: _addressCtrl.text.trim(),
        tinNo: _tinNoCtrl.text.trim(),
        buisnessName: _businessNameCtrl.text.trim(),
        tradeLicenseNo: _tradeLicenseNoCtrl.text.trim(),
        annualTurnOver: _annualTurnOverRange,
        mainProduct: _mainProductCtrl.text.trim(),
        natureOfBuisness: _natureOfBusiness,
        numberOfBuisness: 1,
        numberOfEmployee: _numberOfEmployees,
        attachmentsId: attachmentsJson,
        files: _buildMultipartFiles(), // ✅ bytes → MultipartFile
      );

      _snack('VAT updated successfully');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Failed: ${e.toString()}', true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Update VAT',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (_hasAnyChange)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Unsaved changes',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: VatStepIndicator(currentStep: _currentStep),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------- Step 1 ----------
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _updateHint(),
        const SizedBox(height: 8),
        _fieldLabel('Business Name'),
        _textField(_businessNameCtrl, 'Enter business name',
            original: _origBusinessName),
        const SizedBox(height: 16),
        _fieldLabel('Trade License No.'),
        _textField(_tradeLicenseNoCtrl, 'Enter trade license no.',
            original: _origTradeLicenseNo),
        const SizedBox(height: 16),
        _fieldLabel('TIN No.'),
        _textField(_tinNoCtrl, 'Enter TIN', original: _origTinNo),
        const SizedBox(height: 16),
        _fieldLabel('Business Address'),
        _textField(_addressCtrl, 'Enter address',
            maxLines: 2, original: _origAddress),
      ],
    );
  }

  // ---------- Step 2 ----------
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _updateHint(),
        const SizedBox(height: 8),
        _fieldLabel('Nature of Business'),
        _dropdownWithChange<String>(
          value: _natureOfBusiness,
          hint: 'Select nature',
          items: _natureOptions,
          labelBuilder: (v) => v,
          original: _origNature,
          onChanged: (v) => setState(() => _natureOfBusiness = v),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Annual Turnover'),
        _dropdownWithChange<String>(
          value: _annualTurnOverRange,
          hint: 'Select range',
          items: _turnoverRanges,
          labelBuilder: (v) => v,
          original: _origTurnover,
          onChanged: (v) => setState(() => _annualTurnOverRange = v),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Main Product / Service'),
        _textField(_mainProductCtrl, 'Enter product / service',
            original: _origMainProduct),
        const SizedBox(height: 16),
        _fieldLabel('No. of Employees'),
        _dropdownWithChange<int>(
          value: _numberOfEmployees,
          hint: 'Select range',
          items: _employeeRanges,
          labelBuilder: (v) => '$v',
          original: _origEmployees,
          onChanged: (v) => setState(() => _numberOfEmployees = v),
        ),
      ],
    );
  }

  // ---------- Step 3 ----------
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage Documents',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Existing files remain unless you remove them. Add new files freely.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // Existing files
        if (_existingAttachmentIds.isNotEmpty) ...[
          _docSectionHeader(
            icon: Icons.folder,
            title: 'Existing Documents (${_existingAttachmentIds.length})',
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 8),
          ..._existingAttachmentIds.asMap().entries.map((e) {
            final id = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1565C0).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Existing File',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'ID: ${id.length > 12 ? "${id.substring(0, 12)}…" : id}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility,
                        size: 18, color: Color(0xFF1565C0)),
                    tooltip: 'View',
                    onPressed: () => _openViewer(id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    tooltip: 'Remove',
                    onPressed: () => _removeExistingFile(id),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // New files
        if (_newDocuments.isNotEmpty) ...[
          _docSectionHeader(
            icon: Icons.new_releases,
            title: 'New Files (${_newDocuments.length})',
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 8),
          ..._newDocuments.entries.map((entry) {
            final key = entry.key;
            final picked = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.upload_file,
                        color: Colors.green.shade700, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          picked.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(picked.bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.red),
                    tooltip: 'Remove',
                    onPressed: () => _removeNewFile(key),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Add-new
        _docSectionHeader(
          icon: Icons.add_circle_outline,
          title: 'Add New Files',
          color: Colors.grey.shade700,
        ),
        const SizedBox(height: 8),
        ..._buildNewFileSlotTiles(),
      ],
    );
  }

  List<Widget> _buildNewFileSlotTiles() {
    const slots = [
      ('Trade License', 'Upload trade license (PDF/JPG/PNG)'),
      ('TIN Certificate', 'Upload TIN certificate (PDF/JPG/PNG)'),
      ('NID (Owner/Director)', 'Upload NID (PDF/JPG/PNG)'),
      ('Other Document', 'Upload additional document'),
    ];

    return slots.map((slot) {
      final label = slot.$1;
      final subtitle = slot.$2;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: VatDocumentUploadTile(
          title: label,
          subtitle: subtitle,
          onPick: () => _pickNewFile(slotLabel: label),
        ),
      );
    }).toList();
  }

  // ---------- Step 4 ----------
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hasAnyChange
                ? Colors.orange.shade50
                : Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hasAnyChange
                  ? Colors.orange.shade200
                  : Colors.green.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _hasAnyChange ? Icons.edit_note : Icons.check_circle,
                color: _hasAnyChange
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _hasAnyChange
                      ? 'Review the changes below before updating.'
                      : 'No changes detected yet.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _reviewCard('Business Information', [
          _diffRow('Business Name', _origBusinessName,
              _businessNameCtrl.text),
          _diffRow('Trade License No.', _origTradeLicenseNo,
              _tradeLicenseNoCtrl.text),
          _diffRow('TIN No.', _origTinNo, _tinNoCtrl.text),
          _diffRow('Business Address', _origAddress, _addressCtrl.text),
        ]),
        const SizedBox(height: 12),
        _reviewCard('Business Details', [
          _diffRow('Nature of Business', _origNature ?? '-',
              _natureOfBusiness ?? '-'),
          _diffRow('Annual Turnover', _origTurnover ?? '-',
              _annualTurnOverRange ?? '-'),
          _diffRow('Main Product', _origMainProduct,
              _mainProductCtrl.text),
          _diffRow('No. of Employees',
              _origEmployees?.toString() ?? '-',
              _numberOfEmployees?.toString() ?? '-'),
        ]),
        const SizedBox(height: 12),
        _reviewCard('Documents', [
          _diffRow(
            'Existing kept',
            '${_origAttachmentIds.length}',
            '${_existingAttachmentIds.length}',
          ),
          _diffRow('New files added', '0', '${_newDocuments.length}'),
        ]),
      ],
    );
  }

  // ============ Helpers ============
  Widget _updateHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1565C0).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Color(0xFF1565C0), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Old data is pre-filled. Modify any field you want to update.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF1565C0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    required String original,
  }) {
    final changed = ctrl.text.trim() != original.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
            filled: true,
            fillColor:
                changed ? Colors.orange.shade50 : Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: changed
                    ? Colors.orange.shade300
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: changed
                    ? Colors.orange.shade300
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF1565C0), width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        if (changed)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Changed from: $original',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _dropdownWithChange<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) labelBuilder,
    required T? original,
    required ValueChanged<T?> onChanged,
  }) {
    final changed = value != original;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color:
                changed ? Colors.orange.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: changed
                  ? Colors.orange.shade300
                  : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(
                hint,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(
                          labelBuilder(e),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        if (changed && original != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Changed from: $original',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _reviewCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _diffRow(String label, String oldVal, String newVal) {
    final changed = oldVal.trim() != newVal.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: changed
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oldVal.isEmpty ? '-' : oldVal,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.red.shade400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_forward,
                              size: 10, color: Colors.green),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              newVal.isEmpty ? '-' : newVal,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Text(
                    newVal.isEmpty ? '-' : newVal,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============ Footer ============
  Widget _buildFooter() {
    final isLast = _currentStep == _totalSteps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 1)
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _back,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Back',
                      style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            if (_currentStep > 1) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitting ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast
                      ? (_hasAnyChange
                          ? Colors.green.shade700
                          : Colors.grey.shade400)
                      : const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLast ? 'Update' : 'Next',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Viewer ============
  void _openViewer(String attachmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RJSCAttachmentViewer(
          attachmentId: attachmentId,
          jwtToken: token,
        ),
      ),
    );
  }
}