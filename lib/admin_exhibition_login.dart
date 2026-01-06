import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_exhibition_dashboard.dart';
import 'organizer_dashboard.dart';

class AdminExhibitionLoginPage extends StatefulWidget {
  const AdminExhibitionLoginPage({super.key});

  @override
  State<AdminExhibitionLoginPage> createState() =>
      _AdminExhibitionLoginPageState();
}

class _AdminExhibitionLoginPageState extends State<AdminExhibitionLoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _login() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    final prefs = await SharedPreferences.getInstance();

    // =========================
    // 🔐 ADMIN LOGIN
    // =========================
    if (username == 'admin' && password == 'admin123') {
      await prefs.setString('current_user_role', 'admin');
      await prefs.remove('current_user_uid');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminExhibitionDashboard(),
        ),
      );
      return;
    }

    // =========================
    // 🧑‍💼 ORGANIZER LOGIN
    // =========================
    if (username == 'organizer' && password == 'organizer123') {
      await prefs.setString('current_user_role', 'organizer');
      await prefs.remove('current_user_uid');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OrganizerDashboard(),
        ),
      );
      return;
    }

    // ❌ INVALID
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid credentials'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Admin / Organizer Portal'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.black87),
                  const SizedBox(height: 20),
                  const Text(
                    "Admin / Organizer Login",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Access Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
