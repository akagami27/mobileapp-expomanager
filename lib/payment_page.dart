import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'exhibitor_login.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const PaymentPage({super.key, required this.bookingData});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessing = false;
  bool _isAuthorized = false;

  bool _furniture = false;
  bool _wifi = false;
  bool _promo = false;

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  final int _processingFee = 50;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int get _boothPrice => widget.bookingData['boothPrice'] ?? 0;

  int get _addonsTotal {
    int total = 0;
    if (_furniture) total += 200;
    if (_wifi) total += 100;
    if (_promo) total += 500;
    return total;
  }

  int get _grandTotal => _boothPrice + _addonsTotal + _processingFee;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  /// 🔐 BLOCK GUEST ACCESS
  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('current_user_role');
    final user = _auth.currentUser;

    if (role != 'exhibitor' || user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExhibitorLoginPage()),
        );
      }
      return;
    }

    setState(() => _isAuthorized = true);
  }

  Future<void> _processPayment() async {
    if (_cardNumberCtrl.text.isEmpty ||
        _expiryCtrl.text.isEmpty ||
        _cvvCtrl.text.isEmpty ||
        _holderCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in card details')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));

    final user = _auth.currentUser!;

    final finalData = {
      ...widget.bookingData,
      'addons': [
        if (_furniture) 'Additional Furniture',
        if (_wifi) 'Extended WiFi',
        if (_promo) 'Promotional Spot',
      ],
      'addonsTotal': _addonsTotal,
      'processingFee': _processingFee,
      'totalAmount': _grandTotal,
      'paymentStatus': 'Paid',
      'paymentMethod': 'Credit Card',
      'status': 'Pending',
      'role': 'exhibitor',
      'userId': user.uid,
      'firebase_createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('applications').add(finalData);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          'Payment successful.\nPlease wait for admin approval.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
            },
            child: const Text('Back to Home'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Secure Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _creditCardPreview(),
            const SizedBox(height: 30),
            _inputFields(),
            const SizedBox(height: 20),
            _addonsSection(), // ✅ ADDED HERE
            const SizedBox(height: 30),
            _summary(),
            const SizedBox(height: 30),
            _payButton(),
          ],
        ),
      ),
    );
  }

  Widget _addonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add-On Items',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        CheckboxListTile(
          title: const Text('Additional Furniture (+RM200)'),
          value: _furniture,
          onChanged: (v) => setState(() => _furniture = v!),
        ),
        CheckboxListTile(
          title: const Text('Extended WiFi (+RM100)'),
          value: _wifi,
          onChanged: (v) => setState(() => _wifi = v!),
        ),
        CheckboxListTile(
          title: const Text('Promotional Spot (+RM500)'),
          value: _promo,
          onChanged: (v) => setState(() => _promo = v!),
        ),
      ],
    );
  }

  Widget _summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Order Summary",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(),
        _SummaryRow("Booth Booking", "RM $_boothPrice.00"),
        _SummaryRow("Add-ons", "RM $_addonsTotal.00"),
        _SummaryRow("Processing Fee", "RM $_processingFee.00"),
        const Divider(),
        _SummaryRow("Total", "RM $_grandTotal.00", bold: true),
      ],
    );
  }

  Widget _payButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("PAY NOW",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _creditCardPreview() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.credit_card, color: Colors.white, size: 40),
          Text(
            _cardNumberCtrl.text.isEmpty
                ? '**** **** **** ****'
                : _cardNumberCtrl.text,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, letterSpacing: 2),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _holderCtrl.text.isEmpty
                    ? 'CARD HOLDER'
                    : _holderCtrl.text.toUpperCase(),
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                _expiryCtrl.text.isEmpty ? 'MM/YY' : _expiryCtrl.text,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputFields() {
    return Column(
      children: [
        TextField(
          controller: _cardNumberCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            prefixIcon: Icon(Icons.numbers),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expiry (MM/YY)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: _cvvCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _holderCtrl,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool bold;

  const _SummaryRow(this.label, this.amount, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(amount,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
