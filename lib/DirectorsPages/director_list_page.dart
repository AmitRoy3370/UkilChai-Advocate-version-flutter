// lib/DirectorsPages/director_list_page.dart
import 'package:flutter/material.dart';
import '../../DirectorsPages/director_service.dart';
import '../../DirectorsPages/director_response.dart';
import '../../DirectorsPages/director_profile_page.dart';

class DirectorListPage extends StatefulWidget {
  const DirectorListPage({Key? key}) : super(key: key);

  @override
  State<DirectorListPage> createState() => _DirectorListPageState();
}

class _DirectorListPageState extends State<DirectorListPage> {
  final DirectorService _directorService = DirectorService();
  List<DirectorResponse> _directors = [];
  List<DirectorResponse> _filteredDirectors = [];
  bool _isLoading = true;
  String? _error;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDirectors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectors() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final directors = await _directorService.getAllDirectors();
      if (!mounted) return;
      setState(() {
        _directors = directors;
        _filteredDirectors = directors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterDirectors(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      if (searchQuery.isEmpty) {
        _filteredDirectors = _directors;
      } else {
        _filteredDirectors = _directors.where((director) {
          final name = director.userName.toLowerCase();
          final position = director.position.toLowerCase();
          final email = (director.email ?? '').toLowerCase();
          final phone = director.phone ?? '';
          
          return name.contains(searchQuery) ||
              position.contains(searchQuery) ||
              email.contains(searchQuery) ||
              phone.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterDirectors('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Directors'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDirectors,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search directors...',
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
              onChanged: _filterDirectors,
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
            ElevatedButton(
              onPressed: _loadDirectors,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_directors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Directors Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('There are no directors registered yet.'),
          ],
        ),
      );
    }

    if (_filteredDirectors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No matching directors found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Try adjusting your search terms.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDirectors,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredDirectors.length,
        itemBuilder: (context, index) {
          final director = _filteredDirectors[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DirectorProfilePage(
                      directorId: director.id!,
                      userId: director.userId,
                    ),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  director.userName.isNotEmpty ? director.userName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              title: Text(director.userName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(director.position),
                  if (director.email != null && director.email!.isNotEmpty)
                    Text(director.email!, style: const TextStyle(fontSize: 12)),
                  if (director.companies.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${director.companies.length} companies',
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