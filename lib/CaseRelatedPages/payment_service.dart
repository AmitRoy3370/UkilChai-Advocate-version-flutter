import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Utils/BaseURL.dart' as BASE_URL;

class PaymentService {
  static String baseUrl = "${BASE_URL.Urls().baseURL}payment";

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
}
