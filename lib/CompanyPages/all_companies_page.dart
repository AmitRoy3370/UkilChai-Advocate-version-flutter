// lib/CompanyPages/all_companies_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../CompanyPages/company_service.dart';
import '../CompanyPages/company_response.dart';
import '../CompanyPages/company_details_page.dart';
import '../CompanyPages/registration_process_service.dart';
import '../CompanyPages/registration_process_response.dart';
import '../Auth/AuthService.dart';

class AllCompaniesPage extends StatefulWidget {
  const AllCompaniesPage({Key? key}) : super(key: key);

  @override
  State<AllCompaniesPage> createState() => _AllCompaniesPageState();
}

class _AllCompaniesPageState extends State<AllCompaniesPage>
    with SingleTickerProviderStateMixin {
  final CompanyService _companyService = CompanyService();
  final RegistrationProcessService _processService =
      RegistrationProcessService();

  // All companies as fetched from the server
  List<CompanyResponse> _allCompanies = [];

  // Split lists
  List<CompanyResponse> _approvedCompanies = [];
  List<CompanyResponse> _pendingCompanies = [];

  // Cached fresh status by companyId (from /registration-process/company/{id})
  final Map<String, bool> _freshStatusByCompanyId = {};

  // Currently visible list (approved or pending depending on tab)
  List<CompanyResponse> _visibleCompanies = [];

  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  // Filter states
  String? _selectedType;
  String? _selectedCategory;
  String? _selectedNatureOfBusiness;

  // Filter options (rebuilt whenever the active tab's base list changes)
  final List<String> _types = [];
  final List<String> _categories = [];
  final List<String> _natureOfBusiness = [];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Tab just changed — rebuild filter options + reapply filters
        _rebuildFilterOptionsAndApply();
      }
    });
    _loadCompanies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // Helpers
  //
  // A company is "approved" only when:
  //   1. it has a registration process (fresh status if available,
  //      otherwise the nested one), AND
  //   2. that process's status is true.
  // ============================================================
  bool _isApproved(CompanyResponse c) {
    final cid = c.id ?? '';

    // 1. Prefer the freshly-fetched status from /registration-process/company/{id}
    if (_freshStatusByCompanyId.containsKey(cid)) {
      return _freshStatusByCompanyId[cid] == true;
    }

    // 2. Fallback to the nested registration process from the company list
    final nested = c.registrationProcess;
    if (nested == null) return false;
    return nested.status == true;
  }

  // ============================================================
  // Load
  // ============================================================
  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _freshStatusByCompanyId.clear();
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please login to view companies');
      }

      final companies = await _companyService.getAllCompanies();

      // ✅ Fetch the fresh registration-process status for EVERY company,
      //    in parallel. This guarantees the approved/pending split is
      //    accurate even if the nested registrationProcess in the list
      //    response is stale.
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

      // Split into approved / pending
      final approved = <CompanyResponse>[];
      final pending = <CompanyResponse>[];

      for (final c in companies) {
        if (_isApproved(c)) {
          approved.add(c);
        } else {
          pending.add(c);
        }
      }

      setState(() {
        _allCompanies = companies;
        _approvedCompanies = approved;
        _pendingCompanies = pending;
        _isLoading = false;
      });

      _rebuildFilterOptionsAndApply();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // Rebuild filter options based on active tab, then apply filters
  // ============================================================
  void _rebuildFilterOptionsAndApply() {
    final baseList = _activeBaseList();

    _types.clear();
    _categories.clear();
    _natureOfBusiness.clear();

    for (final c in baseList) {
      if (c.type != null && c.type!.isNotEmpty && !_types.contains(c.type)) {
        _types.add(c.type!);
      }
      if (c.category != null &&
          c.category!.isNotEmpty &&
          !_categories.contains(c.category)) {
        _categories.add(c.category!);
      }
      if (c.natureOfBusiness != null &&
          c.natureOfBusiness!.isNotEmpty &&
          !_natureOfBusiness.contains(c.natureOfBusiness)) {
        _natureOfBusiness.add(c.natureOfBusiness!);
      }
    }

    // Reset selections that no longer exist in the new tab
    if (_selectedType != null && !_types.contains(_selectedType)) {
      _selectedType = null;
    }
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }
    if (_selectedNatureOfBusiness != null &&
        !_natureOfBusiness.contains(_selectedNatureOfBusiness)) {
      _selectedNatureOfBusiness = null;
    }

    _applyFilters();
  }

  List<CompanyResponse> _activeBaseList() {
    return _tabController.index == 0 ? _approvedCompanies : _pendingCompanies;
  }

  bool get _isApprovedTab => _tabController.index == 0;

  // ============================================================
  // Filters
  // ============================================================
  void _applyFilters() {
    setState(() {
      final baseList = _activeBaseList();

      _visibleCompanies = baseList.where((company) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch =
              company.companyName.toLowerCase().contains(query) ||
                  (company.type?.toLowerCase().contains(query) ?? false) ||
                  (company.category?.toLowerCase().contains(query) ?? false) ||
                  (company.natureOfBusiness?.toLowerCase().contains(query) ??
                      false) ||
                  (company.officeRegistryId?.toLowerCase().contains(query) ??
                      false);
          if (!matchesSearch) return false;
        }

        // Type filter
        if (_selectedType != null && _selectedType!.isNotEmpty) {
          if (company.type != _selectedType) return false;
        }

        // Category filter
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
          if (company.category != _selectedCategory) return false;
        }

        // Nature of Business filter
        if (_selectedNatureOfBusiness != null &&
            _selectedNatureOfBusiness!.isNotEmpty) {
          if (company.natureOfBusiness != _selectedNatureOfBusiness) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _selectedCategory = null;
      _selectedNatureOfBusiness = null;
    });
    _applyFilters();
  }

  Future<void> _navigateToCompanyDetail(String companyId) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return CompanyDetailsPage(companyId: companyId);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    // Refresh the list so any status change (accept / approve / delete)
    // from the details page is reflected here immediately.
    if (mounted) await _loadCompanies();
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final crossAxisCount = isDesktop ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Companies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompanies,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 16),
                  const SizedBox(width: 6),
                  Text('Approved (${_approvedCompanies.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top, size: 16),
                  const SizedBox(width: 6),
                  Text('Pending (${_pendingCompanies.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(isApprovedTab: true),
                    _buildTabContent(isApprovedTab: false),
                  ],
                ),
    );
  }

  Widget _buildTabContent({required bool isApprovedTab}) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_types.isNotEmpty ||
            _categories.isNotEmpty ||
            _natureOfBusiness.isNotEmpty)
          _buildFilterChips(),
        _buildResultsCount(isApprovedTab: isApprovedTab),
        Expanded(
          child: _visibleCompanies.isEmpty
              ? _buildEmptyWidget(isApprovedTab: isApprovedTab)
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 800 ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _visibleCompanies.length,
                  itemBuilder: (context, index) {
                    final company = _visibleCompanies[index];
                    return _buildCompanyCard(company,
                        isApproved: isApprovedTab);
                  },
                ),
        ),
      ],
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
            onPressed: _loadCompanies,
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

  Widget _buildEmptyWidget({required bool isApprovedTab}) {
    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedType != null ||
        _selectedCategory != null ||
        _selectedNatureOfBusiness != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isApprovedTab ? Icons.business : Icons.hourglass_empty,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No ${isApprovedTab ? 'approved' : 'pending'} companies match your filters'
                : 'No ${isApprovedTab ? 'approved' : 'pending'} companies found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          if (hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          const SizedBox(height: 8),
          Text(
            isApprovedTab
                ? 'Only companies with a completed registration process are shown.'
                : 'Companies awaiting completion of their registration process are shown here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search companies...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _applyFilters();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (_types.isNotEmpty)
            _buildFilterChip(
              label: 'Type',
              options: _types,
              selectedValue: _selectedType,
              onSelected: (value) {
                setState(() {
                  _selectedType = value;
                  _applyFilters();
                });
              },
            ),
          const SizedBox(width: 8),
          if (_categories.isNotEmpty)
            _buildFilterChip(
              label: 'Category',
              options: _categories,
              selectedValue: _selectedCategory,
              onSelected: (value) {
                setState(() {
                  _selectedCategory = value;
                  _applyFilters();
                });
              },
            ),
          const SizedBox(width: 8),
          if (_natureOfBusiness.isNotEmpty)
            _buildFilterChip(
              label: 'Nature',
              options: _natureOfBusiness,
              selectedValue: _selectedNatureOfBusiness,
              onSelected: (value) {
                setState(() {
                  _selectedNatureOfBusiness = value;
                  _applyFilters();
                });
              },
            ),
          if (_selectedType != null ||
              _selectedCategory != null ||
              _selectedNatureOfBusiness != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ActionChip(
                label: const Text('Clear All'),
                onPressed: _clearFilters,
                backgroundColor: Colors.red.shade100,
                labelStyle: TextStyle(color: Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onSelected,
  }) {
    return FilterChip(
      label: Text(
        selectedValue ?? label,
        style: TextStyle(
          fontWeight:
              selectedValue != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selectedValue != null,
      onSelected: (selected) {
        if (selected) {
          _showFilterOptionsDialog(label, options, selectedValue, onSelected);
        } else {
          onSelected(null);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _showFilterOptionsDialog(
    String label,
    List<String> options,
    String? currentValue,
    Function(String?) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select $label',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ...options.map(
              (option) => ListTile(
                title: Text(option),
                trailing: currentValue == option
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelected(option);
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Clear Filter'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                onSelected(null);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCount({required bool isApprovedTab}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${_visibleCompanies.length} '
                '${isApprovedTab ? 'approved' : 'pending'} '
                'compan${_visibleCompanies.length != 1 ? 'ies' : 'y'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isApprovedTab
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isApprovedTab
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApprovedTab
                          ? Icons.verified
                          : Icons.hourglass_top,
                      size: 14,
                      color: isApprovedTab
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isApprovedTab ? 'Approved' : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        color: isApprovedTab
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_visibleCompanies.length != _activeBaseList().length)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Show All'),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Company Card — green/verified for approved, orange/pending for pending
  // ============================================================
  Widget _buildCompanyCard(CompanyResponse company,
      {required bool isApproved}) {
    final accentColor = isApproved ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () => _navigateToCompanyDetail(company.id!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                    isApproved
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.business,
                        color: isApproved
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        size: 30,
                      ),
                    ),
                  ),

                  // Status badge (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isApproved
                                ? Icons.verified
                                : Icons.hourglass_top,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            isApproved ? 'APPROVED' : 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Registry ID (only for approved)
                  if (isApproved &&
                      company.officeRegistryId != null &&
                      company.officeRegistryId!.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${company.officeRegistryId}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.companyName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company.type ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              isApproved
                                  ? Icons.check_circle
                                  : Icons.hourglass_top,
                              size: 12,
                              color: isApproved
                                  ? Colors.green.shade600
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isApproved ? 'Approved' : 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                color: isApproved
                                    ? Colors.green.shade600
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (company.category != null &&
                            company.category!.isNotEmpty)
                          _buildSmallTag(company.category!, Colors.blue),
                        if (company.directorsName != null &&
                            company.directorsName!.isNotEmpty)
                          _buildSmallTag(
                            '${company.directorsName!.length} Directors',
                            Colors.orange,
                          ),
                        if (company.shareHoldersName != null &&
                            company.shareHoldersName!.isNotEmpty)
                          _buildSmallTag(
                            '${company.shareHoldersName!.length} Shareholders',
                            Colors.purple,
                          ),
                        if (isApproved &&
                            company.officeRegistryId != null &&
                            company.officeRegistryId!.isNotEmpty)
                          _buildSmallTag('Registry ID', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}