import 'dart:convert';

import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './case_request.dart';
import './case_request_service.dart';
import './case_request_details_page.dart';
import '../Utils/AdvocateSpeciality.dart';

class CaseRequestListPage extends StatefulWidget {
  const CaseRequestListPage({super.key});

  @override
  State<CaseRequestListPage> createState() => _CaseRequestListPageState();
}

Future<String> getAdvocateName(String advocateId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token') ?? '';

  final url = "${BASE_URL.Urls().baseURL}advocate/$advocateId";

  final response = await http.get(
    Uri.parse(url),
    headers: {
      "content-type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    final userId = body["userId"];

    return getNameFromUser(userId);
  } else {
    return "";
  }
}

// ---------------- GET USER NAME ----------------
Future<String> getNameFromUser(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token') ?? '';

  final url = "${BASE_URL.Urls().baseURL}user/search?userId=$userId";

  final response = await http.get(
    Uri.parse(url),
    headers: {
      "content-type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    return body["name"] ?? "";
  }
  return "";
}

class _CaseRequestListPageState extends State<CaseRequestListPage> {
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
    list = await service.getAll();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Requests")),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.caseType.label),
                              if (c.requestedAdvocateId != null)
                                FutureBuilder<String>(
                                  future: getAdvocateName(
                                    c.requestedAdvocateId!,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text("Loading advocate...");
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.hasError) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      "Requested Advocate: ${snapshot.data}",
                                    );
                                  },
                                ),
                            ],
                          ),
                          trailing: Text(
                            c.requestDate.toLocal().toString().split(" ").first,
                          ),
                          onTap: () async {
                            final result = await Navigator.push<bool?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CaseRequestDetailsPage(caseRequest: c),
                              ),
                            );

                            if (result == true) {
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
