// lib/CaseRelatedPages/advocate_cases_paged_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CaseRelatedPages/case_model.dart';
import '../CaseRelatedPages/case_service.dart';
import '../CaseRelatedPages/CaseDetailsPage.dart';
import '../CaseRelatedPages/AttachmentViewer.dart';
import '../PageTransition.dart';

class AdvocateCasesPagedPage extends StatefulWidget {
  /// If null, resolves via SharedPreferences (`advocate_id` → `user_id`).
  final String? advocateId;

  /// Optional readable name for the header. Purely cosmetic.
  final String? advocateName;

  const AdvocateCasesPagedPage({
    super.key,
    this.advocateId,
    this.advocateName,
  });

  @override
  State<AdvocateCasesPagedPage> createState() => _AdvocateCasesPagedPageState();
}

class _AdvocateCasesPagedPageState extends State<AdvocateCasesPagedPage>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 4;

  final CaseService _service = CaseService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<PageTransitionType> _transitionTypes =
      AnimatedRoute.getCompanySafeAnimations();

  String? _advocateId;

  // Data state
  bool _loading = true;
  String? _error;
  CasePageModel? _page;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _bootstrap();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ---------- helpers ----------

  PageTransitionType _getRandomTransition() {
    final random =
        DateTime.now().millisecondsSinceEpoch % _transitionTypes.length;
    return _transitionTypes[random];
  }

  void _navigateWithRandomTransition(BuildContext context, Widget page) {
    NavigationHelper.push(
      context,
      page,
      transitionType: _getRandomTransition(),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<String?> _resolveAdvocateId() async {
    if (widget.advocateId != null && widget.advocateId!.trim().isNotEmpty) {
      return widget.advocateId!.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final a = (prefs.getString('advocate_id') ?? '').trim();
    if (a.isNotEmpty) return a;
    final u = (prefs.getString('user_id') ?? '').trim();
    if (u.isNotEmpty) return u;
    return null;
  }

  Future<void> _bootstrap() async {
    final id = await _resolveAdvocateId();
    _advocateId = id;
    if (id == null) {
      setState(() {
        _loading = false;
        _error =
            'No advocate id found. Please sign in again.\nTried SharedPreferences keys: "advocate_id", "user_id".';
      });
      return;
    }
    await _loadPage(0);
  }

  Future<void> _loadPage(int pageIndex) async {
    final id = _advocateId;
    if (id == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await _service.byAdvocatePaginated(
        id,
        page: pageIndex,
        size: _pageSize,
      );

      if (!mounted) return;

      // If the backend returned an empty page but there are total cases,
      // we probably stepped past the end → back off one page.
      if (page.responses.isEmpty && pageIndex > 0) {
        // Fetch the previous page (which should have data).
        final prev = await _service.byAdvocatePaginated(
          id,
          page: pageIndex - 1,
          size: _pageSize,
        );
        if (!mounted) return;
        setState(() {
          _page = prev;
          _currentPage = pageIndex - 1;
          _loading = false;
        });
        return;
      }

      setState(() {
        _page = page;
        _currentPage = pageIndex;
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

  void _nextPage() {
    final p = _page;
    if (p == null) return;
    final totalPages =
        (p.totalElement / _pageSize).ceil().clamp(0, 1 << 30);
    if (_currentPage + 1 >= totalPages) return;
    _loadPage(_currentPage + 1);
  }

  void _prevPage() {
    if (_currentPage <= 0) return;
    _loadPage(_currentPage - 1);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final totalPages = (_page?.totalElement ?? 0) == 0
        ? 1
        : ((_page!.totalElement / _pageSize).ceil());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Advocate Cases",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loading ? null : () => _loadPage(_currentPage),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E),
                Color(0xFF283593),
                Color(0xFF3949AB),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildTopBar(totalPages),
            Expanded(child: _buildBody()),
            _buildPager(totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int totalPages) {
    final id = _advocateId;
    final total = _page?.totalElement ?? 0;
    final shownFrom =
        total == 0 ? 0 : _currentPage * _pageSize + 1;
    final shownTo =
        total == 0 ? 0 : (shownFrom + (_page?.responses.length ?? 0) - 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.advocateName?.isNotEmpty == true
                      ? widget.advocateName!
                      : 'Advocate',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A237E),
                  ),
                ),
                if (id != null)
                  Text(
                    id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: Colors.deepPurple.shade100),
            ),
            child: Text(
              total == 0
                  ? 'No cases'
                  : 'Showing $shownFrom–$shownTo of $total  •  Page ${_currentPage + 1}/$totalPages',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading advocate cases..."),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed:
                    _advocateId == null ? _bootstrap : () => _loadPage(_currentPage),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final cases = _page?.responses ?? const <CaseModel>[];

    if (cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No cases assigned to this advocate",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "New cases will appear here",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.deepPurple,
      onRefresh: () => _loadPage(_currentPage),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cases.length,
        itemBuilder: (context, index) {
          final c = cases[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _buildCaseCard(c),
          );
        },
      ),
    );
  }

  Widget _buildPager(int totalPages) {
    final canPrev = _currentPage > 0 && !_loading;
    final canNext = _currentPage + 1 < totalPages && !_loading;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canPrev ? _prevPage : null,
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E),
                side: BorderSide(
                  color: canPrev
                      ? const Color(0xFF1A237E)
                      : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canNext ? _nextPage : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- card (same visual as MyCasesPage) ----------

  Widget _buildCaseCard(CaseModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(c),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.deepPurple.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.caseName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.deepPurple.shade200),
                        ),
                        child: Text(
                          "ACTIVE",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _row(Icons.category, "Case Type: ${c.caseType}"),
                  const SizedBox(height: 8),
                  _row(Icons.person,
                      'Advocate: ${c.displayAdvocateName.isEmpty ? "Not Assigned" : c.displayAdvocateName}'),
                  const SizedBox(height: 8),
                  _row(Icons.person_outline,
                      'Client: ${c.displayUserName.isEmpty ? "—" : c.displayUserName}'),
                  const SizedBox(height: 8),
                  _row(Icons.calendar_today, 'Issued: ${c.issuedTime}',
                      small: true),

                  // Attachments
                  if (c.attachmentsId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attachment,
                            size: 16,
                            color: Colors.deepPurple.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Attachments (${c.attachmentsId.length})",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: c.attachmentsId.map((id) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.visibility,
                                  size: 18,
                                  color: Colors.deepPurple.shade600,
                                ),
                                onPressed: () =>
                                    _openAttachment(id, view: true),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.download,
                                  size: 18,
                                  color: Colors.deepPurple.shade600,
                                ),
                                onPressed: () =>
                                    _openAttachment(id, view: false),
                              ),
                              Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  id.length > 20
                                      ? '${id.substring(0, 17)}...'
                                      : id,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),
                  _viewDetailsButton(c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, {bool small = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: small ? 14 : 16,
            color: Colors.deepPurple.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: small ? 12 : 13,
              color: small ? Colors.grey.shade600 : Colors.grey.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _viewDetailsButton(CaseModel c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () => _openDetails(c),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "View Details",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _openDetails(CaseModel c) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ??
        prefs.getString('user_id') ??
        '';
    if (!mounted) return;
    _navigateWithRandomTransition(
      context,
      CaseDetailsPage(
        caseModel: c,
        userId: userId,
        onDeleted: () {
          if (mounted) _loadPage(_currentPage);
        },
      ),
    );
  }

  void _openAttachment(String attachmentId, {required bool view}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (!mounted) return;
    _navigateWithRandomTransition(
      context,
      CaseAttachmentView(
        attachmentId: attachmentId,
        jwtToken: token,
      ),
    );
  }
}