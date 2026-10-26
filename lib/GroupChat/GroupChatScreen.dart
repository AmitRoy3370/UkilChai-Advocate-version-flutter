// GroupChatScreen.dart - ডুপ্লিকেট ফিক্স সহ সম্পূর্ণ ফাইল

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../GroupChat/GroupChatModels.dart';
import '../GroupChat/GroupChatServices.dart';
import '../GroupChat/GroupChatWebSocket.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUserId;
  final String currentUserName;
  final bool isAdmin;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    required this.currentUserName,
    required this.isAdmin,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  List<GroupMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final TextEditingController _messageController = TextEditingController();
  final GroupChatServices _services = GroupChatServices();
  bool _isSending = false;
  int _page = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _isWebSocketConnected = false;

  // 📌 ডুপ্লিকেট মেসেজ এড়ানোর জন্য সেট
  final Set<String> _processedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWebSocket();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 0 && _hasMore && !_isLoadingMore && !_isLoading) {
        _loadMoreMessages();
      }
    });
  }

  // ==================== WebSocket সংযোগ ====================
  
  void _connectWebSocket() async {
    try {
      GroupChatWebSocket.addMessageListener(_onNewMessage);
      GroupChatWebSocket.addDeleteListener(_onMessageDeleted);
      GroupChatWebSocket.addEditListener(_onMessageEdited);
      
      await GroupChatWebSocket.connect(widget.groupId);
      
      setState(() {
        _isWebSocketConnected = GroupChatWebSocket.isConnected();
      });
      
      print('✅ WebSocket connected: $_isWebSocketConnected');
    } catch (e) {
      print('❌ WebSocket connection error: $e');
      setState(() {
        _isWebSocketConnected = false;
      });
    }
  }

  // ==================== WebSocket ইভেন্ট হ্যান্ডলার ====================

  void _onNewMessage(GroupMessageModel message) {
    if (message.groupId == widget.groupId) {
      print('📨 WebSocket message received: ${message.id} - ${message.content}');
      
      // ✅ ডুপ্লিকেট চেক - মেসেজ আইডি দিয়ে
      if (!_processedMessageIds.contains(message.id)) {
        _processedMessageIds.add(message.id);
        
        // চেক করুন মেসেজটি ইতিমধ্যে লিস্টে আছে কিনা
        bool exists = _messages.any((msg) => msg.id == message.id);
        
        if (!exists) {
          setState(() {
            _messages.add(message);
            _sortMessagesByTime();
          });
          _scrollToBottom();
          print('✅ New message added: ${message.id}');
        }
      } else {
        print('⏭️ Duplicate message ignored (WebSocket): ${message.id}');
      }
    }
  }

  void _onMessageDeleted(String messageId) {
    setState(() {
      _messages.removeWhere((msg) => msg.id == messageId);
      _processedMessageIds.remove(messageId);
    });
  }

  void _onMessageEdited(GroupMessageModel message) {
    if (message.groupId == widget.groupId) {
      setState(() {
        int index = _messages.indexWhere((msg) => msg.id == message.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            content: message.content,
            edited: message.edited,
          );
        }
      });
    }
  }

  // ==================== মেসেজ লোডিং ====================

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<GroupMessageModel> messages = await _services.getGroupMessages(
        groupId: widget.groupId,
        userId: widget.currentUserId,
        page: 0,
        size: 30,
      );
      
      setState(() {
        _messages = messages;
        _sortMessagesByTime();
        _isLoading = false;
        _hasMore = messages.length >= 30;
        _page = 0;
        
        // 📌 লোড করা মেসেজগুলোর আইডি সংরক্ষণ
        for (var msg in messages) {
          _processedMessageIds.add(msg.id);
        }
      });
      
      _scrollToBottom();
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      int nextPage = _page + 1;
      List<GroupMessageModel> messages = await _services.getGroupMessages(
        groupId: widget.groupId,
        userId: widget.currentUserId,
        page: nextPage,
        size: 30,
      );
      
      setState(() {
        _messages = [...messages, ..._messages];
        _sortMessagesByTime();
        _isLoadingMore = false;
        _hasMore = messages.length >= 30;
        _page = nextPage;
        
        // 📌 লোড করা মেসেজগুলোর আইডি সংরক্ষণ
        for (var msg in messages) {
          _processedMessageIds.add(msg.id);
        }
      });
      
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // ==================== মেসেজ সাজানো ====================

  void _sortMessagesByTime() {
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // ==================== স্ক্রল কন্ট্রোল ====================

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== মেসেজ সেন্ড - শুধুমাত্র REST API ====================

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final content = _messageController.text.trim();
      
      // ✅ REST API দিয়ে মেসেজ পাঠান
      final message = await _services.sendMessage(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        content: content,
      );

      // 📌 মেসেজ আইডি সংরক্ষণ করুন - যাতে WebSocket থেকে ডুপ্লিকেট আসলে ইগনোর হয়
      _processedMessageIds.add(message.id);

      setState(() {
        _messages.add(message);
        _sortMessagesByTime();
        _messageController.clear();
        _isSending = false;
      });
      _scrollToBottom();
      
      print('✅ Message sent via REST API: ${message.id}');
      
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      
      // ❌ REST API ব্যর্থ হলে WebSocket দিয়ে চেষ্টা করুন (ব্যাকআপ)
      if (GroupChatWebSocket.isConnected()) {
        final content = _messageController.text.trim();
        GroupChatWebSocket.sendMessage(
          widget.groupId,
          widget.currentUserId,
          content,
        );
        _messageController.clear();
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sending via WebSocket...')),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  // ==================== মেসেজ ডিলিট ====================

  Future<void> _deleteMessage(String messageId, String senderId) async {
    if (senderId != widget.currentUserId && !widget.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own messages')),
      );
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!confirm) return;

    try {
      bool success = await _services.deleteMessage(
        messageId: messageId,
        userId: widget.currentUserId,
      );

      if (success) {
        setState(() {
          _messages.removeWhere((msg) => msg.id == messageId);
          _processedMessageIds.remove(messageId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  // ==================== মেসেজ এডিট ====================

  Future<void> _editMessage(String messageId, String currentContent) async {
    TextEditingController editController = TextEditingController(text: currentContent);

    String? newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green[700],
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newContent == null || newContent.isEmpty || newContent == currentContent) return;

    try {
      bool success = await _services.editMessage(
        messageId: messageId,
        newContent: newContent,
        userId: widget.currentUserId,
      );

      if (success) {
        setState(() {
          int index = _messages.indexWhere((msg) => msg.id == messageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              content: newContent,
              edited: true,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message updated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to edit: $e')),
      );
    }
  }

  // ==================== মেসেজ অপশন ====================

  void _showMessageOptions(GroupMessageModel message) {
    bool isMyMessage = message.senderId == widget.currentUserId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMyMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message.id, message.content);
                },
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: Icon(
                Icons.delete,
                color: (isMyMessage || widget.isAdmin) ? Colors.red : Colors.grey,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: (isMyMessage || widget.isAdmin) ? Colors.red : Colors.grey,
                ),
              ),
              onTap: (isMyMessage || widget.isAdmin)
                  ? () {
                      Navigator.pop(context);
                      _deleteMessage(message.id, message.senderId);
                    }
                  : null,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ==================== UI হেল্পার ====================

  String _getDisplayName(String senderId, String originalName) {
    if (senderId == widget.currentUserId) {
      return widget.currentUserName;
    }
    return 'AdvocateChai';
  }

  String _getAvatarInitial(String senderId, String originalName) {
    if (senderId == widget.currentUserId) {
      return originalName.isNotEmpty ? originalName[0].toUpperCase() : 'U';
    }
    return 'A';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return DateFormat('hh:mm a').format(time);
    } else {
      return DateFormat('MMM d, hh:mm a').format(time);
    }
  }

  // ==================== UI উইজেট ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(fontSize: 18),
            ),
            Row(
              children: [
                Text(
                  '${_messages.length} messages',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
                if (_isWebSocketConnected)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh',
          ),
          if (widget.isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                // এডমিন অপশন
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_member',
                  child: Text('Add Member'),
                ),
                const PopupMenuItem(
                  value: 'remove_member',
                  child: Text('Remove Member'),
                ),
                const PopupMenuItem(
                  value: 'delete_group',
                  child: Text('Delete Group'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? _buildLoadingState()
                : _errorMessage != null && _messages.isEmpty
                    ? _buildErrorState()
                    : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Loading messages...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 20),
            Text(
              'Error loading messages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            final bool isMyMessage = message.senderId == widget.currentUserId;
            
            return GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: _buildMessageBubble(message, isMyMessage),
            );
          },
        ),
        if (_isLoadingMore)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(GroupMessageModel message, bool isMyMessage) {
    final String displayName = _getDisplayName(message.senderId, message.senderName);
    final String avatarInitial = _getAvatarInitial(message.senderId, message.senderName);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: Text(
                avatarInitial,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMyMessage ? Colors.green[700] : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isMyMessage ? const Radius.circular(4) : const Radius.circular(16),
                  bottomLeft: isMyMessage ? const Radius.circular(16) : const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMyMessage)
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMyMessage ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMyMessage 
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                        ),
                      ),
                      if (message.edited)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                              color: isMyMessage
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: message.readCount > 0 ? Colors.blue : Colors.grey[300],
              ),
              child: Center(
                child: Text(
                  message.readCount > 0 ? '✓' : '',
                  style: TextStyle(
                    fontSize: 10,
                    color: message.readCount > 0 ? Colors.white : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isSending ? Colors.grey[400] : Colors.green[700],
            child: IconButton(
              icon: Icon(
                _isSending ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    GroupChatWebSocket.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _processedMessageIds.clear();
    super.dispose();
  }
}