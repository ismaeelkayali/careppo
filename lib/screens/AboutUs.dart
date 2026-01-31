import 'package:flutter/material.dart';
import 'Drawer.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


    return Scaffold(
      key: _scaffoldKey,
     appBar: AppBar(
  backgroundColor: const Color(0xFFA20505),
  title: const Text('من نحن', style: TextStyle(color: Colors.white)),
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // بطاقة المحتوى
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
                        child: const Icon(Icons.info, size: 45, color: Colors.red),
                      ),
                      const SizedBox(height: 25),

                      const Text(
                        "من نحن",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB71C1C),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "نحن شركة متخصصة في إيجار السيارات الحديثة، "
                        "نقدم لك أسطولاً متجدداً من السيارات الاقتصادية والفاخرة، "
                        "مع خطط تأجير يومية وشهرية مرنة لتناسب ميزانيتك ومخططك.\n\n"
                        "تأمين شامل، صيانة ممتازة، وخدمة عملاء على مدار الساعة.\n\n"
                        "احجز سيارتك الآن واستمتع بتجربة قيادة فريدة!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
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
