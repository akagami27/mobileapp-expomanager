import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'expo_drawer.dart';
import 'exhibition_details.dart';
import 'admin_floor_plan.dart';

class AllExhibitionsPage extends StatefulWidget {
  const AllExhibitionsPage({super.key});

  @override
  State<AllExhibitionsPage> createState() => _AllExhibitionsPageState();
}

class _AllExhibitionsPageState extends State<AllExhibitionsPage> {
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

    // =========================
    // 🔹 LOCAL EXHIBITIONS
    // =========================
    List<Map<String, dynamic>> local = [];
    final raw = prefs.getString('exhibitions');

    if (raw != null) {
      final List<dynamic> arr = json.decode(raw);

      for (var item in arr) {
        final Map<String, dynamic> expo = Map<String, dynamic>.from(item);

        final String reviewKey = 'reviews_${expo['id']}';
        final String? rawReviews = prefs.getString(reviewKey);

        double rating = 0.0;
        int count = 0;

        if (rawReviews != null) {
          final List<dynamic> rList = json.decode(rawReviews);
          if (rList.isNotEmpty) {
            final total = rList.fold(0, (sum, r) => sum + (r['rating'] as int));
            rating = total / rList.length;
            count = rList.length;
          }
        }

        expo['avg_rating'] = rating;
        expo['rating_count'] = count;
        local.add(expo);
      }
    }

    // =========================
    // 🔥 FIREBASE EXHIBITIONS
    // =========================
    List<Map<String, dynamic>> firebase = [];

    try {
      final snap = await _firestore
          .collection('exhibitions')
          .where('is_published', isEqualTo: true)
          .get();

      firebase = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['avg_rating'] = 0.0;
        data['rating_count'] = 0;
        return data;
      }).toList();
    } catch (_) {}

    // =========================
    // 🔀 MERGE LOCAL + FIREBASE
    // =========================
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
          'Manage Exhibitions',
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
                  padding: const EdgeInsets.all(16),
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
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final e = _filtered[index];
                      final image =
                          e['image'] ?? 'https://via.placeholder.com/400x200';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExhibitionDetailsPage(
                                      exhibitionId: e['id'],
                                      exhibitionName: e['name'],
                                      description: e['desc'] ?? '',
                                      startDate: e['start_date'] ?? '',
                                      endDate: e['end_date'] ?? '',
                                      venue: e['venue'] ?? '',
                                    ),
                                  ),
                                );
                                _loadExhibitions();
                              },
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                child: Image.network(
                                  image,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // 🔥 ADMIN ACTIONS
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(e['venue'] ?? ''),
                                  const SizedBox(height: 10),

                                  // ✅ EDIT FLOOR PLAN
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.map),
                                    label: const Text('Edit Floor Plan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                    ),
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
                                ],
                              ),
                            ),
                          ],
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
