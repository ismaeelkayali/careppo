// lib/widgets/MyBookings.dart
import 'package:careppo/widgets/BookingDialog.dart';
import 'package:flutter/material.dart';
import 'Drawer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:careppo/backend/BookingApi.dart';
import 'package:careppo/backend/auth_provider.dart';
import 'package:careppo/backend/api_exception.dart';

class MyBookings extends StatefulWidget {
  const MyBookings({super.key});

  @override
  State<MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<MyBookings> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> filteredBookings = [];
  bool _loading = true;

  String selectedStatus = 'الكل';

  final List<String> statusOptions = [
    'الكل',
    'مقبول',
    'قيد الانتظار',
    'مرفوض',
  ];

  @override
  void initState() {
    super.initState();
    _loadMyBookings();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => filterBookings();

  Future<void> _loadMyBookings() async {
    setState(() {
      _loading = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final api = BookingApi();
      final data = await api.getMyOrders(accessToken: authProvider.accessToken!);

      // data: List of orders (items have carId (object), startDate, endDate, status, createdAt, id, ...)
      // تحويل إلى قائمة محلية سهلة العرض
      final items = data.map<Map<String, dynamic>>((o) {
        final carObj = o['car'] ?? {};
        final images = (carObj['images'] as List<dynamic>?)?.cast<String>() ?? [];
        final model = carObj['model']?.toString() ?? '-';
        final start = o['startDate']?.toString();
        final end = o['endDate']?.toString();
        final created = o['createdAt']?.toString();
        final statusRaw = (o['status'] ?? '').toString().toLowerCase();
        String statusLabel = 'غير معروف';
        if (statusRaw == 'approved') statusLabel = 'مقبول';
        if (statusRaw == 'pending') statusLabel = 'قيد الانتظار';
        if (statusRaw == 'rejected') statusLabel = 'مرفوض';

        DateTime? startDt;
        try {
          startDt = start != null ? DateTime.parse(start).toLocal() : null;
        } catch (_) {
          startDt = null;
        }

        return {
          'id': o['id'] ?? o['_id'] ?? '',
          'carModel': model,
          'image': images.isNotEmpty ? images[0] : null,
          'startDate': startDt,
          'startDateRaw': start,
          'endDateRaw': end,
          'status': statusLabel,
          'statusRaw': statusRaw,
          'createdAt': created,
          'order': o, // keep original for editing
        };
      }).toList();

      // فرز من الأحدث إلى الأقدم حسب createdAt (إن وجد) وإلا حسب startDate
      items.sort((a, b) {
        final ca = a['createdAt'];
        final cb = b['createdAt'];
        if (ca != null && cb != null) {
          try {
            return DateTime.parse(cb).compareTo(DateTime.parse(ca));
          } catch (_) {}
        }
        final sa = a['startDate'] as DateTime?;
        final sb = b['startDate'] as DateTime?;
        if (sa != null && sb != null) return sb.compareTo(sa);
        return 0;
      });

      setState(() {
        bookings = items;
        filteredBookings = List.from(bookings);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (e is ApiException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل جلب حجوزاتي، حاول مرة أخرى')));
      }
    }
  }

  void filterBookings() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      filteredBookings = bookings.where((b) {
        final matchesStatus = selectedStatus == 'الكل' || b['status'] == selectedStatus;
        final matchesQuery = b['carModel'].toString().toLowerCase().contains(query) ||
            (b['startDate'] != null &&
                DateFormat('yyyy-MM-dd').format(b['startDate']).contains(query));
        return matchesStatus && matchesQuery;
      }).toList();
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'مقبول':
        return Colors.green;
      case 'قيد الانتظار':
        return Colors.orange;
      case 'مرفوض':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _onCardTap(Map<String, dynamic> booking) async {
    final statusRaw = booking['statusRaw'] ?? '';
    if (statusRaw == 'pending') {
      // عرض خيارات تعديل / حذف
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('تعديل الطلب'),
                  onTap: () => Navigator.of(ctx).pop('edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('حذف الطلب'),
                  onTap: () => Navigator.of(ctx).pop('delete'),
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('إلغاء'),
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
              ],
            ),
          );
        },
      );

      if (action == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد أنك تريد حذف هذا الطلب؟'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('تأكيد')),
            ],
          ),
        );

        if (confirm == true) {
          await _deleteOrder(booking['id']);
        }
      } else if (action == 'edit') {
        await _openEditDialog(booking);
      }
    } else {
      // حالة غير قابلة للتعديل
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('لا يمكن التعديل'),
          content: const Text('هذه الحجز ليس في حالة انتظار، لا يمكن تعديل أو حذف.'),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('حسناً'))],
        ),
      );
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final api = BookingApi();
      await api.deleteOrder(orderId: orderId, accessToken: auth.accessToken!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الطلب')));
      await _loadMyBookings();
    } catch (e) {
      if (e is ApiException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل حذف الطلب')));
      }
    }
  }
Future<void> _openEditDialog(Map<String, dynamic> booking) async {
  final order = booking['order'] as Map<String, dynamic>;
  final carObj = order['car'] ?? {};

  // استخراج التواريخ
  final DateTime startDate = DateTime.parse(order["startDate"]).toLocal();
  final DateTime endDate   = DateTime.parse(order["endDate"]).toLocal();

  // تحويلها لأجزاء منفصلة
  final initialStart = DateTime(startDate.year, startDate.month, startDate.day);
  final initialEnd   = DateTime(endDate.year, endDate.month, endDate.day);

  final initialStartTime = TimeOfDay(hour: startDate.hour, minute: startDate.minute);
  final initialEndTime   = TimeOfDay(hour: endDate.hour, minute: endDate.minute);
  

  // الأسعار
  

final priceDay = double.tryParse(carObj['pricePerDay']?.toString() ?? "") ?? 0.0;
final priceWeek  = double.tryParse(carObj['pricePerYear']?.toString() ?? "") ?? 0.0;
final priceMonth = double.tryParse(carObj['pricePerMonth']?.toString() ?? "") ?? 0.0;

  final carId = carObj['id'] ?? carObj['_id'];

  final res = await showDialog<bool>(
    context: context,
    builder: (_) => BookingDialog(
      carId: carId,
      carHasDriver: carObj['hasDriver'] == true,
      pricePerDay: priceDay,
      pricePerWeek: priceWeek,
      pricePerMonth: priceMonth,

      // أهم شيء: تفعيل وضع التعديل
      isEdit: true,

      initialOrderId: order['id'] ?? order['_id'],

      initialFullName: order['fullName'],
      initialPhone: order['phoneNumber'],
      initialNotes: order['notes'],

      initialStart: initialStart,
      initialStartTime: initialStartTime,
        initialNeedsDriver: order['needsDriver'],


      initialEnd: initialEnd,
      initialEndTime: initialEndTime,
    ),
  );

  if (res == true) {
    await _loadMyBookings();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
     appBar: AppBar(
  backgroundColor: const Color(0xFFA20505),
  title: const Text('حجوزاتي', style: TextStyle(color: Colors.white)),
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
          child: Column(
            children: [
              // مربع البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => filterBookings(),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم السيارة أو التاريخ...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Dropdown لتصفية الحالة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: statusOptions
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              selectedStatus = value;
                              filterBookings();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // قائمة الحجوزات
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredBookings.isEmpty
                        ? const Center(child: Text('لا توجد حجوزات مطابقة', style: TextStyle(color: Colors.white)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredBookings.length,
                            itemBuilder: (context, index) {
                              final booking = filteredBookings[index];
                              final image = booking['image'] as String?;
                              final startDt = booking['startDate'] as DateTime?;
                              final dateStr = startDt != null ? DateFormat('yyyy-MM-dd').format(startDt) : '-';
                              final timeStr = startDt != null ? DateFormat('HH:mm').format(startDt) : '-';

                              return GestureDetector(
                                onTap: () => _onCardTap(booking),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // صورة السيارة
                                      if (image != null)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                                          child: Image.network(image, height: 180, width: double.infinity, fit: BoxFit.cover),
                                        )
                                      else
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                                          child: Container(height: 180, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.directions_car, size: 48))),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(booking['carModel'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            const Icon(Icons.calendar_today, size: 16),
                                            const SizedBox(width: 5),
                                            Text(dateStr),
                                            const SizedBox(width: 20),
                                            const Icon(Icons.access_time, size: 16),
                                            const SizedBox(width: 5),
                                            Text(timeStr),
                                          ]),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                            decoration: BoxDecoration(color: getStatusColor(booking['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                                            child: Text(booking['status'], style: TextStyle(color: getStatusColor(booking['status']), fontWeight: FontWeight.bold)),
                                          ),
                                        ]),
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
    );
  }
}
