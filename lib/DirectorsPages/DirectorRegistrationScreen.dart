// lib/DirectorsPages/director_registration_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../DirectorsPages/director.dart';
import '../DirectorsPages/director_service.dart';
import '../Auth/AuthService.dart';
import '../DirectorsPages/director_profile_page.dart';
import '../DirectorsPages/DirectorAttachmentViewer.dart';

class DirectorRegistrationScreen extends StatefulWidget {
  final String? userId;
  final Director? existingDirector;
  final String? existingNidId;

  const DirectorRegistrationScreen({
    Key? key,
    required this.userId,
    this.existingDirector,
    this.existingNidId,
  }) : super(key: key);

  @override
  State<DirectorRegistrationScreen> createState() => _DirectorRegistrationScreenState();
}

class _DirectorRegistrationScreenState extends State<DirectorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _directorService = DirectorService();

  late TextEditingController _positionController;
  
  PlatformFile? _nidFile;
  String? _nidFileName;
  bool _isLoading = false;
  bool _isUpdateMode = false;
  bool _keepExistingNid = true;
  String? _jwtToken;
  
  bool _shouldRemoveNid = false;
  String? _currentNidId;

  @override
  void initState() {
    super.initState();
    _positionController = TextEditingController();
    _isUpdateMode = widget.existingDirector != null;
    _currentNidId = widget.existingNidId;
    
    if (_isUpdateMode && widget.existingDirector != null) {
      _positionController.text = widget.existingDirector!.position;
      // ✅ Debug print
      print('📌 Update Mode - Director ID: ${widget.existingDirector!.id}');
      print('📌 Update Mode - User ID: ${widget.userId}');
      print('📌 Update Mode - NID: ${widget.existingNidId}');
    }
    
    _loadToken();
  }

  Future<void> _loadToken() async {
    _jwtToken = await AuthService.getToken();
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        final fileName = file.name.toLowerCase();
        if (!fileName.endsWith('.pdf')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a PDF file only'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            _nidFile = file;
            _nidFileName = file.name;
            _keepExistingNid = false;
            _shouldRemoveNid = false;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF selected: ${file.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking PDF: $e')),
        );
      }
    }
  }

  void _viewExistingNid() {
    if (_currentNidId == null || _currentNidId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No NID document found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_jwtToken == null || _jwtToken!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login again to view NID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DirectorAttachmentViewer(
            attachmentId: _currentNidId!,
            jwtToken: _jwtToken!,
          ),
        ),
      );
    }
  }

  void _showFilePickerOptions() {
    final hasExistingNid = _isUpdateMode && 
        _currentNidId != null && 
        _currentNidId!.isNotEmpty &&
        !_shouldRemoveNid;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (hasExistingNid && _nidFile == null)
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View Current NID'),
                subtitle: const Text('View the existing NID document'),
                onTap: () {
                  Navigator.pop(context);
                  _viewExistingNid();
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(_isUpdateMode ? 'Replace NID with New PDF' : 'Select PDF Document'),
              subtitle: Text(_isUpdateMode ? 'Upload a new NID document' : 'Only PDF files are allowed'),
              onTap: () {
                Navigator.pop(context);
                _pickPDFFile();
              },
            ),
            
            if (hasExistingNid && _nidFile == null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove NID', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Remove the existing NID document'),
                onTap: () {
                  Navigator.pop(context);
                  _removeExistingNid();
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

  void _removeExistingNid() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove NID'),
        content: const Text(
          'Are you sure you want to remove the existing NID document? This action will be applied when you update the director.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  _shouldRemoveNid = true;
                  _currentNidId = null;
                  _keepExistingNid = false;
                  _nidFile = null;
                  _nidFileName = null;
                });
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('NID document will be removed on update'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeFile() {
    if (mounted) {
      setState(() {
        _nidFile = null;
        _nidFileName = null;
        _keepExistingNid = true;
        _shouldRemoveNid = false;
        _currentNidId = widget.existingNidId;
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New file removed. Keeping existing NID.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ✅ For new registration, NID is required
    if (!_isUpdateMode && _nidFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a PDF file for NID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login again'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final position = _positionController.text.trim();
      if (position.isEmpty) {
        throw Exception('Position is required');
      }

      // ✅ Print all values before sending
      print('========== SUBMIT FORM DEBUG ==========');
      print('Is Update Mode: $_isUpdateMode');
      print('User ID: ${widget.userId}');
      print('Position: $position');
      print('Current NID ID: $_currentNidId');
      print('Should Remove NID: $_shouldRemoveNid');
      print('New NID File: ${_nidFile?.name ?? 'None'}');
      print('New NID File Size: ${_nidFile?.size ?? 0}');
      print('========================================');

      if (_isUpdateMode && widget.existingDirector != null) {
        print('🔄 Updating director...');
        print('🔄 Director ID: ${widget.existingDirector!.id}');
        
        // ✅ Create director with all fields INCLUDING the ID
        final director = Director(
          id: widget.existingDirector!.id, // ✅ IMPORTANT: Include the ID
          userId: widget.userId!,
          position: position,
          nid: _currentNidId,
        );
        
        // ✅ Print the JSON that will be sent
        print('📤 Director JSON being sent: ${jsonEncode(director.toJson())}');
        
        final updatedDirector = await _directorService.updateDirector(
          id: widget.existingDirector!.id!,
          director: director,
          userId: widget.userId!,
          nidFile: _nidFile,
          removeNid: _shouldRemoveNid,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Director updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DirectorProfilePage(
                directorId: updatedDirector.id!,
                userId: widget.userId!,
              ),
            ),
          );
        }
      } else {
        print('🆕 Registering new director...');
        
        final director = Director(
          userId: widget.userId!,
          position: position,
        );
        
        final createdDirector = await _directorService.addDirector(
          director: director,
          userId: widget.userId!,
          nidFile: _nidFile,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Director registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DirectorProfilePage(
                directorId: createdDirector.id!,
                userId: widget.userId!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      final errorMsg = e.toString();
      print('❌ Error: $errorMsg');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingNid = _isUpdateMode && 
        _currentNidId != null && 
        _currentNidId!.isNotEmpty &&
        !_shouldRemoveNid;

    // ✅ Safely get the NID display string
    String getNidDisplay() {
      if (_currentNidId == null || _currentNidId!.isEmpty) {
        return 'No NID';
      }
      if (_currentNidId!.length >= 8) {
        return _currentNidId!.substring(0, 8);
      }
      return _currentNidId!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isUpdateMode ? 'Update Director' : 'Register Director'),
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

              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position *',
                  hintText: 'e.g., Managing Director, CEO, CFO',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_center),
                  helperText: 'Enter the director\'s position in the company',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter position';
                  }
                  if (value.trim().length < 2) {
                    return 'Position must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Container(
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
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'NID Document (PDF Only)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isUpdateMode)
                            const Text(
                              ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          const Spacer(),
                          if (hasExistingNid && _nidFile == null)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: TextButton.icon(
                                onPressed: _viewExistingNid,
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
                      
                      // ✅ Fixed: Safely display NID with null check
                      if (hasExistingNid && _nidFile == null) ...[
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current NID: ${getNidDisplay()}...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Tap below to replace or remove',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_shouldRemoveNid) ...[
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
                                  'NID will be removed on update',
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
                          onTap: _showFilePickerOptions,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                if (_nidFile != null)
                                  Icon(
                                    Icons.check_circle,
                                    size: 60,
                                    color: Colors.green,
                                  )
                                else if (_shouldRemoveNid)
                                  Icon(
                                    Icons.delete_forever,
                                    size: 60,
                                    color: Colors.red,
                                  )
                                else if (hasExistingNid)
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 60,
                                    color: Colors.blue.shade700,
                                  )
                                else
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 60,
                                    color: Colors.red,
                                  ),
                                
                                const SizedBox(height: 10),
                                
                                Text(
                                  _nidFile != null
                                      ? _nidFileName ?? 'PDF selected'
                                      : _shouldRemoveNid
                                          ? 'NID will be removed'
                                          : hasExistingNid
                                              ? 'Tap to replace or view NID'
                                              : 'Tap to select PDF file',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _nidFile != null 
                                        ? Colors.green 
                                        : _shouldRemoveNid
                                            ? Colors.red.shade700
                                            : hasExistingNid
                                                ? Colors.blue.shade700
                                                : Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                if (_nidFile != null) ...[
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
                                      'New PDF Ready',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (!kIsWeb)
                                    Text(
                                      '${(_nidFile!.size / 1024).toStringAsFixed(2)} KB',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: _removeFile,
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Remove New File'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                      minimumSize: const Size(double.infinity, 35),
                                    ),
                                  ),
                                ] else if (!_isUpdateMode) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Only PDF files are accepted',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                                
                                if (!_isUpdateMode && _nidFile == null)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '* Required for new registration',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                        _isUpdateMode ? 'Update Director' : 'Register Director',
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