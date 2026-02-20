import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'dart:js' as js;  // ← এটা নতুন যোগ করো!
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../ChatRelatedPages/user_active_service.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

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
  bool _isActive = false;
  bool _hasInitialized = false;
  Timer? _inactiveTimer;

  @override
  void initState() {
    super.initState();
    print("🔵 LifecycleManager initState");
    WidgetsBinding.instance.addObserver(this);
    loadUser();
  }

  Future<void> loadUser() async {
    print("📂 loadUser started");
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    token = prefs.getString("jwt_token");
    activeRecordId = prefs.getString("active_record_id");

    print("📂 loadUser - userId: $userId, token: ${token != null}, activeRecordId: $activeRecordId");

    if (userId != null && token != null && !_hasInitialized) {
      _hasInitialized = true;
      print("📂 loadUser - calling setUserActive(true)");

      await setUserActive(true);

      print("📂 loadUser - setting up web close listener with delay");
      setupWebCloseListener();
    } else {
      print("📂 loadUser - conditions not met: userId=$userId, token=${token!=null}, _hasInitialized=$_hasInitialized");
    }
  }

  // ================== ওয়েব ক্লোজের জন্য KEEPALIVE FETCH (সবচেয়ে শক্তিশালী) ==================
  void _sendInactiveKeepalive() {
    print("🚨 _sendInactiveKeepalive called - Browser closing!");

    if (!_hasInitialized || userId == null || token == null) {
      print("🚨 Not sending - not initialized");
      return;
    }

    String url = "${BASE_URL.Urls().baseURL}user-active/add";
    String method = 'POST';
    final body = jsonEncode({"userId": userId, "active": false});

    if (activeRecordId != null) {
      url = "${BASE_URL.Urls().baseURL}user-active/update/$activeRecordId/$userId";
      method = 'PUT';
      print("📡 Using UPDATE with keepalive (PUT)");
    } else {
      print("📡 Using ADD with keepalive (POST)");
    }

    try {
      final options = js.JsObject.jsify({
        'method': method,
        'headers': {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        'body': body,
        'keepalive': true,  // ← এটাই ম্যাজিক!
      });

      js.context['fetch'].apply([url, options]);
      print("✅ Keepalive fetch sent successfully for $method!");
    } catch (e) {
      print("❌ Keepalive fetch failed: $e → fallback to sync");
      _sendInactiveSync();  // পুরানো fallback
    }
  }

  Future<void> _performSetUserActive(bool active, String uid, String? t) async {
    print("🔄 _performSetUserActive - active: $active, uid: $uid");
    try {
      final response = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$uid"),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $t',
        },
      );

      print("🔄 GET user-active response: ${response.statusCode}");

      String? recordId;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        recordId = body["id"].toString();
        print("🔄 Found existing record with id: $recordId");

        print("🔄 Calling updateUserActive with active=$active");
        await UserActiveService.updateUserActive(recordId, uid, active, t);
      } else {
        print("🔄 No existing record, calling addUserActive with active=$active");
        await UserActiveService.addUserActive(uid, active, t);

        // Fetch the newly created record
        final newResp = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$uid"),
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $t',
          },
        );
        if (newResp.statusCode == 200) {
          recordId = jsonDecode(newResp.body)["id"].toString();
          print("🔄 New record created with id: $recordId");
        }
      }

      // Save the record ID
      if (recordId != null) {
        activeRecordId = recordId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_record_id', recordId);
        print("🔄 Saved activeRecordId to prefs: $recordId");
      }
    } catch (e) {
      print("🔄 _performSetUserActive error: $e");
    }
  }

  // ================== NORMAL SET ACTIVE ==================
  Future<void> setUserActive(bool active) async {
    print("🎯 setUserActive called with active=$active, current _isActive=$_isActive");

    // Don't do anything if state hasn't changed
    if (_isActive == active) {
      print("🎯 State already $active, skipping");
      return;
    }

    print("🎯 Changing active state from $_isActive to $active");
    _isActive = active;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? t = token ?? prefs.getString('jwt_token');
      String? uid = userId ?? prefs.getString('userId');

      if (uid == null || t == null) {
        print("🎯 uid or token is null, returning");
        return;
      }

      // Cancel any pending timer
      _inactiveTimer?.cancel();

      if (!active) {
        print("🎯 Setting inactive timer");
        _inactiveTimer = Timer(const Duration(milliseconds: 500), () async {
          print("🎯 Inactive timer fired");
          await _performSetUserActive(false, uid, t);
        });
      } else {
        print("🎯 Calling _performSetUserActive immediately for active=true");
        await _performSetUserActive(true, uid, t);
      }
    } catch (e) {
      print("🎯 setUserActive error: $e");
    }
  }

  // ================== WEB CLOSE HANDLING ==================
  void setupWebCloseListener() {
    print("🔔 setupWebCloseListener started (keepalive ready)");

    html.window.onBeforeUnload.listen((event) {
      print("🔔 onBeforeUnload → sending keepalive");
      _sendInactiveKeepalive();
    });

    html.window.onPageHide.listen((event) {
      print("🔔 onPageHide → sending keepalive");
      _sendInactiveKeepalive();
    });

    html.document.onVisibilityChange.listen((event) {
      if (_hasInitialized && html.document.visibilityState == 'hidden') {
        print("🔔 Visibility hidden → keepalive");
        Future.delayed(const Duration(milliseconds: 300), _sendInactiveKeepalive);
      }
    });

    print("🔔 setupWebCloseListener completed");
  }

  void _sendInactiveBeacon() {
    print("📡 _sendInactiveBeacon called");
    print("📡 _hasInitialized: $_hasInitialized, userId: $userId, token: ${token != null}");

    // Don't send if we're not properly initialized
    if (!_hasInitialized || userId == null || token == null) {
      print("📡 Not sending beacon - not properly initialized");
      return;
    }

    print("🚨 Browser closing → sending inactive beacon...");

    try {
      String url;
      final body = jsonEncode({"userId": userId, "active": false});

      if (activeRecordId != null) {
        url = "${BASE_URL.Urls().baseURL}user-active/update/$activeRecordId/$userId";
        print("📡 Using UPDATE URL: $url");
      } else {
        url = "${BASE_URL.Urls().baseURL}user-active/add";
        print("📡 Using ADD URL: $url");
      }

      print("📡 Beacon body: $body");

      // Create a blob with the data
      final blob = html.Blob([body], 'application/json');

      // Use sendBeacon for reliable sending even when page closes
      bool success = html.window.navigator.sendBeacon(url, blob);

      if (success) {
        print("✅ Beacon sent successfully");
      } else {
        print("❌ Beacon failed, trying sync request");
        _sendInactiveSync();
      }
    } catch (e) {
      print("❌ Beacon error: $e, trying sync request");
      _sendInactiveSync();
    }
  }

  void _sendInactiveSync() {
    print("📠 _sendInactiveSync called");

    if (!_hasInitialized || userId == null || token == null) {
      print("📠 Not sending sync - not properly initialized");
      return;
    }

    try {
      String url;
      final body = jsonEncode({"userId": userId, "active": false});

      if (activeRecordId != null) {
        url = "${BASE_URL.Urls().baseURL}user-active/update/$activeRecordId/$userId";
      } else {
        url = "${BASE_URL.Urls().baseURL}user-active/add";
      }

      print("📠 Sync request to: $url");
      print("📠 Sync body: $body");

      final request = html.HttpRequest();
      request.open('POST', url, async: false);
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Authorization', 'Bearer $token');
      request.send(body);

      print("✅ Sync inactive request sent, status: ${request.status}");
    } catch (e) {
      print("❌ Sync request failed: $e");
    }
  }

  @override
  void dispose() {
    print("🗑️ LifecycleManager dispose");
    WidgetsBinding.instance.removeObserver(this);
    _inactiveTimer?.cancel();

    if (_hasInitialized && userId != null && token != null) {
      print("🗑️ Dispose → sending keepalive inactive");
      _sendInactiveKeepalive();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🔄 didChangeAppLifecycleState: $state");

    if (!_hasInitialized || userId == null || token == null) {
      print("🔄 Lifecycle change ignored - not initialized");
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      print("📴 App paused/detached/inactive → inactive");
      setUserActive(false);
    } else if (state == AppLifecycleState.resumed) {
      print("✅ App resumed → active");
      setUserActive(true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}