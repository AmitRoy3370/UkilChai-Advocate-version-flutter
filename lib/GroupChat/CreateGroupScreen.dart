// CreateGroupScreen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../GroupChat/GroupChatServices.dart';

class UserModel {
  final String id;
  final String name;
  final String? fullName;

  UserModel({required this.id, required this.name, this.fullName});
}

class CreateGroupScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const CreateGroupScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  
  // Changed to hold UserModels instead of Strings to get the correct user ID for group creation
  final List<UserModel> _selectedMembers = [];
  List<UserModel> _availableUsers = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  final GroupChatServices _services = GroupChatServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedMembers.isNotEmpty && _groupNameController.text.isNotEmpty && !_isLoading
                ? _createGroup
                : null,
            child: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // গ্রুপ নাম
            TextField(
              controller: _groupNameController,
              onChanged: (val) => setState(() {}), // To update the Create button state
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 16),

            // সদস্য সার্চ
            TextField(
              controller: _memberSearchController,
              onChanged: (query) => _searchUsers(query),
              decoration: InputDecoration(
                labelText: 'Search members',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              ),
            ),
            const SizedBox(height: 16),

            // নির্বাচিত সদস্য
            if (_selectedMembers.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selected Members:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMembers.map((member) => Chip(
                  label: Text(member.fullName ?? member.name),
                  onDeleted: () {
                    setState(() {
                      _selectedMembers.remove(member);
                    });
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: Colors.green[50],
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // উপলব্ধ ইউজার
            Expanded(
              child: _availableUsers.isEmpty
                  ? Center(
                      child: Text(
                        _isSearching ? 'Searching...' : 'Search users to add',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = _availableUsers[index];
                        // Ignore current user
                        if (user.id == widget.currentUserId) return const SizedBox.shrink();

                        final isSelected = _selectedMembers.any((m) => m.id == user.id);
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.green[700] : Colors.grey[300],
                            child: Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          title: Text(user.fullName ?? user.name),
                          subtitle: Text("@${user.name}"),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.green[700])
                              : null,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedMembers.removeWhere((m) => m.id == user.id);
                              } else {
                                _selectedMembers.add(user);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔍 Search Users via Backend
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _availableUsers = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      // Using your backend endpoint for fullName partial search
      final url = Uri.parse('${BASE_URL.Urls().baseURL}user/find/fullName/$query');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        setState(() {
          _availableUsers = data.map((json) => UserModel(
            id: json['id'],
            name: json['name'],
            fullName: json['fullName'],
          )).toList();
        });
      } else {
        // If 404 (no user found), clear the list
        setState(() {
          _availableUsers = [];
        });
      }
    } catch (e) {
      debugPrint("Error searching users: $e");
      setState(() {
        _availableUsers = [];
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _createGroup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extracting IDs from the selected UserModels
      final memberIds = _selectedMembers.map((m) => m.id).toList();

      final group = await _services.createGroup(
        groupName: _groupNameController.text.trim(),
        members: memberIds, // Send list of IDs
        creatorId: widget.currentUserId,
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${group.groupName}" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }
}