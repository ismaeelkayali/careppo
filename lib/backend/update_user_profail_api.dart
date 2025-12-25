// lib/backend/user_api.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'constants.dart';

class UserApi {
  static Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> updatedFields,
    required String accessToken,
  }) async {
    final String url = "${ApiConstants.baseUrl}/api/v1/website/users/me";

    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $accessToken",
            },
            body: jsonEncode(updatedFields),
          )
          .timeout(const Duration(seconds: 120));

      final int status = response.statusCode;

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body; // في حال لم يكن JSON
      }

      // نجاح
      if (status == 200 || status == 201) {
        return data is Map<String, dynamic> ? data : {"success": true};
      }

      // **اخطاء السيرفر**
      if (data is Map<String, dynamic>) {
        String message = "";

        if (data["error"] is Map) {
          message = data["error"]["message"]?.toString() ?? "";
        }

        if (message.trim().isEmpty && data["message"] != null) {
          message = data["message"].toString();
        }

        if (message.trim().isEmpty) {
          message = "حدث خطأ أثناء تحديث البيانات";
        }

        throw ApiException(
          statusCode: status,
          message: message,
          details: data,
        );
      }

      throw ApiException(
        statusCode: status,
        message: "فشل الاتصال بالخادم",
        details: data,
      );
    }

    // **انقطاع الإنترنت**
    on SocketException {
      throw ApiException(
        statusCode: 0,
        message: "تعذر الاتصال بالإنترنت.",
      );
    }

    // **مهلة الاتصال بالخادم**
    on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: "انتهت مهلة الاتصال بالخادم.",
      );
    }

    // أخطاء أخرى
    catch (e) {
      throw ApiException(
        statusCode: 0,
        message: e.toString(),
      );
    }
  }
}
