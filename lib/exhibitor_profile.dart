import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'application_status.dart';

class ExhibitorProfilePage extends StatefulWidget {
  const ExhibitorProfilePage({super.key});

  @override
  State<ExhibitorProfilePage> createState() => _ExhibitorProfilePageState();
}

class _ExhibitorProfilePageState extends State<ExhibitorProfilePage> {
  String _name = 'Exhibitor';
  String _email = 'Not logged in';
  String _company = 'Freelance / Individual';

  List<Map<String, dynamic>> _myApplications = [];
  bool _isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // =========================
  // LOAD PROFILE + APPLICATIONS (OPTIMIZED)
  // =========================
  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    // 🔒 HARD BLOCK GUEST
    if (user == null) {
      if (mounted) {
        setState(() {
          _myApplications = [];
          _isLoading = false;
        });
      }
      return;
    }

    _name = user.displayName ?? 'Exhibitor';
    _email = user.email ?? 'Not logged in';

    await _loadApplicationsFromFirebase(user.uid);

    if (mounted) setState(() => _isLoading = false);
  }

  // =========================
  // LOAD APPLICATIONS FROM FIREBASE (NO LOCAL CACHE)
  // =========================
  Future<void> _loadApplicationsFromFirebase(String uid) async {
    try {
      final snap = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: uid)
          .orderBy('firebase_createdAt', descending: true)
          .get();

      _myApplications = snap.docs.map((doc) {
        final data = doc.data();
        data['firebaseId'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      _myApplications = [];
    }
  }

  // =========================
  // SAFE DATE FORMAT
  // =========================
  String _formatDate(dynamic value) {
    if (value == null) return '—';

    try {
      if (value is Timestamp) {
        return DateFormat('dd MMM yyyy').format(value.toDate());
      }
      if (value is String) {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(value));
      }
    } catch (_) {}

    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildStats(),
                  _buildApplications(),
                ],
              ),
            ),
    );
  }

  // =========================
  // HEADER (UNCHANGED)
  // =========================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 30,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(_company,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 5),
                Text(_email,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // STATS (UNCHANGED)
  // =========================
  Widget _buildStats() {
    final approved =
        _myApplications.where((a) => a['status'] == 'Approved').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _statCard('Applications', _myApplications.length.toString()),
          ),
          const SizedBox(width: 15),
          Expanded(child: _statCard('Approved', approved.toString())),
        ],
      ),
    );
  }

  // =========================
  // APPLICATION LIST (OPTIMIZED)
  // =========================
  Widget _buildApplications() {
    if (_myApplications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Text('No applications yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myApplications.length,
      itemBuilder: (_, i) {
        final app = _myApplications[i];
        final status = app['status'] ?? 'Pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicationStatusPage(application: app),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['exhibitionName'] ?? 'Unknown Exhibition',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booth: ${app['boothCode'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(app['firebase_createdAt']),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            app['venue'] ?? '-',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(status),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}
