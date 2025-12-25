// backend/user_status_api.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:careppo/backend/constants.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

class UserStatusApi {
  static const String baseUrl = "${ApiConstants.baseUrl}/api/v1/website";

  /// جلب حالة المستخدم الحالي (isActive) باستخدام التوكن
  /// يعيد true إذا نشط، false إذا غير نشط، ويرمي ApiException عند الخطأ
  static Future<bool> fetchUserIsActive(String accessToken) async {
    final url = "$baseUrl/users/me";

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "Authorization": "Bearer $accessToken",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10)); // حماية من التأخير الطويل

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey("isActive")) {
          return data["isActive"] == true;
        } else {
          throw ApiException(
            statusCode: 200,
            message: "الحقل 'isActive' غير موجود في الاستجابة",
          );
        }
      } else if (response.statusCode == 401) {
        // توكن غير صالح أو منتهي
        throw ApiException(
          statusCode: 401,
          message: "غير مسموح: توكن غير صالح",
        );
      } else {
        // أي خطأ آخر
        String msg = "فشل جلب حالة المستخدم";
        try {
          final body = jsonDecode(response.body);
          msg = body["message"]?.toString() ?? msg;
        } catch (_) {}
        throw ApiException(statusCode: response.statusCode, message: msg);
      }
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: "لا يوجد اتصال بالإنترنت",
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: "انتهت مهلة الاتصال بالخادم",
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: "خطأ غير متوقع: $e",
      );
    }
  }
}
