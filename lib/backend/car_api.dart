import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:careppo/backend/constants.dart';
import 'api_exception.dart';
import 'error_translator.dart';

class CarApi {
  final String url = "${ApiConstants.baseUrl}/api/v1/website/cars";

  // ----------------------------------------------------
  // جلب جميع السيارات
  // ----------------------------------------------------
  Future<Map<String, dynamic>> getCars({required String accessToken}) async {
    try {
      final res = await http
          .get(
            Uri.parse(url),
            headers: {
              "Authorization": "Bearer $accessToken",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 120));

      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        throw ApiException(
          statusCode: res.statusCode,
          message: ErrorTranslator.translate(res.body.toString()),
          details: res.body,
        );
      }

    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: "لا يوجد اتصال بالإنترنت",
        details: "",
      );

    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: "انتهت مهلة الاتصال بالخادم",
        details: "",
      );

    } on FormatException {
      throw ApiException(
        statusCode: 0,
        message: "البيانات المستلمة من الخادم غير صالحة",
        details: "",
      );

    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "حدث خطأ غير متوقع",
        details: e.toString(),
      );
    }
  }

  // ----------------------------------------------------
  // جلب بيانات سيارة واحدة
  // ----------------------------------------------------
  Future<Map<String, dynamic>> getCarById({
    required String id,
    required String accessToken,
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse('$url/$id'),
            headers: {
              "Authorization": "Bearer $accessToken",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 120));

      if (res.statusCode == 200) {
        return json.decode(res.body) ?? {};
      } else {
        throw ApiException(
          statusCode: res.statusCode,
          message: ErrorTranslator.translate(res.body.toString()),
          details: res.body,
        );
      }

    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: "لا يوجد اتصال بالإنترنت",
        details: "",
      );

    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: "انتهت مهلة الاتصال بالخادم",
        details: "",
      );

    } on FormatException {
      throw ApiException(
        statusCode: 0,
        message: "البيانات المستلمة من الخادم غير صالحة",
        details: "",
      );

    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: "حدث خطأ غير متوقع",
        details: e.toString(),
      );
    }
  }
}
