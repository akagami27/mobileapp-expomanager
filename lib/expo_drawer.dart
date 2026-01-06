import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_settings.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  // =========================
  // 🔐 LOGOUT (SAFE & CLEAN)
  // =========================
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // ❌ DO NOT clear everything
    // ✅ Remove ONLY session-related keys
    await prefs.remove('current_user_email');
    await prefs.remove('current_user_uid');
    await prefs.remove('current_user_role');
    await prefs.remove('profile_fullName');
    await prefs.remove('profile_company');

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    }
  }

  // =========================
  // 🔐 READ ROLE ONCE
  // =========================
  Future<String> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_role') ?? 'guest';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<String>(
        future: _getRole(),
        builder: (context, snapshot) {
          final role = snapshot.data ?? 'guest';

          return Column(
            children: [
              // =========================
              // HEADER (UNCHANGED)
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 50, color: Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // =========================
              // MENU
              // =========================
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.home_rounded,
                      text: 'Home',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.search_rounded,
                      text: 'Browse Exhibitions',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/browse');
                      },
                    ),

                    // =========================
                    // EXHIBITOR ONLY
                    // =========================
                    if (role == 'exhibitor')
                      _buildMenuItem(
                        context,
                        icon: Icons.settings_rounded,
                        text: 'Account Settings',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountSettingsPage(),
                            ),
                          );
                        },
                      ),

                    const Divider(indent: 20, endIndent: 20),

                    // =========================
                    // LOGIN / LOGOUT
                    // =========================
                    if (role == 'guest')
                      _buildMenuItem(
                        context,
                        icon: Icons.login,
                        text: 'Login',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/login');
                        },
                      )
                    else
                      _buildMenuItem(
                        context,
                        icon: Icons.logout_rounded,
                        text: 'Logout',
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () => _logout(context),
                      ),
                  ],
                ),
              ),

              // =========================
              // FOOTER
              // =========================
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Expo Manager v1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // MENU ITEM (UNCHANGED)
  // =========================
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.deepPurple),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}
