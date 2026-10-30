// ChatWebSocketService.dart - STOMP Protocol (Matched to Backend)

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentUserId;
  String? _currentOtherUserId;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  
  // Callbacks
  Function(Map<String, dynamic>)? onMessage;
  Function(Map<String, dynamic>)? onMessageEdit;
  Function(String)? onMessageDelete;
  Function(String, bool)? onTyping;
  Function(String, bool)? onOnlineStatus;
  Function(bool)? onConnectionChanged;

  // ==================== WebSocket সংযোগ ====================

  Future<void> connect(String userId, {String? otherUserId}) async {
    if (_isConnecting) {
      print('⚠️ Already connecting...');
      return;
    }

    if (_isConnected && _currentUserId == userId) {
      print('✅ Already connected for user: $userId');
      return;
    }

    _isConnecting = true;
    _currentUserId = userId;
    _currentOtherUserId = otherUserId;
    _reconnectAttempts = 0;

    try {
      print('🔌 Connecting to WebSocket for user: $userId');

      await _closeConnection();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        print('❌ No authentication token found');
        _isConnecting = false;
        return;
      }

      final String wsUrl = 'wss://ukilchai.abrdns.com/ws?token=$token';
      
      print('🔌 WebSocket URL: $wsUrl');

      if (kIsWeb) {
        _channel = HtmlWebSocketChannel.connect(wsUrl);
      } else {
        _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      }

      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _handleDisconnection();
        },
        cancelOnError: false,
      );

      // 🛠️ STOMP CONNECT ফ্রেম পাঠান
      Future.delayed(const Duration(milliseconds: 100), () {
        _sendStompConnect();
      });

    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _isConnecting = false;
      _handleDisconnection();
    }
  }

  // ==================== STOMP Protocol Methods ====================

  void _sendStompConnect() {
    if (_channel == null) return;

    // STOMP CONNECT ফ্রেম
    final connectFrame = [
      'CONNECT',
      'accept-version:1.2',
      'heart-beat:10000,10000',
      '',
      '\u0000'
    ].join('\n');
    
    _channel!.sink.add(connectFrame);
    print('📡 STOMP CONNECT sent');
  }

  void _subscribeToUser(String userId) {
    if (_channel == null || !_isConnected) return;

    // STOMP SUBSCRIBE ফ্রেম - 1-on-1 chat এর জন্য
    final subscribeFrame = [
      'SUBSCRIBE',
      'destination:/user/$userId/queue/messages',
      'id:sub-${DateTime.now().millisecondsSinceEpoch}',
      'ack:auto',
      '',
      '\u0000'
    ].join('\n');
    
    _channel!.sink.add(subscribeFrame);
    print('📡 Subscribed to user queue: /user/$userId/queue/messages');
  }

  void _sendStompMessage(String destination, Map<String, dynamic> payload) {
    if (_channel == null || !_isConnected) {
      print('⚠️ Cannot send STOMP: Not connected');
      _connectWithRetry();
      return;
    }

    try {
      String jsonPayload = jsonEncode(payload);
      
      // STOMP SEND ফ্রেম
      final sendFrame = [
        'SEND',
        'destination:$destination',
        'content-type:application/json',
        'content-length:${jsonPayload.length}',
        '',
        jsonPayload,
        '\u0000'
      ].join('\n');
      
      _channel!.sink.add(sendFrame);
      print('📤 STOMP Sent to $destination');
      
    } catch (e) {
      print('❌ Error sending STOMP message: $e');
      _handleDisconnection();
    }
  }

  // ==================== ইনকামিং মেসেজ হ্যান্ডেল ====================

  void _handleIncomingMessage(dynamic message) {
    try {
      String messageStr = message.toString();
      
      // হৃদস্পন্দন ইগনোর
      if (messageStr.trim() == 'h' || 
          messageStr.trim() == '\n' || 
          messageStr.trim().isEmpty ||
          messageStr.contains('heart-beat')) {
        print('💓 Heartbeat received');
        return;
      }

      // STOMP CONNECTED ফ্রেম
      if (messageStr.contains('CONNECTED')) {
        print('✅ STOMP CONNECTED');
        _isConnected = true;
        _isConnecting = false;
        _reconnectAttempts = 0;
        onConnectionChanged?.call(true);
        _startHeartbeat();
        
        // গ্রাহক সাবস্ক্রাইব করুন
        if (_currentUserId != null) {
          _subscribeToUser(_currentUserId!);
        }
        return;
      }

      // STOMP MESSAGE ফ্রেম পার্স করুন
      if (messageStr.contains('MESSAGE')) {
        _parseStompMessage(messageStr);
        return;
      }

      // JSON মেসেজ চেক করুন (ডাইরেক্ট)
      if (messageStr.trim().startsWith('{')) {
        try {
          Map<String, dynamic> data = jsonDecode(messageStr);
          _processMessage(data);
        } catch (e) {
          print('⚠️ Invalid JSON: $messageStr');
        }
        return;
      }

      print('📨 Raw STOMP: $messageStr');

    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  void _parseStompMessage(String messageStr) {
    try {
      List<String> lines = messageStr.split('\n');
      int bodyStartIndex = -1;
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim() == '') {
          bodyStartIndex = i + 1;
          break;
        }
      }
      
      if (bodyStartIndex != -1 && bodyStartIndex < lines.length) {
        String body = lines.sublist(bodyStartIndex).join('\n').trim();
        if (body.endsWith('\u0000')) {
          body = body.substring(0, body.length - 1);
        }
        
        if (body.isNotEmpty && body.startsWith('{')) {
          try {
            Map<String, dynamic> data = jsonDecode(body);
            _processMessage(data);
          } catch (e) {
            print('⚠️ Invalid JSON in STOMP body: $body');
          }
        }
      }
    } catch (e) {
      print('❌ Error parsing STOMP message: $e');
    }
  }

  void _processMessage(Map<String, dynamic> data) {
    print('📦 Processing: $data');
    
    final type = data['type'] ?? '';
    
    switch (type) {
      case 'message':
      case 'chat':
        if (data.containsKey('data')) {
          onMessage?.call(data['data']);
        } else {
          onMessage?.call(data);
        }
        break;
        
      case 'edit':
        if (data.containsKey('data')) {
          onMessageEdit?.call(data['data']);
        } else {
          onMessageEdit?.call(data);
        }
        break;
        
      case 'delete':
        if (data.containsKey('data')) {
          onMessageDelete?.call(data['data']['id'] ?? '');
        } else {
          onMessageDelete?.call(data['id'] ?? '');
        }
        break;
        
      case 'typing':
        if (data.containsKey('data')) {
          final typingData = data['data'];
          onTyping?.call(
            typingData['sender'] ?? '',
            typingData['typing'] ?? false,
          );
        } else {
          onTyping?.call(
            data['sender'] ?? '',
            data['typing'] ?? false,
          );
        }
        break;
        
      case 'online':
      case 'status':
        if (data.containsKey('data')) {
          onOnlineStatus?.call(
            data['data']['userId'] ?? '',
            data['data']['online'] ?? false,
          );
        } else {
          onOnlineStatus?.call(
            data['userId'] ?? '',
            data['online'] ?? false,
          );
        }
        break;
        
      default:
        if (data.containsKey('sender') || data.containsKey('content') || data.containsKey('message')) {
          onMessage?.call(data);
        } else {
          print('📨 Unknown message type: $type');
        }
    }
  }

  // ==================== মেসেজ পাঠানো (STOMP) ====================

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    // STOMP destination for 1-on-1 chat
    final destination = '/app/chat.send';
    final payload = {
      'sender': senderId,
      'receiver': receiverId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _sendStompMessage(destination, payload);
    print('📤 Message sent to $receiverId');
  }

  void sendTypingIndicator({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  }) {
    if (!_isConnected) return;

    final destination = '/app/chat.typing';
    final payload = {
      'sender': senderId,
      'receiver': receiverId,
      'typing': isTyping,
    };

    _sendStompMessage(destination, payload);
  }

  void sendEditEvent({
    required String senderId,
    required String receiverId,
    required String messageId,
    required String newContent,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send edit: Not connected');
      _connectWithRetry();
      return;
    }

    final destination = '/app/chat.edit';
    final payload = {
      'id': messageId,
      'messageId': messageId,
      'chatId': messageId,
      'sender': senderId,
      'receiver': receiverId,
      'content': newContent,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _sendStompMessage(destination, payload);
    print('✏️ Edit event sent to backend for messageId: $messageId');
  }

  void sendDeleteEvent({
    required String senderId,
    required String receiverId,
    required String messageId,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send delete: Not connected');
      _connectWithRetry();
      return;
    }

    final destination = '/app/chat.delete';
    final payload = {
      'id': messageId,
      'messageId': messageId,
      'chatId': messageId,
      'sender': senderId,
      'receiver': receiverId,
    };

    _sendStompMessage(destination, payload);
    print('🗑️ Delete event sent to backend for messageId: $messageId');
  }

  // ==================== হৃদস্পন্দন ====================

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _channel != null) {
        try {
          // STOMP heartbeats are handled by the server, 
          // but we send a simple "h" to keep the connection alive.
          _channel!.sink.add('h');
          print('💓 Heartbeat sent');
        } catch (e) {
          print('❌ Heartbeat failed: $e');
          _handleDisconnection();
        }
      } else {
        timer.cancel();
      }
    });
  }

  // ==================== রিকানেক্ট ====================

  void _connectWithRetry() {
    if (_currentUserId != null && !_isConnected) {
      _scheduleReconnect();
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    _heartbeatTimer?.cancel();
    onConnectionChanged?.call(false);

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      print('❌ Max reconnection attempts reached');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    final delay = (2 << _reconnectAttempts).clamp(2, 30);
    print('⏳ Reconnecting in $delay seconds... (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _reconnectAttempts++;
      if (_currentUserId != null) {
        connect(_currentUserId!, otherUserId: _currentOtherUserId);
      }
    });
  }

  // ==================== ডিসকানেক্ট ====================

  Future<void> _closeConnection() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (e) {
        print('⚠️ Error closing connection: $e');
      }
      _channel = null;
    }
  }

  Future<void> disconnect() async {
    print('🔌 Disconnecting WebSocket...');
    await _closeConnection();
    _isConnected = false;
    _isConnecting = false;
    _currentUserId = null;
    _currentOtherUserId = null;
    _reconnectAttempts = 0;
    onConnectionChanged?.call(false);
    print('🔌 WebSocket disconnected');
  }

  // ==================== গেটার ====================

  bool get isConnected => _isConnected && _channel != null;
  bool get isConnecting => _isConnecting;
  String? get currentUserId => _currentUserId;
}