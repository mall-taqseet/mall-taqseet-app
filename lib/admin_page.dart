import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_store.dart';
import 'auth.dart';
import 'config.dart';
import 'data.dart';

int _n(Object? v) => (v is num) ? v.toInt() : (int.tryParse('${v ?? ''}') ?? 0);

String _dt(Object? iso) {
  final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
  return d == null ? '' : fmtDate(d);
}

/// بوابة الأدمن: بتطلب الرقم السري وتفتح اللوحة
Future<void> openAdmin(BuildContext context) async {
  final c = TextEditingController();
  final pin = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kCard,
      title: const Text('دخول الأدمن'),
      content: TextField(
        controller: c,
        obscureText: true,
        autofocus: true,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(labelText: 'الرقم السري'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('دخول')),
      ],
    ),
  );
  if (pin == null || pin.isEmpty || !context.mounted) return;
  if (digitsOnly(pin) != kAdminPin) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('الرقم السري غلط ❌')));
    return;
  }
  Navigator.push(
      context, MaterialPageRoute<void>(builder: (_) => const AdminPage()));
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  AdminStore? _s;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await AdminStore.load();
    if (!mounted) return;
    setState(() => _s = s);
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<bool> _confirm(String text) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('تأكيد'),
        content: Text(text, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لأ')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('أيوه')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _import() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('استيراد من واتساب'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'من واتساب: حدد رسايل العملاء ← نسخ، وبعدين الصقها هنا. '
                'ممكن تلصق أكتر من رسالة مرة واحدة، ومفيش مشكلة لو لصقت نفس الرسالة تاني.',
                style: TextStyle(height: 1.5, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'الصق هنا...'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.paste),
              label: const Text('لصق من الحافظة'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kOrange,
                  side: const BorderSide(color: kOrange)),
              onPressed: () async {
                final d = await Clipboard.getData('text/plain');
                if (d?.text != null) c.text = d!.text!;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('استيراد')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || _s == null) return;
    final r = _s!.importText(text);
    await _s!.save();
    if (!mounted) return;
    setState(() {});
    _snack(r.empty
        ? 'مفيش بيانات جديدة في النص ده'
        : 'اتضاف: ${r.customers} مسجل • ${r.orders} طلب • ${r.claims} إيصال');
  }

  Future<void> _confirmPay(Map<String, dynamic> o) async {
    final id = '${o['id']}';
    final n = _n(o['paid']) + 1;
    final months = _n(o['months']);
    final code = payCode(id, n);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('تأكيد دفع القسط $n'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${o['name']} دفع ${fmt(_n(o['inst']))} جنيه؟',
              style: const TextStyle(height: 1.6)),
          const SizedBox(height: 12),
          const Text('كود التأكيد للعميل:',
              style: TextStyle(color: Colors.white70)),
          Text(code,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  color: kOrange,
                  fontSize: 34,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w900)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد وابعت الكود')),
        ],
      ),
    );
    if (go != true || _s == null) return;
    _s!.confirmPay(id);
    await _s!.save();
    if (!mounted) return;
    setState(() {});
    await openWhatsApp(context,
        phone: waNumber('${o['phone']}'),
        text: 'تم تأكيد دفع القسط رقم $n من $months ✅\n'
            'المنتج: ${o['product']}\n'
            'كود التأكيد: $code\n'
            'اكتبه في التطبيق: اقساطي ← عندي كود تأكيد الدفع');
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        actions: [
          IconButton(
              tooltip: 'استيراد من واتساب',
              icon: const Icon(Icons.download),
              onPressed: s == null ? null : _import),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : _content(s),
    );
  }

  Widget _stat(String label, int v) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kOrange.withAlpha(90))),
          child: Column(children: [
            Text('$v',
                style: const TextStyle(
                    color: kOrange, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
      );

  Widget _content(AdminStore s) {
    final customers = s.customerList;
    final orders = s.orderList;
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(children: [
            _stat('مسجلين', customers.length),
            _stat('طلبات', orders.length),
            _stat('إيصالات منتظرة', s.waitingReceipts),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('استيراد رسايل العملاء من واتساب'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
            onPressed: _import,
          ),
        ),
        const SizedBox(height: 6),
        TabBar(
          indicatorColor: kOrange,
          labelColor: kOrange,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'المسجلين (${customers.length})'),
            Tab(text: 'الطلبات (${orders.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(children: [
            _customersTab(s, customers),
            _ordersTab(s, orders),
          ]),
        ),
      ]),
    );
  }

  Widget _empty(String t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, height: 1.6)),
        ),
      );

  Widget _customersTab(AdminStore s, List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _empty('لسه مفيش مسجلين.\nاضغط "استيراد" والصق رسايل طلب الكود من واتساب.');
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: list.map((c) => _customerCard(s, c)).toList(),
    );
  }

  Widget _customerCard(AdminStore s, Map<String, dynamic> c) {
    final phone = '${c['phone']}';
    final paid = s.paidOf(phone);
    final eligible = s.eligible(phone, kRewardAfter);
    final used = c['rewardUsed'] == true;
    return cardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${c['name']}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(phone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('اتضاف: ${_dt(c['addedAt'])}',
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(
            'أقساط مدفوعة: $paid  •  نقاط: ${paid * kPointsPerInstallment}',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        if (eligible)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('🎁 مكافأة متاحة (غيار زيت أو صيانة)',
                style: TextStyle(color: kOrange, fontWeight: FontWeight.bold)),
          ),
        if (used)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('✅ استلم المكافأة',
                style: TextStyle(color: Colors.green)),
          ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.vpn_key, size: 18),
            label: const Text('ابعت الكود'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => openWhatsApp(context,
                phone: waNumber(phone),
                text: 'كود تفعيل مول التقسيط الخاص بيك: $kActivationCode'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('واتساب'),
            style: OutlinedButton.styleFrom(
                foregroundColor: kOrange,
                minimumSize: const Size(0, 40),
                side: const BorderSide(color: kOrange)),
            onPressed: () => openWhatsApp(context,
                phone: waNumber(phone), text: 'أهلاً ${c['name']} 👋'),
          ),
          if (eligible)
            ElevatedButton.icon(
              icon: const Icon(Icons.card_giftcard, size: 18),
              label: const Text('سلّمت المكافأة'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () async {
                if (await _confirm('تسجيل إن ${c['name']} استلم المكافأة؟')) {
                  s.setRewardUsed(phone);
                  await s.save();
                  if (mounted) setState(() {});
                }
              },
            ),
        ]),
      ]),
    );
  }

  Widget _ordersTab(AdminStore s, List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _empty('لسه مفيش طلبات.\nاضغط "استيراد" والصق رسايل الحجز من واتساب.');
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: list.map((o) => _orderCard(s, o)).toList(),
    );
  }

  Widget _orderCard(AdminStore s, Map<String, dynamic> o) {
    final months = _n(o['months']);
    final paid = _n(o['paid']);
    final claim = _n(o['claim']);
    final phone = '${o['phone']}';
    final waiting = claim > paid;
    return cardBox(
      border: waiting ? kOrange : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('${o['product']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900))),
          paid >= months
              ? statusChip('خلّص', Colors.green)
              : statusChip('$paid / $months', kOrange),
        ]),
        const SizedBox(height: 4),
        Text('${o['name']}  •  $phone',
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
            'السعر ${fmt(_n(o['price']))} • المقدم ${fmt(_n(o['down']))}\n'
            'القسط ${fmt(_n(o['inst']))} × $months شهر\n'
            'أول قسط: ${_dt(o['start'])}\n'
            'اتقدم: ${fmtDate(AdminStore.orderTime(o))}',
            style: const TextStyle(color: Colors.white70, height: 1.6)),
        if (waiting)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('📩 العميل بعت إيصال القسط $claim',
                style: const TextStyle(
                    color: kOrange, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (paid < months)
            ElevatedButton.icon(
              icon: const Icon(Icons.payments, size: 18),
              label: Text('تأكيد دفع القسط ${paid + 1}'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => _confirmPay(o),
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('واتساب'),
            style: OutlinedButton.styleFrom(
                foregroundColor: kOrange,
                minimumSize: const Size(0, 40),
                side: const BorderSide(color: kOrange)),
            onPressed: () => openWhatsApp(context,
                phone: waNumber(phone),
                text: 'أهلاً ${o['name']} 👋 بخصوص طلبك ${o['product']}'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('حذف'),
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                minimumSize: const Size(0, 40),
                side: const BorderSide(color: Colors.redAccent)),
            onPressed: () async {
              if (await _confirm('حذف طلب ${o['name']} (${o['product']})؟')) {
                s.deleteOrder('${o['id']}');
                await s.save();
                if (mounted) setState(() {});
              }
            },
          ),
        ]),
      ]),
    );
  }
}
