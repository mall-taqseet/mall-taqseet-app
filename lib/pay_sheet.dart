import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth.dart';
import 'data.dart';
import 'models.dart';
import 'wire.dart';

const _methods = <(String, IconData, String)>[
  ('فودافون كاش', Icons.phone_android, 'حوّل المبلغ على الرقم ده من فودافون كاش'),
  ('انستا باي', Icons.account_balance, 'حوّل المبلغ على الرقم ده من انستا باي'),
  ('فوري', Icons.storefront, 'ادفع المبلغ في أي منفذ فوري بالرقم ده'),
];

/// شاشة دفع القسط: فودافون كاش / انستا باي / فوري
Future<void> showPaySheet(
  BuildContext context, {
  required Session session,
  required Plan plan,
}) {
  final no = plan.paid + 1;
  int sel = 0;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final m = _methods[sel];
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('ادفع القسط رقم $no من ${plan.months}',
                style: const TextStyle(
                    color: kOrange, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${fmt(plan.installment)} جنيه',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(
              children: List.generate(_methods.length, (i) {
                final on = i == sel;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setS(() => sel = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: on ? kOrange : kBlack,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: on ? kOrange : Colors.white24, width: 1.5),
                      ),
                      child: Column(children: [
                        Icon(_methods[i].$2,
                            color: on ? Colors.black : kOrange),
                        const SizedBox(height: 6),
                        Text(_methods[i].$1,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: on ? Colors.black : Colors.white)),
                      ]),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(m.$3, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text(kPhoneDisplay,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      color: kOrange,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              IconButton(
                icon: const Icon(Icons.copy, color: kOrange),
                onPressed: () async {
                  await Clipboard.setData(
                      const ClipboardData(text: kPhoneDisplay));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الرقم ✅')));
                  }
                },
              ),
            ]),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('دفعت؟ ابعت الإيصال على واتساب'),
              onPressed: () async {
                await session.updatePlan(plan.copyWith(claimed: true));
                if (!ctx.mounted) return;
                await openWhatsApp(
                  ctx,
                  phone: kWhatsapp,
                  text: receiptMessage(
                      plan, session.name, session.phone, no, m.$1),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      );
    }),
  );
}
