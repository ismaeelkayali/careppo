// lib/backend/update_password_api.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'api_exception.dart';

class UpdatePasswordApi {
  static Future<void> updatePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final String url = "${ApiConstants.baseUrl}/api/v1/website/users/update-password";

    final Map<String, dynamic> body = {
      "password": currentPassword,
      "newPassword": newPassword,
    };

    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $accessToken",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120)); // مهلة 15 ثانية

      final int status = response.statusCode;

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }

      // نجاح
      if (status == 200 || status == 201) {
        return;
      }

      // خطأ من السيرفر
      if (data is Map<String, dynamic>) {
        String message = "";

        if (data["error"] is Map) {
          message = data["error"]["message"]?.toString() ?? "";
        }

        if (message.trim().isEmpty && data["message"] != null) {
          message = data["message"].toString();
        }

        if (message.trim().isEmpty) message = "حدث خطأ أثناء تغيير كلمة المرور";

        throw ApiException(statusCode: status, message: message, details: data);
      }

      throw ApiException(statusCode: status, message: "فشل الاتصال بالخادم", details: data);

    } on SocketException {
      throw ApiException(statusCode: 0, message: "تعذر الاتصال بالإنترنت.");
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: "انتهت مهلة الاتصال بالخادم.");
    } catch (e) {
      throw ApiException(statusCode: 0, message: e.toString());
    }
  }
}
