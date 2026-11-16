import 'package:flutter/material.dart';

import 'auth.dart';
import 'config.dart';
import 'data.dart';

class AccountPage extends StatefulWidget {
  final Session session;
  const AccountPage({super.key, required this.session});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<void> _requestReward() async {
    final s = widget.session;
    await s.setRewardRequested();
    if (!mounted) return;
    setState(() {});
    await openWhatsApp(context,
        phone: kWhatsapp,
        text: 'أهلاً مول التقسيط 🎁\n'
            'أنا ${s.name} - رقمي ${s.phone}\n'
            'دفعت $kRewardAfter أقساط وعايز أستلم مكافأتي (غيار زيت أو صيانة ببلاش).');
  }

  Widget _reward() {
    final s = widget.session;
    final paid = s.totalPaid;
    if (s.rewardEligible && s.rewardRequested) {
      return cardBox(
        child: Column(children: [
          Row(children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 34),
            SizedBox(width: 12),
            Expanded(
              child: Text('طلبت مكافأتك (غيار زيت أو صيانة ببلاش) ✅',
                  style: TextStyle(fontWeight: FontWeight.bold, height: 1.5)),
            ),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('كلّم المول تاني'),
            style: OutlinedButton.styleFrom(
                foregroundColor: kOrange,
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: kOrange)),
            onPressed: _requestReward,
          ),
        ]),
      );
    }
    if (s.rewardEligible) {
      return cardBox(
        border: kOrange,
        child: Column(children: [
          const Text('🎁 ليك غيار زيت أو صيانة ببلاش!',
              style: TextStyle(
                  color: kOrange, fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('اختار واحدة منهم وكلمنا نحدد ميعاد',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('اطلب مكافأتي'),
            onPressed: _requestReward,
          ),
        ]),
      );
    }
    final shown = paid > kRewardAfter ? kRewardAfter : paid;
    return cardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.card_giftcard, color: kOrange),
          SizedBox(width: 10),
          Expanded(
            child: Text('غيار زيت أو صيانة ببلاش',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 6),
        const Text('ادفع قسطين وتاخد واحدة منهم ببلاش',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: shown / kRewardAfter,
          color: kOrange,
          backgroundColor: Colors.white12,
          minHeight: 8,
        ),
        const SizedBox(height: 6),
        Text('دفعت $shown من $kRewardAfter',
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return ListView(padding: const EdgeInsets.all(16), children: [
      cardBox(
        child: Column(children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: kOrange,
            foregroundColor: Colors.black,
            child: Icon(Icons.person, size: 44),
          ),
          const SizedBox(height: 12),
          Text(s.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(s.phone,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: kOrange, fontSize: 17)),
          const SizedBox(height: 10),
          statusChip('حسابك مفعّل ✅', Colors.green),
        ]),
      ),
      cardBox(
        child: Column(children: [
          const Text('نقطي',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 4),
          Text('${s.points}',
              style: const TextStyle(
                  color: kOrange, fontSize: 48, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('بتاخد نقط على كل قسط بيتأكد دفعه',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
      _reward(),
    ]);
  }
}
