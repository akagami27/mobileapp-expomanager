import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_applications.dart';

class AdminExhibitionDashboard extends StatefulWidget {
  const AdminExhibitionDashboard({super.key});

  @override
  State<AdminExhibitionDashboard> createState() =>
      _AdminExhibitionDashboardState();
}

class _AdminExhibitionDashboardState extends State<AdminExhibitionDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _guardAdmin();
  }

  /// 🔐 ADMIN-ONLY ACCESS
  Future<void> _guardAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('current_user_role');

    if (role != 'admin') {
      if (mounted) Navigator.pop(context);
    }
  }

  Stream<QuerySnapshot> _applicationsStream() {
    return _firestore.collection('applications').snapshots();
  }

  Future<void> _logoutAdmin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _applicationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          final docs = snapshot.data!.docs;

          int approved = 0;
          int pending = 0;
          int rejected = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status =
                (data['status'] ?? 'Pending').toString().toLowerCase();

            if (status == 'approved') {
              approved++;
            } else if (status == 'rejected') {
              rejected++;
            } else {
              pending++;
            }
          }

          final total = docs.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsCard(approved, pending, rejected, total),
              const SizedBox(height: 20),
              const Text(
                "Admin Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildMenu(context),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () => _logoutAdmin(context),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // UI COMPONENTS
  // =========================

  Widget _buildStatsCard(int approved, int pending, int rejected, int total) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildStatBar('Approved', approved, total, Colors.green),
            _buildStatBar('Pending', pending, total, Colors.orange),
            _buildStatBar('Rejected', rejected, total, Colors.red),
            const Divider(height: 30),
            Text(
              'Total Applications: $total',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.assignment, color: Colors.blue),
          title: const Text('Manage Applications'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminApplicationsPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        'No applications found',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildStatBar(String label, int count, int total, Color color) {
    final percent = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '$count (${(percent * 100).toStringAsFixed(0)}%)',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: color.withOpacity(0.2),
            color: color,
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}
