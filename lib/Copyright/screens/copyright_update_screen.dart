// lib/Copyright/screens/copyright_update_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../models/copyright_model.dart';
import '../models/upload_file_model.dart';
import '../services/copyright_service.dart';
import 'widgets/step_indicator.dart';
import 'widgets/step2_work_details.dart';
import 'widgets/step3_applicant_info.dart';
import 'widgets/step4_edit_documents.dart';
import 'widgets/step5_review_submit.dart';

class CopyrightUpdateScreen extends StatefulWidget {
  final CopyrightModel existingCopyright;

  const CopyrightUpdateScreen({
    super.key,
    required this.existingCopyright,
  });

  @override
  State<CopyrightUpdateScreen> createState() => _CopyrightUpdateScreenState();
}

class _CopyrightUpdateScreenState extends State<CopyrightUpdateScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 4; // note: no "Service Overview" step

  final List<String> _titles = [
    'Work Details',
    'Applicant Information',
    'Manage Documents',
    'Review & Submit',
  ];

  // ---------- Form Data ----------
  late String _typeOfWork;
  late String _titleOfWork;
  late String _author;
  late String _yearOfCreation;
  late String _description;
  late String _applicantName;
  late String _mobileNumber;
  late String _email;
  late String _address;

  // New files to upload
  final List<UploadFileModel> _newDocuments = [];

  // Existing file URLs from backend
  late List<String> _existingDocumentUrls;

  bool _isSubmitting = false;
  String? _successMessage;
  bool _submitted = false;

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _yearController;
  late final TextEditingController _descController;
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final c = widget.existingCopyright;
    _typeOfWork = c.typeOfWork;
    _titleOfWork = c.titleOfWork;
    _author = c.author;
    _yearOfCreation = c.yearOfCreation.year.toString();
    _description = c.description;
    _applicantName = c.applicationName;
    _mobileNumber = c.mobileNumber;
    _email = c.email;
    _address = c.adress;
    _existingDocumentUrls = List<String>.from(c.documents);

    _titleController = TextEditingController(text: c.titleOfWork);
    _authorController = TextEditingController(text: c.author);
    _yearController =
        TextEditingController(text: c.yearOfCreation.year.toString());
    _descController = TextEditingController(text: c.description);
    _nameController = TextEditingController(text: c.applicationName);
    _mobileController = TextEditingController(text: c.mobileNumber);
    _emailController = TextEditingController(text: c.email);
    _addressController = TextEditingController(text: c.adress);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _yearController.dispose();
    _descController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ---------- Navigation ----------
  void _next() {
    // Basic validation per step
    if (_currentStep == 0) {
      if (_typeOfWork.isEmpty ||
          _titleOfWork.trim().isEmpty ||
          _author.trim().isEmpty ||
          _yearOfCreation.trim().isEmpty) {
        _showSnack('Please fill all required fields in Work Details');
        return;
      }
    }
    if (_currentStep == 1) {
      if (_applicantName.trim().isEmpty ||
          _mobileNumber.trim().isEmpty ||
          _email.trim().isEmpty ||
          _address.trim().isEmpty) {
        _showSnack('Please fill all required fields in Applicant Information');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final userId = await AuthService.getUserId() ?? '';
    final yearIso = DateTime.tryParse(_yearOfCreation)
            ?.toUtc()
            .toIso8601String() ??
        DateTime(int.tryParse(_yearOfCreation) ?? DateTime.now().year)
            .toUtc()
            .toIso8601String();

    // docIds = kept existing URLs (filtered ones)
    final result = await CopyrightService.updateCopyright(
      id: widget.existingCopyright.id!,
      userId: userId,
      author: _author,
      typeOfWork: _typeOfWork,
      yearOfCreation: yearIso,
      titleOfWork: _titleOfWork,
      description: _description,
      applicationName: _applicantName,
      mobileNumber: _mobileNumber,
      email: _email,
      adress: _address,
      documentsId: _existingDocumentUrls,
      documents: _newDocuments,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      setState(() {
        _submitted = true;
        _successMessage = 'Your copyright has been updated successfully.';
      });
    } else {
      _showSnack(result['message'] ?? 'Update failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Update Copyright',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            StepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              titles: _titles,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Step2WorkDetails(
          typeOfWork: _typeOfWork,
          titleController: _titleController,
          authorController: _authorController,
          yearController: _yearController,
          descController: _descController,
          onTypeChanged: (v) => setState(() => _typeOfWork = v),
          onTitleChanged: (v) => _titleOfWork = v,
          onAuthorChanged: (v) => _author = v,
          onYearChanged: (v) => _yearOfCreation = v,
          onDescChanged: (v) => _description = v,
          onBack: _back,
          onNext: _next,
        );
      case 1:
        return Step3ApplicantInfo(
          nameController: _nameController,
          mobileController: _mobileController,
          emailController: _emailController,
          addressController: _addressController,
          onNameChanged: (v) => _applicantName = v,
          onMobileChanged: (v) => _mobileNumber = v,
          onEmailChanged: (v) => _email = v,
          onAddressChanged: (v) => _address = v,
          onBack: _back,
          onNext: _next,
        );
      case 2:
        return Step4EditDocuments(
          documents: _newDocuments,
          existingDocumentUrls: _existingDocumentUrls,
          onDocumentsChanged: (list) => setState(() {
            _newDocuments
              ..clear()
              ..addAll(list);
          }),
          onExistingUrlsChanged: (urls) => setState(() {
            _existingDocumentUrls
              ..clear()
              ..addAll(urls);
          }),
          onBack: _back,
          onNext: _next,
        );
      case 3:
        return Step5ReviewSubmit(
          typeOfWork: _typeOfWork,
          titleOfWork: _titleOfWork,
          author: _author,
          applicantName: _applicantName,
          documentCount:
              _existingDocumentUrls.length + _newDocuments.length,
          isSubmitting: _isSubmitting,
          onBack: _back,
          onSubmit: _submit,
          isUpdateMode: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------- Success Screen ----------
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF2E7D32), size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'Updated Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _successMessage ??
                    'Your copyright registration has been updated.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 32),
              if (widget.existingCopyright.id != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Application ID',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        widget.existingCopyright.id!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Done'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFF1A3FBF)),
                  foregroundColor: const Color(0xFF1A3FBF),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}