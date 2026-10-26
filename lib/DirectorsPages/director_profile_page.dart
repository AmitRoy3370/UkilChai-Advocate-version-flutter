// lib/DirectorsPages/director_profile_page.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../DirectorsPages/director_service.dart';
import '../DirectorsPages/director_response.dart';
import '../DirectorsPages/director.dart';
import '../DirectorsPages/DirectorRegistrationScreen.dart';
import '../DirectorsPages/DirectorAttachmentViewer.dart';
import '../CompanyPages/company_information.dart';
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'package:shared_preferences/shared_preferences.dart';
import '../ChatRelatedPages/chat_screen.dart';

class DirectorProfilePage extends StatefulWidget {
  final String? directorId;
  final String? userId;

  const DirectorProfilePage({
    Key? key,
    required this.directorId,
    required this.userId,
  }) : super(key: key);

  @override
  State<DirectorProfilePage> createState() => _DirectorProfilePageState();
}

class _DirectorProfilePageState extends State<DirectorProfilePage> {
  final DirectorService _directorService = DirectorService();
  DirectorResponse? _director;
  bool _isLoading = true;
  String? _error;
  String? _jwtToken, currentUserId;
  String? _myName;
  Uint8List? _profileImageBytes;
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndDirector();
  }

  Future<void> _loadTokenAndDirector() async {
    _jwtToken = await AuthService.getToken();
    currentUserId = await AuthService.getUserId();
    // ✅ Fetch user name from server
    if (currentUserId != null && currentUserId!.isNotEmpty) {
      await _fetchUserName(currentUserId!);
    }
    await _loadDirector();
  }

  // ✅ Fetch user name from server
  Future<void> _fetchUserName(String userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('⚠️ No token available to fetch user name');
        return;
      }

      final url = Uri.parse('${BASE_URL.Urls().baseURL}user/search?userId=$userId');
      print('📤 Fetching user name from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 User name response status: ${response.statusCode}');
      print('📥 User name response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ Get fullName first, if null then use name
        _myName = data['fullName'] ?? data['name'] ?? 'User';
        print('✅ My Name: $_myName');
      } else {
        print('⚠️ Failed to fetch user name: ${response.statusCode}');
        _myName = 'User';
      }
    } catch (e) {
      print('❌ Error fetching user name: $e');
      _myName = 'User';
    }
  }

  Future<void> _loadDirector() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final director = await _directorService.getDirectorById(widget.directorId!);
      
      // ✅ Debug: Print director data
      print('=== Director Data ===');
      print('Director ID: ${director.id}');
      print('User ID: ${director.userId}');
      print('User Name: ${director.userName}');
      print('Position: ${director.position}');
      print('Profile Image ID: ${director.profileImageId}');
      print('NID: ${director.nid}');
      print('=====================');
      
      setState(() {
        _director = director;
        _isLoading = false;
      });
      
      // Load profile image if available
      if (director.profileImageId != null && director.profileImageId!.isNotEmpty) {
        await _loadProfileImage(director.profileImageId!);
      } else {
        print('⚠️ No profileImageId found for this director');
      }
    } catch (e) {
      print('Error loading director: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ✅ Load profile image from server
  Future<void> _loadProfileImage(String imageId) async {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      print('⚠️ No JWT token available');
      return;
    }
    
    setState(() {
      _isImageLoading = true;
    });

    try {
      final url = Uri.parse('${BASE_URL.Urls().baseURL}user/download/$imageId');
      print('📸 Loading profile image from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_jwtToken',
        },
      );

      print('📸 Image response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Profile image loaded successfully, size: ${response.bodyBytes.length} bytes');
        setState(() {
          _profileImageBytes = response.bodyBytes;
          _isImageLoading = false;
        });
      } else {
        print('❌ Failed to load profile image: ${response.statusCode}');
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading profile image: $e');
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  // ✅ Method to view attachment
  void _viewAttachment(String attachmentId) {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again to view attachments'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectorAttachmentViewer(
          attachmentId: attachmentId,
          jwtToken: _jwtToken!,
        ),
      ),
    );
  }

  // ✅ Navigate to Chat Screen
  void _navigateToChat() {
    if (currentUserId == null || currentUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to chat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_director == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Director data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🔄 Navigating to chat with:');
    print('Current User ID: $currentUserId');
    print('My Name: $_myName');
    print('Director User ID: ${_director!.userId}');
    print('Director Name: ${_director!.userName}');

    // ✅ Use correct ChatScreen parameters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUser: _director!.userId,      // ✅ Director's user ID
          othersName: _director!.userName,   // ✅ Director's name
          currentUser: currentUserId!,       // ✅ Current user ID
          myName: _myName ?? 'User',         // ✅ Current user's name (fallback)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Director Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDirector,
          ),
          // ✅ Chat button - only show if viewing different user
          if (currentUserId != widget.userId && currentUserId != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: _navigateToChat,
              tooltip: 'Chat with this director',
            ),
          // ✅ Edit button - only show if viewing own profile
          if (currentUserId == widget.userId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (_director != null) {
                  Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DirectorRegistrationScreen(
                      userId: widget.userId,
                      existingDirector: Director(
                        id: _director!.id!,
                        userId: widget.userId!,
                        position: _director!.position,
                      ),
                      existingNidId: _director!.nid,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadDirector();
                  }
                });
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _director == null
                  ? _buildNotFoundWidget()
                  : _buildProfileContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDirector,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Director Not Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The requested director does not exist.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final director = _director!;
    final isOwnProfile = currentUserId == widget.userId;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(director),
          const SizedBox(height: 20),
          _buildInfoCard(director),
          const SizedBox(height: 20),
          if (director.companies.isNotEmpty) _buildCompaniesSection(director),
          const SizedBox(height: 20),
          // ✅ Action buttons based on user type
          if (isOwnProfile) 
            _buildActionButtons(director),
          if (!isOwnProfile && currentUserId != null)
            _buildChatButton(),
        ],
      ),
    );
  }

  // ✅ Chat button for different users
  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _navigateToChat,
        icon: const Icon(Icons.chat),
        label: const Text(
          'Chat with Director',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(DirectorResponse director) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ✅ Profile Image with loading state
          _buildProfileAvatar(director),
          const SizedBox(height: 12),
          Text(
            director.userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              director.position,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${director.id}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Profile Avatar with image support
  Widget _buildProfileAvatar(DirectorResponse director) {
    final hasImage = _profileImageBytes != null && _profileImageBytes!.isNotEmpty;
    final hasImageId = director.profileImageId != null && director.profileImageId!.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _isImageLoading
              ? const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  ),
                )
              : hasImage
                  ? ClipOval(
                      child: Image.memory(
                        _profileImageBytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Error displaying image: $error');
                          return _buildDefaultAvatar(director);
                        },
                      ),
                    )
                  : _buildDefaultAvatar(director),
        ),
        // ✅ Image status indicator
        if (hasImage)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        if (hasImageId && !hasImage && !_isImageLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar(DirectorResponse director) {
    return Center(
      child: Text(
        director.userName.isNotEmpty
            ? director.userName[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoCard(DirectorResponse director) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow(Icons.email, 'Email', director.email ?? 'Not provided'),
            _buildInfoRow(Icons.phone, 'Phone', director.phone ?? 'Not provided'),
            _buildInfoRow(Icons.location_on, 'Location', director.locationName ?? 'Not provided'),
            if (director.latitude != null && director.longitude != null)
              _buildInfoRow(
                Icons.map,
                'Coordinates',
                '${director.latitude!.toStringAsFixed(4)}, ${director.longitude!.toStringAsFixed(4)}',
              ),
            // ✅ NID Row with View Button
            _buildNIDRow(director),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NID Row with View Button
  Widget _buildNIDRow(DirectorResponse director) {
    final hasNid = director.nid != null && director.nid!.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NID Document',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      hasNid ? director.nid! : 'Not provided',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: hasNid ? Colors.black87 : Colors.grey.shade500,
                      ),
                    ),
                    if (hasNid) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'PDF',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (hasNid)
            ElevatedButton.icon(
              onPressed: () {
                _viewAttachment(director.nid!);
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompaniesSection(DirectorResponse director) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Associated Companies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${director.companies.length}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...director.companies.map((company) => _buildCompanyTile(company)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyTile(CompanyInformation company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            company.companyName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildTag(company.type),
              _buildTag(company.category),
              _buildTag(company.natureOfBusiness),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildActionButtons(DirectorResponse director) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DirectorRegistrationScreen(
                    userId: widget.userId,
                    existingDirector: Director(
                      id: director.id!,
                      userId: widget.userId!,
                      position: director.position,
                    ),
                    existingNidId: director.nid,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  _loadDirector();
                }
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showDeleteConfirmation(director);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(DirectorResponse director) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Director'),
        content: Text(
          'Are you sure you want to delete "${director.userName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final deleted = await _directorService.deleteDirector(
                  director.id!,
                  director.userId!,
                );
                if (deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Director deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}