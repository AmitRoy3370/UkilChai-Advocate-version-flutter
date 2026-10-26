// lib/TradeLicense/screens/trade_license_update_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import '../models/trade_license_model.dart';
import '../models/upload_file_model.dart';
import '../services/trade_license_service.dart';
import 'widgets/tl_step_indicator.dart';
import 'widgets/tl_step1_business_info.dart';
import 'widgets/tl_step2_edit_documents.dart';
import 'widgets/tl_step3_review_submit.dart';

class TradeLicenseUpdateScreen extends StatefulWidget {
  final TradeLicenseModel existingLicense;

  const TradeLicenseUpdateScreen({super.key, required this.existingLicense});

  @override
  State<TradeLicenseUpdateScreen> createState() =>
      _TradeLicenseUpdateScreenState();
}

class _TradeLicenseUpdateScreenState extends State<TradeLicenseUpdateScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 3;

  late String _businessName;
  late String _ownerName;
  late String _mobileNumber;
  late String _emailAdress;
  late String _businessType;
  late String _businessCategory;

  final List<UploadFileModel> _newDocuments = [];
  late List<String> _existingDocumentIds;

  bool _isSubmitting = false;
  bool _submitted = false;

  String? _currentUserId;
  String? _currentUserName;

  late final TextEditingController _businessNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;

  static const _businessTypes = [
    'Retail', 'Wholesale', 'Service', 'Manufacturing', 'Online', 'Other',
  ];
  static const _businessCategories = [
    'General Store', 'Restaurant', 'Pharmacy', 'IT Services',
    'Consulting', 'Manufacturing', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.existingLicense;
    _businessName = l.buisnessName;
    _ownerName = ''; // server doesn't store owner name explicitly
    _mobileNumber = l.mobileNumber;
    _emailAdress = l.emailAdress;
    _businessType = l.buisnessType;
    _businessCategory = l.buisnessCategory;
    _existingDocumentIds = List<String>.from(l.documents);

    _businessNameController = TextEditingController(text: l.buisnessName);
    _ownerNameController = TextEditingController();
    _mobileController = TextEditingController(text: l.mobileNumber);
    _emailController = TextEditingController(text: l.emailAdress);

    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userId = await AuthService.getUserId();
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
      _currentUserName = '';
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
    if (_currentStep == 0) {
      if (_businessName.trim().isEmpty ||
          _mobileNumber.trim().isEmpty ||
          _emailAdress.trim().isEmpty ||
          _businessType.isEmpty ||
          _businessCategory.isEmpty) {
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

    final result = await TradeLicenseService.updateTradeLicensePartial(
      id: widget.existingLicense.id!,
      userId: userId,
      buisnessName: _businessName,
      mobileNumber: _mobileNumber,
      emailAdress: _emailAdress,
      buisnessType: _businessType,
      buisnessCategory: _businessCategory,
      attachmentsId: _existingDocumentIds,
      documents: _newDocuments,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      setState(() => _submitted = true);
    } else {
      _snack(result['message'] ?? 'Update failed');
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
        title: const Text('Update Trade License',
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
        return TlStep2EditDocuments(
          documents: _newDocuments,
          existingDocumentIds: _existingDocumentIds,
          onDocumentsChanged: (list) => setState(() => _newDocuments
            ..clear()
            ..addAll(list)),
          onExistingIdsChanged: (ids) => setState(() => _existingDocumentIds
            ..clear()
            ..addAll(ids)),
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
          documentCount:
              _existingDocumentIds.length + _newDocuments.length,
          isSubmitting: _isSubmitting,
          isUpdateMode: true,
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
              const Text('Updated Successfully!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E7A3A))),
              const SizedBox(height: 8),
              Text('Your trade license has been updated.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Done'),
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