import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'models.dart';

/// سر توليد كود تأكيد الدفع (بيتحسب من رقم الطلب + رقم القسط)
const _kPaySecret = 'MALL-PAY-2026-K7X';

/// تحويل الأرقام العربي لإنجليزي وإزالة أي رموز
String digitsOnly(String raw) {
  final b = StringBuffer();
  for (final r in raw.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.write(r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.write(r - 0x06F0);
    } else if (r >= 0x30 && r <= 0x39) {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// توحيد شكل رقم الموبايل 01xxxxxxxxx
String normalizePhone(String raw) {
  var d = digitsOnly(raw);
  if (d.startsWith('0020')) d = d.substring(4);
  if (d.startsWith('20') && d.length == 12) d = '0${d.substring(2)}';
  if (d.length == 10 && d.startsWith('1')) d = '0$d';
  return d;
}

bool isValidPhone(String phone) => RegExp(r'^01[0125]\d{8}$').hasMatch(phone);

/// كود تأكيد دفع القسط رقم n من الطلب (6 أرقام)
String payCode(String orderId, int n) {
  final input = '$_kPaySecret|$orderId|$n';
  var h = 0x811C9DC5;
  for (final byte in input.codeUnits) {
    h = ((h ^ byte) * 16777619) & 0xFFFFFFFF;
  }
  return (100000 + h % 900000).toString();
}

/// تخزين بيانات العميل على الموبايل (بيشتغل بدون إنترنت)
class Session {
  final SharedPreferences _p;
  Session(this._p);

  static Future<Session> load() async =>
      Session(await SharedPreferences.getInstance());

  String get name => _p.getString('name') ?? '';
  String get phone => _p.getString('phone') ?? '';
  bool get activated => _p.getBool('activated') ?? false;

  Future<void> saveProfile(String name, String phone) async {
    if (phone != this.phone) {
      await _p.remove('plans');
      await _p.remove('reward_requested');
    }
    await _p.setString('name', name);
    await _p.setString('phone', phone);
  }

  Future<void> activate() async {
    await _p.setBool('activated', true);
    await _p.setString('activated_at', DateTime.now().toIso8601String());
  }

  Future<void> logout() async {
    await _p.setBool('activated', false);
  }

  // ---------- الأقساط ----------
  List<Plan> get plans {
    final s = _p.getString('plans');
    if (s == null) return [];
    try {
      final l = jsonDecode(s) as List;
      return l
          .map((e) => Plan.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlans(List<Plan> l) =>
      _p.setString('plans', jsonEncode(l.map((e) => e.toMap()).toList()));

  Future<void> addPlan(Plan p) async {
    final l = plans;
    l.add(p);
    await savePlans(l);
  }

  Future<void> updatePlan(Plan p) async {
    await savePlans(plans.map((e) => e.id == p.id ? p : e).toList());
  }

  /// تأكيد دفع القسط الجاي بكود من المول. بيرجع true لو الكود صح.
  Future<bool> confirmPayment(Plan plan, String codeRaw) async {
    if (plan.finished) return false;
    final entered = digitsOnly(codeRaw);
    if (entered != payCode(plan.id, plan.paid + 1)) return false;
    await updatePlan(plan.copyWith(paid: plan.paid + 1, claimed: false));
    return true;
  }

  // ---------- النقط والمكافأة ----------
  int get totalPaid => plans.fold<int>(0, (s, p) => s + p.paid);
  int get points => totalPaid * kPointsPerInstallment;
  bool get rewardEligible => totalPaid >= kRewardAfter;
  bool get rewardRequested => _p.getBool('reward_requested') ?? false;
  Future<void> setRewardRequested() => _p.setBool('reward_requested', true);
}
