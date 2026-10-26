// lib/CaseRelatedPages/hearing_calendar_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'case_tracking_model.dart';
import 'case_model.dart';
import 'HearingModel.dart';
import 'hearing_service.dart';
import 'hearing_details_page.dart';
import 'document_draft.dart';
import 'document_draft_service.dart';
import 'document_draft_details_page.dart';
import 'CaseJudgmentModel.dart';
import 'case_judgment_service.dart';
import 'case_judgment_details_page.dart';

// ============================================================
// Unified event wrapper (so the calendar can hold all types)
// ============================================================
enum CalendarEventType { hearing, draft, judgment, otherStage }

class CalendarEvent {
  final CalendarEventType type;
  final DateTime date;
  final String title;      // for the row
  final String subtitle;   // for the row
  final String? caseId;
  final String? caseName;
  final String? advocateId;
  final String? advocateUserId; // for the specific record’s advocate
  final CaseTrackingStage? stage;
  final HearingResponse? hearing;
  final DocumentDraftResponse? draft;
  final CaseJudgmentResponse? judgment;

  CalendarEvent({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    this.caseId,
    this.caseName,
    this.advocateId,
    this.advocateUserId,
    this.stage,
    this.hearing,
    this.draft,
    this.judgment,
  });
}

class HearingCalendarPage extends StatefulWidget {
  final List<CaseTrackingStage> trackings;
  final String token;

  /// If true → show only events for `SharedPreferences.advocateId` cases.
  /// If false → show all.
  final bool myCasesOnly;

  const HearingCalendarPage({
    super.key,
    required this.trackings,
    required this.token,
    this.myCasesOnly = true,
  });

  @override
  State<HearingCalendarPage> createState() => _HearingCalendarPageState();
}

class _HearingCalendarPageState extends State<HearingCalendarPage> {
  // ---------- Dark theme colors ----------
  final Color _bgColor = const Color(0xFF121413);
  final Color _cardColor = const Color(0xFF1E201F);
  final Color _highlightColor = const Color(0xFF1C3326);
  final Color _borderColor = const Color(0xFFE2B754);
  final Color _textColor = const Color(0xFFE0E0E0);
  final Color _textMuted = const Color(0xFF888888);
  final Color _greenAccent = const Color(0xFF4CAF50);

  // ---------- State ----------
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  bool _loading = true;
  String? _loadError;

  List<CalendarEvent> _events = [];

  // Caches for the loaded full records
  final Map<String, HearingResponse> _hearingsByCaseId = {};
  final Map<String, DocumentDraftResponse> _draftsByCaseId = {};
  final Map<String, CaseJudgmentResponse> _judgmentsByCaseId = {};
  final Map<String, CaseModel> _casesById = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _loadAllData();
  }

  // ============================================================
  // LOAD ALL EVENTS
  // ============================================================
  Future<void> _loadAllData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final myAdvocateId = prefs.getString('advocateId');
      final myUserId = prefs.getString('userId');

      // 1. Base list of trackings — filter if needed
      final filteredTrackings = widget.myCasesOnly
          ? widget.trackings.where((t) {
              return t.trackingCase != null &&
                  myAdvocateId != null &&
                  t.trackingCase!.advocateId == myAdvocateId;
            }).toList()
          : widget.trackings;

      // 2. Cache all case models we see
      for (final t in filteredTrackings) {
        if (t.trackingCase != null) {
          _casesById[t.trackingCase!.id] = t.trackingCase!;
        }
      }

      // 3. Collect the unique caseIds to fetch details for
      final caseIds = _casesById.keys.toList();

      // 4. Fetch hearing, draft, judgment per caseId in parallel
      await Future.wait(caseIds.map((caseId) async {
        // hearing
        try {
          final hearings =
              await HearingService.getByCase(widget.token, caseId);
          if (hearings.isNotEmpty) {
            _hearingsByCaseId[caseId] = hearings.last;
          }
        } catch (_) {}

        // draft
        try {
          final service = DocumentDraftService(widget.token);
          final draft = await service.findByCase(caseId);
          if (draft != null) {
            _draftsByCaseId[caseId] = draft;
          }
        } catch (_) {}

        // judgment
        try {
          final judgment =
              await CaseJudgmentService.getByCase(caseId);
          if (judgment != null) {
            _judgmentsByCaseId[caseId] = judgment;
          }
        } catch (_) {}
      }));

      // 5. Build the CalendarEvent list
      final events = <CalendarEvent>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final stage in filteredTrackings) {
        final parsedTime = DateTime.tryParse(stage.trackingTime ?? '');
        final issuedDateTime = stage.trackingCase?.issuedTime != null
    ? DateTime.tryParse(stage.trackingCase!.issuedTime)
    : null;
final effectiveDate = parsedTime ?? issuedDateTime ?? today;

        final caseId = stage.caseId;
        final c = stage.trackingCase;

        final advocateUserIdForCase = c?.userId; // client user id — not used for ownership
        final advocateIdForCase = c?.advocateId;

        // ----- HEARING -----
        if (stage.caseStage == 'CASE_HEARING_PAYMENT') {
          final h = _hearingsByCaseId[caseId];
          if (h != null) {
            events.add(CalendarEvent(
              type: CalendarEventType.hearing,
              date: h.issuedDate,
              title: c?.caseName ?? "Hearing #${h.hearingNumber}",
              subtitle: "Hearing #${h.hearingNumber}",
              caseId: caseId,
              caseName: c?.caseName,
              advocateId: advocateIdForCase,
              advocateUserId: myUserId,
              stage: stage,
              hearing: h,
            ));
          } else if (parsedTime != null) {
            events.add(CalendarEvent(
              type: CalendarEventType.hearing,
              date: parsedTime,
              title: c?.caseName ?? "Hearing",
              subtitle: "Hearing stage (no hearing record yet)",
              caseId: caseId,
              caseName: c?.caseName,
              advocateId: advocateIdForCase,
              advocateUserId: myUserId,
              stage: stage,
            ));
          }
          continue;
        }

        // ----- DOCUMENT DRAFT -----
        if (stage.caseStage == 'CASE_DOCUMENT_DRAFT_PAYMENT') {
          final d = _draftsByCaseId[caseId];
          if (d != null) {
            events.add(CalendarEvent(
              type: CalendarEventType.draft,
              date: d.issuedDate,
              title: c?.caseName ?? "Document Draft",
              subtitle: "Document Draft",
              caseId: caseId,
              caseName: c?.caseName,
              advocateId: advocateIdForCase,
              advocateUserId: myUserId,
              stage: stage,
              draft: d,
            ));
          } else if (parsedTime != null) {
            events.add(CalendarEvent(
              type: CalendarEventType.draft,
              date: parsedTime,
              title: c?.caseName ?? "Document Draft",
              subtitle: "Document draft stage",
              caseId: caseId,
              caseName: c?.caseName,
              advocateId: advocateIdForCase,
              advocateUserId: myUserId,
              stage: stage,
            ));
          }
          continue;
        }

        // ----- JUDGMENT -----
        if (stage.caseStage == 'CASE_JUDGMENT_PAYMENT') {
          final j = _judgmentsByCaseId[caseId];
          if (j != null) {
            events.add(CalendarEvent(
              type: CalendarEventType.judgment,
              date: j.date,
              title: c?.caseName ?? "Case Judgment",
              subtitle: "Judgment",
              caseId: caseId,
              caseName: c?.caseName,
              advocateId: advocateIdForCase,
              advocateUserId: myUserId,
              stage: stage,
              judgment: j,
            ));
          } else if (parsedTime != null) {
            events.add(CalendarEvent(
              type: CalendarEventType.judgment,
              date: parsedTime,
              title: c?.caseName ?? "Case Judgment",
              subtitle: "Judgment stage",
              caseId: caseId,
              caseName: c?.caseName,
              advocateId: advocateIdForCase,
              advocateUserId: myUserId,
              stage: stage,
            ));
          }
          continue;
        }

        // ----- OTHER STAGES -----
        if (parsedTime != null) {
          events.add(CalendarEvent(
            type: CalendarEventType.otherStage,
            date: parsedTime,
            title: c?.caseName ?? "Stage",
            subtitle: _prettyStageName(stage.caseStage),
            caseId: caseId,
            caseName: c?.caseName,
            advocateId: advocateIdForCase,
            advocateUserId: myUserId,
            stage: stage,
          ));
        }
      }

      events.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  String _prettyStageName(String stage) {
    final name = stage.replaceAll("CASE_", "").replaceAll("_PAYMENT", "");
    return name
        .split("_")
        .map((w) =>
            w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : "")
        .join(" ");
  }

  // ============================================================
  // FILTERING HELPERS
  // ============================================================
  List<CalendarEvent> _eventsForDate(DateTime date) {
    return _events.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  List<CalendarEvent> _upcomingEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _events.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d.isAfter(today) || d.isAtSameMomentAs(today);
    }).toList();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================
  Future<void> _openEvent(CalendarEvent event) async {
    switch (event.type) {
      case CalendarEventType.hearing:
        if (event.hearing != null) {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => HearingDetailsPage(
                hearing: event.hearing!,
                token: widget.token,
                advocateUserId: event.advocateUserId ?? '',
                advocateId: event.advocateId ?? '',
              ),
            ),
          );
          if (changed == true) _loadAllData();
        } else {
          _showStageInfoDialog(event);
        }
        break;

      case CalendarEventType.draft:
        if (event.draft != null) {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentDraftDetailsPage(
                draft: event.draft!,
                token: widget.token,
                advocateUserId: event.advocateUserId,
                advocateId: event.advocateId,
              ),
            ),
          );
          if (changed == true) _loadAllData();
        } else {
          _showStageInfoDialog(event);
        }
        break;

      case CalendarEventType.judgment:
        if (event.judgment != null) {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CaseJudgmentDetailsPage(
                judgment: event.judgment!,
                token: widget.token,
                advocateUserId: event.advocateUserId,
                advocateId: event.advocateId,
              ),
            ),
          );
          if (changed == true) _loadAllData();
        } else {
          _showStageInfoDialog(event);
        }
        break;

      case CalendarEventType.otherStage:
        _showStageInfoDialog(event);
        break;
    }
  }

  void _showStageInfoDialog(CalendarEvent event) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(event.caseName ?? "Stage"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Stage: ${event.subtitle}"),
            const SizedBox(height: 6),
            Text(
              "Date: ${DateFormat('dd MMM yyyy • hh:mm a').format(event.date)}",
            ),
            if (event.stage?.visibility == false) ...[
              const SizedBox(height: 8),
              const Text(
                "Hidden from client",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTH NAVIGATION
  // ============================================================
  void _onPrevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _onNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          "Hearing Calendar",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _cardColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAllData,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCalendarCard(),
                        const SizedBox(height: 16),
                        _buildSelectedDayEvents(),
                        const SizedBox(height: 16),
                        _buildUpcomingEventsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ---------- Calendar card ----------
  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: _onPrevMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: _onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি']
                .map(
                  (day) => Text(
                    day,
                    style: GoogleFonts.notoSansBengali(
                      color: _textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _buildDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildDaysGrid() {
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final prevMonthDays = DateUtils.getDaysInMonth(
        _currentMonth.year, _currentMonth.month - 1);

    final List<Widget> dayWidgets = [];

    for (int i = 0; i < firstWeekday; i++) {
      final day = prevMonthDays - firstWeekday + i + 1;
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: false));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final isSelected = DateUtils.isSameDay(date, _selectedDate);
      final hasEvents = _eventsForDate(date).isNotEmpty;
      dayWidgets.add(
        _buildDayCell(
          i,
          isCurrentMonth: true,
          isSelected: isSelected,
          hasEvent: hasEvents,
          date: date,
        ),
      );
    }

    final remaining = 7 - (dayWidgets.length % 7);
    if (remaining < 7) {
      for (int i = 1; i <= remaining; i++) {
        dayWidgets.add(_buildDayCell(i, isCurrentMonth: false));
      }
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(
    int day, {
    required bool isCurrentMonth,
    bool isSelected = false,
    bool hasEvent = false,
    DateTime? date,
  }) {
    return GestureDetector(
      onTap: () {
        if (isCurrentMonth && date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? _highlightColor
              : (hasEvent && isCurrentMonth
                  ? const Color(0xFF1A251D)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: _borderColor, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          day.toString(),
          style: GoogleFonts.poppins(
            color: isCurrentMonth
                ? (isSelected
                    ? _borderColor
                    : (hasEvent ? _greenAccent : Colors.white))
                : const Color(0xFF444444),
            fontWeight: (isSelected || hasEvent)
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ---------- Selected day ----------
  Widget _buildSelectedDayEvents() {
    final events = _eventsForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Events on ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "No events scheduled on this day.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _textMuted),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildEventRow(events[i]),
          ),
      ],
    );
  }

  // ---------- Upcoming list ----------
  Widget _buildUpcomingEventsList() {
    final upcoming = _upcomingEvents();

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "All upcoming events",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(color: Color(0xFF333333), height: 1),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "No upcoming events.",
                  style: GoogleFonts.inter(color: _textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcoming.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Color(0xFF333333), height: 1),
              itemBuilder: (_, i) => _buildEventRow(upcoming[i]),
            ),
        ],
      ),
    );
  }

  // ---------- Event row (shared) ----------
  Widget _buildEventRow(CalendarEvent event) {
    final date = event.date;

    // Relative date
    String relativeDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) {
      relativeDate = "Today";
    } else if (diff == 1) {
      relativeDate = "Tomorrow";
    } else if (diff > 1) {
      relativeDate = "in ${diff}d";
    } else {
      relativeDate = "${diff.abs()}d ago";
    }

    // Icon + accent by type
    IconData icon;
    Color accent;
    switch (event.type) {
      case CalendarEventType.hearing:
        icon = Icons.gavel;
        accent = _greenAccent;
        break;
      case CalendarEventType.draft:
        icon = Icons.description;
        accent = const Color(0xFF64B5F6);
        break;
      case CalendarEventType.judgment:
        icon = Icons.balance;
        accent = _borderColor;
        break;
      default:
        icon = Icons.timeline;
        accent = _textMuted;
    }

    return InkWell(
      onTap: () => _openEvent(event),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date box
            Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2F2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString().padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: GoogleFonts.inter(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: accent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle,
                    style: GoogleFonts.inter(
                      color: _textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Relative pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2F2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                relativeDate,
                style: GoogleFonts.inter(
                  color: _borderColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}