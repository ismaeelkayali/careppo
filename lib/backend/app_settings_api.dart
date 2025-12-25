import 'dart:convert';
import 'dart:io';
import 'package:careppo/backend/constants.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppSettingsApi {
  static const String _url = "${ApiConstants.baseUrl}/api/v1/app-settings";

  /// جلب بيانات إعدادات التطبيق من السيرفر
  static Future<Map<String, dynamic>> fetchAppSettings() async {
    try {
      final response = await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw ("فشل تحميل إعدادات التطبيق: ");
      }
    } on SocketException {
      throw ("لا يوجد اتصال بالإنترنت");
    } on HttpException {
      throw ("خطأ في الاتصال بالسيرفر");
    } on FormatException {
      throw ("البيانات المستلمة من السيرفر غير صحيحة");
    } catch (e) {
      throw ("حدث خطأغير متوقع:  ");
    }
  }

  /// الحصول على إصدار التطبيق الحالي
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// الحصول على build number الحالي
  static Future<int> getCurrentBuildNumber() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }
}
