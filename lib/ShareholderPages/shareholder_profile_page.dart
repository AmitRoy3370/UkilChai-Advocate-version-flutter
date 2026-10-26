// lib/ShareholderPages/shareholder_profile_page.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../ShareholderPages/shareholder_service.dart';
import '../ShareholderPages/shareholder_response.dart';
import '../ShareholderPages/shareholder.dart';
import '../CompanyPages/company_information.dart';
import '../ShareholderPages/shareholder_registration_screen.dart';
import '../ShareholderPages/ShareholderAttachmentViewer.dart';
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'package:shared_preferences/shared_preferences.dart';
import '../ChatRelatedPages/chat_screen.dart';

class ShareholderProfilePage extends StatefulWidget {
  final String? shareholderId;
  final String? userId;

  const ShareholderProfilePage({
    Key? key,
    required this.shareholderId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ShareholderProfilePage> createState() => _ShareholderProfilePageState();
}

class _ShareholderProfilePageState extends State<ShareholderProfilePage> {
  final ShareholderService _shareholderService = ShareholderService();
  ShareholderResponse? _shareholder;
  bool _isLoading = true;
  String? _error;
  String? _jwtToken, currentUserId;
  String? _myName;
  Uint8List? _profileImageBytes;
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndShareholder();
  }

  Future<void> _loadTokenAndShareholder() async {
    _jwtToken = await AuthService.getToken();
    currentUserId = await AuthService.getUserId();
    if (currentUserId != null && currentUserId!.isNotEmpty) {
      await _fetchUserName(currentUserId!);
    }
    await _loadShareholder();
  }

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

  Future<void> _loadShareholder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shareholder = await _shareholderService.getShareholderById(widget.shareholderId!);
      
      print('=== Shareholder Data ===');
      print('Shareholder ID: ${shareholder.id}');
      print('User ID: ${shareholder.userId}');
      print('User Name: ${shareholder.userName}');
      print('Profile Image ID: ${shareholder.profileImageId}');
      print('NID: ${shareholder.nid}');
      print('TIN: ${shareholder.tin}');
      print('Share Percentage: ${shareholder.sharePercentageWithCompanyName}');
      print('=====================');
      
      setState(() {
        _shareholder = shareholder;
        _isLoading = false;
      });
      
      if (shareholder.profileImageId != null && shareholder.profileImageId!.isNotEmpty) {
        await _loadProfileImage(shareholder.profileImageId!);
      } else {
        print('⚠️ No profileImageId found for this shareholder');
      }
    } catch (e) {
      print('Error loading shareholder: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
        builder: (context) => ShareholderAttachmentViewer(
          attachmentId: attachmentId,
          jwtToken: _jwtToken!,
        ),
      ),
    );
  }

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

    if (_shareholder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shareholder data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🔄 Navigating to chat with:');
    print('Current User ID: $currentUserId');
    print('My Name: $_myName');
    print('Shareholder User ID: ${_shareholder!.userId}');
    print('Shareholder Name: ${_shareholder!.userName}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUser: _shareholder!.userId,
          othersName: _shareholder!.userName,
          currentUser: currentUserId!,
          myName: _myName ?? 'User',
        ),
      ),
    );
  }

  // ==================== SHARE PROFIT DIALOG ====================
  void _showShareProfitDialog() {
    if (_shareholder == null) return;
    
    // Get companies where shareholder has percentage
    final companies = _shareholder!.sharePercentageWithCompanyName;
    if (companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not associated with any company to share profit.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedCompanyName;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Profit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a company to share profit:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select Company',
                ),
                value: selectedCompanyName,
                items: companies.keys.map((name) {
                  final percentages = companies[name] ?? [];
                  final percentage = percentages.isNotEmpty ? percentages[0] : 0.0;
                  return DropdownMenuItem(
                    value: name,
                    child: Text('$name (${percentage.toStringAsFixed(2)}%)'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCompanyName = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Profit Percentage',
                  hintText: 'Enter percentage (e.g., 10.5)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedCompanyName == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a company'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final profitPercentage = double.tryParse(controller.text.trim());
              if (profitPercentage == null || profitPercentage <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid percentage'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _shareProfit(selectedCompanyName!, profitPercentage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Share Profit'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProfit(String companyName, double percentage) async {
    if (_shareholder == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the company ID from the company name
      String? companyId;
      for (var entry in _shareholder!.sharePercentageWithCompanyName.entries) {
        if (entry.key == companyName) {
          // We need to find the actual company ID from the original sharePercentage map
          // Since we have the company name, we need to look it up from the companies list
          for (var company in _shareholder!.companies) {
            if (company.companyName == companyName) {
              companyId = company.id;
              break;
            }
          }
          break;
        }
      }

      if (companyId == null || companyId.isEmpty) {
        throw Exception('Company ID not found');
      }

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please login again');
      }

      final url = Uri.parse(
        '${BASE_URL.Urls().baseURL}shareholders/share-profit?companyId=$companyId&percentage=$percentage&holderId=${_shareholder!.id}&userId=${_shareholder!.userId}'
      );
      
      print('📤 Sharing profit to: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Share profit response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Profit shared successfully for $companyName!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadShareholder(); // Reload data
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      print('❌ Error sharing profit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shareholder Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShareholder,
          ),
          // ✅ Share Profit Button for own profile
          if (currentUserId == widget.userId)
            IconButton(
              icon: const Icon(Icons.percent),
              onPressed: _showShareProfitDialog,
              tooltip: 'Share Profit',
            ),
          if (currentUserId != widget.userId && currentUserId != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: _navigateToChat,
              tooltip: 'Chat with this shareholder',
            ),
          if (currentUserId == widget.userId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (_shareholder != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShareholderRegistrationScreen(
                        userId: widget.userId,
                        existingShareholder: Shareholder(
                          id: _shareholder!.id!,
                          userId: widget.userId!,
                          nid: _shareholder!.nid,
                          tin: _shareholder!.tin,
                        ),
                        existingNidId: _shareholder!.nid,
                        existingTinId: _shareholder!.tin,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadShareholder();
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
              : _shareholder == null
                  ? _buildNotFoundWidget()
                  : _buildProfileContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Error: $_error', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadShareholder,
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
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Shareholder Not Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('The requested shareholder does not exist.', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final shareholder = _shareholder!;
    final isOwnProfile = currentUserId == widget.userId;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(shareholder),
          const SizedBox(height: 20),
          _buildInfoCard(shareholder),
          const SizedBox(height: 20),
          // ✅ Share Percentage Table
          if (shareholder.sharePercentageWithCompanyName.isNotEmpty)
            _buildSharePercentageSection(shareholder),
          const SizedBox(height: 20),
          if (shareholder.companies.isNotEmpty) _buildCompaniesSection(shareholder),
          const SizedBox(height: 20),
          if (isOwnProfile) 
            _buildActionButtons(shareholder),
          if (!isOwnProfile && currentUserId != null)
            _buildChatButton(),
        ],
      ),
    );
  }

  // ✅ Share Percentage Section with improved Table
  Widget _buildSharePercentageSection(ShareholderResponse shareholder) {
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
                const Icon(Icons.pie_chart, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Share Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${shareholder.sharePercentageWithCompanyName.length}',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ✅ Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Company Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Percentage',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ✅ Table Rows
            ...shareholder.sharePercentageWithCompanyName.entries.map((entry) {
              final companyName = entry.key;
              final values = entry.value;
              final percentage = values.isNotEmpty ? values[0] : 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: percentage >= 50 
                              ? Colors.green.shade100 
                              : percentage >= 25 
                                  ? Colors.orange.shade100 
                                  : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${percentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: percentage >= 50 
                                ? Colors.green.shade700 
                                : percentage >= 25 
                                    ? Colors.orange.shade700 
                                    : Colors.blue.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            // ✅ Total Row
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${shareholder.sharePercentageWithCompanyName.values.fold<double>(0, (sum, value) => sum + (value.isNotEmpty ? value[0] : 0)).toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _navigateToChat,
        icon: const Icon(Icons.chat),
        label: const Text(
          'Chat with Shareholder',
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

  Widget _buildProfileHeader(ShareholderResponse shareholder) {
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
          _buildProfileAvatar(shareholder),
          const SizedBox(height: 12),
          Text(
            shareholder.userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${shareholder.id}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(ShareholderResponse shareholder) {
    final hasImage = _profileImageBytes != null && _profileImageBytes!.isNotEmpty;
    final hasImageId = shareholder.profileImageId != null && shareholder.profileImageId!.isNotEmpty;

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
                          return _buildDefaultAvatar(shareholder);
                        },
                      ),
                    )
                  : _buildDefaultAvatar(shareholder),
        ),
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

  Widget _buildDefaultAvatar(ShareholderResponse shareholder) {
    return Center(
      child: Text(
        shareholder.userName.isNotEmpty
            ? shareholder.userName[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoCard(ShareholderResponse shareholder) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow(Icons.email, 'Email', shareholder.email ?? 'Not provided'),
            _buildInfoRow(Icons.phone, 'Phone', shareholder.phone ?? 'Not provided'),
            _buildInfoRow(Icons.location_on, 'Location', shareholder.locationName ?? 'Not provided'),
            _buildAttachmentRow(
              icon: Icons.picture_as_pdf,
              label: 'NID Document',
              value: shareholder.nid,
              color: Colors.red,
              onView: shareholder.nid != null && shareholder.nid!.isNotEmpty 
                  ? () => _viewAttachment(shareholder.nid!)
                  : null,
            ),
            _buildAttachmentRow(
              icon: Icons.assignment,
              label: 'TIN Document',
              value: shareholder.tin,
              color: Colors.orange,
              onView: shareholder.tin != null && shareholder.tin!.isNotEmpty 
                  ? () => _viewAttachment(shareholder.tin!)
                  : null,
            ),
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
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow({
    required IconData icon,
    required String label,
    required String? value,
    required Color color,
    VoidCallback? onView,
  }) {
    final hasAttachment = value != null && value.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
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
                Row(
                  children: [
                    Text(
                      hasAttachment ? value! : 'Not provided',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: hasAttachment ? Colors.black87 : Colors.grey.shade500,
                      ),
                    ),
                    if (hasAttachment) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          'PDF',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
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
          if (hasAttachment && onView != null)
            ElevatedButton.icon(
              onPressed: onView,
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

  Widget _buildCompaniesSection(ShareholderResponse shareholder) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Associated Companies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${shareholder.companies.length}',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...shareholder.companies.map((company) => _buildCompanyTile(company)),
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
          Text(company.companyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
      child: Text(label, style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
    );
  }

  Widget _buildActionButtons(ShareholderResponse shareholder) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShareholderRegistrationScreen(
                        userId: widget.userId,
                        existingShareholder: Shareholder(
                          id: shareholder.id!,
                          userId: widget.userId!,
                          nid: shareholder.nid,
                          tin: shareholder.tin,
                        ),
                        existingNidId: shareholder.nid,
                        existingTinId: shareholder.tin,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadShareholder();
                    }
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(shareholder),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ✅ Share Profit Button
        if (_shareholder!.sharePercentageWithCompanyName.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showShareProfitDialog,
              icon: const Icon(Icons.percent),
              label: const Text(
                'Share Profit',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
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

  void _showDeleteConfirmation(ShareholderResponse shareholder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shareholder'),
        content: Text('Are you sure you want to delete "${shareholder.userName}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final deleted = await _shareholderService.deleteShareholder(shareholder.id!, shareholder.userId);
                if (deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shareholder deleted successfully'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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