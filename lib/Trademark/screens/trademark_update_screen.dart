// lib/Trademark/screens/trademark_update_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../../ChatRelatedPages/FreeConsultantPage.dart';
import '../models/trademark_model.dart';
import '../models/upload_file_model.dart';
import '../services/trademark_service.dart';
import 'widgets/tm_step_indicator.dart';
import 'widgets/tm_step2_applicant_info.dart';
import 'widgets/tm_step3_edit_documents.dart';
import 'widgets/tm_step4_review_submit.dart';
import 'widgets/tm_step3_trademark_details.dart';

class TrademarkUpdateScreen extends StatefulWidget {
  final TrademarkModel existingTrademark;

  const TrademarkUpdateScreen({super.key, required this.existingTrademark});

  @override
  State<TrademarkUpdateScreen> createState() => _TrademarkUpdateScreenState();
}

class _TrademarkUpdateScreenState extends State<TrademarkUpdateScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 4;

  final List<String> _titles = [
    'Applicant Information',
    'Trademark Details',
    'Manage Documents',
    'Review & Submit',
  ];

  // Form
  late String _applicationType;
  late String _applicationName;
  late String _mobileNumber;
  late String _email;
  late String _address;
  late String _trademarkName;
  late String _trademarkType;
  late String _classOfGoods;
  late String _organizationalName;
  late String _legalProtection;
  late String _nationWiseValidity;
  late String _governmentFee;

  final List<UploadFileModel> _newDocuments = [];
  late List<String> _existingDocumentIds;

  bool _isSubmitting = false;
  bool _submitted = false;

  String? _currentUserId;
  String? _currentUserName;

  // Controllers
  late final TextEditingController _appNameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _trademarkNameController;
  late final TextEditingController _classOfGoodsController;
  late final TextEditingController _orgNameController;
  late final TextEditingController _legalProtectionController;
  late final TextEditingController _nationWiseController;
  late final TextEditingController _governmentFeeController;

  static const _applicationTypes = [
    'Individual', 'Company', 'Partnership', 'Startup',
  ];

  static const _trademarkTypes = [
    'Word Mark', 'Device Mark', 'Combined Mark', 'Sound Mark', 'Color Mark',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.existingTrademark;
    _applicationType = t.applicationType;
    _applicationName = t.applicationName;
    _mobileNumber = t.mobileNumber;
    _email = t.email;
    _address = t.adress;
    _trademarkName = t.trademarkName;
    _trademarkType = t.trademarkType;
    _classOfGoods = t.classOfGoods;
    _organizationalName = t.organaizationalName;
    _legalProtection = t.legalProtection;
    _nationWiseValidity = t.nationWiseValidity;
    _governmentFee = t.governmentFee.toStringAsFixed(0);
    _existingDocumentIds = List<String>.from(t.documents);

    _appNameController = TextEditingController(text: t.applicationName);
    _mobileController = TextEditingController(text: t.mobileNumber);
    _emailController = TextEditingController(text: t.email);
    _addressController = TextEditingController(text: t.adress);
    _trademarkNameController = TextEditingController(text: t.trademarkName);
    _classOfGoodsController = TextEditingController(text: t.classOfGoods);
    _orgNameController =
        TextEditingController(text: t.organaizationalName);
    _legalProtectionController =
        TextEditingController(text: t.legalProtection);
    _nationWiseController =
        TextEditingController(text: t.nationWiseValidity);
    _governmentFeeController =
        TextEditingController(text: t.governmentFee.toStringAsFixed(0));

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
    if (_currentStep == 0) {
      if (_applicationName.trim().isEmpty ||
          _mobileNumber.trim().isEmpty ||
          _email.trim().isEmpty ||
          _address.trim().isEmpty) {
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

    final result = await TrademarkService.updateTrademark(
      id: widget.existingTrademark.id!,
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
      documentsId: _existingDocumentIds,
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
        title: const Text('Update Trademark',
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
      case 1:
        return TmStep3TrademarkDetails(
          trademarkType: _trademarkType.isEmpty ? null : _trademarkType,
          trademarkTypes: _trademarkTypes,
          trademarkNameController: _trademarkNameController,
          classOfGoodsController: _classOfGoodsController,
          organizationalNameController: _orgNameController,
          legalProtectionController: _legalProtectionController,
          nationWiseValidityController: _nationWiseController,
          governmentFeeController: _governmentFeeController,
          documents: _newDocuments,
          onDocumentsChanged: (list) => setState(() => _newDocuments
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
          isEditMode: true,
        );
      case 2:
        return TmStep3EditDocuments(
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
      case 3:
        return TmStep4ReviewSubmit(
          applicationName: _applicationName,
          trademarkName: _trademarkName,
          classOfGoods: _classOfGoods,
          trademarkType: _trademarkType,
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
                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF6A1B9A), size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Updated Successfully!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A))),
              const SizedBox(height: 8),
              Text('Your trademark has been updated.',
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