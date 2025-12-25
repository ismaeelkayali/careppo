// lib/backend/auth_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;

  // getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;

  bool get isLoggedIn => _accessToken != null;

  // تعيين كامل بيانات المصادقة
  void setAuthData({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? user,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _user = user;
    notifyListeners();
  }

  // دعم قديم للوظيفة setAccessToken المستخدمة في كود سابق
  void setAccessToken(String token) {
    _accessToken = token;
    notifyListeners();
  }

  // مسح الجلسة (logout)
  void clear() {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    notifyListeners();
  }

  
 void updateUserFields(Map<String, dynamic> fields) {
  if (_user == null) return;
  fields.forEach((key, value) {
    _user![key] = value;
  });
  notifyListeners();
}

  void setUser(Map<String, dynamic> user) {
  _user = Map<String, dynamic>.from(user);
  notifyListeners();
}

// حفظ الجلسة عند تسجيل الدخول
Future<void> saveSession() async {
  final prefs = await SharedPreferences.getInstance();
  if (_accessToken != null) {
    await prefs.setString('accessToken', _accessToken!);
    if (_refreshToken != null) await prefs.setString('refreshToken', _refreshToken!);
    if (_user != null) await prefs.setString('user', jsonEncode(_user));
  }
}

// تحميل الجلسة عند فتح التطبيق
Future<void> loadSession() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');
  if (token != null) {
    _accessToken = token;
    _refreshToken = prefs.getString('refreshToken');
    final userString = prefs.getString('user');
    if (userString != null) _user = Map<String, dynamic>.from(jsonDecode(userString));
    notifyListeners();
  }
}

// مسح الجلسة عند تسجيل الخروج
Future<void> clearSession() async {
  _accessToken = null;
  _refreshToken = null;
  _user = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  notifyListeners();
}


}
