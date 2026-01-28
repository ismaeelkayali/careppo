import 'dart:async';

import 'package:careppo/backend/api_exception.dart';
import 'package:careppo/backend/auth_provider.dart';
import 'package:careppo/backend/car_api.dart';
import 'package:careppo/backend/BookingApi.dart';
import 'package:careppo/widgets/BookingDialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'Drawer.dart';

class CarDetails extends StatefulWidget {
  final String carId;

  const CarDetails({super.key, required this.carId});

  @override
  State<CarDetails> createState() => _CarDetailsState();
}

class _CarDetailsState extends State<CarDetails> {
  Map<String, dynamic>? car;
    Timer? _imageTimer; // 🔹 المؤقت لتغيير الصور
  bool _loading = true;

  bool _loadingBookings = true;
  List<Map<String, dynamic>> bookings = [];

  // صور السيارة وعرض الصور
  List<String> carImages = [];
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchCarDetails();
    _fetchBookings();
       _startAutoSlide();

  }
  void _startAutoSlide() {
    _imageTimer?.cancel(); // أي مؤقت سابق
    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || carImages.isEmpty) return;

      int nextIndex = (_currentImageIndex + 1) % carImages.length;

      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      setState(() {
        _currentImageIndex = nextIndex;
      });
    });
  }

  /// -------------------------
  ///  جلب تفاصيل السيارة
  /// -------------------------
  Future<void> _fetchCarDetails() async {
    try {
      final carApi = CarApi();
      final auth = Provider.of<AuthProvider>(context, listen: false);

     final carData = await carApi.getCarById(
  id: widget.carId,
  accessToken: auth.accessToken, // String?
);

if (!mounted) return;

      setState(() {
        car = carData;
        carImages = (carData['images'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        _loading = false;
      });
    } catch (e) {
      if (e is ApiException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  /// -------------------------
  ///  جلب حجوزات السيارة
  /// -------------------------
 Future<void> _fetchBookings() async {
  final auth = Provider.of<AuthProvider>(context, listen: false);

  // إذا كان ضيف، لا نحاول جلب الحجوزات
  if (auth.isGuest) {
    setState(() {
      bookings = [];
      _loadingBookings = false;
    });
    return;
  }

  try {
    final api = BookingApi();

    final orders = await api.getOrdersForCar(
      carId: widget.carId,
      accessToken: auth.accessToken!, // تأكد أنه ليس null هنا
    );

    if (!mounted) return;

    setState(() {
      bookings = orders;
      _loadingBookings = false;
    });
  } catch (_) {
    setState(() => _loadingBookings = false);
  }
}


  /// هل اليوم محجوز؟
  bool isTodayBooked() {
    final today = DateTime.now();

    for (var o in bookings) {
      final start = DateTime.parse(o["startDate"]);
      final end = DateTime.parse(o["endDate"]);

      if (today.isAfter(start.subtract(const Duration(days: 1))) &&
          today.isBefore(end.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }
   @override
  void dispose() {
    _imageTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (car == null) {
      return const Scaffold(
        body: Center(child: Text("فشل تحميل بيانات السيارة")),
      );
    }

    // التأكد من الحقول
    final model = car!['model']?.toString() ?? '-';
    final priceDay = car!['pricePerDay']?.toString() ?? '0';
    final priceWeek = car!['pricePerYear']?.toString() ?? '0';
    final priceMonth = car!['pricePerMonth']?.toString() ?? '0';
    final engine = car!['engineType']?.toString() ?? '-';
    final year = car!['year']?.toString() ?? '-';
    final fuel = car!['fuelType']?.toString() ?? '-';
    final hasDriver = (car!['hasDriver'] ?? false) ? 'مع سائق' : 'بدون سائق';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA20505),
        title: const Text("معرض السيارات", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MyDrawer(),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA20505), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // عرض الصور
                SizedBox(
                  height: size.height * 0.35,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: carImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: carImages.isNotEmpty
                                  ? Image.network(
                                      carImages[index],
                                      fit: BoxFit.contain
,
                                      width: double.infinity,
                                    )
                                  : const Icon(Icons.directions_car, size: 50),
                            ),
                          );
                        },
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                      ),
                       // 🔹 الأسهم معكوسة للـ RTL
          if (carImages.length > 1)
            Positioned(
              right: 10, // بدل left
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 30, color: Colors.white),
                onPressed: () {
                  if (_currentImageIndex > 0) {
                    _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                },
              ),
            ),
                      if (carImages.length > 1)
                        Positioned(
                          left: 10,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios,
                                size: 30, color: Colors.white),
                            onPressed: () {
                              if (_currentImageIndex > 0) {
                                _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);
                              }
                            },
                          ),
                        ),
                     
                      if (carImages.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              carImages.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 12 : 8,
                                height: _currentImageIndex == index ? 12 : 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white54,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  model,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB71C1C),
                  ),
                ),

                const SizedBox(height: 10),

                // سعر يومي - أسبوعي - شهري
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('$priceDay \$',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('يومي', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('$priceWeek \$',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('أسبوعي', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('$priceMonth \$',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('شهري', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // مواصفات السيارة صف واحد لكل خاصية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('نوع الموتور:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(engine, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('سنة الصنع:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(year, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('نوع الوقود:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(fuel, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 5),
                    
                    ],
                  ),
                ),




                const SizedBox(height: 30),

                // زر الحجز
              Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB71C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      onPressed: () {
        final auth = Provider.of<AuthProvider>(context, listen: false);

        if (auth.isGuest) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("الرجاء تسجيل الدخول لتقديم طلب الحجز")),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (_) => BookingDialog(
            carId: widget.carId,
            carHasDriver: car!['hasDriver'] == true,
            pricePerDay: double.parse(priceDay),
            pricePerWeek: double.parse(priceWeek),
            pricePerMonth: double.parse(priceMonth),
          ),
        );
      },
      child: const Text(
        "تقديم طلب حجز",
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    ),
  ),
),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
