// lib/backend/BookingApi.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:careppo/backend/constants.dart';
import 'api_exception.dart';
import 'error_translator.dart';

class BookingApi {
  final String baseUrl = "${ApiConstants.baseUrl}/api/v1/website/orders";

  /// إنشاء طلب حجز جديد (POST /orders)
  Future<bool> createOrder({
    required String carId,
    required int quantity,
    required String fullName,
    required String phoneNumber,
    required bool needsDriver,
    required String startDate, // ISO string
    required String endDate,   // ISO string
    required String accessToken,
    String notes = "",
  }) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "carId": carId,
          "quantity": quantity,
          "notes": notes,
          "startDate": startDate,
          "endDate": endDate,
          "fullName": fullName,
          "phoneNumber": phoneNumber,
          "needsDriver": needsDriver
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return true;
      } else {
        throw ApiException(
          statusCode: res.statusCode,
          message: ErrorTranslator.translate(res.body.toString()),
          details: res.body,
        );
      }
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: ErrorTranslator.translate(e.toString()),
        details: e,
      );
    }
  }

  /// تحديث طلب موجود (PUT /orders/{id})
  Future<bool> updateOrder({
  required String orderId,
  required String carId,
  required int quantity,
  required String fullName,
  required String phoneNumber,
  required bool needsDriver,
  required String startDate,
  required String endDate,
  required String accessToken,
  String notes = "",
}) async {
  try {
    print("===== إرسال طلب تعديل الحجز =====");
    print("PATCH → $baseUrl/$orderId");
    print("Body:");
    print({
      "carId": carId,
      "quantity": quantity,
      "notes": notes,
      "startDate": startDate,
      "endDate": endDate,
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "needsDriver": needsDriver
    });

    final res = await http.patch(
      Uri.parse("$baseUrl/$orderId"),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "carId": carId,
        "quantity": quantity,
        "notes": notes,
        "startDate": startDate,
        "endDate": endDate,
        "fullName": fullName,
        "phoneNumber": phoneNumber,
        "needsDriver": needsDriver,
      }),
    );

    print("===== استجابة السيرفر =====");
    print("Status Code: ${res.statusCode}");
    print("Response Body: ${res.body}");

    if (res.statusCode == 200) {
      print("✔ تم تعديل الحجز بنجاح");
      return true;
    } else {
      print("❌ خطأ من السيرفر أثناء التعديل");
      throw ApiException(
        statusCode: res.statusCode,
        message: "Server Error",
        details: res.body,
      );
    }
  } catch (e, stacktrace) {
    print("===== خطأ داخلي أثناء إرسال طلب التعديل =====");
    print("Error: $e");
    print("Stacktrace: $stacktrace");

    throw ApiException(
      statusCode: 500,
      message: "Unexpected Error",
      details: "$e\n$stacktrace",
    );
  }
}

  /// حذف طلب (DELETE /orders/{id})
  Future<bool> deleteOrder({
    required String orderId,
    required String accessToken,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/$orderId"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        throw ApiException(
          statusCode: res.statusCode,
          message: ErrorTranslator.translate(res.body.toString()),
          details: res.body,
        );
      }
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: ErrorTranslator.translate(e.toString()),
        details: e,
      );
    }
  }

  /// جلب حجوزات المستخدم (GET /orders/my-orders)
  Future<List<Map<String, dynamic>>> getMyOrders({
    required String accessToken,
  }) async {
    try {
      print("🔵 Access Token used in getMyOrders: $accessToken");

      final res = await http.get(
        Uri.parse("$baseUrl/my-orders"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
    


      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // استجابة متوقعة: { total, results: [ ... ] }
        final results = (body["results"] as List?) ?? [];
        return results.map<Map<String, dynamic>>((e) {
          if (e is Map<String, dynamic>) return e;
          return Map<String, dynamic>.from(e);
        }).toList();
      } else {
        throw ApiException(
          statusCode: res.statusCode,
          message: ErrorTranslator.translate(res.body.toString()),
          details: res.body,
        );
      }
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: ErrorTranslator.translate(e.toString()),
        details: e,
      );
    }
  }

  /// جلب الحجوزات لسيارة معينة (بواسطة endpoint by-car)
  Future<List<Map<String, dynamic>>> getOrdersForCar({
    required String carId,
    required String accessToken,
  }) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/by-car/$carId"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final results = (body["results"] as List?) ?? [];
        return results.map<Map<String, dynamic>>((e) {
          if (e is Map<String, dynamic>) return e;
          return Map<String, dynamic>.from(e);
        }).toList();
      } else {
        throw ApiException(
          statusCode: res.statusCode,
          message: ErrorTranslator.translate(res.body.toString()),
          details: res.body,
        );
      }
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: ErrorTranslator.translate(e.toString()),
        details: e,
      );
    }
  }
}
