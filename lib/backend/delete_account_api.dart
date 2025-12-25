import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'api_exception.dart';

class DeleteAccountApi {
  /// حذف جميع طلبات المستخدم
 static Future<void> _deleteUserOrders(String accessToken) async {
  final String url = "${ApiConstants.baseUrl}/api/v1/website/orders/my-orders";

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);

    // استجابة السيرفر = { total, results: [...] }
    if (data is! Map || data["results"] is! List) return;

    List orders = data["results"];

    for (var order in orders) {
      final String? id = order["id"];
      if (id == null) continue;

      final deleteUrl =
          "${ApiConstants.baseUrl}/api/v1/website/orders/$id";

      await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      ).timeout(const Duration(seconds: 30));
    }
  } catch (_) {
    // تجاهل الأخطاء
  }
}


  /// حذف حساب المستخدم مع حذف طلباته أولًا
  static Future<void> deleteAccount({required String accessToken}) async {
    final String url = "${ApiConstants.baseUrl}/api/v1/website/users/me";

    try {
      // 1) حذف الطلبات
      await _deleteUserOrders(accessToken);

      // 2) حذف الحساب
      final response = await http
          .delete(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $accessToken",
            },
          )
          .timeout(const Duration(seconds: 120));

      final int status = response.statusCode;

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }

      if (status == 200 || status == 204) {
        return;
      }

      if (data is Map<String, dynamic>) {
        String message = "";

        if (data["error"] is Map) {
          message = data["error"]["message"]?.toString() ?? "";
        }

        if (message.trim().isEmpty && data["message"] != null) {
          message = data["message"].toString();
        }

        if (message.trim().isEmpty) message = "فشل حذف الحساب";

        throw ApiException(statusCode: status, message: message, details: data);
      }

      throw ApiException(
        statusCode: status,
        message: "فشل الاتصال بالخادم",
        details: data,
      );
    } on SocketException {
      throw ApiException(statusCode: 0, message: "تعذر الاتصال بالإنترنت.");
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: "انتهت مهلة الاتصال بالخادم.");
    } catch (e) {
      throw ApiException(statusCode: 0, message: e.toString());
    }
  }
}
