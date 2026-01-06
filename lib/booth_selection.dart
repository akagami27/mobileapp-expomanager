import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'payment_page.dart';

class BoothSelectionPage extends StatefulWidget {
  final String exhibitionId;
  final String exhibitionName;
  final String venue;

  const BoothSelectionPage({
    super.key,
    required this.exhibitionId,
    required this.exhibitionName,
    required this.venue,
  });

  @override
  State<BoothSelectionPage> createState() => _BoothSelectionPageState();
}

class _BoothSelectionPageState extends State<BoothSelectionPage> {
  String? _selectedBooth;
  int _selectedPrice = 0;

  Color _boothColor(bool booked, bool selected) {
    if (selected) return Colors.blue;
    if (booked) return Colors.red;
    return Colors.green;
  }

  /// 🔥 LOAD BOOKED BOOTHS FROM APPROVED APPLICATIONS
  Future<Set<String>> _loadBookedBooths() async {
    final snap = await FirebaseFirestore.instance
        .collection('applications')
        .where('exhibitionId', isEqualTo: widget.exhibitionId)
        .where('status', isEqualTo: 'Approved')
        .get();

    return snap.docs.map((d) => d['boothCode'].toString()).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final boothsRef = FirebaseFirestore.instance
        .collection('exhibitions')
        .doc(widget.exhibitionId)
        .collection('booths')
        .orderBy('boothCode');

    return Scaffold(
      appBar: AppBar(
        title: Text('Floor Plan - ${widget.exhibitionName}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Set<String>>(
        future: _loadBookedBooths(),
        builder: (context, bookedSnap) {
          if (!bookedSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookedBooths = bookedSnap.data!;

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: boothsRef.snapshots(),
                  builder: (context, boothSnap) {
                    if (!boothSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final booths = boothSnap.data!.docs;

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: booths.length,
                      itemBuilder: (_, i) {
                        final data = booths[i].data() as Map<String, dynamic>;
                        final code = data['boothCode'];
                        final price = data['price'];
                        final booked = bookedBooths.contains(code);

                        return GestureDetector(
                          onTap: booked
                              ? null
                              : () {
                                  setState(() {
                                    _selectedBooth = code;
                                    _selectedPrice = price;
                                  });
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  _boothColor(booked, _selectedBooth == code),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Booth $code',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'RM $price',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  if (booked)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'BOOKED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              /// 🔥 BOOK NOW BUTTON
              if (_selectedBooth != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'BOOK NOW',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentPage(
                              bookingData: {
                                'exhibitionId': widget.exhibitionId,
                                'exhibitionName': widget.exhibitionName,
                                'venue': widget.venue,
                                'boothCode': _selectedBooth,
                                'boothPrice': _selectedPrice,
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
