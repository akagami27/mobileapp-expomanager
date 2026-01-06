import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final fullNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final companyCtrl = TextEditingController();

  bool enable2FA = false;
  bool notifApplication = true;
  bool notifPromo = false;
  bool notifBooth = true;
  bool smsNotif = true;

  List<Map<String, String>> savedCards = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedInfo();
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      fullNameCtrl.text = prefs.getString('profile_fullName') ?? '';
      emailCtrl.text = prefs.getString('profile_email') ?? '';
      phoneCtrl.text = prefs.getString('profile_phone') ?? '';
      companyCtrl.text = prefs.getString('profile_company') ?? '';
      enable2FA = prefs.getBool('profile_2fa') ?? false;
      notifApplication = prefs.getBool('notif_application') ?? true;
      notifPromo = prefs.getBool('notif_promo') ?? false;
      notifBooth = prefs.getBool('notif_booth') ?? true;
      smsNotif = prefs.getBool('sms_notif') ?? true;

      final rawCards = prefs.getStringList('saved_cards') ?? [];
      savedCards = rawCards.map((e) {
        final parts = e.split('|');
        return {'name': parts[0], 'number': parts[1]};
      }).toList();
    });
  }

  Future<void> _saveInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // =========================
    // 🔹 LOCAL SAVE (UNCHANGED)
    // =========================
    await prefs.setString('profile_fullName', fullNameCtrl.text);
    await prefs.setString('profile_email', emailCtrl.text);
    await prefs.setString('profile_phone', phoneCtrl.text);
    await prefs.setString('profile_company', companyCtrl.text);
    await prefs.setBool('profile_2fa', enable2FA);
    await prefs.setBool('notif_application', notifApplication);
    await prefs.setBool('notif_promo', notifPromo);
    await prefs.setBool('notif_booth', notifBooth);
    await prefs.setBool('sms_notif', smsNotif);

    final rawCards =
        savedCards.map((e) => '${e['name']}|${e['number']}').toList();
    await prefs.setStringList('saved_cards', rawCards);

    // =========================
    // 🔥 FIREBASE MIRROR SAVE
    // =========================
    try {
      final email =
          emailCtrl.text.isEmpty ? 'guest' : emailCtrl.text.toLowerCase();

      await _firestore.collection('users').doc(email).set({
        'fullName': fullNameCtrl.text,
        'email': emailCtrl.text,
        'phone': phoneCtrl.text,
        'company': companyCtrl.text,
        'settings': {
          'enable2FA': enable2FA,
          'notifApplication': notifApplication,
          'notifPromo': notifPromo,
          'notifBooth': notifBooth,
          'smsNotif': smsNotif,
        },
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Firebase failure ignored (offline-safe)
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addCard() {
    showDialog(
      context: context,
      builder: (_) {
        final nameCtrl = TextEditingController();
        final numberCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Card Name')),
              TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Card Number')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  savedCards
                      .add({'name': nameCtrl.text, 'number': numberCtrl.text});
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeCard(int index) {
    setState(() {
      savedCards.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSectionTitle('Personal Information'),
            _buildCard(children: [
              _buildModernTextField('Full Name', Icons.person, fullNameCtrl),
              _buildModernTextField('Email', Icons.email, emailCtrl),
              _buildModernTextField('Phone', Icons.phone, phoneCtrl),
              _buildModernTextField('Company', Icons.business, companyCtrl),
            ]),
            _buildSectionTitle('Security'),
            _buildCard(children: [
              SwitchListTile(
                title: const Text('Two-Factor Authentication'),
                value: enable2FA,
                onChanged: (val) => setState(() => enable2FA = val),
              ),
            ]),
            _buildSectionTitle('Notifications'),
            _buildCard(children: [
              CheckboxListTile(
                title: const Text('Application Updates'),
                value: notifApplication,
                onChanged: (v) => setState(() => notifApplication = v!),
              ),
              CheckboxListTile(
                title: const Text('Booth Notifications'),
                value: notifBooth,
                onChanged: (v) => setState(() => notifBooth = v!),
              ),
              SwitchListTile(
                title: const Text('SMS Alerts'),
                value: smsNotif,
                onChanged: (v) => setState(() => smsNotif = v),
              ),
            ]),
            _buildSectionTitle('Payment Methods'),
            _buildCard(children: [
              ListTile(
                title: const Text('Saved Cards'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                  onPressed: _addCard,
                ),
              ),
              if (savedCards.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No cards saved yet.',
                      style: TextStyle(color: Colors.grey)),
                ),
            ]),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _saveInfo,
                  icon: const Icon(Icons.save),
                  label: const Text('SAVE CHANGES',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildModernTextField(
      String label, IconData icon, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
