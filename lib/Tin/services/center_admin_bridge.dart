// lib/Vat/service/center_admin_bridge.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

class CenterAdminBridge {
  static String _centerAdminUrl = '${BASE_URL.Urls().baseURL}center-admin';
  static String _advocateUrl = '${BASE_URL.Urls().baseURL}advocate';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// Returns the CenterAdmin's document `id` for the given user.
  static Future<String> myCenterAdminId(String userId) async {
    final headers = await _headers();

    final res = await http.get(
      Uri.parse('$_centerAdminUrl/by-user/$userId'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load center admin (${res.statusCode})');
    }

    final body = jsonDecode(res.body);

    final id = (body['id'] ?? body['centerAdminId'] ?? body['_id'] ?? '')
        .toString();

    if (id.isEmpty) {
      throw Exception('CenterAdmin id not found in response: $body');
    }
    return id;
  }

  /// Loads advocates connected to this center admin.
  static Future<List<AdvocateBrief>> myAdvocates(String userId) async {
    final headers = await _headers();

    final res = await http.get(
      Uri.parse('$_centerAdminUrl/by-user/$userId'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load center admin (${res.statusCode})');
    }

    final body = jsonDecode(res.body);

    final ids = (body['advocates'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>[];

    final fullNames = (body['advocatesFullName'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final names =
        (body['advocatesName'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];

    final result = <AdvocateBrief>[];
    for (int i = 0; i < ids.length; i++) {
      String display = ids[i];
      if (i < fullNames.length && fullNames[i].isNotEmpty) {
        display = fullNames[i];
      } else if (i < names.length && names[i].isNotEmpty) {
        display = names[i];
      } else {
        try {
          final advRes = await http.get(
            Uri.parse('$_advocateUrl/${ids[i]}'),
            headers: headers,
          );
          if (advRes.statusCode == 200) {
            final adv = jsonDecode(advRes.body);
            final fn = (adv['fullName'] ?? adv['name'] ?? '').toString();
            if (fn.isNotEmpty) display = fn;
          }
        } catch (_) {}
      }
      result.add(AdvocateBrief(id: ids[i], name: display));
    }
    return result;
  }
}

class AdvocateBrief {
  final String id;
  final String name;
  const AdvocateBrief({required this.id, required this.name});
}