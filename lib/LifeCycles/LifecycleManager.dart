// lib/LifeCycles/LifecycleManager.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'PresenceSocketService.dart';

class LifecycleManager extends StatefulWidget {
  final Widget child;
  const LifecycleManager({super.key, required this.child});

  @override
  State<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends State<LifecycleManager>
    with WidgetsBindingObserver {
  String? userId;
  String? token;
  String? activeRecordId;
  bool _hasInitialized = false;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeatTime;
  bool _isActive = false;
  PresenceSocketService? _socketService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _setUserOffline(); // অ্যাপ ডিসপোজ হওয়ার সময় অফলাইন সেট করুন
    _socketService?.disconnect();
    super.dispose();
  }

  // ইউজার ডাটা লোড করুন
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    token = prefs.getString("jwt_token");
    activeRecordId = prefs.getString("active_record_id");

    if (userId != null && token != null && !_hasInitialized) {
      _hasInitialized = true;
      _isActive = true;
      
      // WebSocket সংযোগ করুন
      _socketService = PresenceSocketService();
      _socketService?.connect(userId!);
      
      // Heartbeat শুরু করুন
      _startHeartbeat();
      _setupWebCloseListener();
      print('✅ LifecycleManager initialized for user: $userId');
    }
  }

  // ✅ Heartbeat - প্রতি ২০ সেকেন্ডে (শুধুমাত্র এখানেই থাকবে)
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 20), // ২০ সেকেন্ড
      (timer) async {
        if (!_hasInitialized || userId == null || token == null) {
          return;
        }
        await _sendHeartbeat();
      },
    );

    print('💓 Heartbeat started (every 20 seconds)');
  }

  // ✅ Heartbeat API Call
  Future<void> _sendHeartbeat() async {
    if (userId == null || token == null) return;

    try {
      final url = Uri.parse("${BASE_URL.Urls().baseURL}user-active/heartbeat/$userId");
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _lastHeartbeatTime = DateTime.now();
        // print("💓 Heartbeat sent at ${_lastHeartbeatTime?.toLocal()}");
      } else {
        print("❌ Heartbeat failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Heartbeat error: $e");
    }
  }

  // ✅ ইউজারকে অফলাইন সেট করুন
  Future<void> _setUserOffline() async {
    if (userId == null || token == null) return;
    
    try {
      final url = Uri.parse("${BASE_URL.Urls().baseURL}user-active/offline/$userId");
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ User set to OFFLINE successfully');
      } else {
        print('❌ Failed to set offline: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error setting offline: $e');
    }
  }

  // ✅ Web Close Listener
  void _setupWebCloseListener() {
    html.window.onBeforeUnload.listen((event) {
      print('🔄 Web page closing');
      _setUserOffline(); // পেজ ক্লোজ হলে অফলাইন সেট করুন
      _heartbeatTimer?.cancel();
      _socketService?.disconnect();
    });

    html.document.onVisibilityChange.listen((event) {
      if (_hasInitialized) {
        if (html.document.visibilityState == 'hidden') {
          print('👻 Page hidden - stopping heartbeat');
          _heartbeatTimer?.cancel();
        } else if (html.document.visibilityState == 'visible') {
          print('👀 Page visible - starting heartbeat');
          _startHeartbeat();
        }
      }
    });
  }

  // ✅ App Lifecycle Management
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasInitialized || userId == null || token == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        print('▶️ App Resumed - Starting heartbeat');
        _startHeartbeat();
        // পুনরায় WebSocket সংযোগ
        if (_socketService != null) {
          _socketService?.connect(userId!);
        }
        break;

      case AppLifecycleState.paused:
        print('⏸️ App Paused - Stopping heartbeat');
        _heartbeatTimer?.cancel();
        break;

      case AppLifecycleState.detached:
        print('🔴 App Detached - Setting user offline');
        _heartbeatTimer?.cancel();
        _setUserOffline(); // অ্যাপ ডিটাচ হলে অফলাইন সেট করুন
        _socketService?.disconnect();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        print('🌙 App Inactive - Stopping heartbeat');
        _heartbeatTimer?.cancel();
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}