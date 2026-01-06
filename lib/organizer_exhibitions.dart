import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_floor_plan.dart';

class OrganizerExhibitionsPage extends StatefulWidget {
  const OrganizerExhibitionsPage({super.key});

  @override
  State<OrganizerExhibitionsPage> createState() =>
      _OrganizerExhibitionsPageState();
}

class _OrganizerExhibitionsPageState extends State<OrganizerExhibitionsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _exhibitions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExhibitions();
  }

  // =========================
  // 🔥 LOAD LOCAL + FIREBASE
  // =========================
  Future<void> _loadExhibitions() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('exhibitions');

    // 1️⃣ LOCAL EXHIBITIONS
    List<Map<String, dynamic>> local = [];

    if (raw != null) {
      final List<dynamic> arr = json.decode(raw);
      local = arr.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['localOnly'] = true;

        // 🔑 ENSURE LOCAL HAS ID
        map['id'] ??= map['id'] ?? 'local_${map['name']}_${map['start_date']}';

        return map;
      }).toList();
    }

    // 2️⃣ FIREBASE EXHIBITIONS
    List<Map<String, dynamic>> firebase = [];

    try {
      final snap = await _firestore.collection('exhibitions').get();
      firebase = snap.docs.map((doc) {
        final map = Map<String, dynamic>.from(doc.data());
        map['id'] = doc.id;
        map['localOnly'] = false;
        return map;
      }).toList();
    } catch (_) {}

    // 3️⃣ MERGE (KEY = NAME)
    final Map<String, Map<String, dynamic>> merged = {};

    for (final e in local) {
      merged[e['name']] = e;
    }
    for (final e in firebase) {
      merged[e['name']] = e;
    }

    if (!mounted) return;

    setState(() {
      _exhibitions = merged.values.toList();
      _loading = false;
    });
  }

  // =========================
  // ✏️ EDIT EXHIBITION
  // =========================
  void _editExhibition(int index) {
    final e = _exhibitions[index];

    final nameCtrl = TextEditingController(text: e['name']);
    final descCtrl = TextEditingController(text: e['desc'] ?? '');
    final venueCtrl = TextEditingController(text: e['venue'] ?? '');
    final startCtrl = TextEditingController(text: e['start_date'] ?? '');
    final endCtrl = TextEditingController(text: e['end_date'] ?? '');
    bool published = e['is_published'] ?? false;

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
                  title: const Text('Published'),
                  value: published,
                  onChanged: (v) => setDialogState(() => published = v),
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
                  ...e,
                  'name': nameCtrl.text,
                  'desc': descCtrl.text,
                  'venue': venueCtrl.text,
                  'start_date': startCtrl.text,
                  'end_date': endCtrl.text,
                  'is_published': published,
                };

                setState(() => _exhibitions[index] = updated);

                // 🔥 SAVE TO FIREBASE IF EXISTS THERE
                if (e['localOnly'] != true) {
                  await _firestore
                      .collection('exhibitions')
                      .doc(e['id'])
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exhibitions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exhibitions.isEmpty
              ? const Center(
                  child: Text(
                    'No exhibitions found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _exhibitions.length,
                  itemBuilder: (context, index) {
                    final e = _exhibitions[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(e['name']),
                        subtitle: Text(
                          '${e['venue']}\n${e['start_date']} → ${e['end_date']}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🗺️ FLOOR PLAN
                            IconButton(
                              icon: const Icon(Icons.map,
                                  color: Colors.deepPurple),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminFloorPlanPage(
                                      exhibitionId: e['id'],
                                      exhibitionName: e['name'],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // ✏️ EDIT
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editExhibition(index),
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
