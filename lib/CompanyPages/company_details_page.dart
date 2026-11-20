// lib/CompanyPages/company_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../CompanyPages/company_service.dart';
import '../CompanyPages/company_response.dart';
import '../CompanyPages/capital.dart';
import '../CompanyPages/subscription.dart';
import '../CompanyPages/company_attachment_viewer.dart';
import '../CompanyPages/company_contact_service.dart';
import '../CompanyPages/company_contact.dart';
import '../CompanyPages/registration_process_service.dart';
import '../CompanyPages/registration_process_response.dart';
import '../CompanyPages/registration_process.dart';
import '../CompanyPages/company_payment_service.dart';
import '../CompanyPages/company_payment_response.dart';
import '../CompanyPages/company_request_payment.dart';
import '../CompanyPages/edit_company_screen.dart';
import '../CompanyPages/center_admin_bridge.dart';
import '../CompanyPages/company_process_control_screen.dart';
import '../Auth/AuthService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyDetailsPage extends StatefulWidget {
  final String companyId;

  /// Optional pre-loaded company (used by the advocate list page).
  /// If supplied, the page renders immediately and refreshes silently.
  final CompanyResponse? company;

  const CompanyDetailsPage({
    Key? key,
    required this.companyId,
    this.company,
  }) : super(key: key);

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final CompanyService _companyService = CompanyService();
  final CompanyContactService _contactService = CompanyContactService();
  final RegistrationProcessService _processService =
      RegistrationProcessService();
  final CompanyPaymentService _paymentService = CompanyPaymentService();

  CompanyResponse? _company;
  bool _isLoading = true;
  String? _error;
  String? _jwtToken;
  String? _userId;
  String? advocateId;

  // Contact data
  List<CompanyContact> _contacts = [];
  bool _isLoadingContacts = false;
  String? _contactsError;

  // Registration Process data
  List<RegistrationProcessResponse> _processes = [];
  bool _isLoadingProcesses = false;
  String? _processesError;

  // Payment data
  List<CompanyPaymentResponse> _payments = [];
  bool _isLoadingPayments = false;
  String? _paymentsError;
  bool _isCreator = false;

  // ✅ Center admin ownership
  bool _isCenterAdminOfThis = false;
  bool _isBusy = false;

  // ✅ Fixed payment details
  static const String _receiverNumber = "+8801874648472";
  static const double _paymentAmount = 5000.0;

  // ✅ Payment form controllers
  final TextEditingController _senderPhoneController =
      TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // ============================================================
  // Single source of truth for the "current" registration process
  // ============================================================
  RegistrationProcessResponse _responseFromModel(
    RegistrationProcess p, {
    String companyName = '',
    String advocateName = '',
    String userName = '',
  }) {
    return RegistrationProcessResponse(
      id: p.id,
      companyId: p.companyId,
      companyName: companyName,
      advocateId: p.advocateId,
      advocateName: advocateName,
      userId: p.userId,
      userName: userName,
      status: p.status,
      shareValuePerShare: p.shareValuePerShare,
      steps: p.steps,
    );
  }

  RegistrationProcessResponse? get _currentProcess {
    if (_processes.isNotEmpty) return _processes.first;

    final nested = _company?.registrationProcess;
    if (nested == null) return null;

    return _responseFromModel(
      nested,
      companyName: _company?.companyName ?? '',
    );
  }

  bool get _hasProcess => _currentProcess != null;

  /// True when the current user owns (created/accepted) this process.
  bool get _isMineProcess {
    final p = _currentProcess;
    if (p == null) return false;
    return p.userId == _userId;
  }

  /// True when the current user is the **advocate** assigned to the process.
  bool get _isAdvocateOfThis {
    final p = _currentProcess;
    if (p == null) return false;
    if (advocateId == null || advocateId!.isEmpty) return false;
    return p.advocateId == advocateId;
  }

  /// Advocate-only edit: status + steps (not owner).
  bool get _canEditStatusAndStepsOnly =>
      _isAdvocateOfThis && !_isMineProcess;

  /// Full edit (owner of the process, or creator acting through center admin).
  bool get _canEditFullProcess => _isMineProcess;

  @override
  void initState() {
    super.initState();

    if (widget.company != null) {
      // Pre-loaded — render immediately, then refresh in background.
      _company = widget.company;
      _isLoading = false;
      _loadTokenAndDetails(skipInitialFetch: true);
    } else {
      _loadTokenAndDetails();
    }
  }

  Future<void> _loadTokenAndDetails({bool skipInitialFetch = false}) async {
    _jwtToken = await AuthService.getToken();
    _userId = await AuthService.getUserId();

    final prefs = await SharedPreferences.getInstance();
    advocateId = prefs.getString('advocateId');
    final currentUserId = prefs.getString('userId');

    if (!mounted) return;

    if (skipInitialFetch && _company != null) {
      setState(() {
        _isCreator = currentUserId != null &&
            currentUserId.isNotEmpty &&
            _company!.creatorId == currentUserId;

        _isCenterAdminOfThis = _company!.registrationProcess != null &&
            currentUserId != null &&
            currentUserId.isNotEmpty &&
            _company!.registrationProcess!.userId == currentUserId;
      });

      _loadContacts();
      await _loadProcesses();
      if (_isCreator || _isCenterAdminOfThis || _isMineProcess) {
        _loadPayments();
      }
      _refreshCompanySilently();
      return;
    }

    await _loadCompanyDetails();
  }

  Future<void> _refreshCompanySilently() async {
    try {
      final fresh = await _companyService.getCompanyById(widget.companyId);
      if (!mounted) return;
      setState(() => _company = fresh);
    } catch (_) {}
  }

  Future<void> _loadCompanyDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please login to view company details');
      }

      final company = await _companyService.getCompanyById(widget.companyId);

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      if (!mounted) return;
      setState(() {
        advocateId = prefs.getString('advocateId');
        _company = company;
        _isLoading = false;

        _isCreator = currentUserId != null &&
            currentUserId.isNotEmpty &&
            company.creatorId == currentUserId;

        _isCenterAdminOfThis = company.registrationProcess != null &&
            currentUserId != null &&
            currentUserId.isNotEmpty &&
            company.registrationProcess!.userId == currentUserId;

        print('✅ Is Creator: $_isCreator');
        print('✅ Is Center Admin (nested): $_isCenterAdminOfThis');
        print('✅ CreatorId: ${company.creatorId}');
        print('✅ CurrentUserId: $currentUserId');
        print('✅ AdvocateId (prefs): $advocateId');
        print('✅ Process advocateId: ${company.registrationProcess?.advocateId}');
      });

      _loadContacts();
      await _loadProcesses();

      if (_isCreator || _isCenterAdminOfThis || _isMineProcess) {
        _loadPayments();
      } else {
        print('⏭️ Skipping payments - user is not creator or center admin');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ==================== LOAD CONTACTS ====================
  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
      _contactsError = null;
    });

    try {
      final contacts =
          await _contactService.getContactsByCompanyId(widget.companyId);
      setState(() {
        _contacts = contacts;
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() {
        _contactsError = e.toString();
        _isLoadingContacts = false;
      });
    }
  }

  // ==================== LOAD PROCESSES ====================
  Future<void> _loadProcesses() async {
    setState(() {
      _isLoadingProcesses = true;
      _processesError = null;
    });

    try {
      final processes =
          await _processService.getProcessesByCompanyId(widget.companyId);
      setState(() {
        _processes = processes;
        _isLoadingProcesses = false;
      });
    } catch (e) {
      setState(() {
        _processesError = e.toString();
        _isLoadingProcesses = false;
      });
    }
  }

  // ==================== LOAD PAYMENTS ====================
  Future<void> _loadPayments() async {
    setState(() {
      _isLoadingPayments = true;
      _paymentsError = null;
    });

    try {
      final payments =
          await _paymentService.getPaymentsByCompanyId(widget.companyId);
      setState(() {
        _payments = payments;
        _isLoadingPayments = false;
      });
    } catch (e) {
      setState(() {
        _paymentsError = e.toString();
        _isLoadingPayments = false;
      });
    }
  }

  void _viewAttachment(String attachmentId) {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again to view attachments'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyAttachmentViewer(
          attachmentId: attachmentId,
          jwtToken: _jwtToken!,
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEditCompany() {
    if (_company != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditCompanyScreen(
            company: _company!,
          ),
        ),
      ).then((result) {
        if (result == true) {
          _loadCompanyDetails();
        }
      });
    }
  }

  // ✅ Delete Company
  Future<void> _deleteCompany() async {
    if (_company == null || _company!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to delete this company'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Company',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this company?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Company: ${_company!.companyName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All company data including directors, shareholders, documents, and payments will be permanently deleted.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await _companyService.deleteCompany(
        _company!.id!,
        _userId!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Company deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to delete company');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ADVOCATE PICKER
  // ============================================================
  Future<AdvocateBrief?> _pickAdvocate() async {
    if (_userId == null || _userId!.isEmpty) return null;

    List<AdvocateBrief> advocates;
    try {
      advocates = await CenterAdminBridge.myAdvocates(_userId!);
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load advocates: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    if (!mounted) return null;

    if (advocates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have no advocates connected. Please add one first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    return showModalBottomSheet<AdvocateBrief>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select an Advocate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick the advocate who will handle this company',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: advocates.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (context, i) {
                    final a = advocates[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.gavel,
                            color: Colors.blue, size: 20),
                      ),
                      title: Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'ID: ${a.id}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing:
                          const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => Navigator.pop(context, a),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ACCEPT (as center admin) — pick advocate + share value
  // ============================================================
  Future<void> _confirmAcceptAsCenterAdmin() async {
    final advocate = await _pickAdvocate();
    if (advocate == null) return;

    final shareValueController = TextEditingController(text: '100');

    final shareValue = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Share Value'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the share value per share for this company registration.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shareValueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Share Value Per Share (BDT) *',
                hintText: 'e.g. 100',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(shareValueController.text.trim());
              if (v == null || v <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid share value > 0'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, v);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Next'),
          ),
        ],
      ),
    );

    shareValueController.dispose();
    if (shareValue == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept as Center Admin?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You will become the registration process controller for this company.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gavel, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Advocate: ${advocate.name}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Share Value: ৳${shareValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBusy = true);

    try {
      final process = RegistrationProcess(
        companyId: widget.companyId,
        advocateId: advocate.id,
        userId: _userId!,
        status: false,
        shareValuePerShare: shareValue,
        steps: const ['accepted'],
      );

      print('📤 Sending registration process payload:');
      print(process.toJson());

      await _processService.addRegistrationProcess(
        process: process,
        userId: _userId!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration process accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadCompanyDetails();
      if (mounted) await _loadProcesses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmRemoveNoProcess() async {
    await _deleteCompany();
  }

  // ============================================================
  // ADVOCATE-ONLY EDIT (status + steps)
  // ============================================================
  Future<void> _openAdvocateStatusStepsEdit() async {
    final fresh = _currentProcess;
    if (fresh == null) return;
    if (fresh.id == null || fresh.id!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing registration process ID — cannot update.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    // Prepare editable step controllers
    final List<TextEditingController> stepControllers =
        fresh.steps.map((s) => TextEditingController(text: s)).toList();
    if (stepControllers.isEmpty) {
      stepControllers.add(TextEditingController());
    }

    bool status = fresh.status;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void addStep() {
              setLocal(() => stepControllers.add(TextEditingController()));
            }

            void removeStep(int index) {
              if (stepControllers.length <= 1) return;
              setLocal(() {
                stepControllers[index].dispose();
                stepControllers.removeAt(index);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Update Progress'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Read-only advocate
                      const Text('Assigned Advocate',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gavel,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fresh.advocateName.isNotEmpty
                                    ? fresh.advocateName
                                    : fresh.advocateId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.lock, size: 14,
                                color: Colors.grey),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Read-only share value
                      const Text('Share Value Per Share',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '৳${fresh.shareValuePerShare.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const Spacer(),
                            const Icon(Icons.lock, size: 14,
                                color: Colors.grey),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Steps — editable
                      Row(
                        children: [
                          const Text('Steps',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: addStep,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Step',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 32),
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      ...List.generate(stepControllers.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Step ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: stepControllers[i],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Describe step ${i + 1}...',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Remove step',
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: stepControllers.length <= 1
                                      ? Colors.grey.shade300
                                      : Colors.red,
                                ),
                                onPressed: stepControllers.length <= 1
                                    ? null
                                    : () => removeStep(i),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title:
                            const Text('Mark as completed (status = true)'),
                        value: status,
                        onChanged: (v) => setLocal(() => status = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      for (final c in stepControllers) {
        c.dispose();
      }
      return;
    }

    final steps = <String>[];
    for (final c in stepControllers) {
      final v = c.text.trim();
      if (v.isNotEmpty) steps.add(v);
    }
    for (final c in stepControllers) {
      c.dispose();
    }

    // Preserve advocate / user / share value exactly as they were.
    final updated = RegistrationProcess(
      id: fresh.id,
      companyId: fresh.companyId,
      advocateId: fresh.advocateId,
      userId: fresh.userId,
      status: status,
      shareValuePerShare: fresh.shareValuePerShare,
      steps: steps,
    );

    setState(() => _isBusy = true);

    try {
      await _processService.updateRegistrationProcess(
        id: fresh.id!,
        process: updated,
        userId: _userId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration progress updated'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCompanyDetails();
      if (mounted) await _loadProcesses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ============================================================
  // FULL EDIT (process owner)
  // ============================================================
  Future<void> _openEditRegistrationProcess() async {
    final fresh = _currentProcess;
    if (fresh == null) return;

    final process = RegistrationProcess(
      id: fresh.id,
      companyId: fresh.companyId,
      advocateId: fresh.advocateId,
      userId: fresh.userId,
      status: fresh.status,
      shareValuePerShare: fresh.shareValuePerShare,
      steps: fresh.steps,
    );

    print('🟪 [update] process.id = ${process.id}');
    print('🟪 [update] process.companyId = ${process.companyId}');

    if (process.id == null || process.id!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing registration process ID — cannot update. '
            'Please refresh and try again.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    final List<TextEditingController> stepControllers =
        process.steps.map((s) => TextEditingController(text: s)).toList();
    if (stepControllers.isEmpty) {
      stepControllers.add(TextEditingController());
    }

    bool status = process.status;
    final shareValueController = TextEditingController(
      text: process.shareValuePerShare.toString(),
    );

    AdvocateBrief? selectedAdvocate = AdvocateBrief(
      id: process.advocateId,
      name: process.advocateId,
    );

    try {
      final list = await CenterAdminBridge.myAdvocates(_userId ?? '');
      for (final a in list) {
        if (a.id == process.advocateId) {
          selectedAdvocate = a;
          break;
        }
      }
    } catch (_) {}

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            void addStep() {
              setLocal(() => stepControllers.add(TextEditingController()));
            }

            void removeStep(int index) {
              if (stepControllers.length <= 1) return;
              setLocal(() {
                stepControllers[index].dispose();
                stepControllers.removeAt(index);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Update Registration Process'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assigned Advocate',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await _pickAdvocate();
                          if (picked != null) {
                            setLocal(() => selectedAdvocate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.gavel,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedAdvocate?.name ?? 'Select advocate',
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text('Share Value Per Share',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: shareValueController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'e.g. 100',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          const Text('Steps',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: addStep,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Step',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 32),
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      ...List.generate(stepControllers.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Step ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: stepControllers[i],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Describe step ${i + 1}...',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Remove step',
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: stepControllers.length <= 1
                                      ? Colors.grey.shade300
                                      : Colors.red,
                                ),
                                onPressed: stepControllers.length <= 1
                                    ? null
                                    : () => removeStep(i),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Mark as completed (status = true)'),
                        value: status,
                        onChanged: (v) => setLocal(() => status = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      for (final c in stepControllers) {
        c.dispose();
      }
      shareValueController.dispose();
      return;
    }

    final steps = <String>[];
    for (final c in stepControllers) {
      final v = c.text.trim();
      if (v.isNotEmpty) steps.add(v);
    }

    final shareValue =
        double.tryParse(shareValueController.text.trim()) ??
            process.shareValuePerShare;

    if (shareValue <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share value must be greater than 0'),
          backgroundColor: Colors.red,
        ),
      );
      for (final c in stepControllers) {
        c.dispose();
      }
      shareValueController.dispose();
      return;
    }

    final advocateIdToSend = (selectedAdvocate?.id.isNotEmpty ?? false)
        ? selectedAdvocate!.id
        : process.advocateId;

    if (advocateIdToSend.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an advocate'),
          backgroundColor: Colors.red,
        ),
      );
      for (final c in stepControllers) {
        c.dispose();
      }
      shareValueController.dispose();
      return;
    }

    shareValueController.dispose();

    final updated = RegistrationProcess(
      id: process.id,
      companyId: process.companyId,
      advocateId: advocateIdToSend,
      userId: process.userId,
      status: status,
      shareValuePerShare: shareValue,
      steps: steps,
    );

    print('📤 [update] Payload: ${updated.toJson()}');

    setState(() => _isBusy = true);

    try {
      await _processService.updateRegistrationProcess(
        id: process.id ?? '',
        process: updated,
        userId: _userId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration process updated'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCompanyDetails();
      if (mounted) await _loadProcesses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ============================================================
  // DELETE REGISTRATION PROCESS (owner only)
  // ============================================================
  Future<void> _confirmDeleteRegistrationProcess() async {
    final process = _currentProcess;
    if (process == null) return;

    if (process.id == null || process.id!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing registration process ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Registration Process?'),
        content: const Text(
          'This will remove your registration process for this company. '
          'The company record itself will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBusy = true);

    try {
      await _processService.deleteRegistrationProcess(
        id: process.id ?? '',
        userId: _userId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration process deleted'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadCompanyDetails();
      if (mounted) await _loadProcesses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _openMyCompanyProcessControlScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CompanyProcessControlScreen(),
      ),
    );
    if (mounted) await _loadCompanyDetails();
  }

  // ============================================================
  // CENTER ADMIN / ADVOCATE CONTROLS
  // ============================================================
  Widget _buildCenterAdminControls() {
    if (_company == null) return const SizedBox.shrink();

    final hasProcess = _hasProcess;

    // Which controls can be shown:
    final showAccept = !hasProcess;
    final showFullOwnerControls = _canEditFullProcess;
    final showAdvocateStatusSteps = _canEditStatusAndStepsOnly;
    final showProcessControlEntry = _isMineProcess || _isAdvocateOfThis;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  showAdvocateStatusSteps && !showFullOwnerControls
                      ? Icons.gavel
                      : Icons.admin_panel_settings,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  showAdvocateStatusSteps && !showFullOwnerControls
                      ? 'Advocate Controls'
                      : 'Center Admin Controls',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (showProcessControlEntry)
              OutlinedButton.icon(
                onPressed: _openMyCompanyProcessControlScreen,
                icon: const Icon(Icons.list_alt),
                label: const Text('My Company Processes'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: Colors.blue),
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

            if (showProcessControlEntry && (showAccept || showAdvocateStatusSteps || showFullOwnerControls))
              const SizedBox(height: 10),

            if (showAccept) ...[
              ElevatedButton.icon(
                onPressed: _confirmAcceptAsCenterAdmin,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Accept Registration Process'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _confirmRemoveNoProcess,
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Remove Registration'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ] else if (showFullOwnerControls) ...[
              // Owner: full edit + delete
              ElevatedButton.icon(
                onPressed: _openEditRegistrationProcess,
                icon: const Icon(Icons.edit_note),
                label: const Text('Update Registration Process'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _confirmDeleteRegistrationProcess,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Registration Process'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ] else if (showAdvocateStatusSteps) ...[
              // Advocate (not owner): only status + steps
              ElevatedButton.icon(
                onPressed: _openAdvocateStatusStepsEdit,
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('Update Status & Steps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'As the assigned advocate you can update the process '
                      'status and steps only.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Show Send Payment Dialog
  void _showSendPaymentDialog() {
    _senderPhoneController.clear();
    _transactionIdController.clear();
    _amountController.text = _paymentAmount.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Send Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const Text(
                      'Receiver Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _receiverNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(_receiverNumber),
                          icon: const Icon(Icons.copy,
                              size: 18, color: Colors.green),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amount: ${_paymentAmount.toStringAsFixed(0)} BDT',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senderPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Sender Phone Number *',
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID *',
                  hintText: 'Enter transaction ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (BDT)',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please ensure you have sent the payment to the receiver number above before submitting.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    final senderPhone = _senderPhoneController.text.trim();
    final transactionId = _transactionIdController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (senderPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (transactionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter transaction ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to send payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_company == null || _company!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);

    setState(() => _isLoadingPayments = true);

    try {
      final payment = CompanyRequestPayment(
        companyId: _company!.id!,
        senderUserId: _userId!,
        senderPhoneNumber: senderPhone,
        transactionId: transactionId,
        amount: amount,
      );

      await _paymentService.addPayment(payment: payment);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Payment submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingPayments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _company?.companyName ?? 'Company Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_isCreator)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditCompany,
              tooltip: 'Edit Company',
            ),
          if (_isCreator)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteCompany,
              tooltip: 'Delete Company',
              color: Colors.red.shade300,
            ),
          if (_isCreator)
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: _showSendPaymentDialog,
              tooltip: 'Send Payment',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompanyDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: (_isLoading || _isBusy)
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _company == null
                  ? _buildNotFoundWidget()
                  : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error: $_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCompanyDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Company Not Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The requested company does not exist.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final company = _company!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(company),
          const SizedBox(height: 16),
          _buildInfoCard(company),
          const SizedBox(height: 16),
          if (company.directorsName != null &&
              company.directorsName!.isNotEmpty)
            _buildDirectorsSection(company),
          const SizedBox(height: 16),
          if (company.shareHoldersName != null &&
              company.shareHoldersName!.isNotEmpty)
            _buildShareholdersSection(company),
          const SizedBox(height: 16),
          if (company.capitals != null && company.capitals!.isNotEmpty)
            _buildCapitalSection(company),
          const SizedBox(height: 16),
          if (company.subscriptions != null &&
              company.subscriptions!.isNotEmpty)
            _buildSubscriptionsSection(company),
          const SizedBox(height: 16),
          _buildDocumentsSection(company),
          const SizedBox(height: 16),
          _buildCompanyContactSection(),
          const SizedBox(height: 16),
          _buildRegistrationProcessSection(),
          const SizedBox(height: 16),

          // ✅ Center Admin / Advocate controls
          if (_isMineProcess || _isAdvocateOfThis || !_hasProcess)
            _buildCenterAdminControls(),

          const SizedBox(height: 16),

          if (_isCreator || _isMineProcess) _buildPaymentSection(),
        ],
      ),
    );
  }

  // ==================== HEADER CARD ====================
  Widget _buildHeaderCard(CompanyResponse company) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company.type ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isCreator)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Owner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_isCreator && _isAdvocateOfThis)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gavel, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Advocate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildHeaderTag(
                  company.category ?? 'N/A', Colors.white.withOpacity(0.2)),
              _buildHeaderTag(company.natureOfBusiness ?? 'N/A',
                  Colors.white.withOpacity(0.2)),
              if (company.creatorName != null)
                _buildHeaderTag('Created by: ${company.creatorName}',
                    Colors.white.withOpacity(0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  // ==================== INFO CARD ====================
  Widget _buildInfoCard(CompanyResponse company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('ID', company.id ?? 'N/A'),
            _buildInfoRow('Type', company.type ?? 'N/A'),
            _buildInfoRow('Category', company.category ?? 'N/A'),
            _buildInfoRow(
                'Nature of Business', company.natureOfBusiness ?? 'N/A'),
            if (company.officeRegistryId != null &&
                company.officeRegistryId!.isNotEmpty)
              _buildInfoRow('Office Registry ID', company.officeRegistryId!),
            _buildInfoRow('Authorized', company.authorized ?? 'N/A'),
            if (company.creatorName != null)
              _buildInfoRow('Created By', company.creatorName!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DIRECTORS SECTION ====================
  Widget _buildDirectorsSection(CompanyResponse company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Directors (${company.directorsName!.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...company.directorsName!.map((name) => _buildPersonTile(name)),
          ],
        ),
      ),
    );
  }

  // ==================== SHAREHOLDERS SECTION ====================
  Widget _buildShareholdersSection(CompanyResponse company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Shareholders (${company.shareHoldersName!.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...company.shareHoldersName!
                .map((name) => _buildPersonTile(name)),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonTile(String? name) {
    final displayName = name ?? 'Unknown';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CAPITAL SECTION ====================
  Widget _buildCapitalSection(CompanyResponse company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Capital Details',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...company.capitals!.map((capital) => _buildCapitalTile(capital)),
          ],
        ),
      ),
    );
  }

  Widget _buildCapitalTile(Capital capital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Authorized Capital',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '৳${capital.authorizedCapital.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share Value',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '৳${capital.shareValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Shares',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                capital.totalShare.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SUBSCRIPTIONS SECTION ====================
  Widget _buildSubscriptionsSection(CompanyResponse company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Subscriptions',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...company.subscriptions!
                .map((sub) => _buildSubscriptionTile(sub)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(Subscription subscription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.subscriberName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Shares: ${subscription.numberOfShare}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (subscription.signatureId != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Signed',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== DOCUMENTS SECTION ====================
  Widget _buildDocumentsSection(CompanyResponse company) {
    if (company.documents == null || company.documents!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Documents',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${company.documents!.length}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...company.documents!.map((docId) => _buildDocumentTile(docId)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Tap View to open document',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _viewAttachment(docId),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== COMPANY CONTACT SECTION ====================
  Widget _buildCompanyContactSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Company Contacts',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isLoadingContacts ? '...' : '${_contacts.length}',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoadingContacts
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _contactsError != null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error loading contacts: $_contactsError',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : _contacts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No contacts found',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          )
                        : Column(
                            children: _contacts
                                .map((contact) => _buildContactTile(contact))
                                .toList(),
                          ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(CompanyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contact.contactPersonName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                contact.contactPersonMobile,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.email, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                contact.contactPersonEmail,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.info, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'How: ${contact.howDidHear}',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          if (contact.anyOtherMessage != null &&
              contact.anyOtherMessage!.isNotEmpty)
            Row(
              children: [
                Icon(Icons.message, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contact.anyOtherMessage!,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ==================== REGISTRATION PROCESS SECTION ====================
  Widget _buildRegistrationProcessSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Registration Process',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isLoadingProcesses ? '...' : '${_processes.length}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoadingProcesses
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _processesError != null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error loading processes: $_processesError',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : _processes.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No registration process found',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          )
                        : Column(
                            children: _processes
                                .map((process) => _buildProcessTile(process))
                                .toList(),
                          ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessTile(RegistrationProcessResponse process) {
    final isMine = process.userId == _userId;
    final isAdvocate =
        advocateId != null && advocateId!.isNotEmpty &&
            process.advocateId == advocateId;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Advocate: ${process.advocateName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isMine)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'You (owner)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (isAdvocate)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'You (advocate)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: process.status
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  process.status ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    fontSize: 11,
                    color: process.status
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Share Value: ৳${process.shareValuePerShare.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          if (process.steps.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Steps: ${process.steps.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children:
                  process.steps.map((step) => _buildStepChip(step)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepChip(String step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        step,
        style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
      ),
    );
  }

  // ==================== PAYMENT SECTION ====================
  Widget _buildPaymentSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Payment Information',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isLoadingPayments ? '...' : '${_payments.length}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isCreator)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showSendPaymentDialog,
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'Send Payment',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (_isCreator) const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.phone,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Receiver Number',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _receiverNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(_receiverNumber),
                        icon: const Icon(Icons.copy,
                            color: Colors.green, size: 20),
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Amount',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_paymentAmount.toStringAsFixed(0)} BDT',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please send the payment to the above number and share the transaction ID with the company.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _isLoadingPayments
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _paymentsError != null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error loading payments: $_paymentsError',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : _payments.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Center(
                              child: Text(
                                'No payment history found',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment History',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._payments.map(
                                  (payment) => _buildPaymentTile(payment)),
                            ],
                          ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(CompanyPaymentResponse payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  payment.senderUserName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '৳${payment.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                payment.senderPhoneNumber,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.receipt, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.transactionId,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                payment.formattedDate,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}