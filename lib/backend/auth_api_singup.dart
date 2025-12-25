import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'api_exception.dart';

class AuthApi {
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String countryCode,
    String role = "user",
  }) async {
    final String url = "${ApiConstants.baseUrl}/api/v1/website/auth/sign-up";

    final Map<String, dynamic> body = {
      "email": email,
      "password": password,
      "firstName": firstName,
      "lastName": lastName,
      "phoneNumber": phoneNumber,
      "countryCode": countryCode,
      "role": role,
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
          .timeout(const Duration(seconds: 120));

      

      final int status = response.statusCode;

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }

      if (status == 200 || status == 201) {
        if (data is Map<String, dynamic>) return data;
        return {"message": "Success", "data": data};
      }

      if (data is Map<String, dynamic>) {
        String message = "";

        if (data["error"] is Map) {
          message = data["error"]["message"]?.toString() ?? "";
        }

        if (message.isEmpty && data["message"] != null) {
          message = data["message"].toString();
        }

        if (message.isEmpty && data["errors"] != null) {
          message = data["errors"].toString();
        }

        if (message.trim().isEmpty) message = "خطأ غير معروف من الخادم";

        throw ApiException(statusCode: status, message: message, details: data);
      }

      throw ApiException(
          statusCode: status,
          message: "فشل الاتصال بالخادم. الرد غير مفهوم.",
          details: data);
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
