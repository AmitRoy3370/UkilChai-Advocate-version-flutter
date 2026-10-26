// notification_service.dart (সঠিক সংস্করণ)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../Utils/BaseURL.dart' as BASE_URL;
import 'notification_model.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  StompClient? _stompClient;
  AudioPlayer? _audioPlayer;
  BuildContext? _context;
  bool _isLoading = false;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  Timer? _pollingTimer;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;

  void setContext(BuildContext context) {
    _context = context;
  }

  NotificationService() {
    _init();
  }

  Future<void> _init() async {
    if (!kIsWeb) {
      _audioPlayer = AudioPlayer();
    }
    await loadUnreadNotifications();

    final connected = await connectWebSocket();
    if (!connected) {
      _startPolling();
    }
  }

  // ✅ সঠিক WebSocket সংযোগ (heartBeat ছাড়া)
  Future<bool> connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) {
      print("⚠️ No user ID found for WebSocket connection");
      return false;
    }

    disconnectWebSocket();

    _isConnected = false;
    notifyListeners();

    String wsUrl = BASE_URL.Urls().baseURL.replaceAll("/api/", "").replaceAll("/api", "");
    if (wsUrl.endsWith('/')) {
      wsUrl = wsUrl.substring(0, wsUrl.length - 1);
    }
    print("🔌 WebSocket URL: $wsUrl/ws");

    try {
      Completer<bool> completer = Completer<bool>();

      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: '$wsUrl/ws',
          onConnect: (frame) {
            _isConnected = true;
            _reconnectAttempts = 0;
            notifyListeners();
            print("✅ WebSocket connected successfully!");

            _stompClient!.subscribe(
              destination: '/user/$userId/queue/notifications',
              callback: (frame) {
                if (frame.body != null && frame.body!.isNotEmpty) {
                  _onNewNotification(frame.body!);
                }
              },
            );

            _pollingTimer?.cancel();
            if (!completer.isCompleted) completer.complete(true);
          },
          onWebSocketError: (error) {
            _isConnected = false;
            notifyListeners();
            print("❌ WebSocket error: $error");
            if (!completer.isCompleted) completer.complete(false);
            _attemptReconnection();
          },
          onDisconnect: (frame) {
            _isConnected = false;
            notifyListeners();
            print("🔌 WebSocket disconnected");
            if (!completer.isCompleted) completer.complete(false);
            _attemptReconnection();
          },
          onDebugMessage: (message) {
            print("🐛 WebSocket debug: $message");
          },
          connectionTimeout: const Duration(seconds: 10),
        ),
      );

      _stompClient!.activate();

      Future.delayed(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      return await completer.future;
    } catch (e) {
      print("❌ WebSocket activation error: $e");
      return false;
    }
  }

  void _attemptReconnection() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print("❌ Max reconnection attempts reached. Starting polling mode...");
      _startPolling();
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: ++_reconnectAttempts * 3);
    print("🔄 Reconnecting in ${delay.inSeconds} seconds (Attempt $_reconnectAttempts/$maxReconnectAttempts)");

    _reconnectTimer = Timer(delay, () async {
      if (!_isConnected) {
        final success = await connectWebSocket();
        if (!success && _reconnectAttempts >= maxReconnectAttempts) {
          _startPolling();
        }
      }
    });
  }

  void _startPolling() {
    print("📡 Starting polling mode (every 15 seconds)");
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await loadUnreadNotifications();
    });
  }

  void disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _pollingTimer?.cancel();
    _stompClient?.deactivate();
    _isConnected = false;
    notifyListeners();
  }

  void _onNewNotification(String body) {
    try {
      final Map<String, dynamic> jsonData = jsonDecode(body);
      final notification = NotificationModel.fromJson(jsonData);

      final exists = _notifications.any((n) => n.id == notification.id);
      if (!exists) {
        _notifications.insert(0, notification);
        _unreadCount = _notifications.length;
        notifyListeners();

        print("🔔 New notification: ${notification.message}");

        _vibrate();
        _showSnackBar(notification.message);
      }
    } catch (e) {
      print("❌ Error parsing notification: $e");
    }
  }

  Future<void> _vibrate() async {
    if (!kIsWeb) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(duration: 300);
        }
      } catch (e) {
        print("⚠️ Vibration error: $e");
      }
    }
  }

  void _showSnackBar(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      print("🔔 Notification: $message");
    }
  }

  Future<void> loadUnreadNotifications() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('jwt_token');

    if (userId == null || token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      print("📡 Loading unread notifications for user: $userId");

      final response = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}notifications/unread/$userId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
        _notifications.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
        _unreadCount = _notifications.length;
        print("✅ Loaded ${_notifications.length} unread notifications");
      } else if (response.statusCode == 404) {
        _notifications = [];
        _unreadCount = 0;
        print("📭 No unread notifications found");
      } else {
        print("❌ Failed to load notifications: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Load notifications error: $e");
      _notifications = [];
      _unreadCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse("${BASE_URL.Urls().baseURL}notifications/mark-read/$notificationId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _unreadCount = _notifications.length;
        notifyListeners();
        print("✅ Notification marked as read: $notificationId");
      }
    } catch (e) {
      print("❌ Mark as read error: $e");
    }
  }

  Future<void> markAllAsRead() async {
    final List<String> ids = _notifications.map((n) => n.id).toList();
    for (String id in ids) {
      await markAsRead(id);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse("${BASE_URL.Urls().baseURL}notifications/delete/$notificationId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _unreadCount = _notifications.length;
        notifyListeners();
        print("✅ Notification deleted: $notificationId");
      }
    } catch (e) {
      print("❌ Delete notification error: $e");
    }
  }

  @override
  void dispose() {
    disconnectWebSocket();
    _audioPlayer?.dispose();
    super.dispose();
  }
}