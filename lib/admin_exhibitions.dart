import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_floor_plan.dart';

class AdminExhibitionsPage extends StatefulWidget {
  const AdminExhibitionsPage({super.key});

  @override
  State<AdminExhibitionsPage> createState() => _AdminExhibitionsPageState();
}

class _AdminExhibitionsPageState extends State<AdminExhibitionsPage> {
  List<Map<String, dynamic>> _exhibitions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _guardOrganizer();
    _loadExhibitions();
  }

  /// 🔐 ORGANIZER-ONLY GUARD
  Future<void> _guardOrganizer() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('current_user_role');

    if (role != 'organizer') {
      if (mounted) Navigator.pop(context);
    }
  }

  // =========================
  // 🔄 LOAD EXHIBITIONS
  // =========================
  Future<void> _loadExhibitions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('exhibitions');

    List<Map<String, dynamic>> localExhibitions = [];

    if (raw != null) {
      final List<dynamic> arr = json.decode(raw);
      localExhibitions = arr.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['localOnly'] = true;
        return map;
      }).toList();
    }

    try {
      final snapshot = await _firestore.collection('exhibitions').get();
      final firestoreExhibitions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 🔥 REQUIRED
        data['localOnly'] = false;
        return data;
      }).toList();

      setState(() {
        _exhibitions = [...localExhibitions, ...firestoreExhibitions];
      });
    } catch (_) {
      setState(() {
        _exhibitions = localExhibitions;
      });
    }
  }

  Future<void> _saveLocalExhibitions() async {
    final prefs = await SharedPreferences.getInstance();
    final localOnly =
        _exhibitions.where((e) => e['localOnly'] == true).toList();
    await prefs.setString('exhibitions', json.encode(localOnly));
  }

  // =========================
  // ✏️ EDIT EXHIBITION
  // =========================
  void _editExhibition(int index) {
    final exhibition = _exhibitions[index];

    final nameCtrl = TextEditingController(text: exhibition['name']);
    final descCtrl = TextEditingController(text: exhibition['desc'] ?? '');
    final venueCtrl = TextEditingController(text: exhibition['venue'] ?? '');
    final startCtrl =
        TextEditingController(text: exhibition['start_date'] ?? '');
    final endCtrl = TextEditingController(text: exhibition['end_date'] ?? '');
    bool published = exhibition['is_published'] ?? false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Exhibition'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                TextField(
                    controller: venueCtrl,
                    decoration: const InputDecoration(labelText: 'Venue')),
                TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(labelText: 'Start Date')),
                TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(labelText: 'End Date')),
                SwitchListTile(
                  title: const Text('Publish Exhibition'),
                  value: published,
                  onChanged: (val) => setDialogState(() => published = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final updated = {
                  ...exhibition,
                  'name': nameCtrl.text,
                  'desc': descCtrl.text,
                  'venue': venueCtrl.text,
                  'start_date': startCtrl.text,
                  'end_date': endCtrl.text,
                  'is_published': published,
                };

                setState(() => _exhibitions[index] = updated);
                await _saveLocalExhibitions();

                if (exhibition['localOnly'] != true) {
                  await _firestore
                      .collection('exhibitions')
                      .doc(exhibition['id'])
                      .update(updated);
                }

                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // ❌ DELETE EXHIBITION
  // =========================
  void _deleteExhibition(int index) async {
    final exhibition = _exhibitions[index];

    setState(() => _exhibitions.removeAt(index));
    await _saveLocalExhibitions();

    if (exhibition['localOnly'] != true) {
      await _firestore.collection('exhibitions').doc(exhibition['id']).delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exhibition deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exhibitions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _exhibitions.length,
        itemBuilder: (context, index) {
          final exhibition = _exhibitions[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(exhibition['name']),
              subtitle: Text(
                '${exhibition['venue']}\n'
                '${exhibition['start_date']} → ${exhibition['end_date']}',
              ),
              isThreeLine: true,

              // 🔥 ORGANIZER ACTIONS
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🗺️ EDIT FLOOR PLAN
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.deepPurple),
                    tooltip: 'Edit Floor Plan',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminFloorPlanPage(
                            exhibitionId: exhibition['id'],
                            exhibitionName: exhibition['name'],
                          ),
                        ),
                      );
                    },
                  ),

                  // ✏️ EDIT EXHIBITION
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editExhibition(index),
                  ),

                  // ❌ DELETE
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteExhibition(index),
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
