import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'expo_drawer.dart';
import 'exhibitions.dart';
import 'all_exhibitions.dart';
import 'exhibitor_profile.dart';
import 'exhibitor_login.dart';

class ExhibitionHomePage extends StatefulWidget {
  const ExhibitionHomePage({super.key});

  @override
  State<ExhibitionHomePage> createState() => _ExhibitionHomePageState();
}

class _ExhibitionHomePageState extends State<ExhibitionHomePage> {
  List<Map<String, dynamic>> _events = [];
  String _query = '';
  bool _loading = true;

  bool _isExhibitor = false;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _checkLogin();
    await _loadDemoEvents();
  }

  /// 🔐 Check exhibitor login
  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('current_user_email');

    setState(() {
      _isExhibitor = email != null && email.isNotEmpty;
    });
  }

  /// 🎪 Demo events
  Future<void> _loadDemoEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final demoEvents = [
      {
        'id': 'expo1',
        'name': 'Future Tech Summit 2025',
        'venue': 'KL Convention Centre',
        'desc': 'Discover AI, Robotics, and the future of computing.',
        'start_date': '2026-12-01',
        'end_date': '2026-12-03',
        'image':
            'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1200',
      },
      {
        'id': 'expo2',
        'name': 'Modern Home & Living',
        'venue': 'Mid Valley Exhibition Centre',
        'desc': 'Interior design showcase featuring minimalist furniture.',
        'start_date': '2026-11-15',
        'end_date': '2026-11-17',
        'image':
            'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=1200',
      },
      {
        'id': 'expo3',
        'name': 'Startup Innovation Expo',
        'venue': 'MITEC Kuala Lumpur',
        'desc': 'Showcasing startups, investors and innovation.',
        'start_date': '2026-10-10',
        'end_date': '2026-10-12',
        'image':
            'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?q=80&w=1200',
      },
      {
        'id': 'expo4',
        'name': 'Green Energy Fair',
        'venue': 'Putrajaya Convention Centre',
        'desc': 'Renewable energy & sustainability exhibition.',
        'start_date': '2026-09-20',
        'end_date': '2026-09-22',
        'image':
            'https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=1200',
      },
    ];

    await prefs.setString('exhibitions', json.encode(demoEvents));

    if (!mounted) return;
    setState(() {
      _events = demoEvents;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.toLowerCase();
    return _events
        .where((e) => (e['name'] ?? '').toString().toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'Expo Manager',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.event_note_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExhibitionsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                if (_isExhibitor) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExhibitorProfilePage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExhibitorLoginPage()),
                  );
                }
              },
            ),
          ],
        ),
        drawer: const MyDrawer(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search for events...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.deepPurple),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Featured Events',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AllExhibitionsPage()),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        return _buildExactCard(_filtered[index]);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 🎨 CARD (EXACT STYLE)
  Widget _buildExactCard(Map<String, dynamic> e) {
    final image = e['image'] ?? 'https://via.placeholder.com/400x200';
    final name = e['name'] ?? 'Untitled Event';
    final venue = e['venue'] ?? 'Unknown venue';
    final desc = e['desc'] ?? '';
    final startDate = e['start_date'] ?? '-';
    final endDate = e['end_date'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              image,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(venue,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        Text(startDate,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (!_isExhibitor) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ExhibitorLoginPage()),
                          );
                          return;
                        }

                        Navigator.pushNamed(
                          context,
                          '/exhibitiondetails',
                          arguments: {
                            'exhibitionId': e['id'] ?? '',
                            'exhibitionName': name,
                            'venue': venue,
                            'description': desc,
                            'start_date': startDate,
                            'end_date': '',
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Book Now',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
