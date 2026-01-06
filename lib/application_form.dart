import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'payment_page.dart';
import 'exhibitor_login.dart';

class ApplicationFormPage extends StatefulWidget {
  final String exhibitionId;
  final String exhibitionName;
  final String venue;
  final String? boothCode;
  final int boothPrice; // ✅ REQUIRED

  const ApplicationFormPage({
    super.key,
    required this.exhibitionId,
    required this.exhibitionName,
    required this.venue,
    this.boothCode,
    required this.boothPrice,
  });

  @override
  State<ApplicationFormPage> createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  final _companyCtrl = TextEditingController();
  final _profileCtrl = TextEditingController();
  late final TextEditingController _boothCtrl;

  bool _furniture = false;
  bool _wifi = false;
  bool _promo = false;

  bool _authorized = false;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _boothCtrl = TextEditingController(text: widget.boothCode ?? '');
    _checkLogin();
  }

  void _checkLogin() {
    if (_auth.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ExhibitorLoginPage()),
      );
    } else {
      setState(() => _authorized = true);
    }
  }

  int get _addonsTotal {
    int total = 0;
    if (_furniture) total += 200;
    if (_wifi) total += 100;
    if (_promo) total += 500;
    return total;
  }

  int get _grandTotal {
    return widget.boothPrice + _addonsTotal + 50;
  }

  void _proceedToPayment() {
    if (_companyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company name required')),
      );
      return;
    }

    final bookingData = {
      'applicationId': DateTime.now().millisecondsSinceEpoch.toString(),
      'exhibitionId': widget.exhibitionId,
      'exhibitionName': widget.exhibitionName,
      'venue': widget.venue,
      'companyName': _companyCtrl.text.trim(),
      'boothCode': _boothCtrl.text,
      'boothPrice': widget.boothPrice,
      'addonsTotal': _addonsTotal,
      'processingFee': 50,
      'totalAmount': _grandTotal,
      'addons': [
        if (_furniture) 'Furniture',
        if (_wifi) 'Extended WiFi',
        if (_promo) 'Promo Spot',
      ],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(bookingData: bookingData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Booth'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Selected Booth: ${widget.boothCode} (RM ${widget.boothPrice})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyCtrl,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _boothCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Booth Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: const Text('Additional Furniture (+RM200)'),
              value: _furniture,
              onChanged: (v) => setState(() => _furniture = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Extended WiFi (+RM100)'),
              value: _wifi,
              onChanged: (v) => setState(() => _wifi = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Promotional Spot (+RM500)'),
              value: _promo,
              onChanged: (v) => setState(() => _promo = v ?? false),
            ),
            const SizedBox(height: 20),
            Text(
              'Total: RM $_grandTotal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
