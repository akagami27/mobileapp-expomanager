import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'application_status.dart';
import 'exhibitor_login.dart';

class ExhibitionsPage extends StatefulWidget {
  const ExhibitionsPage({super.key});

  @override
  State<ExhibitionsPage> createState() => _ExhibitionsPageState();
}

class _ExhibitionsPageState extends State<ExhibitionsPage> {
  List<Map<String, dynamic>> _myApplications = [];
  bool _loading = true;
  bool _authorized = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  /// 🔐 BLOCK GUEST ACCESS
  Future<void> _checkAuthAndLoad() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExhibitorLoginPage()),
        );
      }
      return;
    }

    setState(() => _authorized = true);
    await _loadMyApplications(user.uid);
  }

  /// 🔥 LOAD APPLICATIONS FROM FIREBASE ONLY
  Future<void> _loadMyApplications(String uid) async {
    try {
      final snap = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: uid)
          .orderBy('firebase_createdAt', descending: true)
          .get();

      final data = snap.docs.map((doc) {
        final map = doc.data();
        map['firebaseId'] = doc.id;
        return map;
      }).toList();

      if (!mounted) return;

      setState(() {
        _myApplications = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Firebase load failed: $e');

      if (!mounted) return;

      setState(() {
        _myApplications = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myApplications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No booth applications yet.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _myApplications.length,
                  itemBuilder: (context, index) {
                    final app = _myApplications[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.store,
                          color: Colors.deepPurple,
                        ),
                        title: Text(
                          app['exhibitionName'] ?? 'Unknown Exhibition',
                        ),
                        subtitle: Text(
                          'Booth: ${app['boothCode'] ?? '-'}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ApplicationStatusPage(application: app),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
