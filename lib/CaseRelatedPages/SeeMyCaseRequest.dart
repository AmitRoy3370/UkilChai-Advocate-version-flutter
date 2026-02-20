import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './case_request.dart';
import './case_request_service.dart';
import './edit_case_request_page.dart';
import '../Utils/AdvocateSpeciality.dart';

class SeeMyCaseRequestsPage extends StatefulWidget {
  const SeeMyCaseRequestsPage({super.key});

  @override
  State<SeeMyCaseRequestsPage> createState() => _SeeMyCaseRequestListPageState();
}

class _SeeMyCaseRequestListPageState extends State<SeeMyCaseRequestsPage> {
  final service = CaseRequestService();
  List<CaseRequest> list = [];
  bool loading = true;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';

    list = await service.byUser(userId);
    setState(() => loading = false);
  }

  Future<void> deleteCase(CaseRequest c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete '${c.caseName}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => loading = true);
      await service.deleteCase(c.id, c.userId);
      await loadAll(); // refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Case Requests")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                labelText: "Search case",
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (v) async {
                setState(() => loading = true);
                list = await service.searchByName(v);
                setState(() => loading = false);
              },
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return Card(
                  child: ListTile(
                    title: Text(c.caseName),
                    subtitle: Text(c.caseType.label), // can use label if needed
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteCase(c),
                    ),
                    onTap: () async {
                      // Go to EditCaseRequestPage and refresh list if updated
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditCaseRequestPage(caseRequest: c),
                        ),
                      );
                      if (updated == true) {
                        await loadAll();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
