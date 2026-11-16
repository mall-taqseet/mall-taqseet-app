import 'data.dart';
import 'models.dart';

String _c(String s) => s.replaceAll(RegExp(r'[|\r\n]'), ' ').trim();

String _tail(Plan p, String name) =>
    '${_c(name)}|${_c(p.product)}|${p.price}|${p.down}|${p.months}|${p.installment}|${isoDate(p.start)}';

/// رسالة طلب كود التفعيل
String registerMessage(String name, String phone) =>
    'عايز كود تفعيل مول التقسيط ورقمي هو $phone\nاسمي: $name';

/// رسالة الحجز (آخر سطر فيها بيقراه لوحة الأدمن في الاستيراد)
String orderMessage(Plan p, String name, String phone) =>
    'أهلاً مول التقسيط 👋\n'
    'الاسم: $name\n'
    'رقمي: $phone\n'
    'عايز أحجز: ${p.product}\n'
    'السعر: ${fmt(p.price)} جنيه\n'
    'المقدم: ${fmt(p.down)} جنيه\n'
    'المدة: ${p.months} شهر\n'
    'القسط الشهري: ${fmt(p.installment)} جنيه\n'
    'أول قسط: ${fmtDate(p.start)}\n'
    'رقم الطلب: ${p.id}\n'
    '🔖 ORD|${p.id}|$phone|${_tail(p, name)}';

/// رسالة إيصال الدفع
String receiptMessage(
        Plan p, String name, String phone, int n, String method) =>
    'أهلاً مول التقسيط 🧾\n'
    'دفعت القسط رقم $n من ${p.months}\n'
    'المبلغ: ${fmt(p.installment)} جنيه\n'
    'طريقة الدفع: $method\n'
    'المنتج: ${p.product}\n'
    'الاسم: $name\n'
    'رقمي: $phone\n'
    'رقم الطلب: ${p.id}\n'
    '🔖 PAY|${p.id}|$n|$phone|${_tail(p, name)}';
