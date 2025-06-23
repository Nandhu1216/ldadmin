import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  final TextEditingController _typeController = TextEditingController();
  final DocumentReference categoryDoc = FirebaseFirestore.instance
      .collection('Categories')
      .doc('categories');

  void _showForm({String? currentType}) {
    if (currentType != null) {
      _typeController.text = currentType;
    } else {
      _typeController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Category Type'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Text(currentType == null ? 'Add' : 'Update'),
              onPressed: () async {
                final newType = _typeController.text.trim();
                if (newType.isEmpty) return;

                final doc = await categoryDoc.get();
                final List currentTypes = doc['type'] ?? [];

                if (currentType == null) {
                  // Add new type
                  if (!currentTypes.contains(newType)) {
                    await categoryDoc.update({
                      'type': FieldValue.arrayUnion([newType]),
                    });
                  }
                } else {
                  // Update existing type
                  if (currentType != newType) {
                    await categoryDoc.update({
                      'type': FieldValue.arrayRemove([currentType]),
                    });
                    await categoryDoc.update({
                      'type': FieldValue.arrayUnion([newType]),
                    });
                  }
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteType(String type) async {
    await categoryDoc.update({
      'type': FieldValue.arrayRemove([type]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: categoryDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading categories.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No categories found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List types = data['type'] ?? [];

          return ListView.builder(
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];

              return ListTile(
                title: Text(type),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showForm(currentType: type),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteType(type),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
