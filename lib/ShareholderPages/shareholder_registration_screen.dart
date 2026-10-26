// lib/ShareholderPages/shareholder_registration_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../ShareholderPages/shareholder.dart';
import '../ShareholderPages/shareholder_service.dart';
import '../ShareholderPages/shareholder_profile_page.dart';
import '../ShareholderPages/ShareholderAttachmentViewer.dart';
import '../Auth/AuthService.dart';

class ShareholderRegistrationScreen extends StatefulWidget {
  final String? userId;
  final Shareholder? existingShareholder;
  final String? existingNidId;
  final String? existingTinId;

  const ShareholderRegistrationScreen({
    Key? key,
    required this.userId,
    this.existingShareholder,
    this.existingNidId,
    this.existingTinId,
  }) : super(key: key);

  @override
  State<ShareholderRegistrationScreen> createState() => _ShareholderRegistrationScreenState();
}

class _ShareholderRegistrationScreenState extends State<ShareholderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shareholderService = ShareholderService();

  late TextEditingController _userIdController;
  
  PlatformFile? _nidFile;
  String? _nidFileName;
  PlatformFile? _tinFile;
  String? _tinFileName;
  
  bool _isLoading = false;
  bool _isUpdateMode = false;
  String? _jwtToken;
  
  bool _shouldRemoveNid = false;
  bool _shouldRemoveTin = false;
  String? _currentNidId;
  String? _currentTinId;

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController();
    _isUpdateMode = widget.existingShareholder != null;
    _currentNidId = widget.existingNidId;
    _currentTinId = widget.existingTinId;
    
    if (_isUpdateMode && widget.existingShareholder != null) {
      _userIdController.text = widget.existingShareholder!.userId;
      print('📌 Update Mode - Shareholder ID: ${widget.existingShareholder!.id}');
      print('📌 Update Mode - User ID: ${widget.userId}');
      print('📌 Update Mode - NID: ${widget.existingNidId}');
      print('📌 Update Mode - TIN: ${widget.existingTinId}');
    }
    
    _loadToken();
  }

  Future<void> _loadToken() async {
    _jwtToken = await AuthService.getToken();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file extension
        final fileName = file.name.toLowerCase();
        final validExtensions = ['.pdf', '.doc', '.docx', '.png', '.jpg', '.jpeg'];
        if (!validExtensions.any((ext) => fileName.endsWith(ext))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid document (PDF, DOC, DOCX, PNG, JPG)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          if (type == 'nid') {
            _nidFile = file;
            _nidFileName = file.name;
            _shouldRemoveNid = false;
          } else {
            _tinFile = file;
            _tinFileName = file.name;
            _shouldRemoveTin = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} selected: ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _viewAttachment(String attachmentId, String type) {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again to view attachment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareholderAttachmentViewer(
          attachmentId: attachmentId,
          jwtToken: _jwtToken!,
        ),
      ),
    );
  }

  void _showFilePickerOptions(String type) {
    final hasExisting = type == 'nid' 
        ? (_currentNidId != null && _currentNidId!.isNotEmpty && !_shouldRemoveNid)
        : (_currentTinId != null && _currentTinId!.isNotEmpty && !_shouldRemoveTin);

    final currentId = type == 'nid' ? _currentNidId : _currentTinId;
    final hasFile = type == 'nid' ? _nidFile != null : _tinFile != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (hasExisting && !hasFile)
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: Text('View Current ${type.toUpperCase()}'),
                subtitle: const Text('View the existing document'),
                onTap: () {
                  Navigator.pop(context);
                  _viewAttachment(currentId!, type);
                },
              ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.blue),
              title: Text(hasExisting ? 'Replace ${type.toUpperCase()}' : 'Upload ${type.toUpperCase()}'),
              subtitle: const Text('PDF, DOC, DOCX, PNG, JPG allowed'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(type);
              },
            ),
            if (hasExisting && !hasFile)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('Remove ${type.toUpperCase()}', style: const TextStyle(color: Colors.red)),
                subtitle: const Text('Remove the existing document'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    if (type == 'nid') {
                      _shouldRemoveNid = true;
                      _currentNidId = null;
                      _nidFile = null;
                      _nidFileName = null;
                    } else {
                      _shouldRemoveTin = true;
                      _currentTinId = null;
                      _tinFile = null;
                      _tinFileName = null;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${type.toUpperCase()} will be removed on update'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeFile(String type) {
    setState(() {
      if (type == 'nid') {
        _nidFile = null;
        _nidFileName = null;
        _shouldRemoveNid = false;
        _currentNidId = widget.existingNidId;
      } else {
        _tinFile = null;
        _tinFileName = null;
        _shouldRemoveTin = false;
        _currentTinId = widget.existingTinId;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type.toUpperCase()} file removed. Keeping existing.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ✅ For new registration, at least NID is required
    if (!_isUpdateMode && _nidFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document for NID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('========== SUBMIT FORM DEBUG ==========');
      print('Is Update Mode: $_isUpdateMode');
      print('User ID: ${widget.userId}');
      print('Current NID ID: $_currentNidId');
      print('Current TIN ID: $_currentTinId');
      print('Should Remove NID: $_shouldRemoveNid');
      print('Should Remove TIN: $_shouldRemoveTin');
      print('New NID File: ${_nidFile?.name ?? 'None'}');
      print('New TIN File: ${_tinFile?.name ?? 'None'}');
      print('========================================');

      final shareholder = Shareholder(
        userId: widget.userId!,
        nid: _currentNidId,
        tin: _currentTinId,
        sharePercentage: {},
      );

      if (_isUpdateMode && widget.existingShareholder != null) {
        print('🔄 Updating shareholder...');
        print('🔄 Shareholder ID: ${widget.existingShareholder!.id}');
        
        final updatedShareholder = await _shareholderService.updateShareholder(
          id: widget.existingShareholder!.id!,
          shareholder: shareholder,
          userId: widget.userId!,
          nidFile: _nidFile,
          tinFile: _tinFile,
          removeNid: _shouldRemoveNid,
          removeTin: _shouldRemoveTin,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Shareholder updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ShareholderProfilePage(
                shareholderId: updatedShareholder.id!,
                userId: widget.userId!,
              ),
            ),
          );
        }
      } else {
        print('🆕 Registering new shareholder...');
        
        final createdShareholder = await _shareholderService.addShareholder(
          shareholder: shareholder,
          userId: widget.userId!,
          nidFile: _nidFile,
          tinFile: _tinFile,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Shareholder registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ShareholderProfilePage(
                shareholderId: createdShareholder.id!,
                userId: widget.userId!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      final errorMsg = e.toString();
      print('❌ Error: $errorMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFileUploadSection({
    required String title,
    required String type,
    required bool hasExisting,
    required bool shouldRemove,
    required String? fileName,
    required VoidCallback onRemove,
    required VoidCallback onTap,
    IconData icon = Icons.upload_file,
    Color iconColor = Colors.blue,
  }) {
    final hasFile = fileName != null;
    final isNid = type == 'nid';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isUpdateMode && isNid)
                  const Text(
                    ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                const Spacer(),
                if (hasExisting && !hasFile && !shouldRemove)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        _viewAttachment(
                          isNid ? _currentNidId! : _currentTinId!,
                          type,
                        );
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasExisting && !hasFile && !shouldRemove) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current ${type.toUpperCase()} exists. Tap below to view, replace or remove.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (shouldRemove) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${type.toUpperCase()} will be removed on update',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        hasFile ? Icons.check_circle : icon,
                        size: 50,
                        color: hasFile ? Colors.green : iconColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasFile
                            ? fileName!
                            : hasExisting && !shouldRemove
                                ? 'Tap to view, replace or remove'
                                : shouldRemove
                                    ? 'Document will be removed'
                                    : 'Tap to upload document',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: hasFile 
                              ? Colors.green 
                              : shouldRemove
                                  ? Colors.red.shade700
                                  : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (hasFile) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'New File Ready',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!kIsWeb)
                          Text(
                            '${((_nidFile?.size ?? _tinFile?.size ?? 0) / 1024).toStringAsFixed(2)} KB',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: onRemove,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Remove New File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            minimumSize: const Size(double.infinity, 35),
                          ),
                        ),
                      ] else if (!_isUpdateMode && isNid) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '* Required for new registration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingNid = _isUpdateMode && 
        _currentNidId != null && 
        _currentNidId!.isNotEmpty &&
        !_shouldRemoveNid;

    final hasExistingTin = _isUpdateMode && 
        _currentTinId != null && 
        _currentTinId!.isNotEmpty &&
        !_shouldRemoveTin;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isUpdateMode ? 'Update Shareholder' : 'Register Shareholder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'User ID: ${widget.userId ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // NID Upload
              _buildFileUploadSection(
                title: 'NID Document',
                type: 'nid',
                hasExisting: hasExistingNid,
                shouldRemove: _shouldRemoveNid,
                fileName: _nidFileName,
                onRemove: () => _removeFile('nid'),
                onTap: () => _showFilePickerOptions('nid'),
                icon: Icons.picture_as_pdf,
                iconColor: Colors.red,
              ),
              const SizedBox(height: 20),

              // TIN Upload
              _buildFileUploadSection(
                title: 'TIN Document',
                type: 'tin',
                hasExisting: hasExistingTin,
                shouldRemove: _shouldRemoveTin,
                fileName: _tinFileName,
                onRemove: () => _removeFile('tin'),
                onTap: () => _showFilePickerOptions('tin'),
                icon: Icons.assignment,
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isUpdateMode ? 'Update Shareholder' : 'Register Shareholder',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}