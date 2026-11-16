import 'package:flutter/material.dart';

import 'auth.dart';
import 'data.dart';
import 'models.dart';
import 'pay_sheet.dart';

class InstallmentsPage extends StatefulWidget {
  final Session session;
  final VoidCallback onGoProducts;
  const InstallmentsPage(
      {super.key, required this.session, required this.onGoProducts});

  @override
  State<InstallmentsPage> createState() => _InstallmentsPageState();
}

class _InstallmentsPageState extends State<InstallmentsPage> {
  int _sel = -1; // -1 = آخر طلب

  Future<void> _enterCode(Plan plan) async {
    final c = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('كود تأكيد القسط رقم ${plan.paid + 1}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('المول هيبعتلك الكود على واتساب بعد ما يستلم الإيصال',
              style: TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
                fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w900),
            decoration: const InputDecoration(counterText: ''),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('تأكيد')),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    final ok = await widget.session.confirmPayment(plan, code);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'اتأكد دفع القسط رقم ${plan.paid + 1} ✅'
            : 'الكود غلط ❌ تأكد منه وجرب تاني')));
  }

  Future<void> _pay(Plan plan) async {
    await showPaySheet(context, session: widget.session, plan: plan);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.session.plans;
    if (plans.isEmpty) {
      return ListView(padding: const EdgeInsets.all(16), children: _empty());
    }
    final idx = (_sel < 0 || _sel >= plans.length) ? plans.length - 1 : _sel;
    final plan = plans[idx];
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (plans.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < plans.length; i++)
              ChoiceChip(
                label: Text(plans[i].product),
                selected: i == idx,
                selectedColor: kOrange,
                labelStyle: TextStyle(
                    color: i == idx ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold),
                onSelected: (_) => setState(() => _sel = i),
              ),
          ]),
        ),
      ..._planViews(plan),
    ]);
  }

  List<Widget> _empty() => [
        const SizedBox(height: 60),
        const Icon(Icons.event_note, size: 80, color: kOrange),
        const SizedBox(height: 16),
        const Text('لسه معندكش أقساط',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('اختار مكنة واطلبها وهتلاقي أقساطك ومواعيدها هنا',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.two_wheeler),
          label: const Text('تصفح المنتجات'),
          onPressed: widget.onGoProducts,
        ),
      ];

  Widget _row(String a, String b, {bool hi = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: const TextStyle(color: Colors.white70)),
          Text(b,
              style: TextStyle(
                  color: hi ? kOrange : Colors.white,
                  fontSize: hi ? 19 : 15,
                  fontWeight: FontWeight.w900)),
        ]),
      );

  List<Widget> _planViews(Plan plan) {
    final finished = plan.finished;
    final idx = finished ? plan.months - 1 : plan.paid;
    final due = plan.dueDate(idx);
    final now = DateTime.now();
    final overdue =
        !finished && DateTime(now.year, now.month, now.day).isAfter(due);
    final remaining = (plan.months - plan.paid) * plan.installment;

    return [
      cardBox(
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text(plan.product,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900))),
            finished
                ? statusChip('خلّص ✅', Colors.green)
                : statusChip('شغّال', kOrange),
          ]),
          const SizedBox(height: 10),
          _row('السعر كاش', '${fmt(plan.price)} جنيه'),
          _row('المقدم', '${fmt(plan.down)} جنيه'),
          _row('القسط الشهري', '${fmt(plan.installment)} جنيه', hi: true),
          _row('عدد الأقساط', '${plan.months} شهر'),
          _row('أول قسط', fmtDate(plan.start)),
        ]),
      ),
      cardBox(
        border: overdue ? Colors.redAccent : kOrange,
        child: finished
            ? Column(children: const [
                Icon(Icons.celebration, size: 48, color: kOrange),
                SizedBox(height: 8),
                Text('خلّصت كل أقساطك 🎉',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('القسط القادم: رقم ${plan.paid + 1} من ${plan.months}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (overdue) statusChip('متأخر', Colors.redAccent),
                ]),
                const SizedBox(height: 10),
                Center(
                  child: Text('${fmt(plan.installment)} جنيه',
                      style: const TextStyle(
                          color: kOrange,
                          fontSize: 34,
                          fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.event, size: 18, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text('ميعاده: ${fmtDate(due)}',
                      style: TextStyle(
                          color: overdue ? Colors.redAccent : Colors.white,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: plan.months == 0 ? 0 : plan.paid / plan.months,
                  color: kOrange,
                  backgroundColor: Colors.white12,
                  minHeight: 8,
                ),
                const SizedBox(height: 6),
                Text(
                    'دفعت ${plan.paid} من ${plan.months} • المتبقي ${fmt(remaining)} جنيه',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                if (plan.claimed)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: kOrange.withAlpha(30),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                        'بعتّ إيصال القسط ${plan.paid + 1} — مستني تأكيد المول (هيبعتلك كود التأكيد على واتساب).',
                        style: const TextStyle(height: 1.5, fontSize: 13)),
                  ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  icon: const Icon(Icons.payments),
                  label: const Text('ادفع القسط'),
                  onPressed: () => _pay(plan),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.verified),
                  label: const Text('عندي كود تأكيد الدفع'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kOrange,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: kOrange),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _enterCode(plan),
                ),
              ]),
      ),
      cardBox(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('جدول الأقساط',
                style: TextStyle(
                    color: kOrange, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          for (var i = 0; i < plan.months; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 15,
                backgroundColor: i < plan.paid
                    ? Colors.green
                    : (i == plan.paid ? kOrange : Colors.white12),
                foregroundColor: i < plan.paid ? Colors.white : Colors.black,
                child: Text('${i + 1}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              title: Text(fmtDate(plan.dueDate(i))),
              trailing: i < plan.paid
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : Text('${fmt(plan.installment)} جنيه',
                      style: TextStyle(
                          color: i == plan.paid ? kOrange : Colors.white70,
                          fontWeight: FontWeight.bold)),
            ),
        ]),
      ),
    ];
  }
}
