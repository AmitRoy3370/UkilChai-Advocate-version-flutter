import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/BaseURL.dart' as BASE_URL;
import 'notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}notifications/unread/$userId"),
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      setState(() {
        notifications =
            data.map((e) => NotificationModel.fromJson(e)).toList();
        notifications.reversed;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    await http.put(
      Uri.parse(
          "${BASE_URL.Urls().baseURL}notifications/mark-read/$notificationId"),
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    setState(() {
      notifications.removeWhere((n) => n.id == notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No unread notifications"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(n.message),
              subtitle: Text(n.timeStamp),
              trailing: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => markAsRead(n.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
