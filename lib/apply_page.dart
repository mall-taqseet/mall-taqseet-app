import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
class ApplyPage extends StatefulWidget {
  final String? bikeName;
  const ApplyPage({super.key, this.bikeName});
  @override
  State<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  final _job = TextEditingController();
  final _workPlace = TextEditingController();
  final _workAddress = TextEditingController();
  final _bike = TextEditingController();
  final _downPayment = TextEditingController();
  final _creditDetails = TextEditingController();
  String _duration = '12 شهر';
  String? _creditProblem;
  String? _amanClient;
  XFile? _idImage;
  XFile? _salaryImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.bikeName != null) _bike.text = widget.bikeName!;
  }

  Future<void> _pickImage(bool isId) async {
    final XFile? img = await showModalBottomSheet<XFile>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('افتح الكاميرا'),
            onTap: () async {
              final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
              if (mounted) Navigator.pop(context, f);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('اختار من المعرض'),
            onTap: () async {
              final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (mounted) Navigator.pop(context, f);
            },
          ),
        ]),
      ),
    );
    if (img != null) {
      setState(() {
        if (isId) _idImage = img; else _salaryImage = img;
      });
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_creditProblem == null || _amanClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('من فضلك جاوب على سؤال الاستعلام وسؤال أمان')));
      return;
    }
    if (_idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('من فضلك صور البطاقة الأول')));
      return;
    }
    final down = _downPayment.text.trim().isEmpty ? 'بدون مقدم' : _downPayment.text.trim();
    final credit = _creditProblem == 'نعم' ? 'نعم - ${_creditDetails.text.trim()}' : 'لا';
    final msg = '''
طلب تقسيط جديد - مول التقسيط

الاسم رباعي: ${_name.text}
رقم التليفون: ${_phone.text}
العنوان بالتفصيل: ${_address.text}
علامة مميزة: ${_landmark.text}
الوظيفة: ${_job.text}
مكان العمل: ${_workPlace.text}
عنوان الشغل: ${_workAddress.text}
نوع المكنة: ${_bike.text}
مدة التقسيط: $_duration
المقدم: $down
مشكلة في الاستعلام الائتماني: $credit
عميل حالي في شركة أمان؟: $_amanClient

تم رفع صورة البطاقة ومفردات المرتب - سيتم ارسالها من المعرض
''';
    final uri = Uri.parse('https://wa.me/201105607517?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قدم على التقسيط')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(controller: _name, decoration: _dec('الاسم رباعي *'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: _dec('رقم التليفون - متسجل باسمك *'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _address, decoration: _dec('العنوان بالتفصيل *'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _landmark, decoration: _dec('علامة مميزة جنب البيت *'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _job, decoration: _dec('شغال ايه؟ *'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _workPlace, decoration: _dec('شغال فين؟ *'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _workAddress, decoration: _dec('عنوان الشغل *'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _bike, decoration: _dec('نوع المكنة اللي عايزها *'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _duration,
                decoration: _dec('مدة التقسيط'),
                items: const ['12 شهر', '24 شهر', '36 شهر'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _duration = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _downPayment, keyboardType: TextInputType.number, decoration: _dec('المقدم - اختياري، لو مفيش سيبه فاضي')),
              const SizedBox(height: 16),
              const Text('هل لديك مشكلة في الاستعلام الائتماني؟ (تأخيرات) *', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile(value: 'لا', groupValue: _creditProblem, title: const Text('لا'), onChanged: (v) => setState(() => _creditProblem = v.toString())),
              RadioListTile(value: 'نعم', groupValue: _creditProblem, title: const Text('نعم'), onChanged: (v) => setState(() => _creditProblem = v.toString())),
              if (_creditProblem == 'نعم')
                TextFormField(controller: _creditDetails, decoration: _dec('وضح المشكلة باختصار - اختياري')),
              const SizedBox(height: 16),
              const Text('هل أنت عميل حالي في شركة أمان؟ *', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile(value: 'نعم', groupValue: _amanClient, title: const Text('نعم'), onChanged: (v) => setState(() => _amanClient = v.toString())),
              RadioListTile(value: 'لا', groupValue: _amanClient, title: const Text('لا'), onChanged: (v) => setState(() => _amanClient = v.toString())),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: () => _pickImage(true), icon: const Icon(Icons.badge), label: Text(_idImage == null ? 'صور البطاقة *' : 'تم تصوير البطاقة - دوس لتغييرها')),
              if (_idImage != null) Padding(padding: const EdgeInsets.only(top: 8), child: Image.file(File(_idImage!.path), height: 140)),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () => _pickImage(false), icon: const Icon(Icons.receipt_long), label: Text(_salaryImage == null ? 'صور مفردات المرتب - اختياري' : 'تم تصوير مفردات المرتب')),
              if (_salaryImage != null) Padding(padding: const EdgeInsets.only(top: 8), child: Image.file(File(_salaryImage!.path), height: 140)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _send, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)), child: const Text('ابعت الطلب واتساب', style: TextStyle(fontSize: 18))),
              const SizedBox(height: 8),
              const Text('بعد ما تدوس، الواتساب هيفتح بالبيانات جاهزة، دوس ارسال، وبعدها ابعت صورتين البطاقة ومفردات المرتب من المعرض.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
