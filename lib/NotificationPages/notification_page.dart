// notification_page.dart

import 'notification_service.dart';
import 'notification_model.dart';
import '../ProfilePage/SeeMyProfile.dart';
import '../ChatRelatedPages/chat_screen.dart';
import '../GroupChat/GroupChatScreen.dart';
import '../CaseRelatedPages/case_tracking.dart';
import '../CaseRelatedPages/CaseDetailsPage.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../CaseRelatedPages/case_service.dart';
import '../CaseRelatedPages/case_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // অ্যানিমেশন সেটআপ
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();

    // ✅ Service-এ Context সেট করা এবং ডাটা লোড করা
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<NotificationService>(context, listen: false);
      service.setContext(context);
      service.loadUnreadNotifications();
      service.connectWebSocket();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 7) {
      return '${diff.inDays ~/ 7} সপ্তাহ আগে';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} দিন আগে';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ঘন্টা আগে';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} মিনিট আগে';
    } else {
      return 'এখনই';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("নোটিফিকেশন"),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        actions: [
          // ✅ সংযোগ স্ট্যাটাস ইন্ডিকেটর
          Consumer<NotificationService>(
            builder: (context, service, _) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: service.isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service.isConnected ? "লাইভ" : "অফলাইন",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, service, _) {
          // লোডিং স্টেট
          if (service.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text("নোটিফিকেশন লোড হচ্ছে..."),
                ],
              ),
            );
          }

          // খালি স্টেট
          if (service.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "কোনো নোটিফিকেশন নেই",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "নতুন নোটিফিকেশন এখানে দেখাবে",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // নোটিফিকেশন লিস্ট
          return RefreshIndicator(
            onRefresh: () => service.loadUnreadNotifications(),
            color: Colors.green,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: service.notifications.length,
              itemBuilder: (context, index) {
                final notification = service.notifications[index];

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        index * 0.05,
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    )),
                    child: Dismissible(
                      key: Key(notification.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onDismissed: (_) => service.deleteNotification(notification.id),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: notification.isRead
                                ? Colors.grey.shade200
                                : Colors.green.shade100,
                            child: Icon(
                              Icons.notifications_active,
                              color: notification.isRead
                                  ? Colors.grey.shade600
                                  : Colors.green.shade700,
                            ),
                          ),
                          title: Text(
                            notification.message,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatTime(notification.timeStamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          trailing: notification.isRead
                              ? null
                              : Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () async { 
                                print("i am at here");
                                await service.markAsRead(notification.id);
                                final List<String> destinations = notification.destinations;
                                print("destinations :- $destinations");
                                final Map<String, String> params = notification.params;
                                print("params :- $params");
                                if(destinations.isNotEmpty) {
                                      String className = destinations[destinations.length - 1];
                                      if(className == 'SeeMyProfile' || className == 'ProfilePage') {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SeeMyProfile()));
                                      } else if(className == 'CaseDetailsPage') {
                                            final prefs = await SharedPreferences.getInstance();
                                            final String? token = prefs.getString('jwt_token');
                                            String? caseId = params["caseId"];
                                            CaseModel caseModel = await CaseService(token!).findById(caseId!);
                                            String? userId = caseModel.userId;
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => CaseDetailsPage(caseModel:caseModel, userId:userId, onDeleted : () {setState((){}); }  )));
                                      } else if(className == 'ChatScreen') {
                                            String? currentUser = params["currentUser"];
                                            String? otherUser = params["otherUser"];
                                            String? myName = params["myName"];
                                            String? othersName = params["othersName"];
                                            Navigator.push(context, MaterialPageRoute(builder:(context) => ChatScreen(currentUser:currentUser, otherUser:otherUser, othersName:othersName, myName:myName)));
                                      } else if(className == 'GroupChatScreen') {
                                            String groupId = params["groupId"]!;
                                            String groupName = params["groupName"]!;
                                            String currentUserId = params["currentUserId"]!;
                                            String currentUserName = params["currentUserName"]!;
                                            bool isAdmin = false;
                                            Navigator.push(context, MaterialPageRoute(builder:(context) => GroupChatScreen(groupId:groupId, groupName:groupName, currentUserId:currentUserId, currentUserName:currentUserName, isAdmin:isAdmin) ));
                                      }

                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          onTap: () async {
                            if (!notification.isRead) {
                                print("i am at here");
                                await service.markAsRead(notification.id);
                                final List<String> destinations = notification.destinations;
                                print("destinations :- $destinations");
                                final Map<String, String> params = notification.params;
                                print("params :- $params");
                                if(destinations.isNotEmpty) {
                                      String className = destinations[destinations.length - 1];
                                      if(className == 'SeeMyProfile' || className == 'ProfilePage') {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SeeMyProfile()));
                                      } else if(className == 'CaseDetailsPage') {
                                            final prefs = await SharedPreferences.getInstance();
                                            final String? token = prefs.getString('jwt_token');
                                            String? caseId = params["caseId"];
                                            CaseModel caseModel = await CaseService(token!).findById(caseId!);
                                            String? userId = caseModel.userId;
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => CaseDetailsPage(caseModel:caseModel, userId:userId, onDeleted : () {setState((){}); }  )));
                                      } else if(className == 'ChatScreen') {
                                            String? currentUser = params["currentUser"];
                                            String? otherUser = params["otherUser"];
                                            String? myName = params["myName"];
                                            String? othersName = params["othersName"];
                                            Navigator.push(context, MaterialPageRoute(builder:(context) => ChatScreen(currentUser:currentUser, otherUser:otherUser, othersName:othersName, myName:myName)));
                                      } else if(className == 'GroupChatScreen') {
                                            String groupId = params["groupId"]!;
                                            String groupName = params["groupName"]!;
                                            String currentUserId = params["currentUserId"]!;
                                            String currentUserName = params["currentUserName"]!;
                                            bool isAdmin = false;
                                            Navigator.push(context, MaterialPageRoute(builder:(context) => GroupChatScreen(groupId:groupId, groupName:groupName, currentUserId:currentUserId, currentUserName:currentUserName, isAdmin:isAdmin) ));
                                      }
                            }}
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}