// lib/screens/signup.dart
import 'package:careppo/backend/api_exception.dart';
import 'package:careppo/backend/auth_api_singup.dart';
import 'package:careppo/backend/auth_provider.dart';
import 'package:careppo/backend/error_translator.dart';
import 'package:careppo/screens/CarShow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/TextFormFieldWidget.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedCountryCode = '+963';
  bool isLoading = false;

 
  final List<Map<String, String>> countries = [
    // 🟢 الدول العربية
    {'name': '🇸🇾 سوريا', 'code': '+963'},
    {'name': '🇸🇦 السعودية', 'code': '+966'},
    {'name': '🇪🇬 مصر', 'code': '+20'},
    {'name': '🇦🇪 الإمارات', 'code': '+971'},
    {'name': '🇯🇴 الأردن', 'code': '+962'},
    {'name': '🇶🇦 قطر', 'code': '+974'},
    {'name': '🇰🇼 الكويت', 'code': '+965'},
    {'name': '🇱🇧 لبنان', 'code': '+961'},
    {'name': '🇮🇶 العراق', 'code': '+964'},
    {'name': '🇩🇿 الجزائر', 'code': '+213'},
    {'name': '🇲🇦 المغرب', 'code': '+212'},
    {'name': '🇹🇳 تونس', 'code': '+216'},
    {'name': '🇱🇾 ليبيا', 'code': '+218'},
    {'name': '🇴🇲 عمان', 'code': '+968'},
    {'name': '🇪🇷 إريتريا', 'code': '+291'},

    // 🟣 الدول الأوروبية
    {'name': '🇩🇪 ألمانيا', 'code': '+49'},
    {'name': '🇫🇷 فرنسا', 'code': '+33'},
    {'name': '🇮🇹 إيطاليا', 'code': '+39'},
    {'name': '🇪🇸 إسبانيا', 'code': '+34'},
    {'name': '🇬🇧 المملكة المتحدة', 'code': '+44'},
    {'name': '🇷🇴 رومانيا', 'code': '+40'},
    {'name': '🇸🇪 السويد', 'code': '+46'},
    {'name': '🇳🇴 النرويج', 'code': '+47'},

    // 🟡 دول أفريقية إضافية
    {'name': '🇸🇩 السودان', 'code': '+249'},
    {'name': '🇪🇹 إثيوبيا', 'code': '+251'},
    {'name': '🇳🇬 نيجيريا', 'code': '+234'},
    {'name': '🇰🇪 كينيا', 'code': '+254'},
    {'name': '🇿🇦 جنوب أفريقيا', 'code': '+27'},
  ];


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
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 5, blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: Image.asset(
                          'assets/images/index.png',
                          width: size.width * 0.4,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Email
                      TextFormFieldWidget(
                        labelText: 'البريد الإلكتروني',
                        hintText: 'example@gmail.com',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                       validator: (value) {
  if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';

  // Regex للبريد Gmail فقط، أي شيء قبل @gmail.com
  final gmailRegex = RegExp(r'^.+@gmail\.com$');

  if (!gmailRegex.hasMatch(value)) return 'يرجى إدخال بريد Gmail صالح';

  return null;
},

                        prefixIcon: const Icon(Icons.email),
                      ),
                      const SizedBox(height: 20),

                      // country + phone
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCountryCode,
                              decoration: InputDecoration(labelText: 'الدولة', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              isExpanded: true,
                              items: countries.map((country) => DropdownMenuItem(value: country['code'], child: Text(country['name']!, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountryCode = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            flex: 3,
                            child: TextFormFieldWidget(
                              labelText: 'رقم الهاتف',
                              hintText: '9xxxxxxxx',
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'الرجاء إدخال رقم الهاتف';
                              },
                              prefixIcon: const Icon(Icons.phone),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // password
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
                      const SizedBox(height: 20),

                      // confirm password
                      TextFormFieldWidget(
                        labelText: 'تأكيد كلمة المرور',
                        hintText: 'أعد إدخال كلمة المرور',
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                          if (value != passwordController.text) return 'كلمة المرور غير متطابقة';
                          return null;
                        },
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // first / last name
                      Row(
                        children: [
                          Expanded(
                            child: TextFormFieldWidget(
                              labelText: 'الاسم',
                              hintText: 'الاسم الأول',
                              controller: firstNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'الرجاء إدخال الاسم';
                                return null;
                              },
                              prefixIcon: const Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormFieldWidget(
                              labelText: 'اللقب',
                              hintText: 'الاسم الأخير',
                              controller: lastNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'الرجاء إدخال اللقب';
                                return null;
                              },
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // submit button
                      SizedBox(
                        width: size.width * 0.6,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB71C1C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 5,
                          ),
                          onPressed: isLoading ? null : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => isLoading = true);

                            // clean phone
                            final rawPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
                            final email = emailController.text.trim();

                          
if (!RegExp(r'^\d{7,12}$').hasMatch(rawPhone)) {
  setState(() => isLoading = false);
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text("رقم الهاتف غير صالح")));
  return;
}

                            final phoneToSend = rawPhone.startsWith('0') ? rawPhone : '0$rawPhone';


                            // call API
                            try {
                              final response = await AuthApi.signUp(
                                email: email,
                                password: passwordController.text,
                                firstName: firstNameController.text,
                                lastName: lastNameController.text,
                                phoneNumber: phoneToSend,
                                countryCode: _selectedCountryCode,
                              );

                              // extract tokens (support various key names)
                              String? access;
                              String? refresh;
                              Map<String, dynamic>? userData;

                              if (response.containsKey('accessToken')) access = response['accessToken'];
                              if (response.containsKey('refreshToken')) refresh = response['refreshToken'];
                              if (response.containsKey('token')) access = access ?? response['token'];
                              if (response.containsKey('user') && response['user'] is Map) userData = Map<String, dynamic>.from(response['user']);

                              // save to provider
                              if (access != null) {
                                Provider.of<AuthProvider>(context, listen: false).setAuthData(
                                  accessToken: access,
                                  refreshToken: refresh,
                                  user: userData,
                                );
                                await Provider.of<AuthProvider>(context, listen: false).saveSession();

                              }

                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إنشاء الحساب بنجاح")));

Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const CarShow()),
);
                            } on ApiException catch (e) {
                              final translated = ErrorTranslator.translate(e.message);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translated)));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
                            } finally {
                              setState(() => isLoading = false);
                            }
                          },
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('إنشاء الحساب', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('لديك حساب؟ تسجيل الدخول', style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
