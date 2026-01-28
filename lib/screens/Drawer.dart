import 'package:careppo/screens/AboutUs.dart';
import 'package:careppo/screens/Profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'CarShow.dart';
import 'Login.dart';
import 'MyBookings.dart';
import '../backend/auth_provider.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // بيانات المستخدم
    final userName = authProvider.user?['firstName'] ?? "اسم المستخدم";
    final userEmail = authProvider.user?['email'] ?? "user@email.com";

    
Future<void> _openWhatsApp() async {
  const phone = '+963993111350';

  final uri = Uri.parse("whatsapp://send?phone=$phone");

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // تجربة رابط ويب كخيار بديل
    final fallbackUri = Uri.parse("https://wa.me/$phone");

    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("لا يمكن فتح واتساب");
    }
  }
}



    return Directionality(
        textDirection: TextDirection.rtl, // ← من اليمين لليسار

      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFEF5350)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Color(0xFFB71C1C)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          // في مكان بناء القائمة:
_buildDrawerItem(context, Icons.person, "ملفي الشخصي", const ProfilePage(), requiresLogin: true),
_buildDrawerItem(context, Icons.directions_car, "عرض السيارات", const CarShow(), requiresLogin: false),
_buildDrawerItem(context, Icons.list_alt, "حجوزاتي", const MyBookings(), requiresLogin: true),
_buildDrawerItem(context, Icons.info, "من نحن", const AboutUsPage(), requiresLogin: false),


           // المراسلة عبر واتساب تتطلب تسجيل الدخول
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text("المراسلة عبر واتساب"),
              onTap: () {
                Navigator.pop(context);

                if (!authProvider.isLoggedIn && authProvider.isGuest) {
                  // يظهر نافذة تسجيل الدخول
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      title: const Text("تنبيه"),
                      content: const Text("يجب تسجيل الدخول أولاً للوصول لهذه الخاصية."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const Login()),
                              (route) => false,
                            );
                          },
                          child: const Text("تسجيل الدخول"),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // إذا مسموح الوصول
                _openWhatsApp();
              },
            ),
      
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red)),
              onTap: () async{
      await authProvider.clearSession();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Login()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم تسجيل الخروج")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget page, {bool requiresLogin = true}) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  return ListTile(
    leading: Icon(icon, color: const Color(0xFFB71C1C)),
    title: Text(title, style: const TextStyle(fontSize: 15)),
    onTap: () {
      Navigator.pop(context); // يغلق القائمة

      // إذا الصفحة تتطلب تسجيل الدخول والمستخدم ضيف أو غير مسجل
      if (requiresLogin && !authProvider.isLoggedIn && authProvider.isGuest) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("تنبيه"),
            content: const Text("يجب تسجيل الدخول أولاً للوصول لهذه الصفحة."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // يغلق الـ Dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
                  );
                },
                child: const Text("تسجيل الدخول"),
              ),
            ],
          ),
        );
        return;
      }

      // إذا مسموح الوصول للصفحة
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    },
  );
}

}
