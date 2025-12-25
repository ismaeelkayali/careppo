import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'api_exception.dart';

class LoginApi {
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    final String url = "${ApiConstants.baseUrl}/api/v1/website/auth/login";

    final Map<String, dynamic> body = {
      "phoneNumber": phoneNumber,
      "password": password,
    };

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
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

      if (status == 200 || status == 201) {
        if (data is Map<String, dynamic>) return data;
        throw ApiException(
            statusCode: status, message: "رد غير متوقع من الخادم", details: data);
      }

      if (data is Map<String, dynamic>) {
        String message = "";
        if (data["error"] is Map) {
          message = data["error"]["message"]?.toString() ?? "";
        }
        if (message.trim().isEmpty && data["message"] != null) {
          message = data["message"].toString();
        }
        if (message.trim().isEmpty) message = "فشل تسجيل الدخول";
        throw ApiException(statusCode: status, message: message, details: data);
      }

      throw ApiException(
          statusCode: status, message: "فشل الاتصال بالخادم", details: data);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: "تعذر الاتصال بالإنترنت.",
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: "انتهت مهلة الاتصال بالخادم.",
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: e.toString(),
      );
    }
  }
}
