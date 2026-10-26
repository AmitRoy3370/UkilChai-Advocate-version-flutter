// lib/vat/screens/vat_registration_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
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

class VatRegistrationPage extends StatefulWidget {
  /// If [existing] is provided, this page acts as an **Update** page.
  final VatModel? existing;

  const VatRegistrationPage({super.key, this.existing});

  bool get isUpdate => existing != null;

  @override
  State<VatRegistrationPage> createState() => _VatRegistrationPageState();
}

class _VatRegistrationPageState extends State<VatRegistrationPage> {
  int _currentStep = 1;
  static const int _totalSteps = 4;

  // ============ Form State ============
  final _businessNameCtrl = TextEditingController();
  final _tradeLicenseNoCtrl = TextEditingController();
  final _tinNoCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mainProductCtrl = TextEditingController();

  String? _natureOfBusiness;
  String? _annualTurnOverRange;
  int? _numberOfEmployees;

  // ============ Document State ============
  /// Existing attachment IDs (already on the server)
  List<String> _existingAttachmentIds = [];

  /// Newly picked files, keyed by slot name.
  /// Stores {name, bytes} — never path — so it works on web too.
  final Map<String, _PickedFile> _localDocuments = {};

  bool _submitting = false;
  String? _userId;

  // ============ Dropdown Options ============
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

  static const List<String> _docSlots = [
    'Trade License',
    'TIN Certificate',
    'NID (Owner/Director)',
    'Other Document (if any)',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    if (widget.isUpdate) {
      _prefillFrom(widget.existing!);
    }
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

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ??
          prefs.getString('userId') ??
          prefs.getString('_id');
    });
  }

  void _prefillFrom(VatModel v) {
    _businessNameCtrl.text = v.buisnessName;
    _tradeLicenseNoCtrl.text = v.tradeLicenseNo;
    _tinNoCtrl.text = v.tinNo;
    _addressCtrl.text = v.adress;
    _mainProductCtrl.text = v.mainProduct;
    _natureOfBusiness =
        _natureOptions.contains(v.natureOfBuisness) ? v.natureOfBuisness : null;
    _annualTurnOverRange = _turnoverRanges.contains(v.annualTurnOver)
        ? v.annualTurnOver
        : null;
    _numberOfEmployees = v.numberOfEmployee > 0 ? v.numberOfEmployee : null;
    _existingAttachmentIds = List<String>.from(v.documents);
  }

  // ============ File Picker (Web + Mobile Safe) ============
  Future<void> _pickFile(String slot) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true, // ✅ REQUIRED on web — forces bytes to be populated
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _showSnack('Could not read file bytes', isError: true);
        return;
      }

      // ✅ Only uses file.name + file.bytes — no file.path
      setState(() {
        _localDocuments[slot] = _PickedFile(name: file.name, bytes: bytes);
      });
    } catch (e) {
      _showSnack('Failed to pick file: $e', isError: true);
    }
  }

  void _removeLocal(String slot) {
    setState(() {
      _localDocuments.remove(slot);
    });
  }

  // ============ Validation ============
  bool _validateStep(int step) {
    switch (step) {
      case 1:
        if (_businessNameCtrl.text.trim().isEmpty) {
          _showSnack('Business Name is required', isError: true);
          return false;
        }
        if (_tradeLicenseNoCtrl.text.trim().isEmpty) {
          _showSnack('Trade License No. is required', isError: true);
          return false;
        }
        if (_tinNoCtrl.text.trim().isEmpty) {
          _showSnack('TIN No. is required', isError: true);
          return false;
        }
        if (_addressCtrl.text.trim().isEmpty) {
          _showSnack('Business Address is required', isError: true);
          return false;
        }
        return true;

      case 2:
        if (_natureOfBusiness == null) {
          _showSnack('Nature of Business is required', isError: true);
          return false;
        }
        if (_annualTurnOverRange == null) {
          _showSnack('Annual Turnover is required', isError: true);
          return false;
        }
        if (_mainProductCtrl.text.trim().isEmpty) {
          _showSnack('Main Product / Service is required', isError: true);
          return false;
        }
        if (_numberOfEmployees == null) {
          _showSnack('Number of Employees is required', isError: true);
          return false;
        }
        return true;

      case 3:
        if (_existingAttachmentIds.isEmpty && _localDocuments.isEmpty) {
          _showSnack('Please upload at least one document', isError: true);
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

  // ============ Build MultipartFiles from local docs ============
  List<http.MultipartFile> _buildMultipartFiles() {
    final files = <http.MultipartFile>[];
    _localDocuments.forEach((slot, picked) {
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
      _showSnack('User not logged in', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final files = _buildMultipartFiles();

      if (widget.isUpdate) {
        // ---- UPDATE ----
        final attachmentsJson = _existingAttachmentIds.isNotEmpty
            ? '[${_existingAttachmentIds.map((e) => '"$e"').join(',')}]'
            : null;

        await VatService.updateVatWithFiles(
          id: widget.existing!.id!,
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
          files: files,
        );
        _showSnack('VAT updated successfully');
      } else {
        // ---- CREATE ----
        await VatService.addVatWithFiles(
          userId: _userId!,
          adress: _addressCtrl.text.trim(),
          tinNo: _tinNoCtrl.text.trim(),
          buisnessName: _businessNameCtrl.text.trim(),
          tradeLicenseNo: _tradeLicenseNoCtrl.text.trim(),
          annualTurnOver: _annualTurnOverRange ?? '',
          mainProduct: _mainProductCtrl.text.trim(),
          natureOfBuisness: _natureOfBusiness ?? '',
          numberOfBuisness: 1,
          numberOfEmployee: _numberOfEmployees ?? 0,
          files: files,
        );
        _showSnack('VAT application submitted successfully');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
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
        title: Text(
          widget.isUpdate ? 'Update VAT' : 'VAT Registration',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
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
        _fieldLabel('Business Name'),
        _textField(_businessNameCtrl, 'Enter business name'),
        const SizedBox(height: 16),
        _fieldLabel('Trade License No.'),
        _textField(_tradeLicenseNoCtrl, 'Enter trade license no.'),
        const SizedBox(height: 16),
        _fieldLabel('TIN No.'),
        _textField(_tinNoCtrl, 'Enter TIN'),
        const SizedBox(height: 16),
        _fieldLabel('Business Address'),
        _textField(_addressCtrl, 'Enter address', maxLines: 2),
      ],
    );
  }

  // ---------- Step 2 ----------
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Nature of Business'),
        _dropdown<String>(
          value: _natureOfBusiness,
          hint: 'Select nature',
          items: _natureOptions,
          labelBuilder: (v) => v,
          onChanged: (v) => setState(() => _natureOfBusiness = v),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Annual Turnover'),
        _dropdown<String>(
          value: _annualTurnOverRange,
          hint: 'Select range',
          items: _turnoverRanges,
          labelBuilder: (v) => v,
          onChanged: (v) => setState(() => _annualTurnOverRange = v),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Main Product / Service'),
        _textField(_mainProductCtrl, 'Enter product / service'),
        const SizedBox(height: 16),
        _fieldLabel('No. of Employees'),
        _dropdown<int>(
          value: _numberOfEmployees,
          hint: 'Select range',
          items: _employeeRanges,
          labelBuilder: (v) => '$v',
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
          'Upload required documents',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accepted: PDF, JPG, PNG (max 10 MB each)',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        ..._docSlots.map((slot) {
          final existingIndex = _docSlots.indexOf(slot);
          final existingId = existingIndex < _existingAttachmentIds.length
              ? _existingAttachmentIds[existingIndex]
              : null;
          final local = _localDocuments[slot];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: VatDocumentUploadTile(
              title: slot,
              fileName: local?.name ?? existingId,
              localBytes: local?.bytes,
              onPick: () => _pickFile(slot),
              onRemove: local != null
                  ? () => _removeLocal(slot)
                  : existingId != null
                      ? () => setState(() {
                            _existingAttachmentIds.remove(existingId);
                          })
                      : null,
              onPreview: existingId != null && local == null
                  ? () => _openViewer(existingId)
                  : null,
            ),
          );
        }),
      ],
    );
  }

  // ---------- Step 4 ----------
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review your information',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _reviewCard('Business Information', [
          _reviewRow('Business Name', _businessNameCtrl.text),
          _reviewRow('Trade License No.', _tradeLicenseNoCtrl.text),
          _reviewRow('TIN No.', _tinNoCtrl.text),
          _reviewRow('Business Address', _addressCtrl.text),
        ]),
        const SizedBox(height: 12),
        _reviewCard('Business Details', [
          _reviewRow('Nature of Business', _natureOfBusiness ?? '-'),
          _reviewRow('Annual Turnover', _annualTurnOverRange ?? '-'),
          _reviewRow('Main Product', _mainProductCtrl.text),
          _reviewRow(
              'No. of Employees', _numberOfEmployees?.toString() ?? '-'),
        ]),
        const SizedBox(height: 12),
        _reviewCard('Uploaded Documents', [
          if (_existingAttachmentIds.isEmpty && _localDocuments.isEmpty)
            _reviewRow('Documents', 'None'),
          ..._existingAttachmentIds.map((id) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.attachment,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Attachment: ${id.substring(0, id.length > 10 ? 10 : id.length)}…',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      onPressed: () => _openViewer(id),
                      tooltip: 'View',
                    ),
                  ],
                ),
              )),
          ..._localDocuments.entries
              .map((e) => _reviewRow(e.key, e.value.name)),
        ]),
      ],
    );
  }

  // ============ Reusable widgets ============
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

  Widget _textField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
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
                      ? Colors.green.shade700
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
                        isLast
                            ? (widget.isUpdate ? 'Update' : 'Submit')
                            : 'Next',
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