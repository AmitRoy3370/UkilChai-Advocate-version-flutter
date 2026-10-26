// lib/Tin/screens/tin_update_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Auth/AuthService.dart';
import '../models/tin_response_dto.dart';
import '../models/upload_file_model.dart';
import '../services/tin_service.dart';
import 'widgets/tin_step_indicator.dart';
import 'widgets/tin_step1_personal_info.dart';
import 'widgets/tin_step2_address.dart';
import 'widgets/tin_step3_edit_docs.dart';
import 'widgets/tin_step4_review_submit.dart';

class TinUpdateScreen extends StatefulWidget {
  final TinResponseDTO tin;

  const TinUpdateScreen({super.key, required this.tin});

  @override
  State<TinUpdateScreen> createState() => _TinUpdateScreenState();
}

class _TinUpdateScreenState extends State<TinUpdateScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 4;

  final List<String> _titles = [
    'Personal Information',
    'Present & Permanent Address',
    'Manage Documents',
    'Review & Submit',
  ];

  late String _fullName;
  late String _fatherName;
  late String _motherName;
  late DateTime _dateOfBirth;
  late String _mobile;

  String? _presentDivision;
  String? _presentDistrict;
  String? _presentUpazila;
  String? _permanentDivision;
  String? _permanentDistrict;
  String? _permanentUpazila;

  final List<UploadFileModel> _newDocuments = [];
  late List<String> _existingDocumentIds;

  bool _isSubmitting = false;
  bool _submitted = false;

  late final TextEditingController _fullNameController;
  late final TextEditingController _fatherNameController;
  late final TextEditingController _motherNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _mobileController;

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
    final t = widget.tin;

    _fullName = t.fullName;
    _fatherName = t.fatherName;
    _motherName = t.motherName;
    _dateOfBirth = t.dateOfBirth;
    _mobile = t.phone;

    // Parse addresses (fallback: pick first item from lists)
    final present = _parseAddress(t.presentAdress);
    _presentDivision = present['division'];
    _presentDistrict = present['district'];
    _presentUpazila = present['upazila'];

    final permanent = _parseAddress(t.permanentAdress);
    _permanentDivision = permanent['division'];
    _permanentDistrict = permanent['district'];
    _permanentUpazila = permanent['upazila'];

    _existingDocumentIds = List<String>.from(t.documents);

    _fullNameController = TextEditingController(text: t.fullName);
    _fatherNameController = TextEditingController(text: t.fatherName);
    _motherNameController = TextEditingController(text: t.motherName);
    _dobController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(t.dateOfBirth));
    _mobileController = TextEditingController(text: t.phone);
  }

  Map<String, String?> _parseAddress(String address) {
    // Address format: "upazila, district, division"
    if (address.isEmpty) {
      return {'division': null, 'district': null, 'upazila': null};
    }
    final parts = address.split(',').map((e) => e.trim()).toList();
    return {
      'upazila': parts.isNotEmpty && _upazilas.contains(parts[0])
          ? parts[0]
          : null,
      'district': parts.length > 1 && _districts.contains(parts[1])
          ? parts[1]
          : null,
      'division': parts.length > 2 && _divisions.contains(parts[2])
          ? parts[2]
          : null,
    };
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

  void _next() {
    if (_currentStep == 0) {
      if (_fullName.trim().isEmpty || _mobile.trim().isEmpty) {
        _snack('Please fill required fields');
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

    final presentAddress =
        '${_presentUpazila ?? ''}, ${_presentDistrict ?? ''}, ${_presentDivision ?? ''}';
    final permanentAddress =
        '${_permanentUpazila ?? ''}, ${_permanentDistrict ?? ''}, ${_permanentDivision ?? ''}';

    final result = await TinService.updateTin(
      id: widget.tin.id!,
      userId: userId,
      fullName: _fullName,
      fatherName: _fatherName,
      motherName: _motherName,
      phone: _mobile,
      dateOfBirth: _dateOfBirth.toUtc().toIso8601String(),
      presentAdress: presentAddress,
      permanentAdress: permanentAddress,
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

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Update TIN',
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
        return TinStep3EditDocs(
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
        return TinStep4ReviewSubmit(
          fullName: _fullName,
          dateOfBirth: DateFormat('dd/MM/yyyy').format(_dateOfBirth),
          mobile: _mobile,
          email: '-',
          address: '$_presentUpazila, $_presentDistrict',
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
              Text('Your TIN information has been updated.',
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
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}