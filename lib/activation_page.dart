import 'package:flutter/material.dart';
import 'auth.dart';
import 'config.dart';
import 'wire.dart';
import 'data.dart';

class ActivationPage extends StatefulWidget {
  final Session session;
  final VoidCallback onActivated;
  const ActivationPage(
      {super.key, required this.session, required this.onActivated});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _code = TextEditingController();
  bool _sent = false;
  String? _nameErr, _phoneErr, _codeErr;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.session.name);
    _phone = TextEditingController(text: widget.session.phone);
    // لو طلب كود قبل كده ولسه مفعّلش، نوريله خانة الكود على طول
    _sent = widget.session.name.isNotEmpty && widget.session.phone.isNotEmpty;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  bool _validateProfile() {
    final name = _name.text.trim();
    final phone = normalizePhone(_phone.text);
    setState(() {
      _nameErr = name.length < 2 ? 'اكتب اسمك' : null;
      _phoneErr = isValidPhone(phone)
          ? null
          : 'اكتب رقم موبايل مصري صحيح (مثال: 01012345678)';
    });
    return _nameErr == null && _phoneErr == null;
  }

  Future<void> _requestCode() async {
    if (!_validateProfile()) return;
    final name = _name.text.trim();
    final phone = normalizePhone(_phone.text);
    await widget.session.saveProfile(name, phone);
    if (!mounted) return;
    setState(() {
      _sent = true;
      _codeErr = null;
    });
    await openWhatsApp(
      context,
      phone: kWhatsapp,
      text: registerMessage(name, phone),
    );
  }

  Future<void> _verify() async {
    if (!_validateProfile()) return;
    final phone = normalizePhone(_phone.text);
    final entered = digitsOnly(_code.text);
    if (entered.isNotEmpty && entered == kActivationCode) {
      await widget.session.saveProfile(_name.text.trim(), phone);
      await widget.session.activate();
      widget.onActivated();
    } else {
      setState(() => _codeErr = 'الكود غلط ❌ تأكد منه وجرب تاني');
    }
  }

  InputDecoration _dec(String label, IconData icon, String? err) =>
      InputDecoration(
        labelText: label,
        errorText: err,
        prefixIcon: Icon(icon, color: kOrange),
        filled: true,
        fillColor: kCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kOrange.withAlpha(90))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kOrange.withAlpha(90))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kOrange, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Icon(Icons.two_wheeler, size: 80, color: kOrange),
              const SizedBox(height: 8),
              const Text('مول التقسيط',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: kOrange)),
              const SizedBox(height: 6),
              const Text('سجّل بياناتك عشان تفعّل حسابك',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 28),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: _dec('الاسم', Icons.person, _nameErr),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 14,
                textDirection: TextDirection.ltr,
                decoration: _dec('رقم التليفون', Icons.phone, _phoneErr)
                    .copyWith(counterText: ''),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: Text(_sent ? 'ابعتلي الكود تاني' : 'ابعتلي كود التفعيل'),
                onPressed: _requestCode,
              ),
              if (_sent) ...[
                const SizedBox(height: 28),
                const Divider(color: Colors.white24),
                const SizedBox(height: 14),
                const Text('هنبعتلك الكود على واتساب، اكتبه هنا 👇',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w900),
                  onChanged: (_) {
                    if (_codeErr != null) setState(() => _codeErr = null);
                  },
                  decoration: _dec('كود التفعيل', Icons.lock, _codeErr)
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 14),
                ElevatedButton(onPressed: _verify, child: const Text('تفعيل')),
              ],
              const SizedBox(height: 24),
              const Text('© 2026 مول التقسيط',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}
