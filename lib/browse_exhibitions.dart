import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'exhibition_details.dart';
import 'expo_drawer.dart';

class BrowseExhibitionsPage extends StatefulWidget {
  const BrowseExhibitionsPage({super.key});

  @override
  State<BrowseExhibitionsPage> createState() => _BrowseExhibitionsPageState();
}

class _BrowseExhibitionsPageState extends State<BrowseExhibitionsPage> {
  List<Map<String, dynamic>> _exhibitions = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadExhibitions();
  }

  Future<void> _loadExhibitions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    List<Map<String, dynamic>> local = [];
    final raw = prefs.getString('exhibitions');

    if (raw != null) {
      final List<dynamic> arr = json.decode(raw);
      local = arr.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    List<Map<String, dynamic>> firebase = [];

    try {
      final snap = await _firestore
          .collection('exhibitions')
          .where('is_published', isEqualTo: true)
          .get();

      firebase = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      // Firebase fail = local only
    }

    // 🔹 Merge local + Firebase (avoid duplicates by name)
    final Map<String, Map<String, dynamic>> merged = {};

    for (final e in local) {
      merged[e['name'] ?? UniqueKey().toString()] = e;
    }

    for (final e in firebase) {
      merged[e['name'] ?? UniqueKey().toString()] = e;
    }

    final result = merged.values.toList();

    if (!mounted) return;

    setState(() {
      _exhibitions = result;
      _filtered = result;
      _loading = false;
    });
  }

  void _filterExhibitions(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filtered = _exhibitions.where((e) {
        final name = (e['name'] ?? '').toLowerCase();
        final venue = (e['venue'] ?? '').toLowerCase();
        return name.contains(lowerQuery) || venue.contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Browse Exhibitions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: _filterExhibitions,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.deepPurple),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No exhibitions found'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final e = _filtered[index];
                            final image = e['image'] ??
                                'https://via.placeholder.com/400x200';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExhibitionDetailsPage(
                                      exhibitionId: e['id'] ?? 'expo-$index',
                                      exhibitionName:
                                          e['name'] ?? 'Untitled Exhibition',
                                      description:
                                          e['desc'] ?? 'No description',
                                      startDate: e['start_date'] ?? '',
                                      endDate: e['end_date'] ?? '',
                                      venue: e['venue'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                      child: Image.network(
                                        image,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                          height: 160,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image,
                                              size: 50, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e['name'] ?? 'Untitled Exhibition',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  e['venue'] ?? '',
                                                  style: TextStyle(
                                                      color: Colors.grey[600]),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.deepPurple),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${e['start_date'] ?? ''} - ${e['end_date'] ?? ''}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.deepPurple,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Icon(
                                                  Icons.arrow_circle_right,
                                                  color: Colors.deepPurple,
                                                  size: 28),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
