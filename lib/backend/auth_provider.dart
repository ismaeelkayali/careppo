// lib/backend/auth_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  bool _isGuest = false;


  // getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;
  bool get isGuest => _isGuest;

// المستخدم مسجل دخول حقيقي فقط إذا عنده توكن وليس ضيف
bool get isLoggedIn => _accessToken != null && !_isGuest;


  // تعيين كامل بيانات المصادقة
void setAuthData({
  required String accessToken,
  String? refreshToken,
  Map<String, dynamic>? user,
}) {
  _isGuest = false; // 👈 مهم جدًا
  _accessToken = accessToken;
  _refreshToken = refreshToken;
  _user = user;
  notifyListeners();
}


  void loginAsGuest() {
  _isGuest = true;
  _accessToken = null;
  _refreshToken = null;
  _user = null;
  notifyListeners();
}


  // دعم قديم للوظيفة setAccessToken المستخدمة في كود سابق
  void setAccessToken(String token) {
    _accessToken = token;
    notifyListeners();
  }

  // مسح الجلسة (logout)
  void clear() {
  _isGuest = false;
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
    _isGuest = false; // 👈 أي جلسة محفوظة هي مستخدم حقيقي

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
  _isGuest = false;
  _accessToken = null;
  _refreshToken = null;
  _user = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  notifyListeners();
}


}
