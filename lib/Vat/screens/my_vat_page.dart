// lib/vat/screens/my_vat_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/vat_response_model.dart';
import '../service/vat_service.dart';
import 'vat_details_page.dart';

class MyVatPage extends StatefulWidget {
  const MyVatPage({super.key});

  @override
  State<MyVatPage> createState() => _MyVatPageState();
}

class _MyVatPageState extends State<MyVatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  String? _error;
  List<VatResponseModel> _allVats = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ??
          prefs.getString('userId') ??
          prefs.getString('_id');

      if (_userId == null || _userId!.isEmpty) {
        throw Exception('User not logged in');
      }

      // ✅ Fetch ALL VATs belonging to this user (do NOT filter here —
      //    the tab division happens via getters below).
      final list = await VatService.findByUserId(_userId!);

      if (!mounted) return;
      setState(() {
        _allVats = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // Backend throws "No such vat find at here..." when user has none —
      // treat that as empty rather than an error.
      if (msg.contains('No such vat') ||
          msg.contains('NoSuchElementException')) {
        setState(() {
          _allVats = [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = msg.replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // ✅ Approved = process != null && process.status == true
  // ============================================================
  List<VatResponseModel> get _approvedVats => _allVats.where((v) {
        final process = v.vatRegistrationProcessResponseDTO;
        return process != null && process.status == true;
      }).toList();

  // ============================================================
  // ✅ Pending = everything else
  //    (process == null OR process.status == false)
  // ============================================================
  List<VatResponseModel> get _pendingVats => _allVats.where((v) {
        final process = v.vatRegistrationProcessResponseDTO;
        return process == null || process.status != true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My VAT',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tab,
              indicatorColor: const Color(0xFF1565C0),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF1565C0),
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Approved VAT (${_approvedVats.length})'),
                Tab(text: 'Pending VAT (${_pendingVats.length})'),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  )
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tab,
                        children: [
                          _buildList(_approvedVats, 'No approved VAT yet'),
                          _buildList(_pendingVats, 'No pending VAT yet'),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<VatResponseModel> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => VatCard(
          vat: list[i],
          currentUserId: _userId,
          onChanged: _load,
        ),
      ),
    );
  }
}

// ============================================================
// Shared VAT card widget — used by MyVatPage and AllVatPage
// ============================================================
class VatCard extends StatelessWidget {
  final VatResponseModel vat;
  final String? currentUserId;
  final VoidCallback? onChanged;

  const VatCard({
    super.key,
    required this.vat,
    required this.currentUserId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final process = vat.vatRegistrationProcessResponseDTO;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => VatDetailsPage(
                vat: vat,
                currentUserId: currentUserId,
              ),
            ),
          );
          if (changed == true) onChanged?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Color(0xFF1565C0),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vat.buisnessName.isEmpty
                              ? 'Unnamed Business'
                              : vat.buisnessName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TIN: ${vat.tinNo}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(process),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      'Trade License',
                      vat.tradeLicenseNo.isEmpty ? '-' : vat.tradeLicenseNo,
                    ),
                  ),
                  Expanded(
                    child: _miniStat(
                      'Employees',
                      vat.numberOfEmployee > 0 ? '${vat.numberOfEmployee}' : '-',
                    ),
                  ),
                  Expanded(
                    child: _miniStat('Documents', '${vat.documents.length}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_forward,
                      size: 14, color: Color(0xFF1565C0)),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view details',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Updated status logic — mirrors the tab filter
  // Approved = process != null && process.status == true
  // Pending  = everything else
  Widget _statusChip(VatRegistrationProcessResponseModel? process) {
    final isApproved = process != null && process.status == true;

    final color = isApproved ? Colors.green : Colors.orange;
    final label = isApproved ? 'Approved' : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.hourglass_top,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}