import 'dart:io';
import 'package:careppo/backend/auth_provider.dart';
import 'package:careppo/backend/user_status_api.dart'; // ← الباك اند الجديد
import 'package:careppo/screens/CarShow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend/app_settings_api.dart';
import 'Index.dart';

class LaunchCheck extends StatefulWidget {
  const LaunchCheck({super.key});

  @override
  State<LaunchCheck> createState() => _LaunchCheckState();
}

class _LaunchCheckState extends State<LaunchCheck> {
  bool _loading = true;
  String? _error;
  bool _noConnection = false;

  @override
  void initState() {
    super.initState();
    _checkConnectionAndAppSettings();
  }

  Future<void> _checkConnectionAndAppSettings() async {
    setState(() {
      _loading = true;
      _noConnection = false;
      _error = null;
    });

    try {
      final settings = await AppSettingsApi.fetchAppSettings();
      final currentVersion = await AppSettingsApi.getCurrentVersion();
      final currentBuild = await AppSettingsApi.getCurrentBuildNumber();

      final bool maintenance = settings['maintenanceMode'] ?? false;
      final bool updateRequired = settings['updateRequired'] ?? false;
      final int latestBuildAndroid = settings['latestBuildAndroid'] ?? 0;
      final String updateUrl = settings['updateUrl'] ?? '';

      bool forceUpdate = currentBuild < latestBuildAndroid || updateRequired;

      if (maintenance || forceUpdate) {
        _showForceUpdateDialog(updateUrl, maintenance);
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (authProvider.isLoggedIn) {
          // إذا كان المستخدم مسجل دخول مسبقًا → تحقق من isActive
        try {
  final accessToken = authProvider.accessToken!;
  final isActive = await UserStatusApi.fetchUserIsActive(accessToken);

  if (isActive) {
    // الحساب نشط → الانتقال للصفحة الرئيسية
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CarShow()));
  } else {
    // الحساب معلق → حذف التوكن والبيانات → إعادة التوجيه لتسجيل الدخول
    authProvider.clearSession(); 
    if (!mounted) return;
    _showAccountBlockedDialog();
  }

} catch (e) {
  // تم حذف الحساب من قاعدة البيانات أو حدث خطأ يمنع جلب حالته
  authProvider.clearSession(); // حذف التوكن والبيانات

  if (!mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const Index()),
  );
}
} else {
  // المستخدم غير مسجل → الانتقال إلى صفحة Index
  if (!mounted) return;
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Index()));
}
}
} on SocketException {
setState(() {
  _noConnection = true;
  _loading = false;
});
} catch (e) {
setState(() {
  _error = e.toString();
  _loading = false;
});
}

  }

  void _showForceUpdateDialog(String updateUrl, bool maintenance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(maintenance ? "الصيانة" : "تحديث مطلوب"),
          content: Text(
            maintenance
                ? "التطبيق تحت الصيانة حالياً، يرجى المحاولة لاحقاً."
                : "الرجاء تحديث التطبيق للوصول إلى الخدمات.",
          ),
          actions: [
            if (!maintenance)
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(updateUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text("تحديث"),
              ),
            TextButton(
              onPressed: () => exit(0),
              child: const Text("خروج"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("تم حظر الحساب"),
          content: const Text("حسابك معلق ولا يمكن الدخول للتطبيق."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Index()));
              },
              child: const Text("حسناً"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: _loading
                ? const CircularProgressIndicator()
                : _error != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _checkConnectionAndAppSettings,
                            child: const Text("أعد المحاولة"),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
          ),
          if (_noConnection)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 60, color: Colors.red),
                      const SizedBox(height: 15),
                      const Text(
                        "لا يوجد اتصال بالإنترنت",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _checkConnectionAndAppSettings,
                        child: const Text("أعد الاتصال"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
