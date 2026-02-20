import 'package:dio/dio.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class ApiClient {
  static Dio dio(String token) {
    return Dio(
      BaseOptions(
        baseUrl: BASE_URL.Urls().baseURL.replaceFirst('/api/', '/'), // 🔥 change this
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );
  }
}
