import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;
import 'package:advocatechaiadvocate/ChatRelatedPages/chat_message.dart';
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

  // Polling
  Timer? _pollingTimer;
  DateTime _lastPollTime = DateTime.now().subtract(Duration(minutes: 1));
  bool _isPolling = false;
  static const int _pollingInterval = 2; // seconds - faster for better UX

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('ChatScreen initialized for ${widget.currentUser} -> ${widget.otherUser}');

    _loadChatHistory();
    _startPolling();
    _startReadStatusPolling();
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed - restarting polling');
        _startPolling();
        _loadChatHistory(); // Refresh immediately on resume
        break;
      case AppLifecycleState.paused:
        print('App paused - stopping polling');
        _stopPolling();
        break;
      default:
        break;
    }
  }

  void _startPolling() {
    if (_isPolling) return;

    _isPolling = true;

    // Initial poll immediately
    _pollForNewMessages();

    // Set up periodic polling
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
    if (widget.currentUser == null || widget.otherUser == null) return;
    if (!mounted) return;

    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/history/${widget.currentUser}/${widget.otherUser}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        final Set<String> existingIds = _messages.map((m) => m.id).toSet();

        List<ChatMessage> newMessages = [];

        for (var msgData in data) {
          final msg = ChatMessage.fromJson(msgData);
          if (!existingIds.contains(msg.id)) {
            newMessages.add(msg);
          }
        }

        if (newMessages.isNotEmpty) {
          print('📨 Received ${newMessages.length} new messages via polling');

          setState(() {
            _messages.addAll(newMessages);
            _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
          });

          // Mark received messages as read
          for (var msg in newMessages) {
            if (msg.receiver == widget.currentUser) {
              await _markMessageAsRead(msg);
            }
          }

          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Polling error: $e');
    }
  }

  void _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    print('📤 Sending message: $content');
    await _sendMessageViaHttp(content);
  }

  Future<void> _sendMessageViaHttp(String content) async {
    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

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

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _addMessageFromData(data);
        _textController.clear();
        print('✅ Message sent via HTTP');
      } else {
        print('❌ HTTP send failed: ${response.statusCode}');
        _showErrorSnackBar('Failed to send message');
      }
    } catch (e) {
      print('❌ HTTP send error: $e');
      _showErrorSnackBar('Error sending message');
    }
  }

  void _addMessageFromData(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        final newMessage = ChatMessage.fromJson(data);
        final exists = _messages.any((msg) => msg.id == newMessage.id);
        if (!exists) {
          _messages.add(newMessage);
          _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));

          if (newMessage.receiver == widget.currentUser) {
            _markMessageAsRead(newMessage);
          }
        }
      });
      _scrollToBottom();
    });
  }

  Future<void> _markMessageAsRead(ChatMessage message) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final readableBase = '${BASE_URL.Urls().baseURL}readable-chat';

      final checkResponse = await http.get(
        Uri.parse('$readableBase/chat/${message.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (checkResponse.statusCode == 200) {
        await http.put(
          Uri.parse('$readableBase/update/${message.id}/${widget.currentUser}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({"chatId": message.id, "read": true}),
        );

        if (mounted) {
          setState(() {
            _readStatus[message.id!] = true;
          });
        }
      } else if (checkResponse.statusCode == 404) {
        await http.post(
          Uri.parse('$readableBase/add/${widget.currentUser}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({"chatId": message.id, "read": true}),
        );

        if (mounted) {
          setState(() {
            _readStatus[message.id!] = true;
          });
        }
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/history/${widget.currentUser}/${widget.otherUser}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll(data.map((msg) => ChatMessage.fromJson(msg)).toList());
          _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        });

        await _loadReadStatus();

        for (var msg in _messages) {
          if (msg.receiver == widget.currentUser) {
            await _markMessageAsRead(msg);
          }
        }

        _scrollToBottom();
        print('Loaded ${_messages.length} messages');
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _loadReadStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      final readableBase = '${BASE_URL.Urls().baseURL}readable-chat';

      for (var msg in _messages) {
        if (msg.sender == widget.currentUser) {
          try {
            final response = await http.get(
              Uri.parse('$readableBase/chat/${msg.id}'),
              headers: {'Authorization': 'Bearer $token'},
            );
            if (response.statusCode == 200) {
              var data = jsonDecode(response.body);
              _readStatus[msg.id!] = data['read'] == true;
            }
          } catch (e) {
            _readStatus[msg.id!] = false;
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      print('Read status load error: $e');
    }
  }

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

  Timer? _readStatusTimer;
  static const int _readStatusPollingInterval = 5;

  void _startReadStatusPolling() {
    _readStatusTimer?.cancel();
    _readStatusTimer = Timer.periodic(Duration(seconds: _readStatusPollingInterval), (timer) {
      _pollForReadStatus();
    });
    print('✅ Read status polling started');
  }

  Future<void> _pollForReadStatus() async {
    if (widget.currentUser == null || !mounted) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      final readableBase = '${BASE_URL.Urls().baseURL}readable-chat';
      bool statusChanged = false;

      for (var msg in _messages) {
        if (msg.sender == widget.currentUser) {
          try {
            final response = await http.get(
              Uri.parse('$readableBase/chat/${msg.id}'),
              headers: {'Authorization': 'Bearer $token'},
            );
            if (response.statusCode == 200) {
              var data = jsonDecode(response.body);
              bool currentReadStatus = data['read'] == true;
              if (_readStatus[msg.id] != currentReadStatus) {
                _readStatus[msg.id] = currentReadStatus;
                statusChanged = true;
              }
            }
          } catch (e) {
            print('Error checking read status: $e');
          }
        }
      }

      if (statusChanged && mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Read status polling error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: Duration(seconds: 3)),
    );
  }

  Widget _buildReadTick(ChatMessage msg) {
    final isRead = _readStatus[msg.id] == true;
    return Icon(isRead ? Icons.done_all : Icons.done, size: 16, color: isRead ? Colors.lightBlueAccent : Colors.white70);
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

  Future<bool> isActive(String? userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    final response = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$userId"),
      headers: {'content-type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.othersName ?? 'Chat', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    color: _isPolling ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  _isPolling ? 'Live' : 'Connecting...',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text('No messages yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    SizedBox(height: 8),
                    Text('Send a message to start chatting!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg.sender == widget.currentUser;
                  return _buildMessageBubble(msg, isMe);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    return FutureBuilder<bool>(
      future: isActive(widget.otherUser),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data! ? 'Online' : 'Offline',
            style: TextStyle(fontSize: 12, color: snapshot.data! ? Colors.green : Colors.red),
          );
        }
        return Text('Offline', style: TextStyle(fontSize: 12, color: Colors.red));
      },
    );
  }

  Future<void> _deleteMessage(ChatMessage msg) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse("${BASE_URL.Urls().baseURL}chat/delete/${msg.sender}/${msg.receiver}/${msg.id}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == msg.id);
        });
        print('✅ Message deleted');
      }
    } catch (e) {
      print("Delete error: $e");
      _showErrorSnackBar('Error deleting message');
    }
  }

  Future<void> _editMessage(ChatMessage msg, String newText) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.put(
        Uri.parse("${BASE_URL.Urls().baseURL}chat/edit/${msg.sender}/${msg.id}?newContent=$newText"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          msg.content = newText;
        });
        print('✅ Message edited');
      }
    } catch (e) {
      print("Edit error: $e");
      _showErrorSnackBar('Error editing message');
    }
  }

  void _showEditDialog(ChatMessage msg) {
    TextEditingController editController = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Message"),
        content: TextField(controller: editController, decoration: InputDecoration(hintText: "Edit your message")),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context)),
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

  void _showMessageOptions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Edit Message"),
              onTap: () { Navigator.pop(context); _showEditDialog(msg); },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text("Delete Message"),
              onTap: () { Navigator.pop(context); _deleteMessage(msg); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[600] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(widget.othersName ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                    SizedBox(height: 2),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(msg.content, style: TextStyle(fontSize: 16, color: isMe ? Colors.white : Colors.black))),
                      if (isMe)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 18, color: isMe ? Colors.white70 : Colors.grey[700]),
                          onSelected: (value) {
                            if (value == "edit") _showEditDialog(msg);
                            else if (value == "delete") _deleteMessage(msg);
                          },
                          itemBuilder: (context) => [
                            if (msg.sender == widget.currentUser)
                              PopupMenuItem(value: "edit", child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Edit")])),
                            if (msg.sender == widget.currentUser)
                              PopupMenuItem(value: "delete", child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Delete")])),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('hh:mm a').format(msg.timeStamp), style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Colors.grey[600])),
                      if (isMe) SizedBox(width: 6),
                      if (isMe) _buildReadTick(msg),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    bool hasText = _textController.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(shape: BoxShape.circle, color: hasText ? Colors.blue : Colors.grey[300]),
            child: IconButton(icon: Icon(Icons.send, color: Colors.white), onPressed: hasText ? _sendMessage : null),
          ),
        ],
      ),
    );
  }
}