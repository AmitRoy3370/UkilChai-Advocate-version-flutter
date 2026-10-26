// CreateGroupScreen.dart

import 'package:flutter/material.dart';
import 'package:advocatechai/GroupChat/GroupChatServices.dart';

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
  final List<String> _selectedMembers = [];
  final List<String> _availableUsers = [];
  bool _isLoading = false;
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
            onPressed: _selectedMembers.isNotEmpty && _groupNameController.text.isNotEmpty
                ? _createGroup
                : null,
            child: const Text(
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
              decoration: const InputDecoration(
                labelText: 'Search members',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            // নির্বাচিত সদস্য
            if (_selectedMembers.isNotEmpty) ...[
              const Text(
                'Selected Members:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _selectedMembers.map((member) => Chip(
                  label: Text(member),
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
                        'Search users to add',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = _availableUsers[index];
                        final isSelected = _selectedMembers.contains(user);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? Colors.green[700] : Colors.grey[300],
                            child: Text(
                              user.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          title: Text(user),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.green[700])
                              : null,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedMembers.remove(user);
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

  void _createGroup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final group = await _services.createGroup(
        groupName: _groupNameController.text.trim(),
        members: _selectedMembers,
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