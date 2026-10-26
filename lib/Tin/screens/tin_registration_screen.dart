// lib/Tin/screens/tin_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Auth/AuthService.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import '../models/upload_file_model.dart';
import '../models/tin_registration_process_model.dart';
import '../services/tin_service.dart';
import '../services/tin_registration_process_service.dart';
import 'widgets/tin_step_indicator.dart';
import 'widgets/tin_step1_personal_info.dart';
import 'widgets/tin_step2_address.dart';
import 'widgets/tin_step3_upload_docs.dart';
import 'widgets/tin_step4_review_submit.dart';

class TinRegistrationScreen extends StatefulWidget {
  const TinRegistrationScreen({super.key});

  @override
  State<TinRegistrationScreen> createState() => _TinRegistrationScreenState();
}

class _TinRegistrationScreenState extends State<TinRegistrationScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 4;

  final List<String> _titles = [
    'Personal Information',
    'Present & Permanent Address',
    'Upload Documents',
    'Review & Submit',
  ];

  // ---------- Form Data ----------
  String _fullName = '';
  String _fatherName = '';
  String _motherName = '';
  DateTime? _dateOfBirth;
  String _mobile = '';

  String? _presentDivision;
  String? _presentDistrict;
  String? _presentUpazila;
  String? _permanentDivision;
  String? _permanentDistrict;
  String? _permanentUpazila;

  final List<UploadFileModel> _documents = [];

  bool _isSubmitting = false;
  bool _submitted = false;
  String? _submittedId;

  String? _currentUserId;
  String? _currentUserName;

  // Controllers
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();

  static const _divisions = [
    'Dhaka', 'Chittagong', 'Rajshahi', 'Khulna',
    'Barisal', 'Sylhet', 'Rangpur', 'Mymensingh',
  ];
  static const _districts = [
    'Dhaka', 'Gazipur', 'Narayanganj', 'Chittagong', 'Comilla',
    'Rajshahi', 'Khulna', 'Sylhet', 'Barisal', 'Rangpur',
  ];
  static const _upazilas = [
    'Savar', 'Dhamrai', 'Keraniganj', 'Nawabganj', 'Dohar',
    'Sadar', 'Mirpur', 'Uttara', 'Gulshan', 'Banani',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

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

  @override
  void dispose() {
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  // ---------- Navigation ----------
  void _next() {
    if (_currentStep == 0) {
      if (_fullName.trim().isEmpty ||
          _mobile.trim().isEmpty ||
          _dateOfBirth == null) {
        _snack('Please fill required fields');
        return;
      }
    }
    if (_currentStep == 1) {
      if (_presentDivision == null ||
          _presentDistrict == null ||
          _presentUpazila == null ||
          _permanentDivision == null ||
          _permanentDistrict == null ||
          _permanentUpazila == null) {
        _snack('Please select all address fields');
        return;
      }
    }
    if (_currentStep == 2) {
      if (_documents.isEmpty) {
        _snack('Please upload at least one document');
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final userId = await AuthService.getUserId() ?? '';

    // Format DOB as ISO-8601
    final dobIso = _dateOfBirth?.toUtc().toIso8601String() ??
        DateTime.now().toUtc().toIso8601String();

    // Combined address strings
    final presentAddress =
        '$_presentUpazila, $_presentDistrict, $_presentDivision';
    final permanentAddress =
        '$_permanentUpazila, $_permanentDistrict, $_permanentDivision';

    final result = await TinService.addTin(
      userId: userId,
      fullName: _fullName,
      fatherName: _fatherName,
      motherName: _motherName,
      phone: _mobile,
      dateOfBirth: dobIso,
      presentAdress: presentAddress,
      permanentAdress: permanentAddress,
      documents: _documents,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      final dynamic data = result['data'];
      final String? newId = data is Map ? data['id']?.toString() : null;
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submittedId = newId ?? 'TIN-${DateTime.now().year}-000001';
        _currentStep = _totalSteps;
      });
    } else {
      _snack(result['message'] ?? 'Submission failed');
    }
  }

  void _openChat() {
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
        title: const Text('TIN Registration',
            style: TextStyle(color: Colors.black87, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            TinStepIndicator(
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
        return TinStep1PersonalInfo(
          fullNameController: _fullNameController,
          fatherNameController: _fatherNameController,
          motherNameController: _motherNameController,
          dateOfBirthController: _dobController,
          mobileController: _mobileController,
          onFullNameChanged: (v) => _fullName = v,
          onFatherNameChanged: (v) => _fatherName = v,
          onMotherNameChanged: (v) => _motherName = v,
          onDateOfBirthChanged: (v) => _dateOfBirth = v,
          onMobileChanged: (v) => _mobile = v,
          onBack: _back,
          onNext: _next,
        );
      case 1:
        return TinStep2Address(
          presentDivision: _presentDivision,
          presentDistrict: _presentDistrict,
          presentUpazila: _presentUpazila,
          permanentDivision: _permanentDivision,
          permanentDistrict: _permanentDistrict,
          permanentUpazila: _permanentUpazila,
          divisions: _divisions,
          districts: _districts,
          upazilas: _upazilas,
          onPresentDivisionChanged: (v) =>
              setState(() => _presentDivision = v),
          onPresentDistrictChanged: (v) =>
              setState(() => _presentDistrict = v),
          onPresentUpazilaChanged: (v) =>
              setState(() => _presentUpazila = v),
          onPermanentDivisionChanged: (v) =>
              setState(() => _permanentDivision = v),
          onPermanentDistrictChanged: (v) =>
              setState(() => _permanentDistrict = v),
          onPermanentUpazilaChanged: (v) =>
              setState(() => _permanentUpazila = v),
          onBack: _back,
          onNext: _next,
        );
      case 2:
        return TinStep3UploadDocs(
          documents: _documents,
          onDocumentsChanged: (list) => setState(() => _documents
            ..clear()
            ..addAll(list)),
          onBack: _back,
          onNext: _next,
        );
      case 3:
        return TinStep4ReviewSubmit(
          fullName: _fullName,
          dateOfBirth:
              _dateOfBirth != null ? _formatDate(_dateOfBirth!) : '',
          mobile: _mobile,
          email: '-',
          address: '$_presentUpazila, $_presentDistrict',
          isSubmitting: _isSubmitting,
          isUpdateMode: false,
          onBack: _back,
          onSubmit: _submit,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
                  color: const Color(0xFF1E7A3A).withOpacity(0.1),
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF1E7A3A), size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Application Submitted!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E7A3A))),
              const SizedBox(height: 8),
              Text(
                'Your TIN registration application has been submitted successfully.',
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
                      _submittedId ?? 'N/A',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E7A3A)),
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
                  side: const BorderSide(color: Color(0xFF1E7A3A)),
                  foregroundColor: const Color(0xFF1E7A3A),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Executive'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFF1E7A3A)),
                  foregroundColor: const Color(0xFF1E7A3A),
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