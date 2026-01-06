import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExhibitionPage extends StatefulWidget {
  const AddExhibitionPage({super.key});

  @override
  State<AddExhibitionPage> createState() => _AddExhibitionPageState();
}

class _AddExhibitionPageState extends State<AddExhibitionPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _venueController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  bool _isPublished = false;
  bool _loading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fungsi pembantu untuk memilih tarikh
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveExhibition() async {
    if (_nameController.text.isEmpty || _venueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Exhibition Name and Venue'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final exhibitionData = {
      'exhibitionId': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text.trim(),
      'desc': _descController.text.trim(),
      'venue': _venueController.text.trim(),
      'start_date': _startDateController.text.trim(),
      'end_date': _endDateController.text.trim(),
      'is_published': _isPublished,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      // =========================
      // 🔹 LOCAL SAVE (SharedPreferences)
      // =========================
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_exhibitions');

      List<Map<String, dynamic>> exhibitions = [];

      if (raw != null) {
        final List<dynamic> arr = json.decode(raw);
        exhibitions = arr.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      exhibitions.add(exhibitionData);

      await prefs.setString(
        'local_exhibitions',
        json.encode(exhibitions),
      );

      // =========================
      // 🔥 FIREBASE MIRROR SAVE
      // =========================
      await _firestore.collection('exhibitions').add({
        ...exhibitionData,
        'syncedFromLocal': true,
        'firebase_createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exhibition added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Exhibition'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exhibition Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Venue/Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _startDateController,
              readOnly: true,
              onTap: () => _selectDate(context, _startDateController),
              decoration: const InputDecoration(
                labelText: 'Start Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endDateController,
              readOnly: true,
              onTap: () => _selectDate(context, _endDateController),
              decoration: const InputDecoration(
                labelText: 'End Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Publish Exhibition Immediately?'),
              subtitle: const Text('Exhibitors can only see published events.'),
              value: _isPublished,
              onChanged: (val) => setState(() => _isPublished = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_loading ? 'Saving...' : 'Save Exhibition'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: _loading ? null : _saveExhibition,
            ),
          ],
        ),
      ),
    );
  }
}
