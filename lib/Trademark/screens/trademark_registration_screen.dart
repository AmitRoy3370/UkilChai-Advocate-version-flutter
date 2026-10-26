// lib/Trademark/screens/trademark_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Auth/AuthService.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import '../models/upload_file_model.dart';
import '../models/trademark_registration_process_model.dart';
import '../services/trademark_service.dart';
import '../services/trademark_registration_process_service.dart';
import 'widgets/tm_step_indicator.dart';
import 'widgets/tm_step1_service_overview.dart';
import 'widgets/tm_step2_applicant_info.dart';
import 'widgets/tm_step3_trademark_details.dart';
import 'widgets/tm_step4_review_submit.dart';

class TrademarkRegistrationScreen extends StatefulWidget {
  const TrademarkRegistrationScreen({super.key});

  @override
  State<TrademarkRegistrationScreen> createState() =>
      _TrademarkRegistrationScreenState();
}

class _TrademarkRegistrationScreenState
    extends State<TrademarkRegistrationScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 4;

  final List<String> _titles = [
    'Service Overview',
    'Applicant Information',
    'Trademark Details',
    'Review & Submit',
  ];

  // Form data
  String _applicationType = '';
  String _applicationName = '';
  String _mobileNumber = '';
  String _email = '';
  String _address = '';
  String _trademarkName = '';
  String _trademarkType = '';
  String _classOfGoods = '';
  String _organizationalName = '';
  String _legalProtection = '';
  String _nationWiseValidity = '';
  String _governmentFee = '';
  final List<UploadFileModel> _documents = [];

  bool _isSubmitting = false;
  String? _submittedId;
  bool _submitted = false;

  String? _currentUserId;
  String? _currentUserName;

  // Controllers
  final _appNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _trademarkNameController = TextEditingController();
  final _classOfGoodsController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _legalProtectionController = TextEditingController();
  final _nationWiseController = TextEditingController();
  final _governmentFeeController = TextEditingController();

  static const _applicationTypes = [
    'Individual',
    'Company',
    'Partnership',
    'Startup',
  ];

  static const _trademarkTypes = [
    'Word Mark',
    'Device Mark',
    'Combined Mark',
    'Sound Mark',
    'Color Mark',
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
    _appNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _trademarkNameController.dispose();
    _classOfGoodsController.dispose();
    _orgNameController.dispose();
    _legalProtectionController.dispose();
    _nationWiseController.dispose();
    _governmentFeeController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 1) {
      if (_applicationName.trim().isEmpty ||
          _mobileNumber.trim().isEmpty ||
          _email.trim().isEmpty ||
          _address.trim().isEmpty ||
          _applicationType.isEmpty) {
        _snack('Please fill all required fields');
        return;
      }
    }
    if (_currentStep == 2) {
      if (_trademarkName.trim().isEmpty ||
          _trademarkType.isEmpty ||
          _classOfGoods.trim().isEmpty ||
          _organizationalName.trim().isEmpty) {
        _snack('Please fill all required fields');
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
    final fee = double.tryParse(_governmentFee.trim()) ?? 0.0;

    final result = await TrademarkService.addTrademark(
      userId: userId,
      legalProtection: _legalProtection,
      nationWiseValidity: _nationWiseValidity,
      applicationType: _applicationType,
      applicationName: _applicationName,
      governmentFee: fee,
      organaizationalName: _organizationalName,
      trademarkName: _trademarkName,
      trademarkType: _trademarkType,
      classOfGoods: _classOfGoods,
      adress: _address,
      email: _email,
      mobileNumber: _mobileNumber,
      documents: _documents,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      final dynamic data = result['data'];
      final String? newId = data is Map ? data['id']?.toString() : null;

      if (newId != null) {
        try {
          final process = TrademarkRegistrationProcessModel(
            userId: userId,
            advocateId: '',
            tradeMarkId: newId,
            steps: ['Submitted'],
            status: false,
          );
          await TrademarkRegistrationProcessService.addProcess(
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
        _submittedId = newId ?? 'TM-${DateTime.now().year}-000001';
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
        title: const Text('Trademark Registration',
            style: TextStyle(color: Colors.black87, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            TmStepIndicator(
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
        return TmStep1ServiceOverview(onApplyNow: _next);
      case 1:
        return TmStep2ApplicantInfo(
          applicationNameController: _appNameController,
          mobileController: _mobileController,
          emailController: _emailController,
          addressController: _addressController,
          applicationType:
              _applicationType.isEmpty ? null : _applicationType,
          applicationTypes: _applicationTypes,
          onApplicationNameChanged: (v) => _applicationName = v,
          onMobileChanged: (v) => _mobileNumber = v,
          onEmailChanged: (v) => _email = v,
          onAddressChanged: (v) => _address = v,
          onApplicationTypeChanged: (v) =>
              setState(() => _applicationType = v),
          onBack: _back,
          onNext: _next,
        );
      case 2:
        return TmStep3TrademarkDetails(
          trademarkType: _trademarkType.isEmpty ? null : _trademarkType,
          trademarkTypes: _trademarkTypes,
          trademarkNameController: _trademarkNameController,
          classOfGoodsController: _classOfGoodsController,
          organizationalNameController: _orgNameController,
          legalProtectionController: _legalProtectionController,
          nationWiseValidityController: _nationWiseController,
          governmentFeeController: _governmentFeeController,
          documents: _documents,
          onDocumentsChanged: (list) => setState(() => _documents
            ..clear()
            ..addAll(list)),
          onTrademarkTypeChanged: (v) => setState(() => _trademarkType = v),
          onTrademarkNameChanged: (v) => _trademarkName = v,
          onClassOfGoodsChanged: (v) => _classOfGoods = v,
          onOrganizationalNameChanged: (v) => _organizationalName = v,
          onLegalProtectionChanged: (v) => _legalProtection = v,
          onNationWiseValidityChanged: (v) => _nationWiseValidity = v,
          onGovernmentFeeChanged: (v) => _governmentFee = v,
          onBack: _back,
          onNext: _next,
        );
      case 3:
        return TmStep4ReviewSubmit(
          applicationName: _applicationName,
          trademarkName: _trademarkName,
          classOfGoods: _classOfGoods,
          trademarkType: _trademarkType,
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
                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF6A1B9A), size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Application Submitted!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A))),
              const SizedBox(height: 8),
              Text(
                'Your trademark registration application has been submitted successfully.',
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
                          color: Color(0xFF6A1B9A)),
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
                  side: const BorderSide(color: Color(0xFF6A1B9A)),
                  foregroundColor: const Color(0xFF6A1B9A),
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