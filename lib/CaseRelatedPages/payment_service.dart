import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Utils/BaseURL.dart' as BASE_URL;

class PaymentService {
  static String baseUrl = "${BASE_URL.Urls().baseURL}payment";

  // ================= SAVE or UPDATE PRICE (Add if not exists, Update if exists) =================
  static Future<bool> saveOrUpdatePrice({
    required String token,
    required String userId,
    required String caseId,
    required String paymentType,
    required double price,
  }) async {
    try {
      // Step 1: Check if price already exists
      final checkRes = await http.get(
        Uri.parse("$baseUrl/case/$caseId/type/$paymentType"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (checkRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(checkRes.body);
        if (data.isNotEmpty) {
          final paymentId = data.last['id'];

          // UPDATE existing price
          final body = jsonEncode({
            "paymentFor": paymentType,
            "price": price,
            "userId": userId,
            "caseId": caseId,
          });

          final res = await http.put(
            Uri.parse("$baseUrl/update/$paymentId/$userId"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: body,
          );
          return res.statusCode == 200;
        }
      }

      // Step 2: Add new price
      final body = jsonEncode({
        "paymentFor": paymentType,
        "price": price,
        "userId": userId,
        "caseId": caseId,
      });

      final res = await http.post(
        Uri.parse("$baseUrl/add/$userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: body,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("Price save error: $e");
      return false;
    }
  }

  static Future<double?> getCasePaymentPrice(
    String token,
    String caseId,
    String paymentType,
  ) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/case/$caseId/type/$paymentType"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        if (data.isNotEmpty) {
          final lastItem = data.last; // ✅ LAST INDEX
          return (lastItem["price"] as num).toDouble();
        }
      }
    } catch (e) {
      print("Payment fetch error: $e");
    }

    return null;
  }

  // ================= COUNT OF HEARING PRICES (SAFE VERSION) =================
  static Future<int> getHearingPaymentCount(String token, String caseId) async {
    try {
      print("Counting total hearings price....");

      final res = await http.get(
        Uri.parse("$baseUrl/case/$caseId/type/CASE_HEARING_PAYMENT"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Status code for hearing price count: ${res.statusCode}");

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);

        if (decoded is List) {
          print("✅ total setted hearing price found: ${decoded.length}");
          return decoded.length;
        } else if (decoded is Map) {
          // Backend returned error map or empty response
          print("⚠️ Backend returned Map (no data or error): $decoded");
          return 0;
        }
      } else {
        print("Non-200 status: ${res.statusCode} → ${res.body}");
      }
    } catch (e) {
      print("Hearing price count error: $e");
    }
    return 0; // safe default
  }

}
