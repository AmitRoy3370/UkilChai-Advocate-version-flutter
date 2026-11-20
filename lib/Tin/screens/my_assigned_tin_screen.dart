// lib/Tin/screens/my_assigned_tin_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tin_response_dto.dart';
import '../services/tin_service.dart';
import 'tin_details_screen.dart';

class MyAssignedTinScreen extends StatefulWidget {
  const MyAssignedTinScreen({super.key});

  @override
  State<MyAssignedTinScreen> createState() => _MyAssignedTinScreenState();
}

class _MyAssignedTinScreenState extends State<MyAssignedTinScreen> {
  static const Color _primaryGreen = Color(0xFF1E7A3A);

  List<TinResponseDTO> _assignedTins = [];
  bool _isLoading = true;
  String? _error;
  String? _myAdvocateId;

  @override
  void initState() {
    super.initState();
    _loadAssignedTins();
  }

  Future<void> _loadAssignedTins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final advocateId = (prefs.getString('advocateId') ?? '').trim();

      if (!mounted) return;
      _myAdvocateId = advocateId;

      if (advocateId.isEmpty) {
        setState(() {
          _assignedTins = [];
          _isLoading = false;
          _error = 'No advocate ID found in SharedPreferences.';
        });
        return;
      }

      final res = await TinService.findAll();
      if (!mounted) return;

      if (res['status'] == 'success') {
        final all = TinService.parseList(res);
        final mine = all
            .where((t) =>
                t.registrationProcess != null &&
                t.registrationProcess!.advocateId.trim() == advocateId)
            .toList();

        setState(() {
          _assignedTins = mine;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = res['message']?.toString() ?? 'Failed to load TINs';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  Future<void> _openTinDetails(TinResponseDTO tin) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TinDetailsScreen(
          tin: tin,
          isOwner: false,
        ),
      ),
    );

    if (mounted) {
      await _loadAssignedTins();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Assigned TINs',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _loadAssignedTins,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (_myAdvocateId != null && _myAdvocateId!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Advocate ID: $_myAdvocateId',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadAssignedTins,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignedTins.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAssignedTins,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No assigned TINs found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignedTins,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _assignedTins.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final tin = _assignedTins[index];
          final title =
              tin.fullName.trim().isEmpty ? 'Untitled TIN' : tin.fullName.trim();

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _openTinDetails(tin),
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: _primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
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