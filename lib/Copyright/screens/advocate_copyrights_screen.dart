// lib/Copyright/screens/advocate_copyrights_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/copyright_response_dto.dart';
import '../services/copyright_service.dart';
import 'copyright_details_screen.dart';

/// Shows only the copyrights assigned to the current advocate
/// (`copyright.registrationProcess.advocateId == SharedPreferences('advocateId')`).
///
/// Load flow:
///   1. advocateId ← SharedPreferences('advocateId')
///   2. all        ← CopyrightService.findAll()  (list with embedded process)
///   3. filter     ← process != null && process.advocateId == advocateId
///   4. tap        → CopyrightDetailsScreen(copyright, isOwner: false)
class AdvocateCopyrightsScreen extends StatefulWidget {
  const AdvocateCopyrightsScreen({super.key});

  @override
  State<AdvocateCopyrightsScreen> createState() =>
      _AdvocateCopyrightsScreenState();
}

class _AdvocateCopyrightsScreenState
    extends State<AdvocateCopyrightsScreen> {
  static const Color _primary = Color(0xFF1A3FBF);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);

  final TextEditingController _searchController = TextEditingController();

  String? _advocateId;
  bool _isLoading = true;
  String? _error;

  List<CopyrightResponseDTO> _assigned = [];

  List<CopyrightResponseDTO> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _assigned;
    return _assigned
        .where((c) => c.titleOfWork.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD → fetch all → filter by advocateId
  // ============================================================
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _assigned = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final advocateId = prefs.getString('advocateId');

      if (advocateId == null || advocateId.isEmpty) {
        setState(() {
          _advocateId = null;
          _isLoading = false;
          _error =
              'Advocate ID not found. Please log in again as an advocate.';
        });
        return;
      }
      _advocateId = advocateId;

      final res = await CopyrightService.findAll();
      if (res['status'] != 'success') {
        setState(() {
          _isLoading = false;
          _error = res['message']?.toString() ?? 'Failed to load';
        });
        return;
      }

      final all = CopyrightService.parseList(res);
      final assigned = all.where((c) {
        final p = c.registrationProcess;
        return p != null && p.advocateId == advocateId;
      }).toList();

      // Stable sort by work title
      assigned.sort((a, b) => a.titleOfWork
          .toLowerCase()
          .compareTo(b.titleOfWork.toLowerCase()));

      setState(() {
        _assigned = assigned;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // NAVIGATE
  // ============================================================
  Future<void> _open(CopyrightResponseDTO c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CopyrightDetailsScreen(
          copyright: c,
          isOwner: false,
        ),
      ),
    );
    if (mounted) await _load();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'My Assigned Copyrights',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _primary),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }
    if (_error != null) return _buildError();
    if (_assigned.isEmpty) return _buildEmpty();

    return Column(
      children: [
        _searchBar(),
        _summaryBar(),
        Expanded(child: _list()),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by work title…',
          prefixIcon: const Icon(Icons.search, color: _textGrey),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _searchController.clear(),
                ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _summaryBar() {
    final shown = _filtered.length;
    final total = _assigned.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.copyright, size: 16, color: _textGrey),
          const SizedBox(width: 6),
          Text(
            shown == total
                ? '$total ${total == 1 ? "copyright" : "copyrights"}'
                : '$shown of $total',
            style: const TextStyle(
              fontSize: 12,
              color: _textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_advocateId != null)
            Flexible(
              child: Text(
                'Advocate ID: ${_shortId(_advocateId!)}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _textGrey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _list() {
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No copyrights match your search',
          style: TextStyle(fontSize: 13, color: _textGrey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = items[i];
          return _CopyrightTile(copyright: c, onTap: () => _open(c));
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.copyright,
                  size: 48, color: _primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No copyrights assigned yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Copyrights that you accept as a center admin will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _textGrey),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primary),
                foregroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
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
            const Icon(Icons.error_outline,
                size: 60, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
  }
}

// ============================================================
// Minimal tile — title only + status chip
// ============================================================
class _CopyrightTile extends StatelessWidget {
  final CopyrightResponseDTO copyright;
  final VoidCallback onTap;

  const _CopyrightTile({required this.copyright, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = copyright.registrationProcess?.status ?? false;
    final title =
        copyright.titleOfWork.isEmpty ? 'Untitled' : copyright.titleOfWork;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3FBF).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.copyright,
                    color: Color(0xFF1A3FBF), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(completed: isCompleted),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool completed;
  const _StatusChip({required this.completed});

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? const Color(0xFF2E7D32)
        : const Color(0xFFB45309);
    final bg = completed
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFFBEB);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.timelapse,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            completed ? 'Done' : 'Active',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}