// lib/backend/profile_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'api_exception.dart';

class ProfileApi {
  static Future<Map<String, dynamic>> getProfile({required String accessToken}) async {
    final String url = "${ApiConstants.baseUrl}/api/v1/website/users/me";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    

    final int status = response.statusCode;

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }

    if (status == 200) {
      if (data is Map<String, dynamic>) return data;
      throw ApiException(statusCode: status, message: "رد غير متوقع من الخادم", details: data);
    }

    if (data is Map<String, dynamic>) {
      String message = data["message"]?.toString() ?? "فشل الحصول على بيانات المستخدم";
      throw ApiException(statusCode: status, message: message, details: data);
    }

    throw ApiException(statusCode: status, message: "فشل الاتصال بالخادم", details: data);
  }
}
