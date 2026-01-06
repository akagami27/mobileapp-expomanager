import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_application_detail.dart';

class AdminApplicationsPage extends StatefulWidget {
  const AdminApplicationsPage({super.key});

  @override
  State<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends State<AdminApplicationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  /// 🔥 LOAD APPLICATIONS (FIRESTORE = SOURCE OF TRUTH)
  Future<void> _loadApplications() async {
    setState(() => _loading = true);

    try {
      final snap = await _firestore
          .collection('applications')
          .orderBy('firebase_createdAt', descending: true)
          .get();

      final apps = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['__docId'] = doc.id; // 🔑 REQUIRED
        return data;
      }).toList();

      if (!mounted) return;

      setState(() {
        _applications = apps;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load applications: $e');

      if (!mounted) return;

      setState(() {
        _applications = [];
        _loading = false;
      });
    }
  }

  /// ❌ DELETE APPLICATION (DIRECT BY DOC ID)
  Future<void> _deleteApplication(Map<String, dynamic> app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Delete application for ${app['companyName'] ?? 'this company'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final docId = app['__docId'];
      if (docId == null) return;

      await _firestore.collection('applications').doc(docId).delete();

      await _loadApplications();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application deleted')),
      );
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Applications'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('No applications found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final app = _applications[index];
                    final status = app['status'] ?? 'Pending';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(status).withOpacity(0.15),
                          child: Icon(
                            Icons.store,
                            color: _statusColor(status),
                          ),
                        ),
                        title: Text(
                          app['companyName'] ?? 'Unknown Company',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Exhibition: ${app['exhibitionName'] ?? '-'}'),
                            Text('Booth: ${app['boothCode'] ?? '-'}'),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// ✏️ EDIT STATUS
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminApplicationDetailPage(
                                      documentId: app['__docId'], // 🔥 FIX
                                      application: app,
                                    ),
                                  ),
                                ).then((_) => _loadApplications());
                              },
                            ),

                            /// 🗑 DELETE
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteApplication(app),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
