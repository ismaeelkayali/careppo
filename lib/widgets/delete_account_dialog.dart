import 'package:flutter/material.dart';

Future<bool?> showDeleteAccountDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("تأكيد الحذف"),
      content: const Text("هل أنت متأكد من رغبتك بحذف الحساب؟ لا يمكن التراجع عن هذه العملية وسيتم الغاء جميع الحجوزات عند حذف الحساب."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("إلغاء"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("حذف"),
        ),
      ],
    ),
  );
}
