import 'package:flutter/material.dart';

import 'about_page.dart';
import 'account_page.dart';
import 'admin_page.dart';
import 'auth.dart';
import 'data.dart';
import 'installments_page.dart';
import 'pages.dart';
import 'product_page.dart';

class HomeShell extends StatefulWidget {
  final Session session;
  final VoidCallback onLogout;
  const HomeShell({super.key, required this.session, required this.onLogout});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  static const _titles = [
    'مول التقسيط',
    'اقساطي',
    'المكافآت',
    'ابعت لصاحبك',
    'حسابي',
  ];

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('تسجيل خروج'),
        content: const Text('هتحتاج كود تفعيل تاني لما ترجع. متأكد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لأ')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('خروج')),
        ],
      ),
    );
    if (ok == true) {
      await widget.session.logout();
      widget.onLogout();
    }
  }

  Widget _page() {
    switch (_i) {
      case 1:
        return InstallmentsPage(
          session: widget.session,
          onGoProducts: () => setState(() => _i = 0),
        );
      case 2:
        return const RewardsPage();
      case 3:
        return const ReferralPage();
      case 4:
        return AccountPage(session: widget.session);
      default:
        return ProductsPage(
          session: widget.session,
          onApplied: () => setState(() => _i = 1),
        );
    }
  }

  Widget _drawer() => Drawer(
        backgroundColor: kBlack,
        child: SafeArea(
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: kCard,
                  border: Border(bottom: BorderSide(color: kOrange.withAlpha(90)))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.two_wheeler, size: 48, color: kOrange),
                const SizedBox(height: 8),
                const Text('مول التقسيط',
                    style: TextStyle(
                        color: kOrange,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('أهلاً يا ${widget.session.name}',
                    style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            ListTile(
              leading: const Icon(Icons.storefront, color: kOrange),
              title: const Text('عن المول'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute<void>(builder: (_) => const AboutPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: kOrange),
              title: const Text('لوحة تحكم الأدمن'),
              trailing: const Icon(Icons.lock_outline, size: 18),
              onTap: () {
                Navigator.pop(context);
                openAdmin(context);
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text('تسجيل خروج'),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('© 2026 مول التقسيط',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_i],
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      drawer: _drawer(),
      body: _page(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: kCard,
        indicatorColor: kOrange,
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.two_wheeler), label: 'المنتجات'),
          NavigationDestination(
              icon: Icon(Icons.event_note), label: 'اقساطي'),
          NavigationDestination(
              icon: Icon(Icons.card_giftcard), label: 'المكافآت'),
          NavigationDestination(icon: Icon(Icons.share), label: 'ترشيح'),
          NavigationDestination(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  final Session session;
  final VoidCallback onApplied;
  const ProductsPage(
      {super.key, required this.session, required this.onApplied});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text('أهلاً يا ${session.name} 👋',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: kOrange)),
        ),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.88,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) {
            final p = products[i];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                final applied = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                      builder: (_) => ProductPage(product: p, session: session)),
                );
                if (applied == true) onApplied();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kOrange.withAlpha(90)),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.two_wheeler, size: 54, color: kOrange),
                    const SizedBox(height: 10),
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('${fmt(p.price)} جنيه',
                        style: const TextStyle(
                            color: kOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: kOrange,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('احسب القسط',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('© 2026 مول التقسيط',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ),
    ]);
  }
}
