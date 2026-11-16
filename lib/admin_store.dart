import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

int _i(Object? v) => (v is num) ? v.toInt() : (int.tryParse('${v ?? ''}') ?? 0);

class ImportResult {
  int customers = 0, orders = 0, claims = 0;
  bool get empty => customers + orders + claims == 0;
}

/// بيانات لوحة الأدمن (محفوظة على موبايل الأدمن بس)
class AdminStore {
  final SharedPreferences _p;
  final Map<String, Map<String, dynamic>> customers;
  final Map<String, Map<String, dynamic>> orders;
  AdminStore._(this._p, this.customers, this.orders);

  static Map<String, Map<String, dynamic>> _read(
      SharedPreferences p, String key) {
    final s = p.getString(key);
    if (s == null) return {};
    try {
      return (jsonDecode(s) as Map).map(
          (k, v) => MapEntry('$k', Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  static Future<AdminStore> load() async {
    final p = await SharedPreferences.getInstance();
    return AdminStore._(
        p, _read(p, 'admin_customers'), _read(p, 'admin_orders'));
  }

  Future<void> save() async {
    await _p.setString('admin_customers', jsonEncode(customers));
    await _p.setString('admin_orders', jsonEncode(orders));
  }

  // ---------- قراءة ----------
  static DateTime orderTime(Map<String, dynamic> o) =>
      DateTime.fromMillisecondsSinceEpoch(
          int.tryParse('${o['id']}', radix: 36) ?? 0);

  List<Map<String, dynamic>> get orderList {
    final l = orders.values.toList();
    l.sort((a, b) => orderTime(b).compareTo(orderTime(a)));
    return l;
  }

  List<Map<String, dynamic>> get customerList {
    final l = customers.values.toList();
    l.sort((a, b) => '${b['addedAt']}'.compareTo('${a['addedAt']}'));
    return l;
  }

  int paidOf(String phone) => orders.values
      .where((o) => o['phone'] == phone)
      .fold<int>(0, (s, o) => s + _i(o['paid']));

  bool eligible(String phone, int rewardAfter) =>
      paidOf(phone) >= rewardAfter && customers[phone]?['rewardUsed'] != true;

  int get waitingReceipts =>
      orders.values.where((o) => _i(o['claim']) > _i(o['paid'])).length;

  // ---------- تعديل ----------
  bool _upsertCustomer(String phone, String name) {
    final c = customers[phone];
    if (c == null) {
      customers[phone] = {
        'phone': phone,
        'name': name,
        'addedAt': DateTime.now().toIso8601String(),
        'rewardUsed': false,
      };
      return true;
    }
    if (name.isNotEmpty && c['name'] != name) c['name'] = name;
    return false;
  }

  bool _addOrder(String id, String phone, String name, String product,
      int price, int down, int months, int inst, String start,
      {int paid = 0}) {
    if (orders.containsKey(id) || months <= 0) return false;
    orders[id] = {
      'id': id,
      'phone': phone,
      'name': name,
      'product': product,
      'price': price,
      'down': down,
      'months': months,
      'inst': inst,
      'start': start,
      'paid': paid,
      'claim': 0,
    };
    return true;
  }

  void confirmPay(String id) {
    final o = orders[id];
    if (o == null) return;
    final paid = _i(o['paid']);
    if (paid >= _i(o['months'])) return;
    o['paid'] = paid + 1;
    o['claim'] = 0;
  }

  void deleteOrder(String id) => orders.remove(id);

  void setRewardUsed(String phone) {
    customers[phone]?['rewardUsed'] = true;
  }

  /// بيقرا رسايل العملاء اللي اتلصقت من واتساب (تسجيل / حجز / إيصال)
  ImportResult importText(String raw) {
    final r = ImportResult();
    final text = raw.replaceAll(
        RegExp('[\u200e\u200f\u202a-\u202e\u2066-\u2069]'), '');

    // 1) طلب كود التفعيل
    final reg = RegExp(r'ورقمي هو\s*(01[0125]\d{8})\s+اسمي:\s*([^\n\r]+)');
    for (final m in reg.allMatches(text)) {
      if (_upsertCustomer(m.group(1)!, m.group(2)!.trim())) r.customers++;
    }

    // 2) الحجز
    final ord = RegExp(
        r'ORD\|([a-z0-9]{4,20})\|(01[0125]\d{8})\|([^|\n\r]*)\|([^|\n\r]*)\|(\d+)\|(\d+)\|(\d+)\|(\d+)\|(\d{4}-\d{2}-\d{2})');
    for (final m in ord.allMatches(text)) {
      final phone = m.group(2)!;
      final name = m.group(3)!.trim();
      if (_upsertCustomer(phone, name)) r.customers++;
      if (_addOrder(m.group(1)!, phone, name, m.group(4)!.trim(),
          int.parse(m.group(5)!), int.parse(m.group(6)!),
          int.parse(m.group(7)!), int.parse(m.group(8)!), m.group(9)!)) {
        r.orders++;
      }
    }

    // 3) إيصال دفع
    final pay = RegExp(
        r'PAY\|([a-z0-9]{4,20})\|(\d+)\|(01[0125]\d{8})\|([^|\n\r]*)\|([^|\n\r]*)\|(\d+)\|(\d+)\|(\d+)\|(\d+)\|(\d{4}-\d{2}-\d{2})');
    for (final m in pay.allMatches(text)) {
      final id = m.group(1)!;
      final n = int.parse(m.group(2)!);
      final phone = m.group(3)!;
      final name = m.group(4)!.trim();
      if (_upsertCustomer(phone, name)) r.customers++;
      if (!orders.containsKey(id)) {
        if (_addOrder(id, phone, name, m.group(5)!.trim(),
            int.parse(m.group(6)!), int.parse(m.group(7)!),
            int.parse(m.group(8)!), int.parse(m.group(9)!), m.group(10)!,
            paid: n > 0 ? n - 1 : 0)) {
          r.orders++;
        }
      }
      final o = orders[id];
      if (o != null && n > _i(o['paid']) && _i(o['claim']) != n) {
        o['claim'] = n;
        r.claims++;
      }
    }
    return r;
  }
}
