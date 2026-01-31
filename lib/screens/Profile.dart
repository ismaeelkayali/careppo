import 'package:careppo/backend/delete_account_api.dart';
import 'package:careppo/screens/change_password.dart';
import 'package:careppo/screens/profile_update.dart';
import 'package:careppo/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/auth_provider.dart';
import '../backend/profile_api.dart';
import '../backend/api_exception.dart';
import 'Drawer.dart';
import 'Login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  Map<String, dynamic>? userData;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
      setState(() => isLoading = true); // <<< تفعيل مؤشر التحميل عند البدء

    try {
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final data = await ProfileApi.getProfile(accessToken: authProvider.accessToken!);

      setState(() {
        
        // إزالة الصفر الأول من رقم الهاتف إذا كان موجود
        String phone = data["phoneNumber"];
        if (phone.startsWith('0')) phone = phone.substring(1);

        userData = {
          "firstName": data["firstName"],
          "lastName": data["lastName"],
          "email": data["email"],
          "phoneNumber": phone,
          "countryCode": data["countryCode"],
          "isActive": data["isActive"],
        };
        isLoading = false;
      });
    } catch (e) {
          if (!mounted) return;

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : "حدث خطأ")),
      );
    }
  }

  Widget infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color.fromARGB(255, 235, 6, 6)),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget profileButton(String text, VoidCallback onPressed, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB71C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
     appBar: AppBar(
  backgroundColor: const Color(0xFFA20505),
  title: const Text('Careppo', style: TextStyle(color: Colors.white)),
  centerTitle: true,
  iconTheme: const IconThemeData(color: Colors.white),

  leading: IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () {
      _scaffoldKey.currentState?.openDrawer();
    },
  ),
),

      drawer: const MyDrawer(),
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
          child: isLoading || userData == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // بطاقة البيانات
                      Container(
                        width: size.width * 0.9,
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(86, 255, 255, 255),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(Icons.person, size: 45, color: Colors.red),
                            ),
                            const SizedBox(height: 30),
                            infoRow(Icons.person, "الاسم", "${userData!['firstName']} ${userData!['lastName']}"),
                            infoRow(Icons.email, "البريد الإلكتروني", userData!['email']),
                            infoRow(Icons.phone, "رقم الهاتف", "${userData!['countryCode']}${userData!['phoneNumber']}"),
                            infoRow(Icons.check_circle, "الحالة", userData!['isActive'] ? "نشط" : "محظور"),
                            const SizedBox(height: 40),

                            // أزرار بنفس تصميم ElevatedButton المطلوب
                       // داخل _ProfilePageState، مكان تعريف الأزرار
Column(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
profileButton("تعديل البيانات", () {
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ProfileEditPage()),
).then((_) {
  if (!mounted) return; // ← تأكد أن الصفحة ما زالت موجودة قبل استدعاء setState
  fetchProfile();
});

}, size.width * 0.50, 45),    const SizedBox(height: 20),
    
    profileButton("تغيير كلمة السر", () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
      );
    }, size.width * 0.50, 45),

    const SizedBox(height: 20),
    profileButton("حذف الحساب", () async {
  final confirm = await showDeleteAccountDialog(context);
  if (confirm != true) return;

  setState(() => isLoading = true);

  try {
    final accessToken = Provider.of<AuthProvider>(context, listen: false).accessToken!;
    await DeleteAccountApi.deleteAccount(accessToken: accessToken);

    // مسح التوكن وتسجيل الخروج
await Provider.of<AuthProvider>(context, listen: false).clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم حذف الحساب بنجاح")),
    );
  } on ApiException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("حدث خطأ: $e")),
    );
  } finally {
    setState(() => isLoading = false);
  }
}, size.width * 0.5, 45),

  ],
),

                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
