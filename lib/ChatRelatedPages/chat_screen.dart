import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../ChatRelatedPages/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String? currentUser;
  final String? otherUser;
  final String? othersName;
  final String? myName;
  final String? otherUserId;

  const ChatScreen({
    Key? key,
    required this.currentUser,
    required this.otherUser,
    required this.othersName,
    required this.myName,
    this.otherUserId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _readStatus = {};

  // State
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  // Polling
  Timer? _pollingTimer;
  bool _isPolling = false;
  static const int _pollingInterval = 3; // seconds

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('📱 ChatScreen initialized');

    _loadChatHistory();
    _startPolling();
    _startReadStatusPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed - restarting polling');
        _startPolling();
        _loadChatHistory();
        break;
      case AppLifecycleState.paused:
        print('📱 App paused - stopping polling');
        _stopPolling();
        break;
      default:
        break;
    }
  }

  // ==================== Polling Engine ====================

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollForNewMessages();
    _pollingTimer = Timer.periodic(Duration(seconds: _pollingInterval), (timer) {
      _pollForNewMessages();
    });
    print('✅ HTTP polling started (interval: ${_pollingInterval}s)');
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    print('⏹️ HTTP polling stopped');
  }

  Future<void> _pollForNewMessages() async {
    if (widget.currentUser == null || widget.otherUser == null || !mounted) {
      return;
    }
    if (_isLoading) return;

    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';
      final token = await _getToken();
      if (token == null) return;

      final response = await http
          .get(
            Uri.parse(
                '$apiBaseUrl/history/${widget.currentUser}/${widget.otherUser}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<String, ChatMessage> serverMessages = {
          for (var item in data) item['id']: ChatMessage.fromJson(item)
        };

        bool needsUpdate = false;

        // 1. Check for Deleted Messages
        final List<String> currentIds = _messages.map((m) => m.id).toList();
        for (var id in currentIds) {
          if (!serverMessages.containsKey(id)) {
            setState(() {
              _messages.removeWhere((m) => m.id == id);
            });
            needsUpdate = true;
            print('🗑️ Polling detected message deletion: $id');
          }
        }

        // 2. Check for Edits and New Messages
        final List<ChatMessage> newlyReceived = [];

        for (var entry in serverMessages.entries) {
          final String serverId = entry.key;
          final ChatMessage serverMsg = entry.value;

          final int localIndex = _messages.indexWhere((m) => m.id == serverId);

          if (localIndex == -1) {
            setState(() {
              _messages.add(serverMsg);
              _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
            });
            needsUpdate = true;
            print('📨 Polling detected new message: ${serverMsg.id}');

            if (serverMsg.receiver == widget.currentUser) {
              newlyReceived.add(serverMsg);
            }
          } else {
            final ChatMessage localMsg = _messages[localIndex];
            if (localMsg.content != serverMsg.content) {
              setState(() {
                _messages[localIndex] = serverMsg;
                _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
              });
              needsUpdate = true;
              print('✏️ Polling detected message edit: ${serverMsg.id}');
            }
          }
        }

        // ✅ Mark newly received messages as read — in parallel
        if (newlyReceived.isNotEmpty) {
          await Future.wait(
            newlyReceived.map((m) => _markMessageAsRead(m)),
          );
        }

        if (needsUpdate) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  // ==================== HTTP Operations ====================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      final response = await http
          .get(
            Uri.parse(
                '$apiBaseUrl/history/${widget.currentUser}/${widget.otherUser}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 22));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.clear();
          _messages
              .addAll(data.map((msg) => ChatMessage.fromJson(msg)).toList());
          _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
          _isLoading = false;
        });

        // ✅ Read status + mark-as-read in parallel
        await _loadReadStatus();

        final receivedMessages = _messages
            .where((m) => m.receiver == widget.currentUser)
            .toList();

        if (receivedMessages.isNotEmpty) {
          await Future.wait(
            receivedMessages.map((m) => _markMessageAsRead(m)),
          );
        }

        _scrollToBottom();
        print('📚 Loaded ${_messages.length} messages');
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('❌ Error loading history: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessage(
      id: tempId,
      sender: widget.currentUser!,
      receiver: widget.otherUser!,
      content: content,
      timeStamp: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMessage);
      _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
      _textController.clear();
    });
    _scrollToBottom();

    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sender': widget.currentUser,
          'receiver': widget.otherUser,
          'content': content,
        }),
      );

      if (response.statusCode == 201 && mounted) {
        final data = jsonDecode(response.body);
        final newMsg = ChatMessage.fromJson(data);

        setState(() {
          _messages.removeWhere((m) => m.id == tempId);
          final exists = _messages.any((m) => m.id == newMsg.id);
          if (!exists) {
            _messages.add(newMsg);
            _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
          }
          _isSending = false;
        });
        print('✅ Message sent via HTTP');
      } else {
        throw Exception('Failed to send');
      }
    } catch (e) {
      print('❌ Send error: $e');
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
        _isSending = false;
      });
      _showErrorSnackBar('Failed to send message');
    }
  }

  Future<void> _editMessage(ChatMessage msg, String newText) async {
    final int index = _messages.indexWhere((m) => m.id == msg.id);
    if (index == -1) return;

    final ChatMessage updatedMsg = ChatMessage(
      id: msg.id,
      sender: msg.sender,
      receiver: msg.receiver,
      content: newText,
      timeStamp: msg.timeStamp,
    );

    setState(() {
      _messages[index] = updatedMsg;
    });

    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.put(
        Uri.parse(
            "${BASE_URL.Urls().baseURL}chat/edit/${msg.sender}/${msg.id}?newContent=$newText"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200 && mounted) {
        print('❌ Edit failed on server');
        _showErrorSnackBar('Failed to edit message');
        setState(() {
          _messages[index] = msg;
        });
      } else {
        print('✅ Message edited');
      }
    } catch (e) {
      print("Edit error: $e");
      _showErrorSnackBar('Error editing message');
      if (mounted) {
        setState(() {
          _messages[index] = msg;
        });
      }
    }
  }

  Future<void> _deleteMessage(ChatMessage msg) async {
    setState(() {
      _messages.removeWhere((m) => m.id == msg.id);
    });

    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse(
            "${BASE_URL.Urls().baseURL}chat/delete/${msg.sender}/${msg.receiver}/${msg.id}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200 && mounted) {
        print('❌ Delete failed on server');
        _showErrorSnackBar('Failed to delete message');
        _loadChatHistory();
      } else {
        print('✅ Message deleted');
      }
    } catch (e) {
      print("Delete error: $e");
      _showErrorSnackBar('Error deleting message');
    }
  }

  // ==================== READ RECEIPT ====================
  // ✅ Uses `read: true` (matches backend field)
  // ✅ Tries PUT first; falls back to POST /add only if PUT fails
  Future<void> _markMessageAsRead(ChatMessage message) async {
    if (message.id == null || message.id!.isEmpty) return;

    try {
      final token = await _getToken();
      if (token == null) return;

      final readableBase = '${BASE_URL.Urls().baseURL}readable-chat';

      // 1. Try to update the existing record
      final updateResponse = await http.put(
        Uri.parse('$readableBase/update/${message.id}/${widget.currentUser}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "chatId": message.id,
          "read": true,
        }),
      );

      print('📖 Mark-as-read update: ${updateResponse.statusCode} — ${updateResponse.body}');

      // 2. Fall back to POST only if the update failed
      if (updateResponse.statusCode != 200) {
        final createResponse = await http.post(
          Uri.parse('$readableBase/add/${widget.currentUser}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "chatId": message.id,
            "read": true,
          }),
        );
        print('📖 Mark-as-read create: ${createResponse.statusCode} — ${createResponse.body}');
      }

      if (mounted) {
        setState(() {
          _readStatus[message.id!] = true;
        });
      }
    } catch (e) {
      print('❌ Mark as read error: $e');
    }
  }

  // ==================== PARALLEL: Load read status ====================
  Future<void> _loadReadStatus() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final readableBase = '${BASE_URL.Urls().baseURL}readable-chat';

      // Only sent messages need read status fetched
      final sentMessages =
          _messages.where((m) => m.sender == widget.currentUser).toList();

      if (sentMessages.isEmpty) return;

      // ✅ Fire all requests in parallel
      final results = await Future.wait(
        sentMessages.map((msg) => _fetchReadStatusFor(msg, readableBase, token)),
      );

      if (mounted) {
        setState(() {
          for (final entry in results) {
            if (entry != null) {
              _readStatus[entry.$1] = entry.$2;
            }
          }
        });
      }
    } catch (e) {
      print('❌ Read status load error: $e');
    }
  }

  /// Helper: fetch read status for one message, return (msgId, isRead).
  Future<(String, bool)?> _fetchReadStatusFor(
    ChatMessage msg,
    String readableBase,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$readableBase/chat/${msg.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print(
            '🔍 LOAD READ — msgId=${msg.id} → ${response.statusCode} ${response.body}');

        final raw = jsonDecode(response.body);
        Map<String, dynamic>? data;
        if (raw is List && raw.isNotEmpty) {
          data = raw.first as Map<String, dynamic>;
        } else if (raw is Map<String, dynamic>) {
          data = raw;
        }

        if (data != null) {
          final isRead =
              (data['isRead'] == true) || (data['read'] == true);
          return (msg.id!, isRead);
        }
        return (msg.id!, false);
      } else {
        print(
            '🔍 LOAD READ — msgId=${msg.id} → HTTP ${response.statusCode}');
        return (msg.id!, false);
      }
    } catch (e) {
      return (msg.id!, false);
    }
  }

  Timer? _readStatusTimer;
  static const int _readStatusPollingInterval = 5;

  void _startReadStatusPolling() {
    _readStatusTimer?.cancel();
    _readStatusTimer =
        Timer.periodic(Duration(seconds: _readStatusPollingInterval), (timer) {
      _pollForReadStatus();
    });
  }

  // ==================== PARALLEL: Poll read status ====================
  Future<void> _pollForReadStatus() async {
    if (widget.currentUser == null || !mounted) return;

    try {
      final token = await _getToken();
      if (token == null) return;

      final readableBase = '${BASE_URL.Urls().baseURL}readable-chat';

      final sentMessages =
          _messages.where((m) => m.sender == widget.currentUser).toList();

      if (sentMessages.isEmpty) return;

      // ✅ Fire all requests in parallel
      final results = await Future.wait(
        sentMessages.map((msg) => _pollReadStatusFor(msg, readableBase, token)),
      );

      bool statusChanged = false;
      for (final entry in results) {
        if (entry == null) continue;
        final (msgId, isRead) = entry;
        if (_readStatus[msgId] != isRead) {
          _readStatus[msgId] = isRead;
          statusChanged = true;
        }
      }

      if (statusChanged && mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Helper: poll read status for one message, return (msgId, isRead).
  Future<(String, bool)?> _pollReadStatusFor(
    ChatMessage msg,
    String readableBase,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$readableBase/chat/${msg.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print(
            '🔍 SENDER POLL — msgId=${msg.id} → ${response.statusCode} ${response.body}');

        final raw = jsonDecode(response.body);
        Map<String, dynamic>? data;
        if (raw is List && raw.isNotEmpty) {
          data = raw.first as Map<String, dynamic>;
        } else if (raw is Map<String, dynamic>) {
          data = raw;
        }

        if (data != null) {
          final isRead =
              (data['isRead'] == true) || (data['read'] == true);
          return (msg.id!, isRead);
        }
      } else {
        print(
            '🔍 SENDER POLL — msgId=${msg.id} → HTTP ${response.statusCode}');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== UI Helpers ====================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3)),
    );
  }

  Future<bool> isActive(String? userId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final response = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$userId"),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== UI Builders ====================

  Widget _buildReadTick(ChatMessage msg) {
    final isRead = _readStatus[msg.id] == true;
    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 16,
      color: isRead ? Colors.lightBlueAccent : Colors.white70,
    );
  }

  Widget _buildStatusText() {
    return FutureBuilder<bool>(
      future: isActive(widget.otherUser),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: snapshot.data! ? Colors.green : Colors.red)),
              SizedBox(width: 6),
              Text(snapshot.data! ? 'Online' : 'Offline',
                  style: TextStyle(
                      fontSize: 12,
                      color: snapshot.data! ? Colors.green : Colors.red)),
            ],
          );
        }
        return Text('Offline',
            style: TextStyle(fontSize: 12, color: Colors.red));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.othersName ?? 'Chat',
                style: TextStyle(fontWeight: FontWeight.bold)),
            _buildStatusText(),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPolling ? Colors.green : Colors.red),
                ),
                SizedBox(width: 4),
                Text(_isPolling ? 'Live' : 'Connecting...',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off,
                                  size: 64, color: Colors.red[300]),
                              SizedBox(height: 20),
                              Text('Server is waking up...',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[300])),
                              SizedBox(height: 10),
                              Text(
                                  'The server might be sleeping. Please tap "Wake Up Server" and wait 20 seconds.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600])),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadChatHistory,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12)),
                                child: Text('🟢 Wake Up Server'),
                              ),
                            ],
                          ),
                        )
                      : _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 64, color: Colors.grey[300]),
                                  SizedBox(height: 16),
                                  Text('No messages yet',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600])),
                                  SizedBox(height: 8),
                                  Text('Send a message to start chatting!',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                print('🔄 User pulled to refresh chat...');
                                await _loadChatHistory();
                              },
                              color: Colors.blue,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  final isMe =
                                      msg.sender == widget.currentUser;
                                  return _buildMessageBubble(msg, isMe);
                                },
                              ),
                            ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ChatMessage msg) {
    TextEditingController editController =
        TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Message"),
        content: TextField(
            controller: editController,
            decoration: InputDecoration(hintText: "Edit your message")),
        actions: [
          TextButton(
              child: Text("Cancel"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: Text("Save"),
            onPressed: () async {
              String newText = editController.text.trim();
              if (newText.isEmpty) return;
              await _editMessage(msg, newText);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final isPending = msg.id.startsWith('temp_');

    return GestureDetector(
      onLongPress: isPending
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMe) ...[
                        ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text("Edit Message"),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditDialog(msg);
                          },
                        ),
                        Divider(height: 1),
                      ],
                      ListTile(
                        leading: Icon(Icons.delete,
                            color: isMe ? Colors.red : Colors.grey),
                        title: Text("Delete Message",
                            style: TextStyle(
                                color: isMe ? Colors.red : Colors.grey)),
                        onTap: isMe
                            ? () {
                                Navigator.pop(context);
                                _deleteMessage(msg);
                              }
                            : null,
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                    widget.othersName?.isNotEmpty == true
                        ? widget.othersName![0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue[600] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight:
                        isMe ? Radius.circular(4) : Radius.circular(16),
                    bottomLeft:
                        isMe ? Radius.circular(16) : Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      Text(widget.othersName ?? 'User',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800])),
                      SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Expanded(
                            child: Text(msg.content,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: isMe ? Colors.white : Colors.black))),
                        if (isPending)
                          SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white))),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('hh:mm a').format(msg.timeStamp),
                            style: TextStyle(
                                fontSize: 11,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.grey[600])),
                        if (isMe && !isPending) ...[
                          SizedBox(width: 6),
                          _buildReadTick(msg)
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    bool hasText = _textController.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    hasText && !_isSending ? Colors.blue : Colors.grey[300]),
            child: IconButton(
              icon: Icon(_isSending ? Icons.hourglass_empty : Icons.send,
                  color: Colors.white),
              onPressed: (hasText && !_isSending) ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _readStatusTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}