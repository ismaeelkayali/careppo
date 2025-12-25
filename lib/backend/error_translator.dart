class ErrorTranslator {
  static String translate(String raw, {String? context}) {
    final msg = (raw ?? "").toString().toLowerCase();

    // --- أخطاء تكرار البريد أو الهاتف (أولوية عالية) ---
    if (msg.contains("already registered") || msg.contains("already exists") || msg.contains("is already registered")) {
      if (msg.contains("email")) return "هذا البريد الإلكتروني مستخدم مسبقاً";
      if (msg.contains("phone") || msg.contains("phone number")) return "هذا الرقم مستخدم مسبقاً";
      return "هذا الحساب موجود مسبقاً";
    }

    // --- أخطاء تسجيل الدخول (بناء على السياق optional) ---
    if (context == "login") {
      if (msg.contains("invalid credentials")) return "رقم الهاتف أو كلمة المرور غير صحيحة";
      if (msg.contains("wrong password")) return "كلمة المرور غير صحيحة";
      if (msg.contains("user not found")) return "المستخدم غير موجود";
      if (msg.contains("inactive")) return "الحساب غير مفعل";
    }

    // --- أخطاء تغيير كلمة المرور ---
    if (context == "changePassword") {
      if (msg.contains("password invalid input") || msg.contains("expected string, received undefined")) {
        return "كلمة المرور القديمة غير صحيحة";
      }
      if (msg.contains("new password")) {
        return "كلمة المرور الجديدة غير صالحة أو مطابقة للقديمة";
      }
      if (msg.contains("invalid credentials")) return "كلمة المرور القديمة خاطئة";
    }

    // --- أخطاء متعلقة بالـ phone (محددة) ---
    // تحقق من عبارات محددة بدل الشرط العام 'phone'
    if (msg.contains("not a valid phone") ||
        msg.contains("invalid phone") ||
        msg.contains("phone number invalid") ||
        msg.contains("phone number is invalid")) {
      return "رقم الهاتف غير صالح. يجب أن يكون 9 إلى 10 أرقام بدون رمز البلد.";
    }

    // --- إنشاء حساب عامة ---
    if (msg.contains("unknown role")) return "هذا البريد الإلكتروني مستخدم مسبقاً";
    if (msg.contains("exists")) return "هذا الحساب موجود مسبقاً";
    if (msg.contains("duplicate")) return "هذا الحساب مسجل مسبقاً";

    // --- رموز المصادقة ---
    if (msg.contains("token")) return "خطأ في توثيق الجلسة";

    // --- انقطاع الانترنت ---
    if (msg.contains("socketexception") || msg.contains("تعذر الاتصال") || msg.contains("no_internet") || msg.contains("no internet")) {
      return "لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.";
    }

    // --- مهلة الاتصال ---
    if (msg.contains("timeout") || msg.contains("مهلة الاتصال")) {
      return "انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى.";
    }

    // قيمة افتراضية: أعد الرسالة كما هي (أو يمكن إرجاع نص عام بالعربية)
    return "حدث خطا غير متوقع";
  }
}
