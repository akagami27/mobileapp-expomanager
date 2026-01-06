import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationStatusPage extends StatefulWidget {
  final Map<String, dynamic> application;

  const ApplicationStatusPage({
    super.key,
    required this.application,
  });

  @override
  State<ApplicationStatusPage> createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  late Map<String, dynamic> _application;
  bool _loading = true;
  bool _isCancelling = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _application = Map<String, dynamic>.from(widget.application);
    _guardGuest();
  }

  // =========================
  // 🔐 BLOCK GUEST ACCESS
  // =========================
  Future<void> _guardGuest() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login required to view application status'),
          ),
        );
      }
      return;
    }

    await _syncStatusFromFirebase();
  }

  // =========================
  // 🔥 SYNC STATUS FROM FIREBASE
  // =========================
  Future<void> _syncStatusFromFirebase() async {
    try {
      final snap = await _firestore
          .collection('applications')
          .where('applicationId', isEqualTo: _application['applicationId'])
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty && mounted) {
        setState(() {
          _application = snap.docs.first.data();
        });
      }
    } catch (e) {
      debugPrint('Status sync failed: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  // =========================
  // ❌ CANCEL BOOKING (FIREBASE ONLY)
  // =========================
  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: const Text(
              'Are you sure you want to cancel this booking?\n'
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isCancelling = true);

    try {
      final snap = await _firestore
          .collection('applications')
          .where('applicationId', isEqualTo: _application['applicationId'])
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({
          'status': 'Cancelled',
          'firebase_updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() {
          _application['status'] = 'Cancelled';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('Cancel failed: $e');
    }

    if (mounted) setState(() => _isCancelling = false);
  }

  Color _getStatusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final status = (_application['status'] ?? 'Pending').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 'Approved'
                              ? Icons.check_circle
                              : status == 'Rejected'
                                  ? Icons.cancel
                                  : status == 'Cancelled'
                                      ? Icons.block
                                      : Icons.hourglass_empty,
                          size: 80,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Status: ${status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                        const Divider(height: 30),
                        _infoTile('Exhibition', _application['exhibitionName']),
                        _infoTile('Venue', _application['venue']),
                        _infoTile('Booth Code', _application['boothCode']),
                        _infoTile(
                            'Payment', _application['paymentStatus'] ?? '-'),
                        const SizedBox(height: 25),
                        if (status == 'Pending')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCancelling ? null : _cancelBooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: _isCancelling
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Cancel Booking'),
                            ),
                          ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _infoTile(String title, String? value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value ?? '-'),
    );
  }
}
