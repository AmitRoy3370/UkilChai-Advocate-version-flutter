// lib/ChatRelatedPages/FreeConsultantPage.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import './CenterAdminChatListScreen.dart';
import '../GroupChat/GroupChatModels.dart';
import '../GroupChat/GroupChatServices.dart';
import '../GroupChat/GroupChatScreen.dart'; // গ্রুপ চ্যাট স্ক্রিন ইম্পোর্ট

class FreeConsultantPage extends StatefulWidget {
  final String? currentUserId, currentUserName;
  const FreeConsultantPage({super.key, required this.currentUserId, required this.currentUserName});

  @override
  State<FreeConsultantPage> createState() => _FreeConsultantPageState();
}

class _FreeConsultantPageState extends State<FreeConsultantPage> {
  bool _isProcessing = false;
  final GroupChatServices _groupServices = GroupChatServices();
  
  // গ্রুপ আইডি সংরক্ষণের জন্য
  String? _groupChatId;
  String? _groupChatName;

  @override
  void initState() {
    super.initState();
    // পেজ লোড হওয়ার সাথে সাথে গ্রুপ চেক করুন
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndCreateGroup();
    });
  }

  // ==================== গ্রুপ ম্যানেজমেন্ট ফাংশন ====================

  /// ১. সেন্টার অ্যাডমিনদের লিস্ট পাওয়া
  Future<List<String>> _getAllCenterAdminIds() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('https://ukilchai.abrdns.com/api/center-admin/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<String> adminIds = [];
        
        for (var admin in data) {
          String userId = admin['userId'] ?? '';
          if (userId.isNotEmpty && userId != widget.currentUserId) {
            adminIds.add(userId);
          }
        }
        
        return adminIds;
      } else {
        throw Exception('Failed to load center admins');
      }
    } catch (e) {
      print('Error loading center admins: $e');
      return [];
    }
  }

  /// ২. "Ukil Chai" নামে গ্রুপ খোঁজা
  Future<GroupModel?> _findExistingGroup() async {
    try {
      List<GroupModel> groups = await _groupServices.getUserGroups(
        widget.currentUserId!,
      );
      
      // "Ukil Chai" নামে গ্রুপ খোঁজা (case-insensitive)
      for (var group in groups) {
        if (widget.currentUserId! == group.createdBy && group.groupName == widget.currentUserName) {
          return group;
        }
      }
      
      return null;
    } catch (e) {
      print('Error finding group: $e');
      return null;
    }
  }

  /// ২.১. ইউজারের সব গ্রুপ পাওয়া যেখানে তিনি অ্যাডমিন
  Future<List<GroupModel>> _getAdminGroups() async {
    try {
      List<GroupModel> allGroups = await _groupServices.getUserGroups(
        widget.currentUserId!,
      );
      
      // শুধু সেই গ্রুপগুলো যেখানে ইউজার ক্রিয়েটর (অ্যাডমিন)
      List<GroupModel> adminGroups = [];
      for (var group in allGroups) {
        if (group.createdBy == widget.currentUserId! && group.groupName == widget.currentUserName!) {
          adminGroups.add(group);
        }
      }
      _showSnackBar('No admin group found. Creating one... $adminGroups', Colors.blue);
      return adminGroups;
    } catch (e) {
      print('Error getting admin groups: $e');
      return [];
    }
  }

  /// ২.২. প্রথম অ্যাডমিন গ্রুপে নেভিগেট করা
  Future<void> _navigateToFirstAdminGroup() async {
    try {
      List<GroupModel> adminGroups = await _getAdminGroups();
      
      _showSnackBar('No admin group found. Creating one... $adminGroups', Colors.blue);

      if (adminGroups.isEmpty) {
        // যদি কোনো অ্যাডমিন গ্রুপ না থাকে, তাহলে প্রথমে গ্রুপ তৈরি করুন
        _showSnackBar('No admin group found. Creating one...', Colors.blue);
        await _checkAndCreateGroup();
        
        // আবার চেক করুন
        adminGroups = await _getAdminGroups();
        
        if (adminGroups.isEmpty) {
          _showSnackBar('Failed to create admin group', Colors.red);
          return;
        }
      }
      
      // প্রথম অ্যাডমিন গ্রুপে নেভিগেট করুন
      GroupModel firstGroup = adminGroups.first;
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              groupId: firstGroup.id,
              groupName: firstGroup.groupName,
              currentUserId: widget.currentUserId!,
              currentUserName: widget.currentUserName!,
              isAdmin: true, // যেহেতু অ্যাডমিন গ্রুপ, তাই true
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
      print('Error in _navigateToFirstAdminGroup: $e');
    }
  }

  /// ৩. নতুন গ্রুপ তৈরি করা
  Future<GroupModel?> _createNewGroup(List<String> adminIds) async {
    try {
      // সব সেন্টার অ্যাডমিন + বর্তমান ইউজার
      List<String> members = [widget.currentUserId!, ...adminIds];
      
      // ডুপ্লিকেট রিমুভ
      members = members.toSet().toList();
      
      final group = await _groupServices.createGroup(
        groupName: widget.currentUserName!, // গ্রুপের নাম ঠিক করা হয়েছে
        members: members,
        creatorId: widget.currentUserId!,
      );
      
      return group;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  /// ৪. গ্রুপে নতুন মেম্বার যোগ করা
  Future<bool> _addMemberToGroup(String groupId, String memberId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('https://ukilchai.abrdns.com/api/group-chat/$groupId/add-member?memberId=$memberId&adminId=${widget.currentUserId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding member: $e');
      return false;
    }
  }

  /// ৫. মেইন ফাংশন - গ্রুপ চেক এবং ক্রিয়েট/আপডেট
  Future<void> _checkAndCreateGroup() async {
    // যদি ইতিমধ্যে প্রসেসিং হয় তাহরে ফিরে যান
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // ১. সেন্টার অ্যাডমিনদের লিস্ট নিন
      List<String> centerAdminIds = await _getAllCenterAdminIds();
      
      if (centerAdminIds.isEmpty) {
        _showSnackBar('No center admins found', Colors.orange);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // ২. বিদ্যমান গ্রুপ খোঁজুন
      GroupModel? existingGroup = await _findExistingGroup();

      if (existingGroup == null) {
        // 🔹 গ্রুপ নেই - নতুন গ্রুপ তৈরি করুন
        _showSnackBar('Creating group "${widget.currentUserName}"...', Colors.blue);
        
        GroupModel? newGroup = await _createNewGroup(centerAdminIds);
        
        if (newGroup != null) {
          _groupChatId = newGroup.id;
          _groupChatName = newGroup.groupName;
          _showSnackBar(
            'Group "Ukil Chai" created successfully with ${newGroup.members.length} members!',
            Colors.green,
          );
        } else {
          _showSnackBar('Failed to create group', Colors.red);
        }
      } else {
        // 🔹 গ্রুপ আছে - মেম্বার চেক করুন
        _groupChatId = existingGroup.id;
        _groupChatName = existingGroup.groupName;
        
        // বর্তমান মেম্বার লিস্ট
        List<String> currentMembers = existingGroup.members;
        
        // কোন সেন্টার অ্যাডমিন নেই?
        List<String> missingAdmins = [];
        for (String adminId in centerAdminIds) {
          if (!currentMembers.contains(adminId)) {
            missingAdmins.add(adminId);
          }
        }
        
        if (missingAdmins.isNotEmpty) {
          _showSnackBar(
            'Adding ${missingAdmins.length} new members to group...',
            Colors.blue,
          );
          
          int addedCount = 0;
          for (String adminId in missingAdmins) {
            bool success = await _addMemberToGroup(existingGroup.id, adminId);
            if (success) addedCount++;
          }
          
          if (addedCount > 0) {
            _showSnackBar(
              '$addedCount new members added to "Ukil Chai" group!',
              Colors.green,
            );
          } else {
            _showSnackBar(
              'No new members were added',
              Colors.orange,
            );
          }
        } else {
          _showSnackBar(
            '✅ All center admins are already in "Ukil Chai" group',
            Colors.green,
          );
        }
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
      print('Error in _checkAndCreateGroup: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// ৬. SnackBar শো করার ফাংশন
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ==================== আগের ফাংশনগুলো ====================

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _sendEmail(String email) async {
    try {
      final Uri emailUri = Uri(scheme: 'mailto', path: email);
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /// 🔹 লাইভ চ্যাটে ক্লিক করলে প্রথম অ্যাডমিন গ্রুপে যাবে
  void _goToLiveChat() {
    if (widget.currentUserId != null && widget.currentUserName != null) {
      // প্রথম অ্যাডমিন গ্রুপে নেভিগেট করুন
      _navigateToFirstAdminGroup();
    } else {
      _showSnackBar('User information not available', Colors.orange);
    }
  }

  /// 🔹 চ্যাট লিস্টে যাওয়ার জন্য (যদি প্রয়োজন হয়)
  void _goToChatList() {
    if (widget.currentUserId != null && widget.currentUserName != null) {
      // গ্রুপ চ্যাটে যাওয়ার আগে নিশ্চিত করুন গ্রুপ আছে
      _checkAndCreateGroup().then((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CenterAdminChatListScreen(
                currentUserId: widget.currentUserId!,
                currentUserName: widget.currentUserName!,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== হেডার সেকশন - গ্রিন কালার =====
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // ===== স্ট্যাটাস ইন্ডিকেটর =====
              if (_isProcessing) _buildProcessingIndicator(),
              
              // ===== কন্ট্যাক্ট সেকশন =====
              _buildContactSection(),
              
              const SizedBox(height: 24),
              
              // ===== হেল্প সেকশন =====
              _buildHelpSection(),
              
              const SizedBox(height: 24),
              
              // ===== চ্যাট বাটন =====
              //_buildChatButton(),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===== প্রসেসিং ইন্ডিকেটর =====
  Widget _buildProcessingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Setting up group chat...',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== হেডার =====
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00695C),
            Color(0xFF00897B),
            Color(0xFF26A69A),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Talk to Our Customer Care Team',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Get free legal advice and guidance on\nyour legal concerns. We are here to help!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Available Time',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '10:00 AM - 10:00 PM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '(Everyday)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== কন্ট্যাক্ট সেকশন =====
  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C),
              ),
            ),
          ),
          
          _buildContactCard(
            icon: Icons.phone,
            iconColor: Colors.green,
            title: 'Phone Number',
            subtitle: '+880 1815 696208',
            action: 'Call Now',
            bgColor: const Color(0xFFE8F5E9),
            borderColor: const Color(0xFFA5D6A7),
            onTap: () => _makePhoneCall('+8801815696208'),
          ),
          
          _buildContactCard(
            icon: Icons.chat,
            iconColor: Colors.green,
            title: 'WhatsApp',
            subtitle: 'Chat with us on WhatsApp',
            action: 'Chat Now',
            bgColor: const Color(0xFFE8F5E9),
            borderColor: const Color(0xFFA5D6A7),
            onTap: () => _launchURL('https://wa.me/8801815696208'),
          ),
          
          _buildContactCard(
            icon: Icons.facebook,
            iconColor: const Color(0xFF1565C0),
            title: 'Facebook Page',
            subtitle: 'm.me/ukil.com.bd',
            action: 'Message',
            bgColor: const Color(0xFFE3F2FD),
            borderColor: const Color(0xFF90CAF9),
            onTap: () => _launchURL('https://www.facebook.com/share/1LakTv4oRP/'),
          ),
          
          _buildContactCard(
            icon: Icons.work,
            iconColor: const Color(0xFF1565C0),
            title: 'LinkedIn',
            subtitle: 'linkedin.com/company/ukil',
            action: 'Follow',
            bgColor: const Color(0xFFE3F2FD),
            borderColor: const Color(0xFF90CAF9),
            onTap: () => _launchURL('https://www.linkedin.com/company/%E0%A6%89%E0%A6%95%E0%A6%BF%E0%A6%B2-ukil/'),
          ),
          
          _buildContactCard(
            icon: Icons.email,
            iconColor: const Color(0xFFE65100),
            title: 'Email Us',
            subtitle: 'support@ukil.com.bd',
            action: 'Send Email',
            bgColor: const Color(0xFFFFF3E0),
            borderColor: const Color(0xFFFFCC80),
            onTap: () => _sendEmail('support@ukil.com.bd'),
          ),
          
          _buildContactCard(
            icon: Icons.live_help,
            iconColor: const Color(0xFF6A1B9A),
            title: 'Live Chat',
            subtitle: 'Chat instantly with our team',
            action: 'Start Chat',
            bgColor: const Color(0xFFF3E5F5),
            borderColor: const Color(0xFFCE93D8),
            onTap: _goToLiveChat, // 🔹 এখানে পরিবর্তন - সরাসরি অ্যাডমিন গ্রুপে যাবে
          ),
        ],
      ),
    );
  }

  // ===== কন্ট্যাক্ট কার্ড =====
  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String action,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00695C),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            action,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // ===== হেল্প সেকশন =====
  Widget _buildHelpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'What can we help with?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHelpItem('General legal information and guidance'),
                _buildDivider(),
                _buildHelpItem('Questions about legal rights and procedures'),
                _buildDivider(),
                _buildHelpItem('Help with documents and legal processes'),
                _buildDivider(),
                _buildHelpItem('Guide you to the right advocate if needed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== হেল্প আইটেম =====
  Widget _buildHelpItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF00695C),
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== ডিভাইডার =====
  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      color: Colors.grey.shade200,
      thickness: 0.5,
    );
  }

  // ===== চ্যাট বাটন =====
  Widget _buildChatButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _isProcessing ? null : _goToLiveChat,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00695C),
                Color(0xFF00897B),
                Color(0xFF26A69A),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00695C).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.chat_bubble, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                _isProcessing ? 'Setting up...' : 'Start Chat with Advocate',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}