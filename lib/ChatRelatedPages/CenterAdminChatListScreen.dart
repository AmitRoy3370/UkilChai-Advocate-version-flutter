import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;
import 'package:advocatechaiadvocate/ChatRelatedPages/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocatechaiadvocate/ChatRelatedPages/chat_list_item.dart';

class CenterAdminChatListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const CenterAdminChatListScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  _CenterAdminChatListScreenState createState() =>
      _CenterAdminChatListScreenState();
}

class _CenterAdminChatListScreenState extends State<CenterAdminChatListScreen> {
  List<ChatListItem> _chatList = [];
  List<ChatListItem> _filteredChatList = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  TextEditingController _searchController = TextEditingController();

  // Center Admin Data
  List<dynamic> _centerAdmins = [];
  Map<String, dynamic> _userDetails = {};

  @override
  void initState() {
    super.initState();
    _loadChatList();
  }

  Future<void> _loadChatList() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Step 1: Get all center admins
      final centerAdminResponse = await http.get(
        Uri.parse('${BASE_URL.Urls().baseURL}center-admin/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (centerAdminResponse.statusCode == 200) {
        _centerAdmins = jsonDecode(centerAdminResponse.body);
        print('Loaded ${_centerAdmins.length} center admins');

        // Step 2: Get user details for each admin
        await _loadUserDetails(token);

        // Step 3: Build chat list
        await _buildChatList(token);
      } else {
        throw Exception(
          'Failed to load center admins: ${centerAdminResponse.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading chat list: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _loadUserDetails(String token) async {
    try {
      // Get user details for all userIds in center admins
      for (var admin in _centerAdmins) {
        String userId = admin['userId'];
        if (userId != widget.currentUserId) {
          // Skip current user
          final userResponse = await http.get(
            Uri.parse('${BASE_URL.Urls().baseURL}user/search?userId=$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (userResponse.statusCode == 200) {
            _userDetails[userId] = jsonDecode(userResponse.body);
          }
        }
      }
    } catch (e) {
      print('Error loading user details: $e');
    }
  }

  Future<void> _buildChatList(String token) async {
    List<ChatListItem> tempList = [];

    try {
      for (var admin in _centerAdmins) {
        String userId = admin['userId'];

        // Skip current user
        if (userId == widget.currentUserId) continue;

        // Get user name from user details or use fallback
        String userName = 'Unknown User';
        if (_userDetails.containsKey(userId)) {
          var userData = _userDetails[userId];
          userName = userData['name'] ?? userData['name'] ?? 'Unknown User';
        }

        // Get last message from chat history
        String? lastMessage;
        DateTime? lastMessageTime;
        int unreadCount = 0;

        try {
          final chatHistoryResponse = await http.get(
            Uri.parse(
              '${BASE_URL.Urls().baseURL}chat/history/${widget.currentUserId}/$userId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (chatHistoryResponse.statusCode == 200) {
            List<dynamic> messages = jsonDecode(chatHistoryResponse.body);
            if (messages.isNotEmpty) {
              // Sort by timestamp (newest first)
              messages.sort((a, b) {
                DateTime timeA = DateTime.parse(a['timeStamp']).toLocal();
                DateTime timeB = DateTime.parse(b['timeStamp']).toLocal();
                return timeB.compareTo(timeA);
              });

              print("current user id :- ${widget.currentUserId}");

              for (var msg in messages) {
                if (msg['receiver'] == widget.currentUserId) {
                  String chatId = msg['id'];

                  try {
                    final readResponse = await http.get(
                      Uri.parse(
                        '${BASE_URL.Urls().baseURL}readable-chat/chat/$chatId',
                      ),
                      headers: {'Authorization': 'Bearer $token'},
                    );

                    if (readResponse.statusCode == 200) {
                      var readable = jsonDecode(readResponse.body);

                      if (readable['read'] == false) {
                        unreadCount++;
                      }
                    } else {
                      // If readability not found → treat as unread
                      unreadCount++;
                    }
                  } catch (_) {
                    unreadCount++;
                  }
                }
              }

              print("total un read message :- $unreadCount");

              // Get latest message
              var lastMsg = messages.first;
              lastMessage = lastMsg['content'];
              lastMessageTime = DateTime.parse(lastMsg['timeStamp']).toLocal();

              // Calculate unread messages (messages where receiver is current user and not read)
              /*unreadCount = messages.where((msg) {
                return msg['receiver'] == widget.currentUserId &&
                    (msg['read'] == null || msg['read'] == false);
              }).length;*/
            }
          }
        } catch (e) {
          print('Error loading chat history for $userId: $e');
        }

        // Create chat list item
        tempList.add(
          ChatListItem(
            userId: userId,
            userName: userName,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            unreadCount: unreadCount,
          ),
        );
      }

      // Sort by last message time (most recent first)
      tempList.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      setState(() {
        _chatList = tempList;
        _filteredChatList = List.from(_chatList);
        _isLoading = false;
      });
    } catch (e) {
      print('Error building chat list: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error building chat list: $e';
        _isLoading = false;
      });
    }
  }

  void _filterChatList(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredChatList = List.from(_chatList);
      });
      return;
    }

    final filtered = _chatList.where((chat) {
      return chat.userName.toLowerCase().contains(query.toLowerCase()) ||
          (chat.lastMessage?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();

    setState(() {
      _filteredChatList = filtered;
    });
  }

  void _refreshChatList() async {
    await _loadChatList();
  }

  Future<void> _markChatAsRead(String otherUserId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      final historyResponse = await http.get(
        Uri.parse(
          '${BASE_URL.Urls().baseURL}chat/history/${widget.currentUserId}/$otherUserId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (historyResponse.statusCode == 200) {
        List<dynamic> messages = jsonDecode(historyResponse.body);

        for (var msg in messages) {
          if (msg['receiver'] == widget.currentUserId) {
            await http.put(
              Uri.parse(
                '${BASE_URL.Urls().baseURL}readable-chat/update/${msg['id']}/${widget.currentUserId}',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({"chatId": msg['id'], "isRead": true}),
            );
          }
        }
      }
    } catch (e) {
      print("Error marking chat read: $e");
    }
  }

  void _navigateToChat(String userId, String userName) async {
    await _markChatAsRead(userId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: widget.currentUserId,
          otherUser: userId,
          othersName: userName,
          myName: widget.currentUserName,
        ),
      ),
    );
  }

  Widget _buildChatListItem(ChatListItem chat) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            chat.userName.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.userName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  FutureBuilder<bool>(
                    future: isActive(chat.userId),
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
            ),
            if (chat.unreadCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  chat.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.lastMessage != null)
              Text(
                chat.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
            SizedBox(height: 4),
            if (chat.lastMessageTime != null)
              Text(
                _formatTime(chat.lastMessageTime!),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),

        onTap: () => _navigateToChat(chat.userId, chat.userName),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return DateFormat('hh:mm a').format(time);
    } else if (messageDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Loading chats...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'Error loading chats',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshChatList,
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          SizedBox(height: 20),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Start a conversation with other center admins',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshChatList,
            child: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Center Admin Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshChatList,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onChanged: _filterChatList,
            ),
          ),
          Divider(height: 1),
          // Chat List
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _hasError
                ? _buildErrorState()
                : _filteredChatList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadChatList();
                    },
                    child: ListView.builder(
                      itemCount: _filteredChatList.length,
                      itemBuilder: (context, index) {
                        return _buildChatListItem(_filteredChatList[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
