import 'package:careppo/backend/update_user_profail_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/auth_provider.dart';
import '../backend/api_exception.dart';
import '../backend/error_translator.dart';
import '../backend/profile_api.dart';
import '../widgets/TextFormFieldWidget.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController? emailController;
TextEditingController? firstNameController;
TextEditingController? lastNameController;
TextEditingController? phoneController;


  bool isLoading = true; // <-- عرض مؤشر التحميل عند جلب البيانات
  Map<String, dynamic> originalData = {};

  @override
  void initState() {
    super.initState();
    fetchProfileFromServer();
  }

  /// جلب بيانات المستخدم من السيرفر
  Future<void> fetchProfileFromServer() async {
    setState(() => isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final data = await ProfileApi.getProfile(accessToken: authProvider.accessToken!);

      // إزالة الصفر الأول من رقم الهاتف إذا كان موجود
      String phone = data["phoneNumber"];
      if (phone.startsWith('0')) phone = phone.substring(1);

      emailController = TextEditingController(text: data["email"] ?? "");
      firstNameController = TextEditingController(text: data["firstName"] ?? "");
      lastNameController = TextEditingController(text: data["lastName"] ?? "");
      phoneController = TextEditingController(text: phone);

      originalData = {
        "email": emailController!.text.trim(),
        "firstName": firstNameController!.text.trim(),
        "lastName": lastNameController!.text.trim(),
        "phoneNumber": phoneController!.text.trim(),
      };

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : "حدث خطأ أثناء جلب البيانات")),
      );
    }
  }

  /// مقارنة الحقول مع الأصلية وإرسال فقط المتغيرات المعدلة
  Map<String, dynamic> buildUpdatedFields() {
    Map<String, dynamic> updated = {};

    if (emailController!.text.trim() != originalData["email"]) {
      updated["email"] = emailController!.text.trim();
    }
    if (firstNameController!.text.trim() != originalData["firstName"]) {
      updated["firstName"] = firstNameController!.text.trim();
    }
    if (lastNameController!.text.trim() != originalData["lastName"]) {
      updated["lastName"] = lastNameController!.text.trim();
    }
    if (phoneController!.text.trim() != originalData["phoneNumber"]) {
      updated["phoneNumber"] = phoneController!.text.trim();
    }

    return updated;
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = buildUpdatedFields();

    if (updated.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يجب تعديل حقل واحد على الأقل")),
      );
      return;
    }

    setState(() => isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.accessToken ?? "";

    try {
      final data = await UserApi.updateProfile(
        updatedFields: updated,
        accessToken: token,
      );

      if (data["user"] != null) {
        auth.setUser(data["user"]); // تحديث AuthProvider بالبيانات الجديدة
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تحديث البيانات بنجاح")),
      );

      Navigator.pop(context, true); // يمكن إرسال true لإشارة تحديث الصفحة السابقة
    } on ApiException catch (e) {
      final translated = ErrorTranslator.translate(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translated)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

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
          child: isLoading || emailController == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            spreadRadius: 5,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/index.png',
                              width: size.width * 0.35,
                            ),
                            const SizedBox(height: 20),

                            TextFormFieldWidget(
                              labelText: "البريد الإلكتروني",
                              controller: emailController!,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return "الرجاء إدخال البريد";
                                if (!RegExp(r'^.+@gmail\.com$').hasMatch(value)) return "يجب إدخال بريد Gmail صالح";
                                return null;
                              },
                              prefixIcon: const Icon(Icons.email),
                            ),
                            const SizedBox(height: 20),

                            TextFormFieldWidget(
                              labelText: "الاسم",
                              controller: firstNameController!,
                              validator: (value) => value == null || value.isEmpty ? "الرجاء إدخال الاسم" : null,
                              prefixIcon: const Icon(Icons.person),
                            ),
                            const SizedBox(height: 20),

                            TextFormFieldWidget(
                              labelText: "اللقب",
                              controller: lastNameController!,
                              validator: (value) => value == null || value.isEmpty ? "الرجاء إدخال اللقب" : null,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            const SizedBox(height: 20),

                            TextFormFieldWidget(
                              labelText: "رقم الهاتف",
                              controller: phoneController!,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) return "الرجاء إدخال رقم الهاتف";
                                if (value.length < 8) return "رقم الهاتف غير صالح";
                                return null;
                              },
                              prefixIcon: const Icon(Icons.phone),
                            ),
                            const SizedBox(height: 30),

                            SizedBox(
                              width: size.width * 0.6,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB71C1C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: isLoading ? null : updateProfile,
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        "حفظ التعديلات",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
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
