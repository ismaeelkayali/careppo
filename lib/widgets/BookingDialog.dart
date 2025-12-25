// lib/widgets/BookingDialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:careppo/backend/BookingApi.dart';
import 'package:careppo/backend/api_exception.dart';
import 'package:careppo/backend/auth_provider.dart';

class BookingDialog extends StatefulWidget {
  final String carId;
  final bool carHasDriver;
  final double pricePerDay;
  final double pricePerWeek;
  final double pricePerMonth;

  // حقول لتعديل طلب موجود (اختياري)
  final bool isEdit;
  final String? initialOrderId;
  final String? initialFullName;
  final String? initialPhone;
  final DateTime? initialStart;
  final TimeOfDay? initialStartTime;
  final DateTime? initialEnd;
  final TimeOfDay? initialEndTime;
  final String? initialNotes;
  final bool? initialNeedsDriver; // <-- أضف هذا

  


  const BookingDialog({
    super.key,
    required this.carId,
    required this.carHasDriver,
    required this.pricePerDay,
    required this.pricePerWeek,
    required this.pricePerMonth,
    this.isEdit = false,
    this.initialOrderId,
    this.initialFullName,
    this.initialPhone,
    this.initialStart,
    this.initialStartTime,
    this.initialEnd,
    this.initialEndTime,
    this.initialNotes,
    this.initialNeedsDriver,


  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();


  bool isLoadingDates = true;
  bool isSubmitting = false;
  bool hasDriver = false;


  List<Map<String, DateTime>> bookedRanges = [];
  Set<DateTime> blockedDays = {};

  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? endDate;
  TimeOfDay? endTime;
  

  double? estimatedCost;

  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat displayDate = DateFormat('yyyy/MM/dd');

  @override
void initState() {
  super.initState();

  // جلب بيانات المستخدم من الـ Provider إذا كانت موجودة
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final user = auth.user ?? {};

  final first = (user['firstName'] ?? '').toString().trim();
  final last = (user['lastName'] ?? '').toString().trim();
 String phone = (user['phoneNumber'] ?? '').toString().trim();
String country = (user['countryCode'] ?? '').toString().trim();

// إزالة صفر البداية إن وجد
if (phone.startsWith('0')) {
  phone = phone.substring(1);
}

// دمج الرقم مع رمز الدولة
phoneController.text = "$country$phone";

  
    nameController.text = "$first ${last}".trim();


  // إذا جاءت قيم ابتدائية (عند التعديل) فالأولوية للقيم المدخلة سابقًا (initialXXX)
  if (widget.initialFullName != null) nameController.text = widget.initialFullName!;
  if (widget.initialPhone != null) phoneController.text = widget.initialPhone!;
  if (widget.initialNotes != null) {
  notesController.text = widget.initialNotes!;
}



  startDate = widget.initialStart;
  startTime = widget.initialStartTime;
  endDate = widget.initialEnd;
  endTime = widget.initialEndTime;
hasDriver = widget.initialNeedsDriver ?? widget.carHasDriver;


  _loadBookedDates();
  WidgetsBinding.instance.addPostFrameCallback((_) => _recalculateEstimatedCost());
}

  Future<void> _loadBookedDates() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final api = BookingApi();
      final orders = await api.getOrdersForCar(carId: widget.carId, accessToken: auth.accessToken!);
      final now = DateTime.now().toUtc();

      final approved = orders.where((o) {
        final st = o['startDate']?.toString();
        final en = o['endDate']?.toString();
        final status = (o['status'] ?? '').toString().toLowerCase();
        if (st == null || en == null) return false;
        if (status != 'approved') return false;
        try {
          final sdt = DateTime.parse(st).toUtc();
          final edt = DateTime.parse(en).toUtc();
          return edt.isAfter(now);
        } catch (_) {
          return false;
        }
      }).toList();

      bookedRanges = approved.map((o) {
        final s = DateTime.parse(o['startDate'].toString()).toUtc();
        final e = DateTime.parse(o['endDate'].toString()).toUtc();
        return {"start": s, "end": e};
      }).toList();

      final Set<DateTime> days = {};
      for (var r in bookedRanges) {
        DateTime s = DateTime.utc(r['start']!.year, r['start']!.month, r['start']!.day);
        DateTime e = DateTime.utc(r['end']!.year, r['end']!.month, r['end']!.day);
        for (DateTime d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
          days.add(d);
        }
      }

      setState(() => blockedDays = days);
    } catch (e) {
      if (e is ApiException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحميل تواريخ الحجوزات')));
      }
    } finally {
      setState(() => isLoadingDates = false);
    }
  }

  bool _isRangeValid(DateTime startUtc, DateTime endUtc) {
    for (var r in bookedRanges) {
      final s = r['start']!;
      final e = r['end']!;
      if (!(endUtc.isBefore(s) || startUtc.isAfter(e))) return false;
    }
    return true;
  }

  DateTime _merge(DateTime d, TimeOfDay t) => DateTime(d.year, d.month, d.day, t.hour, t.minute).toUtc();

  Future<DateTime?> _showCalendarDialog() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 200)); // ننتظر قليلًا ليغلق الكيبورد تمامًا
    DateTime? pickedDay;
    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("اختر اليوم"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 400,
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
                  focusedDay: DateTime.now(),
                  availableCalendarFormats: const {CalendarFormat.month: "شهر"},
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  calendarStyle: CalendarStyle(
                    disabledDecoration: BoxDecoration(color: Colors.red.withOpacity(0.6), shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(6)),
                    disabledTextStyle: const TextStyle(color: Colors.white),
                    rangeStartDecoration: BoxDecoration(color: Colors.green.withOpacity(0.8), borderRadius: BorderRadius.circular(6)),
                    rangeEndDecoration: BoxDecoration(color: Colors.green.withOpacity(0.8), borderRadius: BorderRadius.circular(6)),
                    withinRangeDecoration: BoxDecoration(color: Colors.green.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                  ),
                  enabledDayPredicate: (day) {
                    final dUtc = DateTime.utc(day.year, day.month, day.day);
                    if (blockedDays.contains(dUtc)) return false;
                    final now = DateTime.now();
                    if (DateTime(day.year, day.month, day.day).isBefore(DateTime(now.year, now.month, now.day))) return false;
                    return true;
                  },
                  onDaySelected: (selectedDay, _) {
                    pickedDay = selectedDay;
                    Navigator.of(ctx).pop(pickedDay);
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text('الأيام الملونة باللون الأحمر محجوزة', style: TextStyle(fontSize: 14, color: Colors.red)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("إلغاء"))],
      ),
    );
    return result;
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    if (isLoadingDates) return;
    final pickedDay = await _showCalendarDialog();
    if (pickedDay == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;

    setState(() {
      if (isStart) {
        startDate = pickedDay;
        startTime = t;
        if (endDate != null && endTime != null) {
          final sUtc = _merge(startDate!, startTime!);
          final eUtc = _merge(endDate!, endTime!);
          if (!eUtc.isAfter(sUtc)) {
            endDate = null;
            endTime = null;
            estimatedCost = null;
          }
        }
      } else {
        endDate = pickedDay;
        endTime = t;
      }
      _recalculateEstimatedCost();
    });
  }

  void _recalculateEstimatedCost() {
    if (startDate == null || startTime == null || endDate == null || endTime == null) {
      setState(() => estimatedCost = null);
      return;
    }
    final sUtc = _merge(startDate!, startTime!);
    final eUtc = _merge(endDate!, endTime!);
    final days = eUtc.difference(sUtc).inDays + 1;
    double cost = 0;
    if (days < 7) {
      cost = days * widget.pricePerDay;
    } else if (days % 30 == 0) {
      final months = days ~/ 30;
      cost = months * widget.pricePerMonth;
    } else if (days >= 30) {
      final months = days ~/ 30;
      final remainingDays = days % 30;
      cost = months * widget.pricePerMonth + remainingDays * widget.pricePerDay;
    } else if (days % 7 == 0) {
      cost = (days ~/ 7) * widget.pricePerWeek;
    } else {
      final weeks = days ~/ 7;
      final remainingDays = days % 7;
      cost = weeks * widget.pricePerWeek + remainingDays * widget.pricePerDay;
    }
    setState(() => estimatedCost = cost);
  }
Future<void> _submitBooking() async {
  if (!_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يرجى تصحيح الحقول المطلوبة')),
    );
    return;
  }

  if (startDate == null || startTime == null ||
      endDate == null || endTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يرجى اختيار تاريخ ووقت البداية والنهاية')),
    );
    return;
  }
  // 🔥 منع اختيار تاريخ اليوم 🔥
final today = DateTime.now();
final todayDateOnly = DateTime(today.year, today.month, today.day);
final selectedStartDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);

if (selectedStartDateOnly.isAtSameMomentAs(todayDateOnly)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('لا يمكن اختيار تاريخ اليوم كبداية. يرجى اختيار يوم آخر.')),
  );
  return;
}


  // بما أننا جهزنا القيم في initState() فهذا يكفي
  String fullName = nameController.text.trim();
  String phoneNumber = phoneController.text.trim();

  // معالجة رقم الهاتف – فقط إن احتجت ذلك
  if (!phoneNumber.startsWith('+')) {
    // إذا لم يكن فيه رمز دولة، أضفه (إن كنت خزّنته مسبقًا داخل الرقم)
    // أو دع الرقم كما هو حسب API backend عندك
  }

  final startUtc = _merge(startDate!, startTime!);
  final endUtc = _merge(endDate!, endTime!);

  try {
    setState(() => isSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = BookingApi();

    bool success = false;

    if (widget.isEdit && widget.initialOrderId != null) {
      success = await api.updateOrder(
        orderId: widget.initialOrderId!,
        carId: widget.carId,
        quantity: 1,
        fullName: fullName,
        phoneNumber: phoneNumber,
needsDriver: hasDriver,
        startDate: startUtc.toIso8601String(),
        endDate: endUtc.toIso8601String(),
        accessToken: auth.accessToken!,
        notes: notesController.text.trim(),
      );
    } else {
      success = await api.createOrder(
        carId: widget.carId,
        quantity: 1,
        fullName: fullName,
        phoneNumber: phoneNumber,
        needsDriver: hasDriver,
        startDate: startUtc.toIso8601String(),
        endDate: endUtc.toIso8601String(),
        accessToken: auth.accessToken!,
        notes: notesController.text.trim(),
      );
    }

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب بنجاح')),
      );
    }

  } catch (e) {
    // معالجة الأخطاء
  } finally {
    setState(() => isSubmitting = false);
  }
}

  Widget buildFieldCard({required String title, required String subtitle, required VoidCallback onTap}) => Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          title: Text(title, style: const TextStyle(color: Colors.black54)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.calendar_month, color: Colors.black54),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        height: screenHeight * 0.75,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(widget.isEdit ? 'تعديل طلب الحجز' : 'طلب حجز السيارة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              if (isLoadingDates)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        // عرض الاسم (غير قابل للتعديل)
ListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('الاسم الثلاثي', style: TextStyle(color: Colors.black54)),
  subtitle: Text(nameController.text.isNotEmpty ? nameController.text : '-', style: const TextStyle(fontSize: 16, color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
),

const SizedBox(height: 8),

// عرض رقم الهاتف
ListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('رقم الهاتف', style: TextStyle(color: Colors.black54)),
  subtitle: Text(phoneController.text.isNotEmpty ? phoneController.text : '-', style: const TextStyle(fontSize: 16, color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
),

SwitchListTile(
  title: const Text('الحجز مع سائق'),
  subtitle: const Text('قم بتفعيل هذا الخيار إذا كنت ترغب في وجود سائق'),
  value: hasDriver,
  onChanged: (v) {
    setState(() => hasDriver = v);
  },
),

const SizedBox(height: 12),

TextFormField(
  controller: notesController,
  maxLines: 3,
  decoration: InputDecoration(
    labelText: "ملاحظات إضافية",
    hintText: "اكتب أي تفاصيل إضافية يرغب العميل بإضافتها...",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
),


                        const SizedBox(height: 12),
                        buildFieldCard(
                          title: 'تاريخ ووقت البداية',
                          subtitle: (startDate == null || startTime == null) ? 'لم يتم الاختيار' : '${displayDate.format(startDate!)} — ${startTime!.format(context)}',
                          onTap: () => _pickDateTime(isStart: true),
                        ),
                        const SizedBox(height: 10),
                        buildFieldCard(
                          title: 'تاريخ ووقت النهاية',
                          subtitle: (endDate == null || endTime == null) ? 'لم يتم الاختيار' : '${displayDate.format(endDate!)} — ${endTime!.format(context)}',
                          onTap: () => _pickDateTime(isStart: false),
                        ),
                        const SizedBox(height: 12),
if (estimatedCost != null)
  Text('التكلفة التقديرية: \$${estimatedCost!.toStringAsFixed(2)}'),

                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                  child: isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.isEdit ? 'تحديث الطلب' : 'إرسال الطلب', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
