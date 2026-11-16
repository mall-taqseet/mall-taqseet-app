import 'dart:math';

int _i(Object? v) => (v is num) ? v.toInt() : (int.tryParse('${v ?? ''}') ?? 0);

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// خطة تقسيط (طلب) محفوظة على موبايل العميل
class Plan {
  final String id;
  final String product;
  final int price, down, months, installment, paid;
  final DateTime start;

  /// العميل بعت إيصال القسط الجاي وبيستنى تأكيد المول
  final bool claimed;

  const Plan({
    required this.id,
    required this.product,
    required this.price,
    required this.down,
    required this.months,
    required this.installment,
    required this.paid,
    required this.start,
    this.claimed = false,
  });

  factory Plan.fromMap(Map<String, dynamic> m) => Plan(
        id: '${m['id']}',
        product: '${m['product']}',
        price: _i(m['price']),
        down: _i(m['down']),
        months: _i(m['months']),
        installment: _i(m['inst']),
        paid: _i(m['paid']),
        start: DateTime.tryParse('${m['start']}') ?? DateTime(2026, 12, 1),
        claimed: m['claimed'] == true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'product': product,
        'price': price,
        'down': down,
        'months': months,
        'inst': installment,
        'paid': paid,
        'start': isoDate(start),
        'claimed': claimed,
      };

  Plan copyWith({int? paid, bool? claimed}) => Plan(
        id: id,
        product: product,
        price: price,
        down: down,
        months: months,
        installment: installment,
        paid: paid ?? this.paid,
        start: start,
        claimed: claimed ?? this.claimed,
      );

  bool get finished => months > 0 && paid >= months;

  /// ميعاد القسط رقم index (يبدأ من 0)
  DateTime dueDate(int index) =>
      DateTime(start.year, start.month + index, min(start.day, 28));
}
