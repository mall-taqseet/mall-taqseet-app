import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kOrange = Color(0xFFFF6A00);
const kBlack = Color(0xFF0A0A0A);
const kCard = Color(0xFF1A1A1A);

/// رقم الواتساب الثابت
const kWhatsapp = '201105607517';
const kPhoneDisplay = '01105607517';

class Product {
  final String name;
  final int price;
  const Product(this.name, this.price);
}

const products = <Product>[
  Product('هوجن 4', 42000),
  Product('هوجن 3', 40000),
  Product('بوكسر', 60000),
  Product('TVS', 59000),
  Product('دايون 6', 48000),
  Product('هوجن 5', 45000),
];

/// معامل الزيادة لكل مدة (المبلغ المتبقي × المعامل ÷ عدد الشهور)
/// مطابق لمثال البوكسر: مقدم 20,000 => 12=6000 / 24=3500 / 36=2666
const kFactors = <int, double>{12: 1.8, 24: 2.1, 36: 2.4};

int installmentFor(int price, int down, int months) =>
    ((price - down) * kFactors[months]! / months).floor();

int totalFor(int price, int down, int months) =>
    down + installmentFor(price, down, months) * months;

String fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

const _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// رقم الموبايل المصري بصيغة دولية لواتساب (01012345678 -> 201012345678)
String waNumber(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  return d.startsWith('0') ? '20${d.substring(1)}' : d;
}

Future<bool> openUrl(BuildContext context, Uri uri,
    {String failMsg = 'مقدرناش نفتح الرابط'}) async {
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(failMsg)));
  }
  return ok;
}

Future<void> openWhatsApp(BuildContext context,
    {String? phone, required String text}) async {
  final base = phone == null ? 'https://wa.me/' : 'https://wa.me/$phone';
  final uri = Uri.parse('$base?text=${Uri.encodeComponent(text)}');
  await openUrl(context, uri,
      failMsg: 'مقدرناش نفتح واتساب، تأكد إنه متسطب');
}

Widget cardBox(
        {required Widget child,
        Color? border,
        EdgeInsets? padding,
        EdgeInsets? margin}) =>
    Container(
      margin: margin ?? const EdgeInsets.only(bottom: 14),
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? kOrange.withAlpha(90)),
      ),
      child: child,
    );

Widget statusChip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
