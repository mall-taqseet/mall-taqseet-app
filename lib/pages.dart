import 'package:flutter/material.dart';
import 'data.dart';

// ---------------- المكافآت ----------------
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      cardBox(
        child: Column(children: const [
          Icon(Icons.emoji_events, size: 56, color: kOrange),
          SizedBox(height: 10),
          Text('ادفع قسطين… وخد هدية!',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: kOrange)),
          SizedBox(height: 6),
          Text('اختار واحدة من الاتنين ببلاش',
              style: TextStyle(color: Colors.white70)),
        ]),
      ),
      cardBox(
        child: Row(children: const [
          Icon(Icons.oil_barrel, size: 40, color: kOrange),
          SizedBox(width: 14),
          Expanded(
            child: Text('غيار زيت ببلاش',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
      cardBox(
        child: Row(children: const [
          Icon(Icons.build_circle, size: 40, color: kOrange),
          SizedBox(width: 14),
          Expanded(
            child: Text('صيانة ببلاش',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Text('شوف موقفك من المكافأة في صفحة "حسابي"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60)),
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.chat),
        label: const Text('اسأل عن المكافأة على واتساب'),
        onPressed: () => openWhatsApp(context,
            phone: kWhatsapp,
            text: 'أهلاً مول التقسيط، عايز أستفسر عن مكافأة القسطين 🎁'),
      ),
    ]);
  }
}

// ---------------- الترشيح ----------------
class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      cardBox(
        child: Column(children: const [
          Icon(Icons.groups, size: 60, color: kOrange),
          SizedBox(height: 10),
          Text('اكسب 500 جنيه',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: kOrange)),
          SizedBox(height: 6),
          Text('عن كل صاحب ترشحله مول التقسيط ويشتري',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70)),
        ]),
      ),
      cardBox(
        child: Row(children: const [
          Icon(Icons.lock_outline, color: kOrange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
                'خصوصيتك محفوظة: التطبيق مش بيطلب ولا بياخد جهات الاتصال. '
                'انت اللي بتفتح واتساب وتختار صاحبك وتبعتله بنفسك.',
                style: TextStyle(height: 1.5)),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      ElevatedButton.icon(
        icon: const Icon(Icons.share),
        label: const Text('ابعت لصاحبك واكسب 500 جنيه'),
        onPressed: () => openWhatsApp(
          context,
          text: 'أهلاً 👋 جرّب مول التقسيط! موتوسيكلات (هوجن، بوكسر، TVS، دايون) '
              'بالتقسيط على 12 و24 و36 شهر، وادفع قسطين وخد غيار زيت أو صيانة ببلاش 🎁\n'
              'كلمهم على واتساب: $kPhoneDisplay\n'
              'ولما تشتري قولهم إني اللي رشحتلك.',
        ),
      ),
    ]);
  }
}
