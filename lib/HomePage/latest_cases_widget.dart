// lib/HomePage/latest_cases_widget.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:advocatechaiadvocate/CaseRelatedPages/case_model.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/case_service.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/advocate_cases_paged_page.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/CaseDetailsPage.dart'; // Import CaseDetailsPage

class LatestCasesWidget extends StatefulWidget {
  final int count;
  final String? advocateId;
  final void Function(CaseModel)? onCaseTap;
  final Key? refreshKey;

  const LatestCasesWidget({
    super.key,
    this.count = 4,
    this.advocateId,
    this.onCaseTap,
    this.refreshKey,
  });

  @override
  State<LatestCasesWidget> createState() => _LatestCasesWidgetState();
}

class _LatestCasesWidgetState extends State<LatestCasesWidget> {
  final CaseService _service = CaseService();

  bool _loading = true;
  String? _error;
  List<CaseModel> _cases = const [];
  String? _resolvedAdvocateId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LatestCasesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.advocateId != widget.advocateId) {
      _load();
    }
  }

  Future<String?> _resolveAdvocateId() async {
    if (widget.advocateId != null && widget.advocateId!.trim().isNotEmpty) {
      return widget.advocateId!.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final fromAdvocate = (prefs.getString('advocateId') ?? '').trim();
    if (fromAdvocate.isNotEmpty) return fromAdvocate;
    final fromUser = (prefs.getString('user_id') ?? '').trim();
    if (fromUser.isNotEmpty) return fromUser;
    return null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final advocateId = await _resolveAdvocateId();
      _resolvedAdvocateId = advocateId;

      if (advocateId == null || advocateId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cases = const [];
          _loading = false;
          _error = 'No advocate id found. Please sign in again.';
        });
        return;
      }

      final page = await _service.byAdvocatePaginated(
        advocateId,
        page: 0,
        size: widget.count,
      );

      final sorted = [...page.responses]..sort(_byNewestFirst);

      if (!mounted) return;
      setState(() {
        _cases = sorted.take(widget.count).toList(growable: false);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _byNewestFirst(CaseModel a, CaseModel b) {
    final da = DateTime.tryParse(a.issuedTime) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final db = DateTime.tryParse(b.issuedTime) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return db.compareTo(da);
  }

  void _openCase(CaseModel c) {
    if (widget.onCaseTap != null) {
      widget.onCaseTap!(c);
      return;
    }
    
    // 👇 Navigate directly to CaseDetailsPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseDetailsPage(caseModel: c),
      ),
    );
  }

  void _openSeeAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdvocateCasesPagedPage(
          advocateId: _resolvedAdvocateId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // 👈 Changed to white
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: 'Latest Cases',
            count: _cases.length,
            onRefresh: _loading ? null : _load,
          ),
          const SizedBox(height: 12),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue),
          ),
        ),
      );
    }

    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _load);
    }

    if (_cases.isEmpty) {
      return _EmptyState(
        advocateId: _resolvedAdvocateId,
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: Colors.blue,
      child: Column(
        children: [
          for (var i = 0; i < _cases.length; i++) ...[
            _CaseTile(
              caseModel: _cases[i],
              onTap: () => _openCase(_cases[i]),
            ),
            if (i != _cases.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          _SeeAllButton(onPressed: _openSeeAll),
        ],
      ),
    );
  }
}

// =============================================================================
// ============================== SEE ALL BUTTON ===============================
// =============================================================================
class _SeeAllButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SeeAllButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              color: Colors.blue.withOpacity(0.05),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.blue,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ============================== HEADER =======================================
// =============================================================================
class _Header extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onRefresh;

  const _Header({
    required this.title,
    required this.count,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: Icon(Icons.refresh_rounded, color: Colors.grey[600]),
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

// =============================================================================
// ============================== CASE TILE ====================================
// =============================================================================
class _CaseTile extends StatelessWidget {
  final CaseModel caseModel;
  final VoidCallback onTap;

  const _CaseTile({required this.caseModel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(caseModel.caseType);
    final issued = _formatDate(caseModel.issuedTime);
    final attachmentCount = caseModel.attachmentsId.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caseModel.caseName.isEmpty
                          ? 'Untitled case'
                          : caseModel.caseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.grey[850],
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: caseModel.caseType.isEmpty
                        ? 'CASE'
                        : caseModel.caseType,
                    color: typeColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      caseModel.displayUserName.isEmpty
                          ? '—'
                          : caseModel.displayUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.gavel_rounded,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      caseModel.displayAdvocateName.isEmpty
                          ? '—'
                          : caseModel.displayAdvocateName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    issued,
                    style: GoogleFonts.inter(
                      color: Colors.grey[500], 
                      fontSize: 11
                    ),
                  ),
                  const Spacer(),
                  if (attachmentCount > 0) ...[
                    const Icon(Icons.attach_file,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(
                      '$attachmentCount',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500], 
                        fontSize: 11
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _typeColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('CRIMINAL')) return const Color(0xFFEF4444);
    if (t.contains('CIVIL')) return const Color(0xFF3B82F6);
    if (t.contains('DIVORCE') || t.contains('FAMILY')) {
      return const Color(0xFFA855F7);
    }
    if (t.contains('PROPERTY')) return const Color(0xFFF59E0B);
    if (t.contains('CORPORATE') || t.contains('COMPANY')) {
      return const Color(0xFF10B981);
    }
    if (t.contains('LABOR') || t.contains('LABOUR')) {
      return const Color(0xFF0EA5E9);
    }
    return const Color(0xFF14B8A6);
  }

  static String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

// =============================================================================
// ============================== CHIP =========================================
// =============================================================================
class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// =============================================================================
// ============================== STATE VIEWS ==================================
// =============================================================================
class _EmptyState extends StatelessWidget {
  final String? advocateId;
  final VoidCallback onRetry;

  const _EmptyState({required this.advocateId, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded,
              color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          Text(
            'No cases assigned to you yet',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
          ),
          if (advocateId != null && advocateId!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Advocate: $advocateId',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.blue),
            label: Text('Retry', style: GoogleFonts.inter(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 40),
          const SizedBox(height: 8),
          Text(
            'Failed to load cases',
            style: GoogleFonts.inter(color: Colors.grey[800], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              error,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.blue),
            label: Text('Retry', style: GoogleFonts.inter(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}