// lib/GroupChat/GroupChatListScreen.dart
//
// Group Chat List Screen
// ─ Lists every group the current user belongs to
// ─ Shows unread badges
// ─ Tap a row → opens GroupChatScreen
// ─ Auto-reloads when the screen becomes visible again
// ─ Pull-to-refresh, error/empty states

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/AuthService.dart';
import 'GroupChatModels.dart';
import 'GroupChatServices.dart';
import 'GroupChatScreen.dart';

class GroupChatListScreen extends StatefulWidget {
  const GroupChatListScreen({super.key});

  @override
  State<GroupChatListScreen> createState() => _GroupChatListScreenState();
}

class _GroupChatListScreenState extends State<GroupChatListScreen>
    with RouteAware {
  final GroupChatServices _services = GroupChatServices();

  bool _isLoading = true;
  String? _errorMessage;

  String? _userId;
  String? _userName;

  List<GroupModel> _groups = [];
  Map<String, int> _unreadCounts = {};

  // ── RouteObserver hook (for auto-reload on re-entry) ────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // Subscribe to route changes via the app-wide observer.
      // See note below if `routeObserver` isn't yet set up.
      groupChatRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    groupChatRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when the user navigates BACK to this page from a pushed route.
  @override
  void didPopNext() {
    // Refresh whenever we return from a child screen (e.g. GroupChatScreen).
    _loadGroups();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // ── Bootstrap: resolve the current user, then load groups ────────────────
  Future<void> _bootstrap() async {
    try {
      String? id = await AuthService.getUserId();
      if (id == null || id.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        id = prefs.getString('userId');
      }

      final prefs = await SharedPreferences.getInstance();
      final String? name =
          prefs.getString('userName') ?? prefs.getString('fullName');

      if (!mounted) return;

      if (id == null || id.isEmpty) {
        setState(() {
          _userId = null;
          _userName = name;
          _isLoading = false;
          _errorMessage = 'Please log in to view your groups';
        });
        return;
      }

      setState(() {
        _userId = id;
        _userName = (name != null && name.trim().isNotEmpty) ? name : 'Admin';
      });

      await _loadGroups();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ── Load groups + unread counts ──────────────────────────────────────────
  Future<void> _loadGroups() async {
    if (_userId == null || _userId!.isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<GroupModel> groups =
          await _services.getUserGroups(_userId!);

      groups.sort((a, b) {
        final aTime = _safeLastMessageTime(a);
        final bTime = _safeLastMessageTime(b);
        return bTime.compareTo(aTime);
      });

      Map<String, int> counts = {};
      if (groups.isNotEmpty) {
        try {
          counts = await _services.getMultipleUnreadCounts(
            userId: _userId!,
            groupIds: groups.map((g) => g.id).toList(),
          );
        } catch (_) {
          counts = {};
        }
      }

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _unreadCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  DateTime _safeLastMessageTime(GroupModel g) {
    try {
      // ignore: avoid_dynamic_calls
      final dynamic t = (g as dynamic).lastMessageTime;
      if (t is DateTime) return t;
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ── Navigation ───────────────────────────────────────────────────────────
  Future<void> _openGroup(GroupModel group) async {
    if (_userId == null || _userId!.isEmpty) {
      _showSnack('Please log in first');
      return;
    }

    final groupId = group.id.toString().trim();
    if (groupId.isEmpty) {
      _showSnack('Invalid group (missing id)');
      return;
    }

    final userName =
        (_userName != null && _userName!.trim().isNotEmpty)
            ? _userName!
            : 'Admin';
    final groupName =
        group.groupName.trim().isEmpty ? 'Group' : group.groupName;

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupChatScreen(
            groupId: groupId,
            groupName: groupName,
            currentUserId: _userId!,
            currentUserName: userName,
            isAdmin: false,
          ),
        ),
      );
      // Note: didPopNext() will auto-refresh when we return,
      // so no manual _loadGroups() call is needed here.
    } catch (e, st) {
      // ignore: avoid_print
      print('❌ Error opening group: $e\n$st');
      _showSnack('Could not open group: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Group Chats',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadGroups,
          ),
        ],
      ),
      body: _buildBody(),
      // ✅ FAB removed — no "New Group" button on this screen
    );
  }

  Widget _buildBody() {
    if (_isLoading && _groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Loading your groups...'),
          ],
        ),
      );
    }

    if (_userId == null || _userId!.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lock_outline,
        title: 'Please log in',
        subtitle: 'You need to be logged in to view your group chats.',
      );
    }

    if (_errorMessage != null && _groups.isEmpty) {
      return _buildErrorState(_errorMessage!);
    }

    if (_groups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.groups_outlined,
        title: 'No groups yet',
        subtitle: 'You will see your group chats here once you join one.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: Colors.green,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _groups.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 76,
          color: Color(0xFFEFEFEF),
        ),
        itemBuilder: (context, index) {
          final group = _groups[index];
          final unread = _unreadCounts[group.id] ?? 0;
          return _GroupListTile(
            group: group,
            unreadCount: unread,
            onTap: () => _openGroup(group),
          );
        },
      ),
    );
  }

  // ── States ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load groups',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadGroups,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
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
}

// ═════════════════════════════════════════════════════════════════════════════
// App-wide RouteObserver — used for auto-reload on re-entry
// ═════════════════════════════════════════════════════════════════════════════
//
// ⚠️ ONE-TIME SETUP: In your main.dart, wire this observer into MaterialApp
//     so `didPopNext()` above actually fires:
//
//     final RouteObserver<PageRoute> groupChatRouteObserver =
//         RouteObserver<PageRoute>();
//
//     MaterialApp(
//       navigatorObservers: [groupChatRouteObserver],
//       ...
//     );
//
//     If you already have a global routeObserver in your app, just import it
//     instead and delete this declaration (then update the references above).

final RouteObserver<PageRoute> groupChatRouteObserver =
    RouteObserver<PageRoute>();

// ═════════════════════════════════════════════════════════════════════════════
// Tile widget
// ═════════════════════════════════════════════════════════════════════════════

class _GroupListTile extends StatelessWidget {
  final GroupModel group;
  final int unreadCount;
  final VoidCallback onTap;

  const _GroupListTile({
    required this.group,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _GroupAvatar(group: group),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName.isEmpty
                        ? 'Untitled Group'
                        : group.groupName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleFor(group),
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread ? Colors.grey[700] : Colors.grey[500],
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitleFor(GroupModel g) {
    try {
      // ignore: avoid_dynamic_calls
      final dynamic lm = (g as dynamic).lastMessage;
      if (lm is String && lm.isNotEmpty) {
        return lm;
      }
    } catch (_) {}

    final memberCount = g.members.isNotEmpty ? g.members.length : 0;
    if (memberCount == 0) {
      return 'No members yet';
    }
    return '$memberCount member${memberCount == 1 ? '' : 's'}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Avatar
// ═════════════════════════════════════════════════════════════════════════════

class _GroupAvatar extends StatelessWidget {
  final GroupModel group;
  const _GroupAvatar({required this.group});

  @override
  Widget build(BuildContext context) {
    const double size = 46;

    final String? icon = group.groupIcon;
    if (icon != null && icon.isNotEmpty && icon.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          icon,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(size),
        ),
      );
    }

    return _initialsAvatar(size);
  }

  Widget _initialsAvatar(double size) {
    final String name = group.groupName.trim();
    final String initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[400]!, Colors.green[700]!],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}