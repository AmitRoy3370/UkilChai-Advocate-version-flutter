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
  static const int _pollingInterval = 3; // seconds

  // Connection status
  bool _isConnected = false;
  bool _isUsingWebSocket = false; // Set to false to use HTTP polling

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print(
      'ChatScreen initialized for ${widget.currentUser} -> ${widget.otherUser}',
    );
    _loadChatHistory();
    _startPolling();
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
    _isConnected = true; // We consider HTTP as "connected" since it's working

    // Initial poll immediately
    _pollForNewMessages();

    // Set up periodic polling
    _pollingTimer = Timer.periodic(Duration(seconds: _pollingInterval), (
        timer,
        ) {
      _pollForNewMessages();
    });

    print('✅ HTTP polling started (interval: ${_pollingInterval}s)');
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    _isConnected = false;
    print('⏹️ HTTP polling stopped');
  }

  Future<void> _pollForNewMessages() async {
    if (widget.currentUser == null || widget.otherUser == null) return;

    try {
      final apiBaseUrl = '${BASE_URL.Urls().baseURL}chat';

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/history/${widget.currentUser}/${widget.otherUser}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<ChatMessage> newMessages = data
            .map((msg) => ChatMessage.fromJson(msg))
            .where(
              (msg) =>
          // Only get messages after last poll time
          msg.timeStamp.isAfter(_lastPollTime) &&
              // Don't add messages we already have
              !_messages.any((existing) => existing.id == msg.id),
        )
            .toList();

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

        // Update last poll time
        _lastPollTime = DateTime.now();
      }
    } catch (e) {
      print('Polling error: $e');
      // Don't stop polling on error, just log it
    }
  }

  void _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    print('📤 Sending message: $content');

    // Always use HTTP for sending
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
      setState(() {
        final newMessage = ChatMessage.fromJson(data);

        // Check if message already exists (prevent duplicates)
        final exists = _messages.any((msg) => msg.id == newMessage.id);
        if (!exists) {
          _messages.add(newMessage);
          _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));

          // Mark as read if it's for current user
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

      // Check if readability record exists
      final checkResponse = await http.get(
        Uri.parse('$readableBase/chat/${message.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (checkResponse.statusCode == 200) {
        // Update existing record
        await http.put(
          Uri.parse('$readableBase/update/${message.id}/${widget.currentUser}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({"chatId": message.id, "read": true}),
        );

        setState(() {
          _readStatus[message.id!] = true;
        });
      } else if (checkResponse.statusCode == 404) {
        // Create new record
        await http.post(
          Uri.parse('$readableBase/add/${widget.currentUser}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({"chatId": message.id, "read": true}),
        );

        setState(() {
          _readStatus[message.id!] = true;
        });
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
        Uri.parse(
          '$apiBaseUrl/history/${widget.currentUser}/${widget.otherUser}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll(
            data.map((msg) => ChatMessage.fromJson(msg)).toList(),
          );
          _messages.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        });

        // Load read status for sent messages
        await _loadReadStatus();

        // Mark received messages as read
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
  static const int _readStatusPollingInterval = 5; // seconds

  void _stopReadStatusPolling() {
    _readStatusTimer?.cancel();
    _readStatusTimer = null;
    print('⏹️ Read status polling stopped');
  }

  void _startReadStatusPolling() {
    _readStatusTimer?.cancel();

    // Poll for read status updates
    _readStatusTimer = Timer.periodic(
      Duration(seconds: _readStatusPollingInterval),
          (timer) {
        _pollForReadStatus();
      },
    );

    print('✅ Read status polling started');
  }

  Future<void> _pollForReadStatus() async {
    if (widget.currentUser == null) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final readableBase = '${BASE_URL.Urls().baseURL}readable-chat';

      bool statusChanged = false;

      // Check read status for all messages sent by current user
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

              // If status changed, update it
              if (_readStatus[msg.id] != currentReadStatus) {
                _readStatus[msg.id] = currentReadStatus;
                statusChanged = true;
                print(
                  '📨 Read status updated for message ${msg.id}: $currentReadStatus',
                );
              }
            }
          } catch (e) {
            print('Error checking read status: $e');
          }
        }
      }

      // Refresh UI if any status changed
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildReadTick(ChatMessage msg) {
    final isRead = _readStatus[msg.id] == true;

    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 16,
      color: isRead ? Colors.lightBlueAccent : Colors.white70,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> isActive(String? userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$userId"),
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.othersName ?? 'Chat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            FutureBuilder<bool>(
              future: isActive(widget.otherUser),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data! ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: snapshot.data! ? Colors.green : Colors.red,
                    ),
                  );
                } else {
                  return Text(
                    'Offline',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  );
                }
              },
            ),
          ],
        ),

        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
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
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Send a message to start chatting!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
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

  Future<void> _deleteMessage(ChatMessage msg) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse(
          "${BASE_URL.Urls().baseURL}chat/delete/${msg.sender}/${msg.receiver}/${msg.id}",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages.removeWhere((m) => m.id == msg.id);
        });
      }
    } catch (e) {
      print("Delete error: $e");
    }
  }

  Future<void> _editMessage(ChatMessage msg, String newText) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? token = prefs.getString('jwt_token');

      final response = await http.put(
        Uri.parse(
          "${BASE_URL.Urls().baseURL}chat/edit/${msg.sender}/${msg.id}?newContent=$newText",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          msg.content = newText;
        });
      }
    } catch (e) {
      print("Edit error: $e");
    }
  }

  void _showEditDialog(ChatMessage msg) {
    TextEditingController editController = TextEditingController(
      text: msg.content,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Message"),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(hintText: "Edit your message"),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),

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
        );
      },
    );
  }

  void _showMessageOptions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit Message"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(msg);
                },
              ),

              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text("Delete Message"),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[600] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      widget.othersName ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),

                  if (!isMe) SizedBox(height: 2),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          msg.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),

                      if (isMe)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: isMe ? Colors.white70 : Colors.grey[700],
                          ),
                          onSelected: (value) {
                            if (value == "edit") {
                              _showEditDialog(msg);
                            } else if (value == "delete") {
                              _deleteMessage(msg);
                            }
                          },
                          itemBuilder: (context) {
                            final isMe = msg.sender == widget.currentUser;

                            return [
                              if (isMe)
                                PopupMenuItem(
                                  value: "edit",
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text("Edit"),
                                    ],
                                  ),
                                ),

                              if (isMe)
                                PopupMenuItem(
                                  value: "delete",
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text("Delete"),
                                    ],
                                  ),
                                ),
                            ];
                          },
                        ),
                    ],
                  ),

                  SizedBox(height: 4),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(msg.timeStamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),

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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          SizedBox(width: 8),

          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasText ? Colors.blue : Colors.grey[300],
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: hasText ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }
}
