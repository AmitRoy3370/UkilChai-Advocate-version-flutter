import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentUserId;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _subscriptionId = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Callbacks
  Function(Map<String, dynamic>)? onMessage;
  Function(Map<String, dynamic>)? onMessageEdit;
  Function(String)? onMessageDelete;
  Function(String, bool)? onTyping;
  Function(String, bool)? onOnlineStatus;
  Function(bool)? onConnectionChanged;

  // Connect to WebSocket
  Future<void> connect(String userId) async {
    if (_isConnecting) {
      print('⚠️ Already connecting, please wait...');
      return;
    }

    if (_isConnected && _currentUserId == userId) {
      print('✅ Already connected for user: $userId');
      return;
    }

    _isConnecting = true;
    _currentUserId = userId;

    try {
      print('🔌 Connecting to WebSocket for user: $userId');

      // Close existing connection if any
      await _closeConnection();

      // Use appropriate WebSocket implementation based on platform
      final wsUrl = Uri.parse('wss://ukilchai.abrdns.com/ws-chat/websocket');

      if (kIsWeb) {
        // For Flutter Web
        _channel = HtmlWebSocketChannel.connect(wsUrl.toString());
        print('🌐 Using HTML WebSocket for web platform');
      } else {
        // For mobile (iOS/Android)
        _channel = IOWebSocketChannel.connect(wsUrl);
        print('📱 Using IO WebSocket for mobile platform');
      }

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('⚠️ WebSocket connection closed');
          _handleDisconnection();
        },
        cancelOnError: false,
      );

      // Wait for connection to establish
      await Future.delayed(Duration(milliseconds: 500));

      // Send connection initialization
      _sendRawMessage('init');

      _isConnecting = false;
      _isConnected = true;
      _reconnectAttempts = 0;
      onConnectionChanged?.call(true);
      _startHeartbeat();

      print('✅ WebSocket connected successfully for user: $userId');
    } catch (e) {
      print('❌ Failed to connect: $e');
      _isConnecting = false;
      _handleDisconnection();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = data.toString();
      print('📨 Received: $message');

      // Parse JSON message
      if (message.startsWith('{')) {
        final jsonData = jsonDecode(message);
        final type = jsonData['type'];

        switch (type) {
          case 'message':
            onMessage?.call(jsonData['data']);
            break;
          case 'edit':
            onMessageEdit?.call(jsonData['data']);
            break;
          case 'delete':
            onMessageDelete?.call(jsonData['data']['id']);
            break;
          case 'typing':
            onTyping?.call(jsonData['data']['sender'], jsonData['data']['typing']);
            break;
          case 'pong':
          // Heartbeat response
            print('💓 Heartbeat received');
            break;
          default:
            print('Unknown message type: $type');
        }
      }
    } catch (e) {
      print('❌ Error parsing message: $e');
    }
  }

  void _sendRawMessage(String message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        print('❌ Error sending message: $e');
      }
    }
  }

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send message: Not connected');
      return;
    }

    final message = jsonEncode({
      'type': 'message',
      'data': {
        'sender': senderId,
        'receiver': receiverId,
        'content': content,
      }
    });

    _sendRawMessage(message);
    print('📤 Message sent to $receiverId');
  }

  void sendTypingIndicator({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  }) {
    if (!_isConnected) return;

    final message = jsonEncode({
      'type': 'typing',
      'data': {
        'sender': senderId,
        'receiver': receiverId,
        'typing': isTyping,
      }
    });

    _sendRawMessage(message);
  }

  void sendEditEvent({
    required String senderId,
    required String receiverId,
    required String messageId,
    required String newContent,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send edit event: Not connected');
      return;
    }

    final message = jsonEncode({
      'type': 'edit',
      'data': {
        'id': messageId,
        'sender': senderId,
        'receiver': receiverId,
        'content': newContent,
      }
    });

    _sendRawMessage(message);
    print('📝 Edit event sent for message: $messageId');
  }

  void sendDeleteEvent({
    required String senderId,
    required String receiverId,
    required String messageId,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send delete event: Not connected');
      return;
    }

    final message = jsonEncode({
      'type': 'delete',
      'data': {
        'id': messageId,
        'sender': senderId,
        'receiver': receiverId,
      }
    });

    _sendRawMessage(message);
    print('🗑️ Delete event sent for message: $messageId');
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    // Send heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          final heartbeat = jsonEncode({'type': 'ping'});
          _sendRawMessage(heartbeat);
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

    // Exponential backoff: 2^attempt seconds, max 30 seconds
    final delay = (2 << _reconnectAttempts).clamp(2, 30);

    print('⏳ Scheduling reconnect in $delay seconds... (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _reconnectAttempts++;
      if (_currentUserId != null) {
        connect(_currentUserId!);
      }
    });
  }

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
    _reconnectAttempts = 0;
    onConnectionChanged?.call(false);
    print('🔌 WebSocket disconnected');
  }

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentUserId => _currentUserId;
}