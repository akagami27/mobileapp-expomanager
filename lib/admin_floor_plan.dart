import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFloorPlanPage extends StatelessWidget {
  final String exhibitionId;
  final String exhibitionName;

  const AdminFloorPlanPage({
    super.key,
    required this.exhibitionId,
    required this.exhibitionName,
  });

  @override
  Widget build(BuildContext context) {
    final boothsRef = FirebaseFirestore.instance
        .collection('exhibitions')
        .doc(exhibitionId)
        .collection('booths');

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Floor Plan - $exhibitionName'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _addBooth(context, boothsRef),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: boothsRef.orderBy('boothCode').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No booths added yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text('Booth ${data['boothCode']}'),
                subtitle: Text('RM ${data['price']}'),
                trailing: Switch(
                  value: data['isBooked'] ?? false,
                  onChanged: (val) {
                    doc.reference.update({'isBooked': val});
                  },
                ),
                onTap: () => _editBooth(context, doc),
              );
            },
          );
        },
      ),
    );
  }

  void _addBooth(BuildContext context, CollectionReference boothsRef) {
    final codeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Booth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Booth Code (A1)'),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price (RM)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final boothCode = codeCtrl.text.trim();
              if (boothCode.isEmpty) return;

              await boothsRef.doc(boothCode).set({
                'boothCode': boothCode,
                'price': int.tryParse(priceCtrl.text) ?? 0,
                'isBooked': false,
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editBooth(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final priceCtrl = TextEditingController(text: data['price'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Booth ${data['boothCode']}'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({
                'price': int.tryParse(priceCtrl.text) ?? data['price'],
              });
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
