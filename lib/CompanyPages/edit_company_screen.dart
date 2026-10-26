// lib/CompanyPages/edit_company_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Auth/AuthService.dart';
import '../CompanyPages/company_information.dart';
import '../CompanyPages/company_service.dart';
import '../CompanyPages/capital_service.dart';
import '../CompanyPages/capital.dart';
import '../DirectorsPages/director_service.dart';
import '../DirectorsPages/director_response.dart';
import '../DirectorsPages/director.dart';
import '../ShareholderPages/shareholder_service.dart';
import '../ShareholderPages/shareholder.dart';
import '../ShareholderPages/shareholder_response.dart';
import '../CompanyPages/subscription.dart';
import '../CompanyPages/subscription_service.dart';
import '../CompanyPages/company_contact.dart';
import '../CompanyPages/company_contact_service.dart';
import '../CompanyPages/company_response.dart';
import '../CompanyPages/company_attachment_viewer.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../main.dart';

class EditCompanyScreen extends StatefulWidget {
  final CompanyResponse company;

  const EditCompanyScreen({Key? key, required this.company}) : super(key: key);

  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  // ==================== CONTROLLERS ====================
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _authorizedController = TextEditingController();

  // ==================== DIRECTOR FORM CONTROLLERS ====================
  final TextEditingController _directorFullNameController = TextEditingController();
  final TextEditingController _directorFatherNameController = TextEditingController();
  final TextEditingController _directorMotherNameController = TextEditingController();
  final TextEditingController _directorNidNumberController = TextEditingController();
  final TextEditingController _directorMobileNumberController = TextEditingController();
  final TextEditingController _directorEmailController = TextEditingController();
  PlatformFile? _directorNidFile;
  bool _hasDirectorNid = false;

  // Map to store NID files per director (keyed by temp ID)
  final Map<String, PlatformFile?> _directorNidFiles = {};

  // ==================== SHAREHOLDER FORM CONTROLLERS ====================
  final TextEditingController _shareholderFullNameController = TextEditingController();
  final TextEditingController _shareholderNidController = TextEditingController();
  final TextEditingController _shareholderTinController = TextEditingController();
  final TextEditingController _shareholderPercentageController = TextEditingController();
  PlatformFile? _shareholderNidFile;
  bool _hasShareholderNid = false;
  PlatformFile? _shareholderTinFile;
  bool _hasShareholderTin = false;

  // Maps to store NID and TIN files per shareholder (keyed by temp ID)
  final Map<String, PlatformFile?> _shareholderNidFiles = {};
  final Map<String, PlatformFile?> _shareholderTinFiles = {};

  // ==================== DOCUMENT UPLOAD FILES ====================
  PlatformFile? _tinCertificateFile;
  bool _hasTinCertificate = false;
  PlatformFile? _taxReturnFile;
  bool _hasTaxReturn = false;
  PlatformFile? _utilityBillFile;
  bool _hasUtilityBill = false;
  PlatformFile? _tradeLicenseFile;
  bool _hasTradeLicense = false;

  // ==================== SERVICES ====================
  final CompanyService _companyService = CompanyService();
  final DirectorService _directorService = DirectorService();
  final ShareholderService _shareholderService = ShareholderService();
  final CapitalService _capitalService = CapitalService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final CompanyContactService _companyContactService = CompanyContactService();

  // ==================== STATE ====================
  bool _isLoading = false;
  bool _isSubmitting = false;
  int _currentStep = 0;
  String? _submitMessage;
  bool _isSubmitSuccess = false;
  String? _userId;
  String? _companyId;

  // ==================== DIRECTORS ====================
  List<DirectorResponse> _availableDirectors = [];
  List<String> _selectedDirectors = [];
  bool _isLoadingDirectors = false;
  String? _directorsError;
  List<String> _removedDirectors = [];

  // ==================== SHAREHOLDERS ====================
  List<ShareholderResponse> _availableShareholders = [];
  List<ShareholderResponse> _selectedShareholders = [];
  bool _isLoadingShareholders = false;
  String? _shareholdersError;
  List<String> _removedShareholders = [];

  // ==================== DOCUMENTS ====================
  List<PlatformFile> _newDocuments = [];
  bool _hasNewDocuments = false;
  List<String> _existingDocuments = [];
  List<String> _removedDocuments = [];

  // ==================== CAPITAL ====================
  Capital? _capital;
  bool _hasCapital = false;
  bool _capitalChanged = false;

  // ==================== SUBSCRIPTION ====================
  Subscription? _subscription;
  bool _hasSubscription = false;
  PlatformFile? _signatureFile;
  bool _hasSignature = false;
  bool _subscriptionChanged = false;

  // ==================== COMPANY CONTACT ====================
  CompanyContact? _companyContact;
  bool _hasCompanyContact = false;
  bool _contactChanged = false;

  // ==================== STEP 1: COMPANY INFORMATION ====================
  String? _selectedType;
  String? _selectedNatureOfBusiness;
  String? _selectedCategory;
  bool _companyInfoChanged = false;

  final List<String> _companyTypes = [
    'Private Limited',
    'Public Limited',
    'Sole Proprietorship',
    'Partnership',
    'LLP',
    'Others',
  ];

  final List<String> _natureOfBusinessOptions = [
    'IT Consulting',
    'Software Development',
    'Manufacturing',
    'Trading',
    'Service',
    'Education',
    'Healthcare',
    'Construction',
    'Real Estate',
    'Others',
  ];

  final List<String> _categoryOptions = [
    'Large',
    'Medium',
    'Small',
    'Micro',
  ];

  bool _hasAgreedToTerms = false;

  // ==================== REVIEW DATA ====================
  Map<String, dynamic> get _reviewData => {
    'Company Name': _companyNameController.text.isEmpty
        ? 'Not provided'
        : _companyNameController.text,
    'Company Type': _selectedType ?? 'Not selected',
    'Nature of Business': _selectedNatureOfBusiness ?? 'Not selected',
    'Category': _selectedCategory ?? 'Not selected',
    'Authorized Person': _authorizedController.text.isEmpty
        ? 'Not provided'
        : _authorizedController.text,
    'Directors': _selectedDirectors.isNotEmpty
        ? _selectedDirectors.length.toString()
        : 'None selected',
    'Shareholders': _selectedShareholders.isNotEmpty
        ? _selectedShareholders.length.toString()
        : 'None selected',
    'New Documents': _newDocuments.isNotEmpty
        ? _newDocuments.length.toString()
        : 'None uploaded',
    'Existing Documents': _existingDocuments.isNotEmpty
        ? _existingDocuments.length.toString()
        : 'None',
    'Capital': _capital != null
        ? 'Authorized Capital: ৳${_capital!.authorizedCapital.toStringAsFixed(2)}'
        : 'Not added',
    'Subscription': _subscription != null
        ? 'Subscriber: ${_subscription!.subscriberName} (${_subscription!.numberOfShare} shares)'
        : 'Not added',
    'Company Contact': _companyContact != null
        ? 'Contact: ${_companyContact!.contactPersonName}'
        : 'Not added',
  };

  @override
  void initState() {
    super.initState();
    print('🟢 ============================================');
    print('🟢 INIT STATE - EditCompanyScreen');
    print('🟢 ============================================');
    _initializeData();
  }

  Future<void> _initializeData() async {
    print('🔄 INITIALIZING DATA...');
    print('🔄 ============================================');
    await _loadUserId();
    await _loadDirectors();
    await _loadShareholders();
    _populateExistingData();
    print('✅ DATA INITIALIZATION COMPLETE');
    print('✅ ============================================');
  }

  Future<void> _loadUserId() async {
    print('🔍 LOADING USER ID...');
    print('🔍 ============================================');
    try {
      String? userId;

      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      print('🔍 Source 1 - SharedPreferences userId: "$userId"');

      if (userId == null || userId.isEmpty) {
        userId = widget.company.creatorId;
        print('🔍 Source 2 - Company creatorId: "$userId"');
      }

      if (userId == null || userId.isEmpty) {
        userId = await AuthService.getUserId();
        print('🔍 Source 3 - AuthService userId: "$userId"');
      }

      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
        });
        await prefs.setString('userId', userId);
        await AuthService.saveUserId(userId);
        print('✅ User ID loaded successfully: "$_userId"');
        print('✅ ============================================');
      } else {
        print('⚠️ No user ID found in any source');
        print('⚠️ ============================================');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to edit a company'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading user ID: $e');
      print('❌ ============================================');
    }
  }

  void _populateExistingData() {
    final company = widget.company;

    _companyId = company.id;
    _companyNameController.text = company.companyName;

    // Company Type
    if (company.type.isNotEmpty && _companyTypes.contains(company.type)) {
      _selectedType = company.type;
    }

    // Nature of Business
    if (company.natureOfBusiness.isNotEmpty && _natureOfBusinessOptions.contains(company.natureOfBusiness)) {
      _selectedNatureOfBusiness = company.natureOfBusiness;
    }

    // Category
    if (company.category.isNotEmpty && _categoryOptions.contains(company.category)) {
      _selectedCategory = company.category;
    }

    // Authorized Person
    if (company.authorized != null && company.authorized!.isNotEmpty) {
      _authorizedController.text = company.authorized!;
    }

    // Directors
    if (company.directorsId != null && company.directorsId!.isNotEmpty) {
      _selectedDirectors = List.from(company.directorsId!);
    }

    // Shareholders
    if (company.shareHolders != null && company.shareHolders!.isNotEmpty) {
      _populateSelectedShareholders();
    }

    // Capital
    if (company.capitals != null && company.capitals!.isNotEmpty) {
      _capital = company.capitals!.first;
      _hasCapital = true;
    }

    // Subscription
    if (company.subscriptions != null && company.subscriptions!.isNotEmpty) {
      _subscription = company.subscriptions!.first;
      _hasSubscription = true;
    }

    // Documents
    if (company.documents != null && company.documents!.isNotEmpty) {
      _existingDocuments = List.from(company.documents!);
    }

    print('✅ Existing data populated');
    print('   Company: ${company.companyName}');
    print('   Directors: ${_selectedDirectors.length}');
    print('   Shareholders: ${_selectedShareholders.length}');
    print('   Documents: ${_existingDocuments.length}');
    print('   Capital: ${_capital != null ? "Yes" : "No"}');
    print('   Subscription: ${_subscription != null ? "Yes" : "No"}');
  }

  void _populateSelectedShareholders() {
    final company = widget.company;
    if (company.shareHolders == null || company.shareHolders!.isEmpty) return;

    for (var id in company.shareHolders!) {
      final match = _availableShareholders.where((s) => s.id == id).toList();
      if (match.isNotEmpty) {
        final exists = _selectedShareholders.any((s) => s.id == id);
        if (!exists) {
          double percentage = 0.0;
          if (match.first.sharePercentage != null &&
              match.first.sharePercentage!.isNotEmpty &&
              match.first.sharePercentage!.containsKey(company.id!)) {
            final percentages = match.first.sharePercentage![company.id!];
            if (percentages != null && percentages.isNotEmpty) {
              percentage = percentages.first;
            }
          }

          final updatedShareholder = ShareholderResponse(
            id: match.first.id,
            userId: match.first.userId,
            userName: match.first.userName ?? match.first.fullName ?? 'Unknown',
            fullName: match.first.fullName,
            nid: match.first.nid,
            tin: match.first.tin,
            sharePercentage: {
              company.id! : [percentage],
            },
          );
          _selectedShareholders.add(updatedShareholder);
        }
      }
    }
  }

  @override
  void dispose() {
    print('🗑️ DISPOSING - EditCompanyScreen');
    print('🗑️ ============================================');
    _companyNameController.dispose();
    _authorizedController.dispose();
    _directorFullNameController.dispose();
    _directorFatherNameController.dispose();
    _directorMotherNameController.dispose();
    _directorNidNumberController.dispose();
    _directorMobileNumberController.dispose();
    _directorEmailController.dispose();
    _shareholderFullNameController.dispose();
    _shareholderPercentageController.dispose();
    _shareholderNidController.dispose();
    _shareholderTinController.dispose();
    super.dispose();
  }

  // ==================== LOAD DIRECTORS ====================
  Future<void> _loadDirectors() async {
    print('🔄 LOADING DIRECTORS...');
    print('🔄 ============================================');
    setState(() {
      _isLoadingDirectors = true;
      _directorsError = null;
    });

    try {
      final directors = await _directorService.getAllDirectors();
      print('📊 Directors loaded: ${directors.length}');
      setState(() {
        _availableDirectors = directors.where((d) => d.id != null && d.id!.isNotEmpty).toList();
        _isLoadingDirectors = false;
      });
      print('✅ Directors loaded successfully');
      print('✅ ============================================');
    } catch (e) {
      print('❌ Error loading directors: $e');
      print('❌ ============================================');
      setState(() {
        _directorsError = e.toString();
        _isLoadingDirectors = false;
      });
    }
  }

  // ==================== LOAD SHAREHOLDERS ====================
  Future<void> _loadShareholders() async {
    print('🔄 LOADING SHAREHOLDERS...');
    print('🔄 ============================================');
    setState(() {
      _isLoadingShareholders = true;
      _shareholdersError = null;
    });

    try {
      final shareholders = await _shareholderService.getAllShareholders();
      print('📊 Shareholders loaded: ${shareholders.length}');
      setState(() {
        _availableShareholders = shareholders;
        _isLoadingShareholders = false;
      });
      _populateSelectedShareholders();
      print('✅ Shareholders loaded successfully');
      print('✅ ============================================');
    } catch (e) {
      print('❌ Error loading shareholders: $e');
      print('❌ ============================================');
      setState(() {
        _shareholdersError = e.toString();
        _isLoadingShareholders = false;
      });
    }
  }

  // ==================== PICK DOCUMENTS ====================
  Future<void> _pickDocuments() async {
    print('📎 PICKING DOCUMENTS...');
    print('📎 ============================================');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        print('📎 Documents selected: ${result.files.length}');
        setState(() {
          _newDocuments.addAll(result.files);
          _hasNewDocuments = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} new document(s) selected'),
            backgroundColor: Colors.green,
          ),
        );
        print('✅ Documents picked successfully');
        print('✅ ============================================');
      } else {
        print('ℹ️ No documents selected');
        print('ℹ️ ============================================');
      }
    } catch (e) {
      print('❌ Error picking documents: $e');
      print('❌ ============================================');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking documents: $e')),
      );
    }
  }

  // ==================== REMOVE NEW DOCUMENT ====================
  void _removeNewDocument(int index) {
    print('🗑️ Removing new document at index: $index');
    setState(() {
      _newDocuments.removeAt(index);
      if (_newDocuments.isEmpty) {
        _hasNewDocuments = false;
      }
    });
    print('✅ Document removed');
  }

  // ==================== REMOVE EXISTING DOCUMENT ====================
  void _removeExistingDocument(String docId) {
    print('🗑️ Removing existing document: $docId');
    setState(() {
      _existingDocuments.remove(docId);
      _removedDocuments.add(docId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document marked for removal'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ==================== VIEW EXISTING DOCUMENT ====================
  void _viewExistingDocument(String docId) async {
    print('👁️ Viewing document: $docId');
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view documents')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompanyAttachmentViewer(
            attachmentId: docId,
            jwtToken: token,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error viewing document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing document: $e')),
      );
    }
  }

  // ==================== ADD CAPITAL ====================
  void _showAddCapitalDialog() {
    print('💰 Opening Add Capital Dialog');
    print('💰 ============================================');

    final authorizedController = TextEditingController(
      text: _capital?.authorizedCapital.toString() ?? '',
    );
    final totalShareController = TextEditingController(
      text: _capital?.totalShare.toString() ?? '',
    );
    final numberOfShareController = TextEditingController(
      text: _capital?.numberOfShare.toString() ?? '',
    );
    final shareValueController = TextEditingController(
      text: _capital?.shareValue.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Capital Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: authorizedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Authorized Capital (BDT)',
                  hintText: 'Enter authorized capital',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: totalShareController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Shares',
                  hintText: 'Enter total shares',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: numberOfShareController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Shares',
                  hintText: 'Enter number of shares',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: shareValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Share Value (Per Share)',
                  hintText: 'Enter share value',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final authorized = double.tryParse(authorizedController.text);
              final totalShare = int.tryParse(totalShareController.text);
              final numberOfShare = int.tryParse(numberOfShareController.text);
              final shareValue = double.tryParse(shareValueController.text);

              print('💰 Capital values:');
              print('   Authorized: $authorized');
              print('   TotalShare: $totalShare');
              print('   NumberOfShare: $numberOfShare');
              print('   ShareValue: $shareValue');

              if (authorized == null || totalShare == null || numberOfShare == null || shareValue == null) {
                print('❌ Invalid capital values - showing error');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid numbers'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                _capital = Capital(
                  id: _capital?.id,
                  companyId: _companyId ?? '',
                  authorizedCapital: authorized,
                  totalShare: totalShare,
                  numberOfShare: numberOfShare,
                  shareValue: shareValue,
                );
                _hasCapital = true;
                _capitalChanged = true;
                print('✅ Capital updated: ${_capital!.toJson()}');
                print('✅ ============================================');
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Capital'),
          ),
        ],
      ),
    );
  }

  // ==================== ADD SUBSCRIPTION ====================
  void _showAddSubscriptionDialog() {
    print('📝 Opening Add Subscription Dialog');
    print('📝 ============================================');

    final subscriberNameController = TextEditingController(
      text: _subscription?.subscriberName ?? '',
    );
    final numberOfShareController = TextEditingController(
      text: _subscription?.numberOfShare.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Subscription Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subscriberNameController,
                    decoration: const InputDecoration(
                      labelText: 'Subscriber Name *',
                      hintText: 'Enter subscriber name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberOfShareController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of Shares *',
                      hintText: 'Enter number of shares',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            print('📎 Picking signature file...');
                            try {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                                withData: kIsWeb,
                              );

                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.first;
                                print('📎 Signature file selected: ${file.name}');
                                setDialogState(() {
                                  _signatureFile = file;
                                  _hasSignature = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Signature: ${file.name} selected'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              print('❌ Error picking signature: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(_hasSignature || _subscription?.signatureId != null
                              ? 'Change Signature'
                              : 'Upload Signature'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_hasSignature || _subscription?.signatureId != null)
                                ? Colors.orange
                                : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (_hasSignature || _subscription?.signatureId != null)
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: null,
                        ),
                    ],
                  ),
                  if (_hasSignature)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.file_present, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _signatureFile!.name,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_subscription?.signatureId != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.file_present, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Existing signature attached',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _signatureFile = null;
                    _hasSignature = false;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final subscriberName = subscriberNameController.text.trim();
                  final numberOfShare = int.tryParse(numberOfShareController.text.trim());

                  print('📝 Subscription values:');
                  print('   Subscriber Name: "$subscriberName"');
                  print('   Number of Shares: $numberOfShare');
                  print('   Signature: ${_hasSignature ? _signatureFile!.name : _subscription?.signatureId ?? "None"}');

                  if (subscriberName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter subscriber name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (numberOfShare == null || numberOfShare <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid number of shares'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _subscription = Subscription(
                      id: _subscription?.id,
                      companyId: _companyId ?? '',
                      subscriberName: subscriberName,
                      numberOfShare: numberOfShare,
                      signatureId: _subscription?.signatureId,
                    );
                    _hasSubscription = true;
                    _subscriptionChanged = true;
                    print('✅ Subscription updated: ${_subscription!.toJson()}');
                    print('✅ ============================================');
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Subscription'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== ADD COMPANY CONTACT ====================
  void _showAddCompanyContactDialog() {
    print('📞 Opening Add Company Contact Dialog');
    print('📞 ============================================');

    final contactPersonNameController = TextEditingController(
      text: _companyContact?.contactPersonName ?? '',
    );
    final contactPersonMobileController = TextEditingController(
      text: _companyContact?.contactPersonMobile ?? '',
    );
    final contactPersonEmailController = TextEditingController(
      text: _companyContact?.contactPersonEmail ?? '',
    );
    String? selectedHowDidHear = _companyContact?.howDidHear;
    final anyOtherMessageController = TextEditingController(
      text: _companyContact?.anyOtherMessage ?? '',
    );

    final List<String> howDidHearOptions = [
      'Search Engine',
      'Social Media',
      'Friend/Colleague',
      'Advertisement',
      'Email',
      'Newsletter',
      'Event',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Company Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contactPersonNameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person Name *',
                  hintText: 'Enter contact person name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactPersonMobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: 'Enter mobile number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactPersonEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'How Did You Hear About Us? *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                value: selectedHowDidHear,
                items: howDidHearOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  selectedHowDidHear = value;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: anyOtherMessageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Any Other Message',
                  hintText: 'Enter any additional message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = contactPersonNameController.text.trim();
              final mobile = contactPersonMobileController.text.trim();
              final email = contactPersonEmailController.text.trim();
              final message = anyOtherMessageController.text.trim();

              print('📞 Company Contact values:');
              print('   Name: "$name"');
              print('   Mobile: "$mobile"');
              print('   Email: "$email"');
              print('   How Did Hear: "$selectedHowDidHear"');
              print('   Message: "$message"');

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter contact person name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (mobile.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter mobile number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter email address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (selectedHowDidHear == null || selectedHowDidHear!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select how you heard about us'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                _companyContact = CompanyContact(
                  id: _companyContact?.id,
                  contactPersonName: name,
                  contactPersonMobile: mobile,
                  contactPersonEmail: email,
                  howDidHear: selectedHowDidHear!,
                  anyOtherMessage: message.isNotEmpty ? message : null,
                  companyId: _companyId ?? '',
                );
                _hasCompanyContact = true;
                _contactChanged = true;
                print('✅ Company Contact updated: ${_companyContact!.toJson()}');
                print('✅ ============================================');
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Contact'),
          ),
        ],
      ),
    );
  }

  // ==================== ADD DIRECTOR FROM FORM ====================
  void _addDirectorFromForm() {
    final fullName = _directorFullNameController.text.trim();
    final fatherName = _directorFatherNameController.text.trim();
    final motherName = _directorMotherNameController.text.trim();
    final nidNumber = _directorNidNumberController.text.trim();
    final mobileNumber = _directorMobileNumberController.text.trim();
    final email = _directorEmailController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter full name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mobileNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create temp ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Store the NID file for this director
    if (_directorNidFile != null) {
      _directorNidFiles[tempId] = _directorNidFile;
    }

    // Create a new director response with ALL the data
    final newDirector = DirectorResponse(
      id: tempId,
      userId: _userId ?? '',
      userName: fullName,
      position: 'Director',
      fullName: fullName,
      fatherName: fatherName.isNotEmpty ? fatherName : null,
      motherName: motherName.isNotEmpty ? motherName : null,
      nidNumber: nidNumber.isNotEmpty ? nidNumber : null,
      mobileNumber: mobileNumber,
      directorEmail: email,
      nid: _directorNidFile?.name,
    );

    setState(() {
      _selectedDirectors.add(newDirector.id!);
      _availableDirectors.add(newDirector);

      // Clear form fields
      _directorFullNameController.clear();
      _directorFatherNameController.clear();
      _directorMotherNameController.clear();
      _directorNidNumberController.clear();
      _directorMobileNumberController.clear();
      _directorEmailController.clear();
      _directorNidFile = null;
      _hasDirectorNid = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Director added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ==================== REMOVE DIRECTOR ====================
  void _removeDirector(String directorId) {
    print('🗑️ Removing director: $directorId');
    setState(() {
      _selectedDirectors.remove(directorId);
      // If it's not a temp director, mark for removal from company
      if (!directorId.startsWith('temp_')) {
        _removedDirectors.add(directorId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Director removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ==================== ADD SHAREHOLDER FROM FORM ====================
  void _addShareholderFromForm() {
    final fullName = _shareholderFullNameController.text.trim();
    final percentageStr = _shareholderPercentageController.text.trim();
    final nid = _shareholderNidController.text.trim();
    final tin = _shareholderTinController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter full name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final percentage = double.tryParse(percentageStr);
    if (percentage == null || percentage < 0 || percentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid percentage (0-100)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create temp ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Store the NID file for this specific shareholder
    if (_shareholderNidFile != null) {
      _shareholderNidFiles[tempId] = _shareholderNidFile;
    }

    // Store the TIN file for this specific shareholder
    if (_shareholderTinFile != null) {
      _shareholderTinFiles[tempId] = _shareholderTinFile;
    }

    // Create a new shareholder response with ALL the data
    final newShareholder = ShareholderResponse(
      id: tempId,
      userId: _userId ?? '',
      userName: fullName,
      fullName: fullName,
      nid: nid.isNotEmpty ? nid : null,
      tin: tin.isNotEmpty ? tin : null,
      sharePercentage: {
        _companyId ?? 'temp': [percentage],
      },
    );

    setState(() {
      _selectedShareholders.add(newShareholder);

      // Clear form fields
      _shareholderFullNameController.clear();
      _shareholderPercentageController.clear();
      _shareholderNidController.clear();
      _shareholderTinController.clear();
      _shareholderNidFile = null;
      _hasShareholderNid = false;
      _shareholderTinFile = null;
      _hasShareholderTin = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Shareholder added with ${percentage.toStringAsFixed(2)}%'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ==================== REMOVE SHAREHOLDER ====================
  void _removeShareholder(String shareholderId) {
    print('🗑️ Removing shareholder: $shareholderId');
    setState(() {
      _selectedShareholders.removeWhere((e) => e.id == shareholderId);
      // If it's not a temp shareholder, mark for removal from company
      if (!shareholderId.startsWith('temp_')) {
        _removedShareholders.add(shareholderId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shareholder removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ==================== UPDATE SHAREHOLDER PERCENTAGES ====================
  Future<void> _updateShareholderPercentages({
    required String companyId,
    required String userId,
    required List<ShareholderResponse> shareholders,
  }) async {
    print('📊 ============================================');
    print('📊 UPDATING SHAREHOLDER PERCENTAGES...');
    print('📊 ============================================');

    if (shareholders.isEmpty) {
      print('⏭️ No shareholders to update');
      return;
    }

    try {
      for (var holder in shareholders) {
        if (holder.id == null || holder.id!.isEmpty) {
          print('⚠️ Skipping shareholder with no ID');
          continue;
        }

        // Skip temp shareholders - they should be handled separately
        if (holder.id!.startsWith('temp_')) {
          print('⏭️ Skipping temp shareholder: ${holder.id}');
          continue;
        }

        double percentage = 0.0;
        if (holder.sharePercentage != null &&
            holder.sharePercentage!.isNotEmpty) {
          final percentages = holder.sharePercentage!.values.first;
          if (percentages.isNotEmpty) {
            percentage = percentages.first;
          }
        }

        print('📊 Processing shareholder: ${holder.id} (${percentage}%)');

        try {
          final shareholderResponse = await _shareholderService.getShareholderById(holder.id);

          if (shareholderResponse.id != null) {
            Map<String, List<double>> sharePercentage = {};

            if (shareholderResponse.sharePercentage != null &&
                shareholderResponse.sharePercentage!.isNotEmpty) {
              for (var entry in shareholderResponse.sharePercentage!.entries) {
                String key = entry.key;
                List<double> values = entry.value;
                if (values is List) {
                  sharePercentage[key] = List<double>.from(values);
                } else {
                  sharePercentage[key] = [];
                }
              }
            }

            if (sharePercentage.containsKey(companyId)) {
              final existingPercentages = sharePercentage[companyId] ?? [];
              if (!existingPercentages.contains(percentage)) {
                existingPercentages.add(percentage);
                sharePercentage[companyId] = existingPercentages;
                print('📊 Appended ${percentage}% to existing company entry');
              } else {
                print('📊 Percentage ${percentage}% already exists for this company');
              }
            } else {
              sharePercentage[companyId] = [percentage];
              print('📊 Added new company entry with ${percentage}%');
            }

            print('📊 Updated sharePercentage: $sharePercentage');

            final updatedShareholder = Shareholder(
              id: shareholderResponse.id,
              userId: shareholderResponse.userId,
              fullName: shareholderResponse.fullName,
              nid: shareholderResponse.nid,
              tin: shareholderResponse.tin,
              sharePercentage: sharePercentage,
            );

            print('📤 Updated Shareholder data: ${updatedShareholder.toJson()}');

            await _shareholderService.updateShareholder(
              id: shareholderResponse.id!,
              shareholder: updatedShareholder,
              userId: shareholderResponse.userId,
              nidFile: null,
              tinFile: null,
              removeNid: false,
              removeTin: false,
            );

            print('✅ Shareholder ${holder.id} updated with company $companyId at ${percentage}%');
          } else {
            print('⚠️ Shareholder ${holder.id} has no ID, skipping');
          }
        } catch (e) {
          print('⚠️ Error updating shareholder ${holder.id}: $e');
        }
      }

      print('✅ All shareholder percentages updated successfully');
      print('📊 ============================================');
    } catch (e) {
      print('❌ Error updating shareholder percentages: $e');
      print('❌ ============================================');
    }
  }

// ==================== SUBMIT COMPANY ====================
Future<void> _submitCompany() async {
  print('🚀 ============================================');
  print('🚀 SUBMITTING COMPANY UPDATE...');
  print('🚀 ============================================');

  print('📋 Step 1: Validating form data...');

  String? validationError;

  final companyName = _companyNameController.text.trim();
  if (companyName.isEmpty) {
    validationError = 'Please enter company name';
    print('❌ Validation failed: Company name is empty');
  }

  if (validationError == null && (_selectedType == null || _selectedType!.isEmpty)) {
    validationError = 'Please select company type';
    print('❌ Validation failed: Company type not selected');
  }

  if (validationError == null && (_selectedNatureOfBusiness == null || _selectedNatureOfBusiness!.isEmpty)) {
    validationError = 'Please select nature of business';
    print('❌ Validation failed: Nature of business not selected');
  }

  if (validationError == null && (_selectedCategory == null || _selectedCategory!.isEmpty)) {
    validationError = 'Please select business category';
    print('❌ Validation failed: Business category not selected');
  }

  if (validationError != null) {
    print('❌ Form validation failed: $validationError');
    print('❌ ============================================');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(validationError),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  print('✅ All validations passed');

  print('📋 Step 2: Checking terms agreement...');
  if (!_hasAgreedToTerms) {
    print('❌ User did not agree to terms');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please confirm that all information is accurate'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  print('✅ User agreed to terms');

  print('📋 Step 3: Getting User ID...');
  String? userId;

  final prefs = await SharedPreferences.getInstance();
  userId = prefs.getString('userId');
  print('📋 Source 1 - SharedPreferences userId: "$userId"');

  if (userId == null || userId.isEmpty) {
    userId = widget.company.creatorId;
    print('📋 Source 2 - Company creatorId: "$userId"');
  }

  if (userId == null || userId.isEmpty) {
    userId = _userId;
    print('📋 Source 3 - State _userId: "$userId"');
  }

  if (userId == null || userId.isEmpty) {
    userId = await AuthService.getUserId();
    print('📋 Source 4 - AuthService userId: "$userId"');
  }

  if (userId == null || userId.isEmpty) {
    print('❌❌❌ CRITICAL: No userId found from any source!');
    setState(() {
      _isSubmitSuccess = false;
      _submitMessage = '❌ Error: User not logged in. Please login again.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Please login again'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  print('✅ Final userId: "$userId"');

  setState(() {
    _userId = userId;
  });
  await prefs.setString('userId', userId!);
  await AuthService.saveUserId(userId!);

  // Collect all documents - ONLY NEW documents
  // ✅ Existing documents are kept unless removed via _removedDocuments
  List<PlatformFile> newDocumentsToUpload = [];
  if (_tinCertificateFile != null) newDocumentsToUpload.add(_tinCertificateFile!);
  if (_taxReturnFile != null) newDocumentsToUpload.add(_taxReturnFile!);
  if (_utilityBillFile != null) newDocumentsToUpload.add(_utilityBillFile!);
  if (_tradeLicenseFile != null) newDocumentsToUpload.add(_tradeLicenseFile!);
  newDocumentsToUpload.addAll(_newDocuments);

  // ✅ Start with the ORIGINAL documents from the company
  // Then remove any that were explicitly removed by the user
  final List<String> finalExistingDocuments = List.from(widget.company.documents ?? []);
  
  // Remove documents that were marked for removal
  for (String docId in _removedDocuments) {
    finalExistingDocuments.remove(docId);
  }

  print('📊 ============================================');
  print('📊 Company Update Data:');
  print('📊   UserId: "$userId"');
  print('📊   Name: "$companyName"');
  print('📊   Type: "${_selectedType ?? ''}"');
  print('📊   Nature: "${_selectedNatureOfBusiness ?? ''}"');
  print('📊   Category: "${_selectedCategory ?? ''}"');
  print('📊   Directors: ${_selectedDirectors.length}');
  print('📊   Shareholders: ${_selectedShareholders.length}');
  print('📊   New Documents: ${newDocumentsToUpload.length}');
  print('📊   Existing Documents: ${finalExistingDocuments.length} (kept)');
  print('📊   Removed Documents: ${_removedDocuments.length} (removed)');
  print('📊   Removed Directors: ${_removedDirectors.length}');
  print('📊   Removed Shareholders: ${_removedShareholders.length}');
  print('📊   Capital: ${_capital != null ? "Yes" : "No"}');
  print('📊   Subscription: ${_subscription != null ? "Yes" : "No"}');
  print('📊 ============================================');

  setState(() {
    _isSubmitting = true;
    _submitMessage = null;
    _isSubmitSuccess = false;
  });

  try {
    // Step 4: Build final lists for directors and shareholders
    // Remove any temp IDs from the lists
    final List<String> finalDirectorIds = _selectedDirectors
        .where((id) => !id.startsWith('temp_'))
        .toList();
    
    final List<String> finalShareholderIds = _selectedShareholders
        .where((holder) => holder.id != null && !holder.id!.startsWith('temp_'))
        .map((holder) => holder.id!)
        .toList();

    // Step 5: Build company object with final lists
    print('📋 Step 5: Building company object...');

    final company = CompanyInformation(
      companyName: companyName,
      type: _selectedType ?? '',
      natureOfBusiness: _selectedNatureOfBusiness ?? '',
      category: _selectedCategory ?? '',
      officeRegistryId: widget.company.officeRegistryId,
      authorized: _authorizedController.text.trim().isEmpty
          ? null
          : _authorizedController.text.trim(),
      directorsId: finalDirectorIds, // Only existing directors (no temp)
      shareHolders: finalShareholderIds, // Only existing shareholders (no temp)
      creatorId: userId,
      capital: _capital != null ? [_capital!.id ?? ''] : [],
      // ✅ Keep existing documents that were NOT removed
      // Start with original documents and remove those that were removed
      documents: finalExistingDocuments ?? [],
    );

    print('📤 Company object created:');
    print('📤 ${company.toJson()}');
    print('📤 Documents in company object: ${company.documents}');

    // Step 6: Update company
    print('📋 Step 6: Updating company via API...');
    print('📤 Uploading ${newDocumentsToUpload.length} new documents...');

    await _companyService.updateCompany(
      id: widget.company.id!,
      company: company,
      userId: userId,
      files: newDocumentsToUpload.isNotEmpty ? newDocumentsToUpload : null,
    );

    print('✅ Company updated successfully!');

    // Step 7: Add new directors (temp ones)
    List<String> newDirectorIds = [];
    for (String dirId in _selectedDirectors) {
      if (dirId.startsWith('temp_')) {
        print('📋 Creating new director: "$dirId"');
        final directorData = _availableDirectors.firstWhere(
          (d) => d.id == dirId,
          orElse: () => DirectorResponse(userId: '', userName: 'Unknown', position: 'Director'),
        );

        PlatformFile? directorNidFile = _directorNidFiles[dirId];

        try {
          final newDirector = Director(
            userId: userId,
            position: directorData.position ?? 'Director',
            fullName: directorData.fullName ?? directorData.userName,
            fatherName: directorData.fatherName,
            motherName: directorData.motherName,
            nidNumber: directorData.nidNumber,
            mobileNumber: directorData.mobileNumber,
            email: directorData.directorEmail ?? directorData.email,
            nid: directorData.nid,
          );

          final createdDirector = await _directorService.addDirector(
            director: newDirector,
            userId: userId,
            nidFile: directorNidFile,
          );

          if (createdDirector.id != null && createdDirector.id!.isNotEmpty) {
            newDirectorIds.add(createdDirector.id!);
            print('✅ New director created: "${createdDirector.id}"');
          }
        } catch (e) {
          print('❌ Failed to create director: $e');
        }
      }
    }

    // Step 8: Add new directors to company
    if (newDirectorIds.isNotEmpty) {
      print('📋 Step 8: Adding new directors to company...');
      for (String dirId in newDirectorIds) {
        try {
          await _companyService.addDirectorToCompany(
            companyId: widget.company.id!,
            directorId: dirId,
            userId: userId,
          );
          print('✅ Director "$dirId" added to company');
        } catch (e) {
          print('⚠️ Error adding director "$dirId": $e');
        }
      }
    }

    // Step 9: Add new shareholders (temp ones)
    List<String> newShareholderIds = [];
    for (var holder in _selectedShareholders) {
      if (holder.id != null && holder.id!.startsWith('temp_')) {
        print('📋 Creating new shareholder: "${holder.id}"');

        double percentage = 0.0;
        if (holder.sharePercentage != null && holder.sharePercentage!.isNotEmpty) {
          final percentages = holder.sharePercentage!.values.first;
          if (percentages.isNotEmpty) {
            percentage = percentages.first;
          }
        }

        PlatformFile? shareholderNidFile = _shareholderNidFiles[holder.id];
        PlatformFile? shareholderTinFile = _shareholderTinFiles[holder.id];

        try {
          final newShareholder = Shareholder(
            userId: userId,
            fullName: holder.fullName,
            nid: holder.nid,
            tin: holder.tin,
            sharePercentage: {},
          );

          final createdShareholder = await _shareholderService.addShareholder(
            shareholder: newShareholder,
            userId: userId,
            nidFile: shareholderNidFile,
            tinFile: shareholderTinFile,
          );

          if (createdShareholder.id != null && createdShareholder.id!.isNotEmpty) {
            newShareholderIds.add(createdShareholder.id!);
            print('✅ New shareholder created: "${createdShareholder.id}"');
          }
        } catch (e) {
          print('❌ Failed to create shareholder: $e');
        }
      }
    }

    // Step 10: Add new shareholders to company
    if (newShareholderIds.isNotEmpty) {
      print('📋 Step 10: Adding new shareholders to company...');
      for (String holderId in newShareholderIds) {
        try {
          await _companyService.addShareholderToCompany(
            companyId: widget.company.id!,
            shareholderId: holderId,
            userId: userId,
          );
          print('✅ Shareholder "$holderId" added to company');
        } catch (e) {
          print('⚠️ Error adding shareholder "$holderId": $e');
        }
      }
    }

    // Step 11: Update shareholder percentages for existing shareholders
    if (_selectedShareholders.isNotEmpty) {
      print('📊 Step 11: Updating shareholder percentages...');
      // Only update shareholders that are not temp
      final List<ShareholderResponse> existingShareholders = _selectedShareholders
          .where((holder) => holder.id != null && !holder.id!.startsWith('temp_'))
          .toList();
      
      if (existingShareholders.isNotEmpty) {
        await _updateShareholderPercentages(
          companyId: widget.company.id!,
          userId: userId,
          shareholders: existingShareholders,
        );
      }
    }

    // Step 12: Update Capital if changed
    if (_capital != null && _capitalChanged) {
      print('📋 Step 12: Updating Capital...');
      final capital = _capital!.copyWith(companyId: widget.company.id!);
      if (_capital!.id != null && _capital!.id!.isNotEmpty) {
        await _capitalService.updateCapital(
          id: _capital!.id!,
          capital: capital,
          userId: userId,
        );
        print('✅ Capital updated successfully!');
      } else {
        final addedCapital = await _capitalService.addCapital(
          capital: capital,
          userId: userId,
        );
        _capital = addedCapital;
        print('✅ New Capital added successfully!');
      }
    }

    // Step 13: Update Subscription if changed
    if (_subscription != null && _subscriptionChanged) {
      print('📋 Step 13: Updating Subscription...');
      try {
        final subscription = _subscription!.copyWith(companyId: widget.company.id!);
        if (_subscription!.id != null && _subscription!.id!.isNotEmpty) {
          await _subscriptionService.updateSubscription(
            id: _subscription!.id!,
            subscription: subscription,
            userId: userId,
            signatureFile: _signatureFile,
          );
        } else {
          await _subscriptionService.addSubscription(
            subscription: subscription,
            userId: userId,
            signatureFile: _signatureFile,
          );
        }
        print('✅ Subscription updated successfully!');
      } catch (e) {
        print('⚠️ Error updating subscription: $e');
      }
    }

    // Step 14: Update Company Contact if changed
    if (_companyContact != null && _contactChanged) {
      print('📋 Step 14: Updating Company Contact...');
      try {
        final contact = _companyContact!.copyWith(companyId: widget.company.id!);
        if (_companyContact!.id != null && _companyContact!.id!.isNotEmpty) {
          await _companyContactService.updateCompanyContact(
            id: _companyContact!.id!,
            contact: contact,
            userId: userId,
          );
        } else {
          await _companyContactService.addCompanyContact(
            contact: contact,
            userId: userId,
          );
        }
        print('✅ Company Contact updated successfully!');
      } catch (e) {
        print('⚠️ Error updating company contact: $e');
      }
    }

    print('✅✅✅ ============================================');
    print('✅✅✅ COMPANY UPDATE COMPLETE!');
    print('✅✅✅ Company ID: "${widget.company.id}"');
    print('✅✅✅ Documents: ${finalExistingDocuments.length} existing + ${newDocumentsToUpload.length} new');
    print('✅✅✅ Final document IDs: ${finalExistingDocuments}');
    print('✅✅✅ ============================================');

    setState(() {
      _isSubmitSuccess = true;
      _submitMessage = '✅ Company updated successfully!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Company updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  } catch (e) {
    print('❌❌❌ ============================================');
    print('❌❌❌ ERROR in company update process: $e');
    print('❌❌❌ ============================================');
    setState(() {
      _isSubmitSuccess = false;
      _submitMessage = '❌ Error: ${e.toString()}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
    print('🏁 Update process completed');
    print('🏁 ============================================');
  }
}
  // ==================== BUILD STEPS ====================
  List<Step> _buildSteps() {
    print('🏗️ Building steps...');
    return [
      _buildStep(
        title: 'Company Information',
        subtitle: 'Basic company details',
        content: _buildCompanyInfoStep(),
      ),
      _buildStep(
        title: 'Directors',
        subtitle: 'Manage company directors',
        content: _buildDirectorsStep(),
      ),
      _buildStep(
        title: 'Shareholders',
        subtitle: 'Manage company shareholders',
        content: _buildShareholdersStep(),
      ),
      _buildStep(
        title: 'Documents',
        subtitle: 'Manage documents',
        content: _buildDocumentsStep(),
      ),
      _buildStep(
        title: 'Capital',
        subtitle: 'Manage capital details',
        content: _buildCapitalStep(),
      ),
      _buildStep(
        title: 'Subscription',
        subtitle: 'Manage subscription details',
        content: _buildSubscriptionStep(),
      ),
      _buildStep(
        title: 'Company Contact',
        subtitle: 'Manage contact information',
        content: _buildCompanyContactStep(),
      ),
      _buildStep(
        title: 'Review',
        subtitle: 'Review all information',
        content: _buildReviewStep(),
      ),
    ];
  }

  Step _buildStep({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Step(
      title: Text(title),
      subtitle: Text(subtitle),
      content: content,
      isActive: true,
      state: _currentStep == _getStepIndex(title)
          ? StepState.editing
          : StepState.indexed,
    );
  }

  int _getStepIndex(String title) {
    const titles = [
      'Company Information',
      'Directors',
      'Shareholders',
      'Documents',
      'Capital',
      'Subscription',
      'Company Contact',
      'Review',
    ];
    return titles.indexOf(title);
  }

  // ==================== STEP 1: COMPANY INFORMATION ====================
  Widget _buildCompanyInfoStep() {
    print('🏗️ Building Company Info Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyNameController,
          decoration: const InputDecoration(
            labelText: 'Proposed Name *',
            hintText: 'Enter company name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter company name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Company Type *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          value: _selectedType,
          items: _companyTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
              _companyInfoChanged = true;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select company type';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Nature of Business *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
          value: _selectedNatureOfBusiness,
          items: _natureOfBusinessOptions.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedNatureOfBusiness = value;
              _companyInfoChanged = true;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select nature of business';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Business Category *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          value: _selectedCategory,
          items: _categoryOptions.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
              _companyInfoChanged = true;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select business category';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _authorizedController,
          decoration: const InputDecoration(
            labelText: 'Authorized Person',
            hintText: 'Enter authorized person name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: (value) {
            _companyInfoChanged = true;
          },
        ),
      ],
    );
  }

// ==================== STEP 2: DIRECTORS ====================
Widget _buildDirectorsStep() {
  print('🏗️ Building Directors Step');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Manage Directors',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Add new directors or remove existing ones from your company.',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
      const SizedBox(height: 16),

      // Selected Directors List
      if (_selectedDirectors.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Directors (${_selectedDirectors.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._selectedDirectors.asMap().entries.map((entry) {
                final index = entry.key;
                final directorId = entry.value;
                final director = _availableDirectors.firstWhere(
                  (d) => d.id == directorId,
                  orElse: () => DirectorResponse(
                    userId: '',
                    userName: 'Unknown',
                    position: 'Unknown',
                  ),
                );
                final isTemp = directorId.startsWith('temp_');
                
                // Use fullName if available, fallback to userName, then "Unknown"
                final displayName = director.fullName != null && director.fullName!.isNotEmpty
                    ? director.fullName!
                    : director.userName != null && director.userName!.isNotEmpty
                        ? director.userName!
                        : 'Unknown';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTemp ? Colors.green.shade300 : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isTemp ? Colors.green.shade100 : Colors.green.shade50,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isTemp ? Colors.green.shade700 : Colors.green.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isTemp)
                              Text(
                                'New',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 16),
                        onPressed: () => _removeDirector(directorId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // Add Existing Directors Section
      if (_availableDirectors.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Add Existing Directors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select directors from the list below to add to your company.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ..._availableDirectors.map((director) {
                // Check if this director is already selected
                final isSelected = _selectedDirectors.contains(director.id);
                
                // Use fullName if available, fallback to userName, then "Unknown"
                final displayName = director.fullName != null && director.fullName!.isNotEmpty
                    ? director.fullName!
                    : director.userName != null && director.userName!.isNotEmpty
                        ? director.userName!
                        : 'Unknown';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isSelected ? Colors.green.shade100 : Colors.grey.shade200,
                        child: Icon(
                          isSelected ? Icons.check : Icons.person,
                          size: 14,
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.green.shade700 : Colors.black87,
                              ),
                            ),
                            if (director.position != null && director.position!.isNotEmpty)
                              Text(
                                director.position!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.green, size: 16)
                      else
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                          onPressed: () {
                            setState(() {
                              if (director.id != null && director.id!.isNotEmpty) {
                                _selectedDirectors.add(director.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Added ${displayName} to directors'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // Add Director Form
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Add New Director',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _directorFullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _directorFatherNameController,
                decoration: const InputDecoration(
                  labelText: 'Father Name',
                  hintText: 'Enter father name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _directorMotherNameController,
                decoration: const InputDecoration(
                  labelText: 'Mother Name',
                  hintText: 'Enter mother name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _directorNidNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'NID Number',
                  hintText: 'Enter NID number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _directorMobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: 'Enter mobile number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _directorEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            withData: kIsWeb,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setState(() {
                              _directorNidFile = result.files.first;
                              _hasDirectorNid = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('NID PDF: ${result.files.first.name} selected'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error picking NID: $e');
                        }
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(_hasDirectorNid ? 'Change NID PDF' : 'Upload NID PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasDirectorNid ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_hasDirectorNid)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                ],
              ),
              if (_hasDirectorNid)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _directorNidFile!.name,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addDirectorFromForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Director'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selected: ${_selectedDirectors.length} director(s)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
      if (_removedDirectors.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_removedDirectors.length} director(s) marked for removal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
// ==================== STEP 3: SHAREHOLDERS ====================
Widget _buildShareholdersStep() {
  print('🏗️ Building Shareholders Step');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Manage Shareholders',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Add new shareholders or remove existing ones from your company.',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
      const SizedBox(height: 16),

      // Selected Shareholders List
      if (_selectedShareholders.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Shareholders (${_selectedShareholders.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._selectedShareholders.asMap().entries.map((entry) {
                final index = entry.key;
                final holder = entry.value;
                final isTemp = holder.id?.startsWith('temp_') ?? false;
                double percentage = 0.0;
                if (holder.sharePercentage != null && holder.sharePercentage!.isNotEmpty) {
                  final percentages = holder.sharePercentage!.values.first;
                  if (percentages.isNotEmpty) {
                    percentage = percentages.first;
                  }
                }
                
                // Use fullName if available, fallback to userName, then "Unknown"
                final displayName = holder.fullName != null && holder.fullName!.isNotEmpty
                    ? holder.fullName!
                    : holder.userName != null && holder.userName!.isNotEmpty
                        ? holder.userName!
                        : 'Unknown';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTemp ? Colors.orange.shade300 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isTemp ? Colors.orange.shade100 : Colors.orange.shade50,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isTemp ? Colors.orange.shade700 : Colors.orange.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isTemp) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'New',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 16),
                        onPressed: () => _removeShareholder(holder.id!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // Add Existing Shareholders Section
      if (_availableShareholders.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Add Existing Shareholders',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select shareholders from the list below to add to your company.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ..._availableShareholders.map((shareholder) {
                // Check if this shareholder is already selected
                final isSelected = _selectedShareholders.any((s) => s.id == shareholder.id);
                
                // Use fullName if available, fallback to userName, then "Unknown"
                final displayName = shareholder.fullName != null && shareholder.fullName!.isNotEmpty
                    ? shareholder.fullName!
                    : shareholder.userName != null && shareholder.userName!.isNotEmpty
                        ? shareholder.userName!
                        : 'Unknown';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.orange.shade300 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isSelected ? Colors.orange.shade100 : Colors.grey.shade200,
                        child: Icon(
                          isSelected ? Icons.check : Icons.person,
                          size: 14,
                          color: isSelected ? Colors.orange.shade700 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.orange.shade700 : Colors.black87,
                              ),
                            ),
                            if (shareholder.nid != null && shareholder.nid!.isNotEmpty)
                              Text(
                                'NID: ${shareholder.nid}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.orange, size: 16)
                      else
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                          onPressed: () {
                            setState(() {
                              if (shareholder.id != null && shareholder.id!.isNotEmpty) {
                                // Add shareholder with a default percentage of 0%
                                final newShareholder = ShareholderResponse(
                                  id: shareholder.id,
                                  userId: shareholder.userId,
                                  userName: shareholder.userName ?? shareholder.fullName ?? 'Unknown',
                                  fullName: shareholder.fullName,
                                  nid: shareholder.nid,
                                  tin: shareholder.tin,
                                  sharePercentage: {
                                    _companyId ?? 'temp': [0.0],
                                  },
                                );
                                _selectedShareholders.add(newShareholder);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Added ${displayName} to shareholders'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // Add Shareholder Form
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Add New Shareholder',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _shareholderFullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _shareholderPercentageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Share Percentage *',
                  hintText: 'Enter share percentage',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _shareholderNidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'NID Number',
                  hintText: 'Enter NID number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _shareholderTinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'TIN Number',
                  hintText: 'Enter TIN number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            withData: kIsWeb,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setState(() {
                              _shareholderNidFile = result.files.first;
                              _hasShareholderNid = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('NID PDF: ${result.files.first.name} selected'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error picking NID: $e');
                        }
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(_hasShareholderNid ? 'Change NID PDF' : 'Upload NID PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasShareholderNid ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_hasShareholderNid)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                ],
              ),
              if (_hasShareholderNid)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _shareholderNidFile!.name,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            withData: kIsWeb,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setState(() {
                              _shareholderTinFile = result.files.first;
                              _hasShareholderTin = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('TIN PDF: ${result.files.first.name} selected'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error picking TIN: $e');
                        }
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(_hasShareholderTin ? 'Change TIN PDF' : 'Upload TIN PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasShareholderTin ? Colors.orange : Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_hasShareholderTin)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                ],
              ),
              if (_hasShareholderTin)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _shareholderTinFile!.name,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addShareholderFromForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Shareholder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selected: ${_selectedShareholders.length} shareholder(s)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
      if (_removedShareholders.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_removedShareholders.length} shareholder(s) marked for removal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
  // ==================== STEP 4: DOCUMENTS ====================
  Widget _buildDocumentsStep() {
    print('🏗️ Building Documents Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'View, remove, or upload new documents for your company.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Existing Documents
        if (_existingDocuments.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Existing Documents (${_existingDocuments.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._existingDocuments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final docId = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Document ${index + 1}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue, size: 16),
                          onPressed: () => _viewExistingDocument(docId),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 16),
                          onPressed: () => _removeExistingDocument(docId),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // New Documents
        if (_newDocuments.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'New Documents (${_newDocuments.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._newDocuments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 16),
                          onPressed: () => _removeNewDocument(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Upload New Documents Button
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 48,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload New Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add PDF, DOC, DOCX, PNG, JPG files',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickDocuments,
                  icon: const Icon(Icons.add),
                  label: const Text('Select Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total: ${_existingDocuments.length + _newDocuments.length} document(s) '
                  '(${_newDocuments.length} new, ${_existingDocuments.length} existing)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_removedDocuments.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_removedDocuments.length} document(s) marked for removal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==================== STEP 5: CAPITAL ====================
  Widget _buildCapitalStep() {
    print('🏗️ Building Capital Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Authorized Capital & Shares',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'View and edit capital details for your company.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_capital != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Capital Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _showAddCapitalDialog,
                    ),
                  ],
                ),
                const Divider(),
                _buildCapitalRow('Authorized Capital', '৳${_capital!.authorizedCapital.toStringAsFixed(2)}'),
                _buildCapitalRow('Total Shares', _capital!.totalShare.toString()),
                _buildCapitalRow('Number of Shares', _capital!.numberOfShare.toString()),
                _buildCapitalRow('Share Value', '৳${_capital!.shareValue.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No capital added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddCapitalDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Capital'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==================== STEP 6: SUBSCRIPTION ====================
  Widget _buildSubscriptionStep() {
    print('🏗️ Building Subscription Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'View and edit subscription information for your company.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_subscription != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subscription Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _showAddSubscriptionDialog,
                    ),
                  ],
                ),
                const Divider(),
                _buildCapitalRow('Subscriber Name', _subscription!.subscriberName),
                _buildCapitalRow('Number of Shares', _subscription!.numberOfShare.toString()),
                _buildCapitalRow('Signature', _subscription!.signatureId != null ? 'Attached' : 'No signature uploaded'),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.description,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No subscription added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddSubscriptionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==================== STEP 7: COMPANY CONTACT ====================
  Widget _buildCompanyContactStep() {
    print('🏗️ Building Company Contact Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Contact Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'View and edit contact information for your company.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_companyContact != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contact Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.purple),
                      onPressed: _showAddCompanyContactDialog,
                    ),
                  ],
                ),
                const Divider(),
                _buildCapitalRow('Contact Person', _companyContact!.contactPersonName),
                _buildCapitalRow('Mobile', _companyContact!.contactPersonMobile),
                _buildCapitalRow('Email', _companyContact!.contactPersonEmail),
                _buildCapitalRow('How Did Hear', _companyContact!.howDidHear),
                if (_companyContact!.anyOtherMessage != null && _companyContact!.anyOtherMessage!.isNotEmpty)
                  _buildCapitalRow('Message', _companyContact!.anyOtherMessage!),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.contact_phone,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No company contact added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddCompanyContactDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCapitalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 8: REVIEW ====================
  Widget _buildReviewStep() {
    print('🏗️ Building Review Step');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Changes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please review all changes before submitting.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Company Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ..._reviewData.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                // Show changes summary
                const Divider(),
                const Text(
                  'Changes Summary:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (_companyInfoChanged)
                  Text('• Company information updated',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                if (_removedDirectors.isNotEmpty)
                  Text('• ${_removedDirectors.length} director(s) removed',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                if (_removedShareholders.isNotEmpty)
                  Text('• ${_removedShareholders.length} shareholder(s) removed',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                if (_newDocuments.isNotEmpty)
                  Text('• ${_newDocuments.length} new document(s) added',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                if (_removedDocuments.isNotEmpty)
                  Text('• ${_removedDocuments.length} document(s) removed',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                if (_capitalChanged)
                  Text('• Capital information updated',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                if (_subscriptionChanged)
                  Text('• Subscription information updated',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                if (_contactChanged)
                  Text('• Contact information updated',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                if (!_companyInfoChanged &&
                    _removedDirectors.isEmpty &&
                    _removedShareholders.isEmpty &&
                    _newDocuments.isEmpty &&
                    _removedDocuments.isEmpty &&
                    !_capitalChanged &&
                    !_subscriptionChanged &&
                    !_contactChanged)
                  Text('• No changes detected',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_submitMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isSubmitSuccess
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSubmitSuccess
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSubmitSuccess ? Icons.check_circle : Icons.error_outline,
                  color: _isSubmitSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _submitMessage!,
                    style: TextStyle(
                      color: _isSubmitSuccess ? Colors.green : Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _hasAgreedToTerms,
              onChanged: (value) {
                setState(() {
                  _hasAgreedToTerms = value ?? false;
                });
              },
              activeColor: Colors.blue,
            ),
            Expanded(
              child: Text(
                'I confirm that all the information provided is accurate and complete.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    print('🏗️ BUILDING EditCompanyScreen - Step: $_currentStep');
    print('🏗️ UserId: "$_userId"');
    print('🏗️ IsSubmitting: $_isSubmitting');

    if (_userId == null || _userId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Company',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'User not logged in',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please login to edit a company',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Company',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 7) {
            _submitCompany();
          } else {
            setState(() {
              _currentStep++;
            });
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isSubmitting ? null : details.onStepCancel,
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 7
                          ? Colors.green
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == 7
                                ? 'Update Company'
                                : 'Save & Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
        steps: _buildSteps(),
      ),
    );
  }
}