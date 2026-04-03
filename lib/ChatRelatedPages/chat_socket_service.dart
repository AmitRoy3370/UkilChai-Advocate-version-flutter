import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

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
  Function(String, bool)? onTyping;
  Function(String, bool)? onOnlineStatus;
  Function(bool)? onConnectionChanged;

  // Connect to WebSocket with SockJS and STOMP
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

      // SockJS endpoint
      final wsUrl = Uri.parse('wss://ukilchai.abrdns.com/ws-chat/websocket');

      _channel = IOWebSocketChannel.connect(
        wsUrl,
        protocols: ['websocket'],
      );

      // Wait for connection to establish
      await _channel!.ready.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      // Send STOMP CONNECT frame
      _sendStompFrame('CONNECT', {
        'accept-version': '1.1,1.2',
        'heart-beat': '10000,10000',
      });

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

      _isConnecting = false;
      print('🔌 WebSocket setup complete, waiting for CONNECTED frame...');
    } catch (e) {
      print('❌ Failed to connect: $e');
      _isConnecting = false;
      _handleDisconnection();
    }
  }

  void _handleMessage(dynamic data) {
    String message = data.toString();

    // Handle SockJS frames (they come wrapped in arrays)
    if (message.startsWith('o')) {
      // Open frame
      print('📖 SockJS connection opened');
      return;
    } else if (message.startsWith('h')) {
      // Heartbeat frame
      print('💓 Heartbeat received');
      return;
    } else if (message.startsWith('a[')) {
      // Array frame - extract the actual message
      try {
        final content = message.substring(2, message.length - 1);
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is List && decoded.isNotEmpty) {
            message = decoded[0];
          }
        }
      } catch (e) {
        print('❌ Error parsing SockJS frame: $e');
        return;
      }
    }

    // Now handle STOMP frames
    if (message.startsWith('CONNECTED')) {
      print('✅ WebSocket connected successfully');
      _isConnected = true;
      _reconnectAttempts = 0;
      _isConnecting = false;
      onConnectionChanged?.call(true);
      _startHeartbeat();
      _subscribeToUserQueue();
    } else if (message.startsWith('MESSAGE')) {
      _parseStompMessage(message);
    } else if (message.startsWith('ERROR')) {
      print('❌ STOMP error: $message');
      _handleDisconnection();
    } else if (message.startsWith('RECEIPT')) {
      print('✅ Receipt received');
    }
  }

  void _subscribeToUserQueue() {
    if (_currentUserId == null) return;

    _subscriptionId++;

    // Subscribe to user's private message queue
    _sendStompFrame('SUBSCRIBE', {
      'id': 'sub-$_subscriptionId',
      'destination': '/user/queue/messages',
    });

    // Also subscribe to typing indicators
    _sendStompFrame('SUBSCRIBE', {
      'id': 'sub-typing-$_subscriptionId',
      'destination': '/user/queue/typing',
    });

    print('📬 Subscribed to user queues for: $_currentUserId');
  }

  void _parseStompMessage(String stompFrame) {
    try {
      // Extract JSON body from STOMP frame
      final lines = stompFrame.split('\n');
      int bodyIndex = -1;

      // Find the empty line that separates headers from body
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) {
          bodyIndex = i + 1;
          break;
        }
      }

      if (bodyIndex > 0 && bodyIndex < lines.length) {
        final jsonBody = lines.sublist(bodyIndex).join('\n').trim();
        final body = jsonBody.replaceAll('\u0000', ''); // Remove null terminator

        if (body.isNotEmpty && body.startsWith('{')) {
          final data = json.decode(body);

          // Determine message type based on destination header
          String? destination;
          for (var line in lines) {
            if (line.startsWith('destination:')) {
              destination = line.substring('destination:'.length).trim();
              break;
            }
          }

          if (destination != null) {
            if (destination.contains('/queue/messages')) {
              onMessage?.call(data);
            } else if (destination.contains('/queue/typing')) {
              if (data['sender'] != null && data['typing'] != null) {
                onTyping?.call(data['sender'], data['typing']);
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error parsing STOMP message: $e');
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

    final messageBody = json.encode({
      'sender': senderId,
      'receiver': receiverId,
      'content': content,
    });

    _sendStompFrame(
      'SEND',
      {'destination': '/app/chat.send'},
      messageBody,
    );

    print('📤 Message sent to $receiverId');
  }

  void sendTypingIndicator({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  }) {
    if (!_isConnected) return;

    final body = json.encode({
      'sender': senderId,
      'receiver': receiverId,
      'typing': isTyping,
    });

    _sendStompFrame(
      'SEND',
      {'destination': '/app/chat.typing'},
      body,
    );
  }

  void _sendStompFrame(String command, Map<String, String> headers, [String? body]) {
    if (_channel == null) {
      print('⚠️ Cannot send STOMP frame: Channel is null');
      return;
    }

    final frame = StringBuffer();
    frame.writeln(command);

    headers.forEach((key, value) {
      frame.writeln('$key:$value');
    });

    frame.writeln();

    if (body != null) {
      frame.write(body);
    }

    frame.write('\u0000'); // Null terminator

    final frameStr = frame.toString();

    // Wrap in SockJS format
    final sockjsMessage = jsonEncode([frameStr]);

    try {
      _channel!.sink.add(sockjsMessage);
    } catch (e) {
      print('❌ Error sending STOMP frame: $e');
      _handleDisconnection();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    // Send heartbeat every 10 seconds
    _heartbeatTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_isConnected && _channel != null) {
        try {
          // Send STOMP heartbeat (just a newline)
          _channel!.sink.add(jsonEncode(['\n']));
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
        if (_isConnected) {
          _sendStompFrame('DISCONNECT', {'receipt': 'disconnect-${DateTime.now().millisecondsSinceEpoch}'});
          await Future.delayed(Duration(milliseconds: 100));
        }
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