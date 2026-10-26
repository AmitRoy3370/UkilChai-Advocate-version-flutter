// GroupChatWebSocket.dart

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'GroupChatModels.dart';
import 'package:web_socket_channel/status.dart' as status;

class GroupChatWebSocket {
  static WebSocketChannel? _channel;
  static String? _currentGroupId;
  static bool _isConnected = false;
  static bool _isConnecting = false;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  
  static final List<Function(GroupMessageModel)> _messageListeners = [];
  static final List<Function(String)> _deleteListeners = [];
  static final List<Function(GroupMessageModel)> _editListeners = [];

  // 📌 WebSocket সংযোগ
  static Future<void> connect(String groupId) async {
    if (_isConnected && _currentGroupId == groupId) {
      print('✅ Already connected to group: $groupId');
      return;
    }

    if (_isConnecting) {
      print('⏳ Connection already in progress...');
      return;
    }

    _isConnecting = true;
    _currentGroupId = groupId;
    _reconnectAttempts = 0;

    try {
      // টোকেন পাওয়া
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      
      if (token == null) {
        print('❌ No authentication token found');
        _isConnecting = false;
        return;
      }

      // WebSocket URL - টোকেন কুয়েরি প্যারামিটার হিসেবে পাঠানো
      final String wsUrl = 'wss://ukilchai.abrdns.com/ws?token=$token';
      
      print('🔌 Connecting to WebSocket: $wsUrl');

      // WebSocket সংযোগ তৈরি
      final channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      _channel = channel;

      // মেসেজ রিসিভ করা
      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('🔌 WebSocket disconnected');
          _handleDisconnect();
        },
      );

      // সংযোগ সফল
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      print('✅ WebSocket connected successfully!');

      // গ্রুপ সাবস্ক্রাইব - STOMP ফরম্যাটে
      _subscribeToGroup(groupId);

    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _isConnected = false;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // 📌 গ্রুপ সাবস্ক্রাইব - STOMP প্রোটোকল অনুযায়ী
  static void _subscribeToGroup(String groupId) {
    if (_channel != null && _isConnected) {
      try {
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

        // STOMP SUBSCRIBE ফ্রেম
        Future.delayed(const Duration(milliseconds: 500), () {
          final subscribeFrame = [
            'SUBSCRIBE',
            'destination:/topic/group/$groupId',
            'id:sub-0',
            'ack:auto',
            '',
            '\u0000'
          ].join('\n');
          
          _channel!.sink.add(subscribeFrame);
          print('📡 Subscribed to group: $groupId');
        });

      } catch (e) {
        print('❌ Error subscribing to group: $e');
      }
    }
  }

  // 📌 ইনকামিং মেসেজ হ্যান্ডেল - STOMP প্রোটোকল সাপোর্ট
  static void _handleIncomingMessage(dynamic message) {
    try {
      String messageStr = message.toString();
      
      // 🔹 হৃদস্পন্দন (Heartbeat) মেসেজ চেক করুন
      if (messageStr.trim() == 'h' || 
          messageStr.trim() == '\n' || 
          messageStr.trim() == '' ||
          messageStr.contains('heart-beat') ||
          messageStr.contains('CONNECTED')) {
        print('💓 Heartbeat received');
        
        // হৃদস্পন্দনের জবাব দিন (যদি প্রয়োজন হয়)
        if (messageStr.contains('CONNECTED')) {
          // STOMP সংযোগ সফল হয়েছে
          print('✅ STOMP CONNECTED');
        }
        return;
      }

      // 🔹 STOMP ফ্রেম পার্স করুন
      if (messageStr.contains('MESSAGE')) {
        // STOMP MESSAGE ফ্রেম থেকে ডেটা বের করুন
        _parseStompMessage(messageStr);
        return;
      }

      // 🔹 JSON মেসেজ চেক করুন (সরাসরি JSON)
      if (messageStr.trim().startsWith('{')) {
        try {
          Map<String, dynamic> data = jsonDecode(messageStr);
          _processJsonMessage(data);
        } catch (e) {
          print('⚠️ Invalid JSON: $messageStr');
        }
        return;
      }

      // 🔹 অন্যান্য মেসেজ
      print('📨 Raw message: $messageStr');

    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  // 📌 STOMP মেসেজ পার্স করা
  static void _parseStompMessage(String messageStr) {
    try {
      // STOMP ফ্রেম থেকে বডি বের করা
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
        // শেষের null চ্যারেক্টার রিমুভ
        if (body.endsWith('\u0000')) {
          body = body.substring(0, body.length - 1);
        }
        
        if (body.isNotEmpty && body.startsWith('{')) {
          try {
            Map<String, dynamic> data = jsonDecode(body);
            _processJsonMessage(data);
          } catch (e) {
            print('⚠️ Invalid JSON in STOMP body: $body');
          }
        }
      }
    } catch (e) {
      print('❌ Error parsing STOMP message: $e');
    }
  }

  // 📌 JSON মেসেজ প্রসেস করা
  static void _processJsonMessage(Map<String, dynamic> data) {
    print('📦 Processing JSON: $data');
    
    // মেসেজ টাইপ চেক
    if (data.containsKey('content') && data.containsKey('senderId')) {
      // নতুন মেসেজ
      try {
        GroupMessageModel msg = GroupMessageModel.fromJson(data);
        print('💬 New message from ${msg.senderName}: ${msg.content}');
        _notifyMessageListeners(msg);
      } catch (e) {
        print('❌ Error parsing message: $e');
      }
    } 
    else if (data.containsKey('messageId') && data.containsKey('deleted')) {
      // মেসেজ ডিলিট
      print('🗑️ Message deleted: ${data['messageId']}');
      _notifyDeleteListeners(data['messageId']);
    } 
    else if (data.containsKey('id') && data.containsKey('edited')) {
      // মেসেজ এডিট
      try {
        GroupMessageModel msg = GroupMessageModel.fromJson(data);
        print('✏️ Message edited: ${msg.id}');
        _notifyEditListeners(msg);
      } catch (e) {
        print('❌ Error parsing edit message: $e');
      }
    }
    else if (data.containsKey('type')) {
      // বিভিন্ন টাইপের মেসেজ
      String type = data['type'] ?? '';
      switch(type) {
        case 'CONNECTED':
          print('✅ STOMP Connected');
          break;
        case 'SUBSCRIBE':
          print('✅ STOMP Subscribed');
          break;
        case 'ERROR':
          print('❌ STOMP Error: ${data['message']}');
          break;
        default:
          print('📨 Unknown type: $type');
      }
    }
  }

  // 🔌 ডিসকানেক্ট হ্যান্ডেল
  static void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _scheduleReconnect();
  }

  // 🔄 রিকানেক্ট শিডিউল
  static void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts && _currentGroupId != null) {
      _reconnectAttempts++;
      int delay = _reconnectAttempts * 3;
      print('🔄 Reconnect attempt $_reconnectAttempts in $delay seconds');
      
      Future.delayed(Duration(seconds: delay), () {
        if (!_isConnected && _currentGroupId != null) {
          connect(_currentGroupId!);
        }
      });
    } else {
      print('❌ Max reconnect attempts reached');
      _isConnecting = false;
    }
  }

  // ✉️ মেসেজ পাঠানো - STOMP ফরম্যাটে
  static void sendMessage(String groupId, String senderId, String content) {
    if (!_isConnected || _channel == null) {
      print('❌ Cannot send: WebSocket not connected');
      return;
    }

    try {
      final message = {
        'groupId': groupId,
        'senderId': senderId,
        'content': content,
      };

      // STOMP SEND ফ্রেম
      final sendFrame = [
        'SEND',
        'destination:/app/group.send',
        'content-type:application/json',
        'content-length:${jsonEncode(message).length}',
        '',
        jsonEncode(message),
        '\u0000'
      ].join('\n');
      
      _channel!.sink.add(sendFrame);
      print('📤 Message sent via STOMP');
      
    } catch (e) {
      print('❌ Error sending message: $e');
    }
  }

  // 📝 মেসেজ এডিট - STOMP ফরম্যাটে
  static void editMessage(String messageId, String newContent, String userId) {
    if (!_isConnected || _channel == null) {
      print('❌ Cannot edit: WebSocket not connected');
      return;
    }

    try {
      final message = {
        'messageId': messageId,
        'newContent': newContent,
        'userId': userId,
      };

      final editFrame = [
        'SEND',
        'destination:/app/group.edit',
        'content-type:application/json',
        'content-length:${jsonEncode(message).length}',
        '',
        jsonEncode(message),
        '\u0000'
      ].join('\n');
      
      _channel!.sink.add(editFrame);
      print('✏️ Edit message sent: $messageId');
      
    } catch (e) {
      print('❌ Error editing message: $e');
    }
  }

  // ❌ মেসেজ ডিলিট - STOMP ফরম্যাটে
  static void deleteMessage(String messageId, String userId) {
    if (!_isConnected || _channel == null) {
      print('❌ Cannot delete: WebSocket not connected');
      return;
    }

    try {
      final message = {
        'messageId': messageId,
        'userId': userId,
      };

      final deleteFrame = [
        'SEND',
        'destination:/app/group.delete',
        'content-type:application/json',
        'content-length:${jsonEncode(message).length}',
        '',
        jsonEncode(message),
        '\u0000'
      ].join('\n');
      
      _channel!.sink.add(deleteFrame);
      print('🗑️ Delete message sent: $messageId');
      
    } catch (e) {
      print('❌ Error deleting message: $e');
    }
  }

  // 👁️ মেসেজ রিড - STOMP ফরম্যাটে
  static void markAsRead(String messageId, String userId) {
    if (!_isConnected || _channel == null) {
      print('❌ Cannot mark as read: WebSocket not connected');
      return;
    }

    try {
      final message = {
        'messageId': messageId,
        'userId': userId,
      };

      final readFrame = [
        'SEND',
        'destination:/app/group.mark-read',
        'content-type:application/json',
        'content-length:${jsonEncode(message).length}',
        '',
        jsonEncode(message),
        '\u0000'
      ].join('\n');
      
      _channel!.sink.add(readFrame);
      print('👁️ Mark as read sent: $messageId');
      
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  // 📌 সংযোগ স্ট্যাটাস
  static bool isConnected() {
    return _isConnected && _channel != null;
  }

  // 📌 লিসেনার যোগ
  static void addMessageListener(Function(GroupMessageModel) listener) {
    if (!_messageListeners.contains(listener)) {
      _messageListeners.add(listener);
    }
  }

  static void addDeleteListener(Function(String) listener) {
    if (!_deleteListeners.contains(listener)) {
      _deleteListeners.add(listener);
    }
  }

  static void addEditListener(Function(GroupMessageModel) listener) {
    if (!_editListeners.contains(listener)) {
      _editListeners.add(listener);
    }
  }

  // 📌 লিসেনার রিমুভ
  static void removeMessageListener(Function(GroupMessageModel) listener) {
    _messageListeners.remove(listener);
  }

  static void removeDeleteListener(Function(String) listener) {
    _deleteListeners.remove(listener);
  }

  static void removeEditListener(Function(GroupMessageModel) listener) {
    _editListeners.remove(listener);
  }

  // 📌 লিসেনার নোটিফাই
  static void _notifyMessageListeners(GroupMessageModel message) {
    for (var listener in _messageListeners) {
      try {
        listener(message);
      } catch (e) {
        print('❌ Error in message listener: $e');
      }
    }
  }

  static void _notifyDeleteListeners(String messageId) {
    for (var listener in _deleteListeners) {
      try {
        listener(messageId);
      } catch (e) {
        print('❌ Error in delete listener: $e');
      }
    }
  }

  static void _notifyEditListeners(GroupMessageModel message) {
    for (var listener in _editListeners) {
      try {
        listener(message);
      } catch (e) {
        print('❌ Error in edit listener: $e');
      }
    }
  }

  // 🔌 সংযোগ বন্ধ
  static void disconnect() {
    try {
      if (_channel != null) {
        _channel!.sink.close();
      }
    } catch (e) {
      print('Error disconnecting: $e');
    }
    _channel = null;
    _currentGroupId = null;
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _messageListeners.clear();
    _deleteListeners.clear();
    _editListeners.clear();
    print('🔌 WebSocket disconnected');
  }
}