import 'dart:math';

import 'package:flutter/material.dart';
import 'auth.dart';
import 'data.dart';
import 'models.dart';
import 'wire.dart';

class ProductPage extends StatefulWidget {
  final Product product;
  final Session session;
  const ProductPage({super.key, required this.product, required this.session});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late int down;
  int months = 12;
  DateTime start = DateTime(2026, 12, 1);

  Product get p => widget.product;
  double get minDown => (p.price * 0.2).roundToDouble();
  double get maxDown => (p.price * 0.8).roundToDouble();

  @override
  void initState() {
    super.initState();
    down = (p.price / 3).round(); // مقدم افتراضي = ثلث السعر
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 12, 31),
      locale: const Locale('ar', 'EG'),
    );
    if (d != null) setState(() => start = d);
  }

  List<DateTime> _schedule() {
    final day = min(start.day, 28);
    return List.generate(
        months, (i) => DateTime(start.year, start.month + i, day));
  }

  void _showSchedule() {
    final inst = installmentFor(p.price, down, months);
    final dates = _schedule();
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(children: [
            const SizedBox(height: 14),
            Text('جدول أقساط ${p.name} - $months شهر',
                style: const TextStyle(
                    color: kOrange, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: dates.length,
                itemBuilder: (_, i) => ListTile(
                  leading: CircleAvatar(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.black,
                      child: Text('${i + 1}')),
                  title: Text(fmtDate(dates[i])),
                  trailing: Text('${fmt(inst)} جنيه',
                      style: const TextStyle(
                          color: kOrange, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _order() async {
    final inst = installmentFor(p.price, down, months);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('تأكيد الطلب'),
        content: Text('هتقدّم على ${p.name}\n'
            'المقدم: ${fmt(down)} جنيه\n'
            'القسط: ${fmt(inst)} جنيه × $months شهر'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('رجوع')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الطلب')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final s = widget.session;
    final plan = Plan(
      id: DateTime.now().millisecondsSinceEpoch.toRadixString(36),
      product: p.name,
      price: p.price,
      down: down,
      months: months,
      installment: inst,
      paid: 0,
      start: start,
    );
    await s.addPlan(plan);
    if (!mounted) return;
    await openWhatsApp(
      context,
      phone: kWhatsapp,
      text: orderMessage(plan, s.name, s.phone),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final inst = installmentFor(p.price, down, months);
    final total = totalFor(p.price, down, months);

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kOrange.withAlpha(90))),
          child: Row(children: [
            const Icon(Icons.two_wheeler, size: 48, color: kOrange),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              Text('السعر كاش: ${fmt(p.price)} جنيه',
                  style: const TextStyle(color: Colors.white70)),
            ]),
          ]),
        ),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('المقدم',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text('${fmt(down)} جنيه',
              style: const TextStyle(
                  color: kOrange, fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
        Slider(
          value: down.toDouble().clamp(minDown, maxDown),
          min: minDown,
          max: maxDown,
          activeColor: kOrange,
          inactiveColor: Colors.white24,
          onChanged: (v) => setState(() => down = (v / 500).round() * 500),
        ),
        const SizedBox(height: 8),
        const Text('اختار مدة التقسيط',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: kFactors.keys.map((m) {
            final sel = m == months;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => months = m),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: sel ? kOrange : kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: sel ? kOrange : Colors.white24, width: 1.5),
                  ),
                  child: Column(children: [
                    Text('$m شهر',
                        style: TextStyle(
                            color: sel ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(fmt(installmentFor(p.price, down, m)),
                        style: TextStyle(
                            color: sel ? Colors.black : kOrange,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    Text('جنيه / شهر',
                        style: TextStyle(
                            color: sel ? Colors.black87 : Colors.white54,
                            fontSize: 11)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kCard, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _row('المقدم', '${fmt(down)} جنيه'),
            _row('القسط الشهري', '${fmt(inst)} جنيه', hi: true),
            _row('عدد الأقساط', '$months شهر'),
            _row('الإجمالي', '${fmt(total)} جنيه'),
            const Divider(),
            InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  const Icon(Icons.event, color: kOrange),
                  const SizedBox(width: 8),
                  const Text('أول قسط:'),
                  const Spacer(),
                  Text(fmtDate(start),
                      style: const TextStyle(
                          color: kOrange, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showSchedule,
          icon: const Icon(Icons.list_alt),
          label: const Text('شوف جدول الأقساط'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kOrange,
            side: const BorderSide(color: kOrange),
            minimumSize: const Size.fromHeight(50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('اطلب دلوقتي'),
          onPressed: _order,
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _row(String a, String b, {bool hi = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: const TextStyle(color: Colors.white70)),
          Text(b,
              style: TextStyle(
                  color: hi ? kOrange : Colors.white,
                  fontSize: hi ? 20 : 15,
                  fontWeight: FontWeight.w900)),
        ]),
      );
}
