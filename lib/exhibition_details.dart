import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'booth_selection.dart';
import 'exhibitor_login.dart';

class ExhibitionDetailsPage extends StatefulWidget {
  final String exhibitionId;
  final String exhibitionName;
  final String description;
  final String startDate;
  final String endDate;
  final String venue;

  const ExhibitionDetailsPage({
    super.key,
    required this.exhibitionId,
    required this.exhibitionName,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.venue,
  });

  @override
  State<ExhibitionDetailsPage> createState() => _ExhibitionDetailsPageState();
}

class _ExhibitionDetailsPageState extends State<ExhibitionDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _reviews = [];
  int _selectedStar = 5;
  final TextEditingController _commentCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _isExhibitor = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkRole();
    await _loadReviews();
  }

  /// 🔐 ROLE CHECK
  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('current_user_role');
    setState(() => _isExhibitor = role == 'exhibitor');
  }

  // =========================
  // 🔥 LOAD REVIEWS (FIRESTORE ONLY)
  // =========================
  Future<void> _loadReviews() async {
    try {
      final snap = await _firestore
          .collection('reviews')
          .where('exhibitionId', isEqualTo: widget.exhibitionId)
          .get();

      final data = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'user': d['user'] ?? 'User',
          'rating': d['rating'] ?? 0,
          'comment': d['comment'] ?? '',
          'date': d['date'] ?? '',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _reviews = data;
      });
    } catch (e) {
      debugPrint('❌ Failed to load reviews: $e');
    }
  }

  // =========================
  // ✍️ SUBMIT REVIEW
  // =========================
  Future<void> _submitReview() async {
    if (!_isExhibitor) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExhibitorLoginPage()),
      );
      return;
    }

    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('profile_fullName') ?? 'Exhibitor';

    final review = {
      'user': userName,
      'rating': _selectedStar,
      'comment': _commentCtrl.text.trim(),
      'date': DateTime.now().toString().substring(0, 10),
      'exhibitionId': widget.exhibitionId,
      'created_at': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('reviews').add(review);

    _commentCtrl.clear();
    _selectedStar = 5;

    await _loadReviews();

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    double avgRating = 0;
    if (_reviews.isNotEmpty) {
      avgRating = _reviews.fold(0, (s, r) => s + (r['rating'] as int)) /
          _reviews.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exhibitionName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exhibitionName,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _infoCard(avgRating),
            const SizedBox(height: 20),
            _selectBoothButton(),
            const SizedBox(height: 30),
            _reviewSection(),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  Widget _infoCard(double avgRating) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(Icons.location_on, widget.venue),
            const SizedBox(height: 10),
            _infoRow(Icons.calendar_today,
                '${widget.startDate} - ${widget.endDate}'),
            const SizedBox(height: 10),
            _infoRow(
              Icons.star,
              _reviews.isEmpty
                  ? 'No ratings yet'
                  : '${avgRating.toStringAsFixed(1)} / 5 (${_reviews.length} reviews)',
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.deepPurple),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _selectBoothButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.map),
        label: const Text('Select Booth & Apply'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BoothSelectionPage(
              exhibitionId: widget.exhibitionId,
              exhibitionName: widget.exhibitionName,
              venue: widget.venue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rate & Review',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return IconButton(
              icon: Icon(
                i < _selectedStar ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: _isExhibitor
                  ? () => setState(() => _selectedStar = i + 1)
                  : null,
            );
          }),
        ),
        TextField(
          controller: _commentCtrl,
          enabled: _isExhibitor,
          decoration: InputDecoration(
            hintText:
                _isExhibitor ? 'Share your experience...' : 'Login to review',
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const CircularProgressIndicator()
              : const Text('Submit Review'),
        ),
        const SizedBox(height: 20),
        const Text('Recent Reviews',
            style: TextStyle(fontWeight: FontWeight.bold)),
        if (_reviews.isEmpty)
          const Text('No reviews yet.')
        else
          ..._reviews.map(
            (r) => ListTile(
              title: Text(r['user']),
              subtitle: Text(r['comment']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  r['rating'],
                  (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
