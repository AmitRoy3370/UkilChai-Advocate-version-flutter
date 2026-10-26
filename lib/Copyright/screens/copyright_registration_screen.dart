// lib/Copyright/screens/copyright_registration_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../models/copyright_model.dart';
import '../models/upload_file_model.dart';
import '../services/copyright_service.dart';
import '../services/copyright_registration_process_service.dart';
import '../models/copyright_registration_process_model.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/step_indicator.dart';
import 'widgets/step1_service_overview.dart';
import 'widgets/step2_work_details.dart';
import 'widgets/step3_applicant_info.dart';
import 'widgets/step4_upload_documents.dart';
import 'widgets/step5_review_submit.dart';

class CopyrightRegistrationScreen extends StatefulWidget {
  /// যদি update করতে চান, existing copyright model pass করুন
  final CopyrightModel? existingCopyright;
  final String? copyrightId;

  const CopyrightRegistrationScreen({
    super.key,
    this.existingCopyright,
    this.copyrightId,
  });

  @override
  State<CopyrightRegistrationScreen> createState() =>
      _CopyrightRegistrationScreenState();
}

class _CopyrightRegistrationScreenState
    extends State<CopyrightRegistrationScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 5;

  String? _currentUserId;
  String? _currentUserName;


  final List<String> _titles = [
    'Service Overview',
    'Work Details',
    'Applicant Information',
    'Upload Documents',
    'Review & Submit',
  ];

  // ---------- Form Data ----------
  String _typeOfWork = '';
  String _titleOfWork = '';
  String _author = '';
  String _yearOfCreation = '';
  String _description = '';
  String _applicantName = '';
  String _mobileNumber = '';
  String _email = '';
  String _address = '';
  final List<UploadFileModel> _documents = [];

  bool _isSubmitting = false;
  String? _submittedApplicationId;
  bool _submitted = false;

  // Controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _yearController = TextEditingController();
  final _descController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingCopyright != null) {
      _prefillFromExisting(widget.existingCopyright!);
    }
  _loadUserInfo();
  }

 /// Copyright registration page এর মতোই user info load করা
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentUserId = prefs.getString('userId');
      _currentUserName = prefs.getString('userName') ??
          prefs.getString('name') ??
          '';
    });
  }


  void _prefillFromExisting(CopyrightModel c) {
    _typeOfWork = c.typeOfWork;
    _titleOfWork = c.titleOfWork;
    _author = c.author;
    _yearOfCreation =
        c.yearOfCreation.year.toString(); // or full ISO if you prefer
    _description = c.description;
    _applicantName = c.applicationName;
    _mobileNumber = c.mobileNumber;
    _email = c.email;
    _address = c.adress;

    _titleController.text = c.titleOfWork;
    _authorController.text = c.author;
    _yearController.text = c.yearOfCreation.year.toString();
    _descController.text = c.description;
    _nameController.text = c.applicationName;
    _mobileController.text = c.mobileNumber;
    _emailController.text = c.email;
    _addressController.text = c.adress;
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

  bool get _isUpdateMode => widget.copyrightId != null;

  // ---------- Navigation ----------
  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
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

    Map<String, dynamic> result;

    if (_isUpdateMode) {
      result = await CopyrightService.updateCopyright(
        id: widget.copyrightId!,
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
        documents: _documents,
      );
    } else {
      result = await CopyrightService.addCopyright(
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
        documents: _documents,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      // ✅ FIX: data কে try এর বাইরে declare করা হয়েছে
      final dynamic data = result['data'];
      final String? newId = data is Map ? data['id']?.toString() : null;

      // Create the registration-process record (শুধু নতুন registration এ)
      if (newId != null && !_isUpdateMode) {
        try {
          final process = CopyrightRegistrationProcessModel(
            copyrightId: newId,
            userId: userId,
            advocateId: '',
            stpes: ['Submitted'],
            status: false,
          );
          await CopyrightRegistrationProcessService.addProcess(
            userId: userId,
            process: process,
          );
        } catch (e) {
          debugPrint('Process creation failed: $e');
          // Process fail হলেও registration সফল, তাই continue
        }
      }

      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submittedApplicationId =
            newId ?? 'CR-${DateTime.now().year}-000001';
        _currentStep = _totalSteps; // show success
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Submission failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔹 Chat with Executive — RJSC page এর মতোই FreeConsultantPage open করবে
  void _openChatWithExecutive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FreeConsultantPage(
          currentUserId: _currentUserId,
          currentUserName: _currentUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          _isUpdateMode ? 'Update Copyright' : 'Copyright Registration',
          style: const TextStyle(color: Colors.black87, fontSize: 18),
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
        return Step1ServiceOverview(onApplyNow: _next);
      case 1:
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
      case 2:
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
      case 3:
        return Step4UploadDocuments(
          documents: _documents,
          onDocumentsChanged: (list) => setState(() => _documents
            ..clear()
            ..addAll(list)),
          onBack: _back,
          onNext: _next,
        );
      case 4:
        return Step5ReviewSubmit(
          typeOfWork: _typeOfWork,
          titleOfWork: _titleOfWork,
          author: _author,
          applicantName: _applicantName,
          documentCount: _documents.length,
          isSubmitting: _isSubmitting,
          onBack: _back,
          onSubmit: _submit,
          isUpdateMode: _isUpdateMode,
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
              Text(
                _isUpdateMode
                    ? 'Application Updated!'
                    : 'Application Submitted!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isUpdateMode
                    ? 'Your copyright registration has been updated successfully.'
                    : 'Your copyright registration application has been submitted successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Application ID',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      _submittedApplicationId ?? 'N/A',
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
                icon: const Icon(Icons.track_changes),
                label: const Text('Track Application'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFF1A3FBF)),
                  foregroundColor: const Color(0xFF1A3FBF),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openChatWithExecutive(),
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Executive'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  foregroundColor: const Color(0xFF2E7D32),
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