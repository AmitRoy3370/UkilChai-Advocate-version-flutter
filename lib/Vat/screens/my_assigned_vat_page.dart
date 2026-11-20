// lib/vat/screens/my_assigned_vat_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vat_response_model.dart';
import '../service/vat_service.dart';
import 'vat_details_page.dart';

class MyAssignedVatPage extends StatefulWidget {
  const MyAssignedVatPage({super.key});

  @override
  State<MyAssignedVatPage> createState() => _MyAssignedVatPageState();
}

class _MyAssignedVatPageState extends State<MyAssignedVatPage> {
  static const Color _primaryBlue = Color(0xFF1565C0);

  List<VatResponseModel> _assignedVats = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  String? _myAdvocateId;

  @override
  void initState() {
    super.initState();
    _loadAssignedVats();
  }

  Future<void> _loadAssignedVats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ??
          prefs.getString('userId') ??
          prefs.getString('_id');
      final advocateId = (prefs.getString('advocateId') ?? '').trim();

      if (!mounted) return;
      _currentUserId = userId;
      _myAdvocateId = advocateId;

      if (advocateId.isEmpty) {
        setState(() {
          _assignedVats = [];
          _isLoading = false;
          _error = 'No advocate ID found in SharedPreferences.';
        });
        return;
      }

      final all = await VatService.findAll();
      if (!mounted) return;

      final mine = all.where((v) {
        final rp = v.vatRegistrationProcessResponseDTO;
        return rp != null && rp.advocateId.trim() == advocateId;
      }).toList();

      setState(() {
        _assignedVats = mine;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('No such vat') ||
          msg.contains('NoSuchElementException')) {
        setState(() {
          _assignedVats = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _assignedVats = [];
          _isLoading = false;
          _error = msg.replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _openVatDetails(VatResponseModel vat) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VatDetailsPage(
          vat: vat,
          currentUserId: _currentUserId,
        ),
      ),
    );

    if (mounted) {
      await _loadAssignedVats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Assigned VATs',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAssignedVats,
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey.shade700),
              ),
              if (_myAdvocateId != null && _myAdvocateId!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Advocate ID: $_myAdvocateId',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAssignedVats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignedVats.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAssignedVats,
        color: _primaryBlue,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No assigned VATs found',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignedVats,
      color: _primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _assignedVats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final vat = _assignedVats[index];
          final process = vat.vatRegistrationProcessResponseDTO;
          final isApproved = process != null && process.status == true;
          final title = vat.buisnessName.trim().isEmpty
              ? 'Unnamed Business'
              : vat.buisnessName.trim();
          final subtitleParts = <String>[
            if (vat.tinNo.trim().isNotEmpty) 'TIN: ${vat.tinNo.trim()}',
            if (vat.tradeLicenseNo.trim().isNotEmpty)
              'License: ${vat.tradeLicenseNo.trim()}',
          ];

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _openVatDetails(vat),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: _primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (subtitleParts.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitleParts.join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isApproved ? Colors.green : Colors.orange)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isApproved ? 'Approved' : 'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isApproved
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}