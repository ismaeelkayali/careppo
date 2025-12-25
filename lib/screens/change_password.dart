// lib/screens/change_password.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/auth_provider.dart';
import '../backend/update_password_api.dart';
import '../backend/api_exception.dart';
import '../backend/error_translator.dart';
import '../widgets/TextFormFieldWidget.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

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

                          // كلمة المرور القديمة
                          TextFormFieldWidget(
                            labelText: 'كلمة المرور الحالية',
                            hintText: 'أدخل كلمة المرور القديمة',
                            controller: oldPasswordController,
                            obscureText: _obscureOld,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور الحالية';
                              if (value.length < 6) return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                              return null;
                            },
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureOld ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureOld = !_obscureOld),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // كلمة المرور الجديدة
                          TextFormFieldWidget(
                            labelText: 'كلمة المرور الجديدة',
                            hintText: 'أدخل كلمة المرور الجديدة',
                            controller: newPasswordController,
                            obscureText: _obscureNew,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور الجديدة';
                              if (value.length < 6) return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                              return null;
                            },
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // تأكيد كلمة المرور الجديدة
                          TextFormFieldWidget(
                            labelText: 'تأكيد كلمة المرور الجديدة',
                            hintText: 'أعد إدخال كلمة المرور الجديدة',
                            controller: confirmPasswordController,
                            obscureText: _obscureConfirm,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور الجديدة';
                              if (value != newPasswordController.text) return 'كلمة المرور غير متطابقة';
                              return null;
                            },
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // زر التغيير
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

        final oldPassword = oldPasswordController.text.trim();
        final newPassword = newPasswordController.text.trim();
        final confirmPassword = confirmPasswordController.text.trim();

        // تحقق محلي من أن الجديدة مختلفة عن القديمة
        if (oldPassword == newPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("كلمة المرور الجديدة يجب أن تكون مختلفة عن القديمة"),
            ),
          );
          return;
        }

        if (newPassword != confirmPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("كلمة المرور الجديدة وتأكيدها غير متطابقين"),
            ),
          );
          return;
        }

        setState(() => _isLoading = true);

        try {
          final accessToken = Provider.of<AuthProvider>(context, listen: false).accessToken!;
          await UpdatePasswordApi.updatePassword(
            accessToken: accessToken,
            currentPassword: oldPassword,
            newPassword: newPassword,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم تغيير كلمة المرور بنجاح")),
          );
          Navigator.pop(context);
        } on ApiException catch (e) {
        final msg = ErrorTranslator.translate(e.message, context: "changePassword");
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
        } finally {
          setState(() => _isLoading = false);
        }
      },
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('تغيير كلمة المرور', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
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
