import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_exhibition.dart';
import 'organizer_exhibitions.dart'; // ✅ CORRECT PAGE

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  @override
  void initState() {
    super.initState();
    _guardOrganizer();
  }

  /// 🔐 ORGANIZER-ONLY ACCESS
  Future<void> _guardOrganizer() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('current_user_role');

    if (role != 'organizer') {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Organizer Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // ➕ ADD EXHIBITION
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_business, color: Colors.green),
              title: const Text('Add Exhibition'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddExhibitionPage(),
                  ),
                );
              },
            ),
          ),

          // 🏗️ MANAGE EXHIBITIONS + FLOOR PLAN
          Card(
            child: ListTile(
              leading: const Icon(Icons.event, color: Colors.deepPurple),
              title: const Text('Manage Exhibitions & Floor Plan'),
              subtitle: const Text('Edit details, booths & pricing'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrganizerExhibitionsPage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),

          // 🚪 LOGOUT
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
