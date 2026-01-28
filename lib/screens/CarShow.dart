import 'dart:io';

import 'package:careppo/backend/api_exception.dart';
import 'package:careppo/backend/app_settings_api.dart';
import 'package:careppo/backend/auth_provider.dart';
import 'package:careppo/backend/car_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'CarDetails.dart';
import 'Drawer.dart';

class CarShow extends StatefulWidget {
  const CarShow({super.key});

  @override
  State<CarShow> createState() => _CarShowState();
}

class _CarShowState extends State<CarShow> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _filteredCars = [];
  bool _loading = true;

  List<String> _logos = [
    'assets/images/show_cars_icon.png',
    'assets/images/show_cars_icon2.png',
    'assets/images/show_cars_icon3.png',
  ];
  int _currentLogoIndex = 0;
  Timer? _logoTimer;
  String get _currentLogo => _logos[_currentLogoIndex];

  @override
  void initState() {
    super.initState();
      _checkConnection(); // تحقق من الإنترنت قبل جلب البيانات


    _logoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _currentLogoIndex = (_currentLogoIndex + 1) % _logos.length;
      });
    });

    _fetchCars();
  }

  
Future<void> _checkConnection() async {
  try {
    // نجرب طلب بسيط أو API settings
    await AppSettingsApi.fetchAppSettings();
  } on SocketException {
    // عرض نافذة وسط الشاشة مثل LaunchCheck
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("لا يوجد اتصال بالإنترنت"),
        content: const Text("يرجى إعادة الاتصال بالإنترنت."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkConnection();
            },
            child: const Text("أعد المحاولة"),
          ),
        ],
      ),
    );
  }
}

  Future<void> _fetchCars() async {
  try {
    final carApi = CarApi();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final carsData = await carApi.getCars(
      accessToken: auth.accessToken, // null للضيف ✔
    );

    final results = carsData['results'] as List;

    setState(() {
      _cars = results.map<Map<String, dynamic>>((car) {
        return {
          'id': car['id'],
          'name': car['model'],
          'image': (car['images'] as List).isNotEmpty
              ? car['images'][0]
              : '',
        };
      }).toList();

      _filteredCars = List.from(_cars);
      _loading = false;
    });
  } catch (e) {
    if (e is ApiException) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    setState(() => _loading = false);
  }
}


  void _searchCars(String query) {
    setState(() {
      _filteredCars = query.isEmpty
          ? List.from(_cars)
          : _cars
              .where((car) => car['name'].toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA20505),
        title: const Text('Careppo', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 800),
                              child: Container(
                                key: ValueKey(_currentLogo),
                                height: size.height * 0.18,
                                width: size.width * 0.9,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(_currentLogo),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _cars.isEmpty
                                ? const Text(
                                    'لم يتم إضافة سيارات للمعرض بعد',
                                    style: TextStyle(fontSize: 18, color: Colors.black54),
                                  )
                                : TextField(
                                    controller: _searchController,
                                    onChanged: _searchCars,
                                    decoration: InputDecoration(
                                      hintText: 'ابحث عن سيارة...',
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 0, horizontal: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(25),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _filteredCars.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemBuilder: (context, index) {
                            final car = _filteredCars[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CarDetails(carId: car['id']),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                        child: car['image'] != ''
                                            ? Image.network(
                                                car['image'],
                                               fit: BoxFit.contain
,
                                                width: double.infinity,
                                              )
                                            : const Icon(Icons.directions_car, size: 50),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        car['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB71C1C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
