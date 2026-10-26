// lib/vat/service/vat_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path/path.dart' as path;

import '../models/vat_response_model.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;
import 'vat_auth_helper.dart';   // ✅ NEW

class VatService {
  // ============================================================
  // BASE URL HELPER
  // ============================================================
  static String get _baseUrl => BASE_URL.Urls().baseURL;

  // ============================================================
  // MULTIPART FILE HELPER — works on web + mobile
  // ============================================================
  static http.MultipartFile multipartFromBytes({
    required String field,
    required Uint8List bytes,
    required String fileName,
  }) {
    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: fileName,
      contentType: _mediaTypeForFileName(fileName),
    );
  }

  static Future<http.MultipartFile> multipartFromPath({
    required String field,
    required String filePath,
  }) {
    return http.MultipartFile.fromPath(
      field,
      filePath,
      contentType: _mediaTypeForFile(filePath),
    );
  }

  // ============================================================
  // CREATE — Preferred method (works on web + mobile)
  // POST /api/vat/add
  // ============================================================
  static Future<Map<String, dynamic>> addVatWithFiles({
    required String userId,
    required String adress,
    required String tinNo,
    required String buisnessName,
    required String tradeLicenseNo,
    required String annualTurnOver,
    required String mainProduct,
    required String natureOfBuisness,
    required int numberOfBuisness,
    required int numberOfEmployee,
    String? attachmentsId,
    List<http.MultipartFile> files = const [],
  }) async {
    final uri = Uri.parse('${_baseUrl}vat/add');
    final request = http.MultipartRequest('POST', uri);

    // ✅ JWT
    final bearer = await VatAuthHelper.getBearerToken();
    if (bearer != null) request.headers['Authorization'] = bearer;

    request.fields['userId'] = userId;
    request.fields['adress'] = adress;
    request.fields['tinNo'] = tinNo;
    request.fields['buisnessName'] = buisnessName;
    request.fields['tradeLicenseNo'] = tradeLicenseNo;
    request.fields['annualTurnOver'] = annualTurnOver;
    request.fields['mainProduct'] = mainProduct;
    request.fields['natureOfBuisness'] = natureOfBuisness;
    request.fields['numberOfBuisness'] = numberOfBuisness.toString();
    request.fields['numberOfEmployee'] = numberOfEmployee.toString();

    if (attachmentsId != null && attachmentsId.trim().isNotEmpty) {
      request.fields['attachmentsId'] = attachmentsId.trim();
    }

    request.files.addAll(files);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // ============================================================
  // UPDATE — Preferred method (works on web + mobile)
  // PUT /api/vat/update/{id}
  // ============================================================
  static Future<Map<String, dynamic>> updateVatWithFiles({
    required String id,
    required String userId,
    String? adress,
    String? tinNo,
    String? buisnessName,
    String? tradeLicenseNo,
    String? annualTurnOver,
    String? mainProduct,
    String? natureOfBuisness,
    int? numberOfBuisness,
    int? numberOfEmployee,
    String? attachmentsId,
    List<http.MultipartFile> files = const [],
  }) async {
    final uri = Uri.parse('${_baseUrl}vat/update/$id');
    final request = http.MultipartRequest('PUT', uri);

    // ✅ JWT
    final bearer = await VatAuthHelper.getBearerToken();
    if (bearer != null) request.headers['Authorization'] = bearer;

    request.fields['userId'] = userId;

    if (adress != null && adress.trim().isNotEmpty) {
      request.fields['adress'] = adress.trim();
    }
    if (tinNo != null && tinNo.trim().isNotEmpty) {
      request.fields['tinNo'] = tinNo.trim();
    }
    if (buisnessName != null && buisnessName.trim().isNotEmpty) {
      request.fields['buisnessName'] = buisnessName.trim();
    }
    if (tradeLicenseNo != null && tradeLicenseNo.trim().isNotEmpty) {
      request.fields['tradeLicenseNo'] = tradeLicenseNo.trim();
    }
    if (annualTurnOver != null && annualTurnOver.trim().isNotEmpty) {
      request.fields['annualTurnOver'] = annualTurnOver.trim();
    }
    if (mainProduct != null && mainProduct.trim().isNotEmpty) {
      request.fields['mainProduct'] = mainProduct.trim();
    }
    if (natureOfBuisness != null && natureOfBuisness.trim().isNotEmpty) {
      request.fields['natureOfBuisness'] = natureOfBuisness.trim();
    }
    if (numberOfBuisness != null) {
      request.fields['numberOfBuisness'] = numberOfBuisness.toString();
    }
    if (numberOfEmployee != null) {
      request.fields['numberOfEmployee'] = numberOfEmployee.toString();
    }
    if (attachmentsId != null && attachmentsId.trim().isNotEmpty) {
      request.fields['attachmentsId'] = attachmentsId.trim();
    }

    request.files.addAll(files);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // ============================================================
  // CREATE — Legacy (path-based, mobile only)
  // ============================================================
  static Future<Map<String, dynamic>> addVat({
    required String userId,
    required String adress,
    required String tinNo,
    required String buisnessName,
    required String tradeLicenseNo,
    required String annualTurnOver,
    required String mainProduct,
    required String natureOfBuisness,
    required int numberOfBuisness,
    required int numberOfEmployee,
    String? attachmentsId,
    List<String> documentPaths = const [],
  }) async {
    final uri = Uri.parse('${_baseUrl}vat/add');
    final request = http.MultipartRequest('POST', uri);

    // ✅ JWT
    final bearer = await VatAuthHelper.getBearerToken();
    if (bearer != null) request.headers['Authorization'] = bearer;

    request.fields['userId'] = userId;
    request.fields['adress'] = adress;
    request.fields['tinNo'] = tinNo;
    request.fields['buisnessName'] = buisnessName;
    request.fields['tradeLicenseNo'] = tradeLicenseNo;
    request.fields['annualTurnOver'] = annualTurnOver;
    request.fields['mainProduct'] = mainProduct;
    request.fields['natureOfBuisness'] = natureOfBuisness;
    request.fields['numberOfBuisness'] = numberOfBuisness.toString();
    request.fields['numberOfEmployee'] = numberOfEmployee.toString();

    if (attachmentsId != null && attachmentsId.trim().isNotEmpty) {
      request.fields['attachmentsId'] = attachmentsId.trim();
    }

    for (final filePath in documentPaths) {
      try {
        final multipartFile = await http.MultipartFile.fromPath(
          'documents',
          filePath,
          contentType: _mediaTypeForFile(filePath),
        );
        request.files.add(multipartFile);
      } catch (_) {}
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // ============================================================
  // UPDATE — Legacy (path-based, mobile only)
  // ============================================================
  static Future<Map<String, dynamic>> updateVat({
    required String id,
    required String userId,
    String? adress,
    String? tinNo,
    String? buisnessName,
    String? tradeLicenseNo,
    String? annualTurnOver,
    String? mainProduct,
    String? natureOfBuisness,
    int? numberOfBuisness,
    int? numberOfEmployee,
    String? attachmentsId,
    List<String> documentPaths = const [],
  }) async {
    final uri = Uri.parse('${_baseUrl}vat/update/$id');
    final request = http.MultipartRequest('PUT', uri);

    // ✅ JWT
    final bearer = await VatAuthHelper.getBearerToken();
    if (bearer != null) request.headers['Authorization'] = bearer;

    request.fields['userId'] = userId;

    if (adress != null && adress.trim().isNotEmpty) {
      request.fields['adress'] = adress.trim();
    }
    if (tinNo != null && tinNo.trim().isNotEmpty) {
      request.fields['tinNo'] = tinNo.trim();
    }
    if (buisnessName != null && buisnessName.trim().isNotEmpty) {
      request.fields['buisnessName'] = buisnessName.trim();
    }
    if (tradeLicenseNo != null && tradeLicenseNo.trim().isNotEmpty) {
      request.fields['tradeLicenseNo'] = tradeLicenseNo.trim();
    }
    if (annualTurnOver != null && annualTurnOver.trim().isNotEmpty) {
      request.fields['annualTurnOver'] = annualTurnOver.trim();
    }
    if (mainProduct != null && mainProduct.trim().isNotEmpty) {
      request.fields['mainProduct'] = mainProduct.trim();
    }
    if (natureOfBuisness != null && natureOfBuisness.trim().isNotEmpty) {
      request.fields['natureOfBuisness'] = natureOfBuisness.trim();
    }
    if (numberOfBuisness != null) {
      request.fields['numberOfBuisness'] = numberOfBuisness.toString();
    }
    if (numberOfEmployee != null) {
      request.fields['numberOfEmployee'] = numberOfEmployee.toString();
    }
    if (attachmentsId != null && attachmentsId.trim().isNotEmpty) {
      request.fields['attachmentsId'] = attachmentsId.trim();
    }

    for (final filePath in documentPaths) {
      try {
        final multipartFile = await http.MultipartFile.fromPath(
          'documents',
          filePath,
          contentType: _mediaTypeForFile(filePath),
        );
        request.files.add(multipartFile);
      } catch (_) {}
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // ============================================================
  // READ — By ID
  // ============================================================
  static Future<VatResponseModel> findById(String id) async {
    final uri = Uri.parse('${_baseUrl}vat/$id');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    return VatResponseModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — All
  // ============================================================
  static Future<List<VatResponseModel>> findAll() async {
    final uri = Uri.parse('${_baseUrl}vat/all');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // READ — By User ID
  // ============================================================
  static Future<List<VatResponseModel>> findByUserId(String userId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/userId?userId=${Uri.encodeQueryComponent(userId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Adress
  // ============================================================
  static Future<List<VatResponseModel>> findByAdress(String adress) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/adress?adress=${Uri.encodeQueryComponent(adress)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By TIN No
  // ============================================================
  static Future<List<VatResponseModel>> findByTinNo(String tinNo) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/tinNo?tinNo=${Uri.encodeQueryComponent(tinNo)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Business Name
  // ============================================================
  static Future<List<VatResponseModel>> findByBuisnessName(
      String buisnessName) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/buisnessName?buisnessName=${Uri.encodeQueryComponent(buisnessName)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Trade License No
  // ============================================================
  static Future<List<VatResponseModel>> findByTradeLicenseNo(
      String tradeLicenseNo) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/tradeLicenseNo?tradeLicenseNo=${Uri.encodeQueryComponent(tradeLicenseNo)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Annual TurnOver
  // ============================================================
  static Future<List<VatResponseModel>> findByAnnualTurnOver(
      String annualTurnOver) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/annualTurnOver?annualTurnOver=${Uri.encodeQueryComponent(annualTurnOver)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Main Product
  // ============================================================
  static Future<List<VatResponseModel>> findByMainProduct(
      String mainProduct) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/mainProduct?mainProduct=${Uri.encodeQueryComponent(mainProduct)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Nature of Business
  // ============================================================
  static Future<List<VatResponseModel>> findByNatureOfBuisness(
      String natureOfBuisness) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/natureOfBuisness?natureOfBuisness=${Uri.encodeQueryComponent(natureOfBuisness)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Number of Business >=
  // ============================================================
  static Future<List<VatResponseModel>> findByNumberOfBuisnessGTE(
      int numberOfBuisness) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/numberOfBuisness/greaterThanEqual?numberOfBuisness=$numberOfBuisness');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Number of Business <=
  // ============================================================
  static Future<List<VatResponseModel>> findByNumberOfBuisnessLTE(
      int numberOfBuisness) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/numberOfBuisness/lessThanEqual?numberOfBuisness=$numberOfBuisness');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Number of Employee >=
  // ============================================================
  static Future<List<VatResponseModel>> findByNumberOfEmployeeGTE(
      int numberOfEmployee) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/numberOfEmployee/greaterThanEqual?numberOfEmployee=$numberOfEmployee');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Number of Employee <=
  // ============================================================
  static Future<List<VatResponseModel>> findByNumberOfEmployeeLTE(
      int numberOfEmployee) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/numberOfEmployee/lessThanEqual?numberOfEmployee=$numberOfEmployee');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Document
  // ============================================================
  static Future<List<VatResponseModel>> findByDocuments(
      String documents) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/search/documents?documents=${Uri.encodeQueryComponent(documents)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // DELETE
  // ============================================================
  static Future<bool> deleteVat({
    required String id,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat/delete/$id?userId=${Uri.encodeQueryComponent(userId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.delete(uri, headers: headers);

    final json = _handleResponse(response);
    return json['status'] == 'success';
  }

  // ============================================================
  // HELPERS
  // ============================================================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Non-JSON body (e.g. 401 Unauthorized from Spring Security)
      throw Exception(
          'Request failed (${response.statusCode}): ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          json['message'] ?? 'Request failed (${response.statusCode})');
    }

    if (json['status'] == 'error') {
      throw Exception(json['message'] ?? 'Unknown error');
    }

    return json;
  }

  static MediaType _mediaTypeForFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase().replaceFirst('.', '');
    return _mediaTypeForExt(ext);
  }

  static MediaType _mediaTypeForFileName(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        : '';
    return _mediaTypeForExt(ext);
  }

  static MediaType _mediaTypeForExt(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'xlsx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      case 'txt':
        return MediaType('text', 'plain');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}