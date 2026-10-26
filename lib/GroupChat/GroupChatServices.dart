// GroupChatServices.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'GroupChatModels.dart';

class GroupChatServices {
  static const String baseUrl = 'https://ukilchai.abrdns.com/api/group-chat';

  // 📌 টোকেন পাওয়ার ফাংশন
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // ==================== গ্রুপ ম্যানেজমেন্ট ====================

  // ✅ ১. নতুন গ্রুপ তৈরি
  Future<GroupModel> createGroup({
    required String groupName,
    required List<String> members,
    required String creatorId,
    String? groupIcon,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final request = CreateGroupRequest(
        groupName: groupName,
        members: members,
        groupIcon: groupIcon,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/create?creatorId=$creatorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create group: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating group: $e');
    }
  }

  // ✅ ২. নির্দিষ্ট গ্রুপের তথ্য দেখা
  Future<GroupModel> getGroupById(String groupId) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get group: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting group: $e');
    }
  }

  // ✅ ৩. ইউজারের সব গ্রুপ পাওয়া
  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/my-groups/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GroupModel.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load groups: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading groups: $e');
    }
  }

  // ✅ ৪. গ্রুপ আপডেট করা
  Future<GroupModel> updateGroup({
    required String groupId,
    required String groupName,
    required List<String> members,
    required String userId,
    String? groupIcon,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final body = {
        'groupName': groupName,
        'members': members,
        'groupIcon': groupIcon,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/update/$groupId?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update group: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating group: $e');
    }
  }

  // ✅ ৫. গ্রুপ ডিলিট করা
  Future<bool> deleteGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$groupId?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting group: $e');
    }
  }

  // ✅ ৬. গ্রুপে নতুন সদস্য যোগ করা
  Future<bool> addMember({
    required String groupId,
    required String memberId,
    required String adminId,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/$groupId/add-member?memberId=$memberId&adminId=$adminId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error adding member: $e');
    }
  }

  // ✅ ৭. গ্রুপ থেকে সদস্য সরানো
  Future<bool> removeMember({
    required String groupId,
    required String memberId,
    required String adminId,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse('$baseUrl/$groupId/remove-member?memberId=$memberId&adminId=$adminId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error removing member: $e');
    }
  }

  // ==================== গ্রুপ মেসেজিং ====================

  // ✅ ৮. গ্রুপে মেসেজ পাঠানো (REST API)
  Future<GroupMessageModel> sendMessage({
    required String groupId,
    required String senderId,
    required String content,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final body = {
        'groupId': groupId,
        'senderId': senderId,
        'content': content,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/send-message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GroupMessageModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // ✅ ৯. গ্রুপের মেসেজ পাওয়া (পেজিনেশন সহ)
  Future<List<GroupMessageModel>> getGroupMessages({
    required String groupId,
    required String userId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/$groupId?userId=$userId&page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GroupMessageModel.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading messages: $e');
    }
  }

  // ✅ ১০. গ্রুপ মেসেজ এডিট করা
  Future<bool> editMessage({
    required String messageId,
    required String newContent,
    required String userId,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/edit-message/$messageId?userId=$userId&newContent=${Uri.encodeComponent(newContent)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error editing message: $e');
    }
  }

  // ✅ ১১. গ্রুপ মেসেজ ডিলিট করা
  Future<bool> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse('$baseUrl/delete-message/$messageId?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  // ✅ ১২. নির্দিষ্ট গ্রুপ মেসেজ দেখা (আইডি দিয়ে)
  Future<GroupMessageModel> getMessageById(String messageId) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/message/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GroupMessageModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting message: $e');
    }
  }

  // ==================== রিড রিসিপ্ট ====================

  // ✅ ১৩. মেসেজ রিড মার্ক করা
  Future<bool> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/mark-read/$messageId?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error marking message as read: $e');
    }
  }

  // ✅ ১৪. আনরিড কাউন্ট পাওয়া
  Future<int> getUnreadCount({
    required String groupId,
    required String userId,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/unread-count/$groupId/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // ✅ ১৫. একাধিক গ্রুপের আনরিড কাউন্ট একসাথে দেখা
  Future<Map<String, int>> getMultipleUnreadCounts({
    required String userId,
    required List<String> groupIds,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/unread-counts/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(groupIds),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        Map<String, int> result = {};
        data.forEach((key, value) {
          result[key] = value as int;
        });
        return result;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  // ==================== গ্রুপ মেম্বার ম্যানেজমেন্ট (অতিরিক্ত) ====================

  // ✅ ১৬. গ্রুপের সব মেম্বারের নাম পাওয়া
  Future<List<String>> getGroupMemberNames(String groupId) async {
    try {
      GroupModel group = await getGroupById(groupId);
      return group.membersName;
    } catch (e) {
      throw Exception('Error getting member names: $e');
    }
  }

  // ✅ ১৭. ইউজার গ্রুপের মেম্বার কিনা চেক করা
  Future<bool> isUserMemberOfGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      GroupModel group = await getGroupById(groupId);
      return group.members.contains(userId);
    } catch (e) {
      return false;
    }
  }
}