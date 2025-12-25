import 'package:careppo/backend/auth_provider.dart';
import 'package:careppo/screens/launch_check.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/CarShow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.loadSession(); // تحميل الجلسة عند فتح التطبيق

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
      ],
      child: const Homebages(),
    ),
  );
}

class Homebages extends StatelessWidget {
  const Homebages({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
  fontFamily: "LandRover", // أو Righteous حسب رغبتك
),

     home: const LaunchCheck(), // دائمًا نبدأ بـ LaunchCheck للتحقق

      builder: (context, child) {
        return Directionality(
              textDirection: TextDirection.rtl,

          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.1),
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
