// lib/ShareholderPages/shareholder_list_page.dart
import 'package:flutter/material.dart';
import '../ShareholderPages/shareholder_service.dart';
import '../ShareholderPages/shareholder_response.dart';
import '../ShareholderPages/shareholder_profile_page.dart';

class ShareholderListPage extends StatefulWidget {
  const ShareholderListPage({Key? key}) : super(key: key);

  @override
  State<ShareholderListPage> createState() => _ShareholderListPageState();
}

class _ShareholderListPageState extends State<ShareholderListPage> {
  final ShareholderService _shareholderService = ShareholderService();
  List<ShareholderResponse> _shareholders = [];
  List<ShareholderResponse> _filteredShareholders = [];
  bool _isLoading = true;
  String? _error;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadShareholders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShareholders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shareholders = await _shareholderService.getAllShareholders();
      setState(() {
        _shareholders = shareholders;
        _filteredShareholders = shareholders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      
      if (_searchQuery.isEmpty) {
        _filteredShareholders = _shareholders;
      } else {
        _filteredShareholders = _shareholders.where((shareholder) {
          final name = shareholder.userName.toLowerCase();
          final email = (shareholder.email ?? '').toLowerCase();
          final phone = shareholder.phone ?? '';
          
          return name.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              phone.contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _applySearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Shareholders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShareholders,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _applySearch,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadShareholders, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_shareholders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Shareholders Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('There are no shareholders registered yet.'),
          ],
        ),
      );
    }

    if (_filteredShareholders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No matching shareholders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Try adjusting your search terms.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _clearSearch, child: const Text('Clear Search')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShareholders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredShareholders.length,
        itemBuilder: (context, index) {
          final shareholder = _filteredShareholders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShareholderProfilePage(
                      shareholderId: shareholder.id!,
                      userId: shareholder.userId,
                    ),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  shareholder.userName.isNotEmpty ? shareholder.userName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ),
              title: Text(shareholder.userName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shareholder.email != null && shareholder.email!.isNotEmpty)
                    Text(shareholder.email!, style: const TextStyle(fontSize: 12)),
                  if (shareholder.phone != null && shareholder.phone!.isNotEmpty)
                    Text(shareholder.phone!, style: const TextStyle(fontSize: 12)),
                  if (shareholder.companies.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${shareholder.companies.length} companies',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}