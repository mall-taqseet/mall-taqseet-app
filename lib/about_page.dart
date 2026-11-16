import 'package:flutter/material.dart';

import 'config.dart';
import 'data.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _title(IconData icon, String text) => Row(children: [
        Icon(icon, color: kOrange),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن المول')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        cardBox(
          child: Column(children: const [
            Icon(Icons.two_wheeler, size: 70, color: kOrange),
            SizedBox(height: 8),
            Text('مول التقسيط',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: kOrange)),
            SizedBox(height: 6),
            Text('موتوسيكلات بالتقسيط المريح على 12 و24 و36 شهر',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70)),
          ]),
        ),
        cardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _title(Icons.location_on, 'العنوان'),
            const SizedBox(height: 8),
            const Text(kAddress, style: TextStyle(height: 1.6)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('افتح على الخريطة'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kOrange,
                  side: const BorderSide(color: kOrange)),
              onPressed: () => openUrl(
                  context,
                  Uri.https('www.google.com', '/maps/search/',
                      {'api': '1', 'query': kAddress})),
            ),
          ]),
        ),
        cardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _title(Icons.chat, 'واتساب'),
            const SizedBox(height: 8),
            const Text(kPhoneDisplay,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: kOrange,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text('واتساب'),
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: () => openWhatsApp(context,
                      phone: kWhatsapp, text: 'أهلاً مول التقسيط 👋'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('اتصال'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: kOrange,
                      minimumSize: const Size(0, 46),
                      side: const BorderSide(color: kOrange)),
                  onPressed: () => openUrl(
                      context, Uri(scheme: 'tel', path: kPhoneDisplay)),
                ),
              ),
            ]),
          ]),
        ),
        cardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _title(Icons.schedule, 'مواعيد العمل'),
            const SizedBox(height: 8),
            const Text(kWorkingHours,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('© 2026 مول التقسيط',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
      ]),
    );
  }
}
