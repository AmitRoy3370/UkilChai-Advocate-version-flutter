// lib/TradeLicense/screens/trade_license_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Auth/AuthService.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import '../models/upload_file_model.dart';
import '../models/trade_license_registration_process_model.dart';
import '../services/trade_license_service.dart';
import '../services/trade_license_registration_process_service.dart';
import 'widgets/tl_step_indicator.dart';
import 'widgets/tl_step1_business_info.dart';
import 'widgets/tl_step2_upload_documents.dart';
import 'widgets/tl_step3_review_submit.dart';

class TradeLicenseRegistrationScreen extends StatefulWidget {
  const TradeLicenseRegistrationScreen({super.key});

  @override
  State<TradeLicenseRegistrationScreen> createState() =>
      _TradeLicenseRegistrationScreenState();
}

class _TradeLicenseRegistrationScreenState
    extends State<TradeLicenseRegistrationScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Form data
  String _businessName = '';
  String _ownerName = '';
  String _mobileNumber = '';
  String _emailAdress = '';
  String _businessType = '';
  String _businessCategory = '';
  final List<UploadFileModel> _documents = [];

  bool _isSubmitting = false;
  String? _submittedId;
  bool _submitted = false;

  // User info
  String? _currentUserId;
  String? _currentUserName;

  // Controllers
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  static const _businessTypes = [
    'Retail',
    'Wholesale',
    'Service',
    'Manufacturing',
    'Online',
    'Other',
  ];

  static const _businessCategories = [
    'General Store',
    'Restaurant',
    'Pharmacy',
    'IT Services',
    'Consulting',
    'Manufacturing',
    'Other',
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
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _next() {
    // Validation
    if (_currentStep == 0) {
      if (_businessName.trim().isEmpty ||
          _ownerName.trim().isEmpty ||
          _mobileNumber.trim().isEmpty ||
          _emailAdress.trim().isEmpty ||
          _businessType.isEmpty ||
          _businessCategory.isEmpty) {
        _snack('Please fill all required fields');
        return;
      }
    }
    if (_currentStep == 1) {
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

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final userId = await AuthService.getUserId() ?? '';

    final result = await TradeLicenseService.addTradeLicense(
      userId: userId,
      buisnessName: _businessName,
      mobileNumber: _mobileNumber,
      emailAdress: _emailAdress,
      buisnessType: _businessType,
      buisnessCategory: _businessCategory,
      documents: _documents,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      final dynamic data = result['data'];
      final String? newId = data is Map ? data['id']?.toString() : null;

      // Create process record
      if (newId != null) {
        try {
          final process = TradeLicenseRegistrationProcessModel(
            userId: userId,
            advocateId: '',
            tradeLicenseId: newId,
            steps: ['Submitted'],
            status: false,
          );
          await TradeLicenseRegistrationProcessService.addProcess(
            userId: userId,
            process: process,
          );
        } catch (e) {
          debugPrint('Process creation failed: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submittedId = newId ?? 'TL-${DateTime.now().year}-000001';
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
        title: const Text('Trade License',
            style: TextStyle(color: Colors.black87, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            TlStepIndicator(currentStep: _currentStep, totalSteps: _totalSteps),
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
        return TlStep1BusinessInfo(
          businessNameController: _businessNameController,
          ownerNameController: _ownerNameController,
          mobileController: _mobileController,
          emailController: _emailController,
          selectedBusinessType:
              _businessType.isEmpty ? null : _businessType,
          selectedBusinessCategory:
              _businessCategory.isEmpty ? null : _businessCategory,
          businessTypes: _businessTypes,
          businessCategories: _businessCategories,
          onBusinessNameChanged: (v) => _businessName = v,
          onOwnerNameChanged: (v) => _ownerName = v,
          onMobileChanged: (v) => _mobileNumber = v,
          onEmailChanged: (v) => _emailAdress = v,
          onBusinessTypeChanged: (v) => setState(() => _businessType = v),
          onBusinessCategoryChanged: (v) =>
              setState(() => _businessCategory = v),
          onBack: _back,
          onNext: _next,
        );
      case 1:
        return TlStep2UploadDocuments(
          documents: _documents,
          onDocumentsChanged: (list) => setState(() => _documents
            ..clear()
            ..addAll(list)),
          onBack: _back,
          onNext: _next,
        );
      case 2:
        return TlStep3ReviewSubmit(
          businessName: _businessName,
          ownerName: _ownerName,
          mobileNumber: _mobileNumber,
          emailAdress: _emailAdress,
          businessType: _businessType,
          businessCategory: _businessCategory,
          documentCount: _documents.length,
          isSubmitting: _isSubmitting,
          isUpdateMode: false,
          onBack: _back,
          onSubmit: _submit,
        );
      default:
        return const SizedBox.shrink();
    }
  }

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
                'Your trade license application has been submitted successfully.',
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
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              const SizedBox(height: 20),
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