import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  List<Map<String, dynamic>> _events = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('events');

    if (raw != null) {
      final List<dynamic> arr = json.decode(raw);
      setState(() {
        _events = arr.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      _events = [
        {
          'id': 'e1',
          'name': 'Wedding Expo 2025',
          'date': '2025-12-15',
          'time': '10:00 AM',
          'venue': 'Grand Ballroom',
          'desc': 'Showcase of wedding vendors and services',
          'link': 'https://example.com/wedding-expo',
          'localOnly': true,
        },
        {
          'id': 'e2',
          'name': 'Corporate Seminar',
          'date': '2025-12-20',
          'time': '2:00 PM',
          'venue': 'Conference Hall A',
          'desc': 'Business seminar with guest speakers',
          'link': 'https://example.com/corporate-seminar',
          'localOnly': true,
        },
      ];
      await prefs.setString('events', json.encode(_events));
      setState(() {});
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('events', json.encode(_events));
  }

  void _addEvent() {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Event'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Event Name')),
              TextField(
                  controller: dateCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
              TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'Time')),
              TextField(
                  controller: venueCtrl,
                  decoration: const InputDecoration(labelText: 'Venue')),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description')),
              TextField(
                  controller: linkCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Registration Link')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newEvent = {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': nameCtrl.text,
                'date': dateCtrl.text,
                'time': timeCtrl.text,
                'venue': venueCtrl.text,
                'desc': descCtrl.text,
                'link': linkCtrl.text,
                'localOnly': true,
              };

              setState(() {
                _events.add(newEvent);
              });

              await _saveEvents();

              // 🔥 FIREBASE MIRROR SAVE
              try {
                await _firestore.collection('events').add({
                  ...newEvent,
                  'localOnly': false,
                  'firebase_createdAt': FieldValue.serverTimestamp(),
                });
              } catch (_) {}

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editEvent(int index) {
    final event = _events[index];

    final nameCtrl = TextEditingController(text: event['name']);
    final dateCtrl = TextEditingController(text: event['date']);
    final timeCtrl = TextEditingController(text: event['time']);
    final venueCtrl = TextEditingController(text: event['venue']);
    final descCtrl = TextEditingController(text: event['desc']);
    final linkCtrl = TextEditingController(text: event['link']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Event Name')),
              TextField(
                  controller: dateCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
              TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'Time')),
              TextField(
                  controller: venueCtrl,
                  decoration: const InputDecoration(labelText: 'Venue')),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description')),
              TextField(
                  controller: linkCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Registration Link')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedEvent = {
                ...event,
                'name': nameCtrl.text,
                'date': dateCtrl.text,
                'time': timeCtrl.text,
                'venue': venueCtrl.text,
                'desc': descCtrl.text,
                'link': linkCtrl.text,
              };

              setState(() {
                _events[index] = updatedEvent;
              });

              await _saveEvents();

              // 🔥 FIREBASE MIRROR UPDATE
              if (event['localOnly'] != true) {
                try {
                  await _firestore
                      .collection('events')
                      .doc(event['id'])
                      .update({
                    ...updatedEvent,
                    'firebase_updatedAt': FieldValue.serverTimestamp(),
                  });
                } catch (_) {}
              }

              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(int index) async {
    final event = _events[index];

    setState(() {
      _events.removeAt(index);
    });

    await _saveEvents();

    // 🔥 FIREBASE MIRROR DELETE
    if (event['localOnly'] != true) {
      try {
        await _firestore.collection('events').doc(event['id']).delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(event['name']),
              subtitle: Text(
                '${event['date']} • ${event['time']} • ${event['venue']}\n${event['desc']}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editEvent(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEvent(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
