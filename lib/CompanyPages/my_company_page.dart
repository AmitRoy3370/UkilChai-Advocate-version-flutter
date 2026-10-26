// lib/CompanyPages/my_company_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../CompanyPages/company_service.dart';
import '../CompanyPages/company_response.dart';
import '../CompanyPages/company_details_page.dart';
import '../CompanyPages/registration_process_service.dart';
import '../Auth/AuthService.dart';

class MyCompanyPage extends StatefulWidget {
  const MyCompanyPage({Key? key}) : super(key: key);

  @override
  State<MyCompanyPage> createState() => _MyCompanyPageState();
}

class _MyCompanyPageState extends State<MyCompanyPage>
    with SingleTickerProviderStateMixin {
  final CompanyService _companyService = CompanyService();
  final RegistrationProcessService _processService =
      RegistrationProcessService();

  List<CompanyResponse> _allCompanies = [];
  List<CompanyResponse> _registeredCompanies = [];
  List<CompanyResponse> _unregisteredCompanies = [];

  /// Fresh `registrationProcess.status` per companyId, fetched from
  /// `/registration-process/company/{id}`. Falls back to the nested value
  /// in the company response if the fetch failed or hasn't run yet.
  final Map<String, bool> _freshStatusByCompanyId = {};

  bool _isLoading = true;
  String? _error;
  String? _userId;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        userId = await AuthService.getUserId();
      }

      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
        });
        await _loadCompanies(userId);
      } else {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading user: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // A company is "approved" only when:
  //   1. it has a registration process, AND
  //   2. that process's status is true.
  //
  // We prefer the freshly-fetched status from
  // /registration-process/company/{id} (see _loadCompanies) and fall
  // back to the nested `registrationProcess` from the company response.
  // ============================================================
  bool _isApproved(CompanyResponse c) {
    final cid = c.id ?? '';

    if (_freshStatusByCompanyId.containsKey(cid)) {
      return _freshStatusByCompanyId[cid] == true;
    }

    final nested = c.registrationProcess;
    if (nested == null) return false;
    return nested.status == true;
  }

  Future<void> _loadCompanies(String userId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _freshStatusByCompanyId.clear();
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please login to view your companies');
      }

      final companies = await _companyService.getCompaniesByCreatorId(userId);

      // ✅ Fetch the fresh registration-process status for every company,
      //    in parallel, so the split is accurate even when the nested
      //    `registrationProcess` in the list response is stale.
      final futures = <Future<void>>[];
      for (final c in companies) {
        final cid = c.id;
        if (cid == null || cid.isEmpty) continue;

        futures.add(
          _processService
              .getProcessesByCompanyId(cid)
              .then((procs) {
            if (procs.isEmpty) {
              _freshStatusByCompanyId[cid] = false;
            } else {
              _freshStatusByCompanyId[cid] = procs.first.status == true;
            }
          })
              .catchError((_) {
            // On error, leave the map entry absent so we fall back
            // to the nested status in _isApproved().
          }),
        );
      }
      await Future.wait(futures);

      // Split using the strict rule
      final registered = <CompanyResponse>[];
      final unregistered = <CompanyResponse>[];

      for (final c in companies) {
        if (_isApproved(c)) {
          registered.add(c);
        } else {
          unregistered.add(c);
        }
      }

      setState(() {
        _allCompanies = companies;
        _registeredCompanies = registered;
        _unregisteredCompanies = unregistered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCompanyDetail(String companyId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailsPage(companyId: companyId),
      ),
    );

    // Refresh so any status change (accept / approve / delete) from the
    // details page is reflected here immediately.
    if (mounted && _userId != null) {
      await _loadCompanies(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Companies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Approved (${_registeredCompanies.length})',
            ),
            Tab(
              icon: const Icon(Icons.pending),
              text: 'Pending (${_unregisteredCompanies.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_userId != null) {
                _loadCompanies(_userId!);
              } else {
                _loadUserId();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCompanyList(_registeredCompanies,
                        isRegistered: true),
                    _buildCompanyList(_unregisteredCompanies,
                        isRegistered: false),
                  ],
                ),
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
            onPressed: () {
              if (_userId != null) {
                _loadCompanies(_userId!);
              } else {
                _loadUserId();
              }
            },
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

  Widget _buildCompanyList(List<CompanyResponse> companies,
      {required bool isRegistered}) {
    if (companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRegistered
                  ? Icons.check_circle_outline
                  : Icons.pending_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isRegistered
                  ? 'No Approved Companies'
                  : 'No Pending Companies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRegistered
                  ? 'You don\'t have any approved companies yet.'
                  : 'All your companies are approved.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        return _buildCompanyCard(company, isRegistered: isRegistered);
      },
    );
  }

  Widget _buildCompanyCard(CompanyResponse company,
      {required bool isRegistered}) {
    final cardColor =
        isRegistered ? Colors.green.shade50 : Colors.orange.shade50;
    final borderColor =
        isRegistered ? Colors.green.shade200 : Colors.orange.shade200;

    return GestureDetector(
      onTap: () {
        if (company.id != null) {
          _navigateToCompanyDetail(company.id!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isRegistered ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRegistered ? Icons.check_circle : Icons.pending,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          company.type ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRegistered
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isRegistered ? 'Approved' : 'Pending',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isRegistered
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (company.category != null &&
                            company.category!.isNotEmpty)
                          _buildTag(company.category!, Colors.blue),
                        if (company.directorsName != null &&
                            company.directorsName!.isNotEmpty)
                          _buildTag(
                            '${company.directorsName!.length} Directors',
                            Colors.purple,
                          ),
                        if (company.shareHoldersName != null &&
                            company.shareHoldersName!.isNotEmpty)
                          _buildTag(
                            '${company.shareHoldersName!.length} Shareholders',
                            Colors.orange,
                          ),
                        if (isRegistered &&
                            company.officeRegistryId != null &&
                            company.officeRegistryId!.isNotEmpty)
                          _buildTag(
                              'ID: ${company.officeRegistryId}', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}