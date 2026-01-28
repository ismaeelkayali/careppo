// lib/screens/login.dart
import 'package:careppo/backend/api_exception.dart';
import 'package:careppo/backend/auth_provider.dart';
import 'package:careppo/backend/login_api.dart';
import 'package:careppo/backend/error_translator.dart';
import 'package:careppo/backend/user_status_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/TextFormFieldWidget.dart';
import 'CarShow.dart';
import 'signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA20505), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 5, blurRadius: 20, offset: Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Image.asset('assets/images/index.png', width: size.width * 0.5, fit: BoxFit.contain),
                          ),
                          TextFormFieldWidget(
                            labelText: 'رقم الهاتف',
                            hintText: 'أدخل رقم هاتفك',
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'الرجاء إدخال رقم الهاتف';
                              if (value.length < 9) return 'رقم الهاتف غير صحيح';
                              return null;
                            },
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          const SizedBox(height: 20),
                          TextFormFieldWidget(
                            labelText: 'كلمة المرور',
                            hintText: 'أدخل كلمة المرور',
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
                              if (value.length < 6) return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                              return null;
                            },
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: size.width * 0.5,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) return;

                                      setState(() => _isLoading = true);

                                      final rawPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
// نضيف صفر البداية تلقائياً إن لم يكن موجوداً
final phoneForLogin = rawPhone.startsWith('0') ? rawPhone : '0$rawPhone';
                                      // client phone validation
                                      if (!RegExp(r'^\d{9,10}$').hasMatch(phoneForLogin)) {
                                        setState(() => _isLoading = false);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("رقم الهاتف غير صالح")));
                                        return;
                                      }
                                      
try {
  final response = await LoginApi.login(
    phoneNumber: phoneForLogin, 
    password: passwordController.text.trim()
  );

  // استخراج توكنات و user
  String? access;
  String? refresh;
  Map<String, dynamic>? userData;

  if (response.containsKey('accessToken')) access = response['accessToken'];
  if (response.containsKey('refreshToken')) refresh = response['refreshToken'];
  if (response.containsKey('token')) access = access ?? response['token'];
  if (response.containsKey('user') && response['user'] is Map) userData = Map<String, dynamic>.from(response['user']);

  if (access == null) {
    throw ApiException(statusCode: 500, message: "لم يتم استلام التوكن من الخادم", details: response);
  }

  // حفظ التوكن بالـ Provider
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  authProvider.setAuthData(
    accessToken: access,
    refreshToken: refresh,
    user: userData,
  );
  await authProvider.saveSession();

  // ✅ التحقق من حالة الحساب بعد تسجيل الدخول
  try {
    final isActive = await UserStatusApi.fetchUserIsActive(access);
    if (!isActive) {
      // الحساب معلق → حذف التوكن والبيانات → عرض رسالة → العودة لصفحة Login
      authProvider.clearSession();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("تم حظر الحساب"),
          content: const Text("حسابك معلق ولا يمكن الدخول للتطبيق."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("حسناً"),
            ),
          ],
        ),
      );
      return; // لا ننتقل للصفحة الرئيسية
    }
  } catch (e) {
    // إذا حدث خطأ أثناء التحقق من isActive، يمكن متابعة الدخول أو عرض رسالة
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ أثناء التحقق من حالة الحساب: $e")));
    return;
  }

  // الحساب نشط → الانتقال للصفحة الرئيسية
  if (!mounted) return;
 Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const CarShow()),
  (Route<dynamic> route) => false,
);


} on ApiException catch (e) {
  final msg = ErrorTranslator.translate(e.message, context: "login");
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
} finally {
  setState(() => _isLoading = false);
}

                                    },
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 10),

SizedBox(
  width: size.width * 0.5,
  height: 45,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFFB71C1C)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
    onPressed: () {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      authProvider.loginAsGuest();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CarShow()),
        (Route<dynamic> route) => false,
      );
    },
    child: const Text(
      'الدخول كضيف',
      style: TextStyle(
        color: Color(0xFFB71C1C),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
                          const SizedBox(height: 20),


                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Signup())),
                            child: const Text('ليس لديك حساب؟ أنشئ حساب الآن', style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
