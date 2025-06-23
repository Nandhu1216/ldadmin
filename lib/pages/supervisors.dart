import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Supervisor extends StatefulWidget {
  final String? zoneId; // If null, show zones. Else, show supervisor list

  const Supervisor({super.key, this.zoneId});

  @override
  State<Supervisor> createState() => _SupervisorState();
}

class _SupervisorState extends State<Supervisor> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wardsController = TextEditingController();

  /// 🔁 If zoneId is null, show Zone List View
  /// Else, show Supervisor List under that Zone
  @override
  Widget build(BuildContext context) {
    if (widget.zoneId == null) {
      // 🚩 Zone Selection Screen
      final zonesRef = FirebaseFirestore.instance.collection('Zones');

      return Scaffold(
        appBar: AppBar(
          title: const Text('Select a Zone'),
          backgroundColor: Colors.green,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: zonesRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(child: Text('Error loading zones.'));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final zoneDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: zoneDocs.length,
              itemBuilder: (context, index) {
                final zoneId = zoneDocs[index].id;

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Supervisor(zoneId: zoneId),
                        ),
                      );
                    },
                    child: Text(zoneId, style: const TextStyle(fontSize: 18)),
                  ),
                );
              },
            );
          },
        ),
      );
    } else {
      // ✅ Supervisor CRUD Screen for selected zone
      final supervisorRef = FirebaseFirestore.instance
          .collection('Zones')
          .doc(widget.zoneId)
          .collection('Supervisors');

      void _showForm({DocumentSnapshot? doc}) {
        if (doc != null) {
          _nameController.text = doc['name'];
          _wardsController.text = (doc['wards'] as List).join(', ');
        } else {
          _nameController.clear();
          _wardsController.clear();
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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Supervisor Name',
                  ),
                ),
                TextField(
                  controller: _wardsController,
                  decoration: const InputDecoration(
                    labelText: 'Wards (comma-separated)',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: Text(doc == null ? 'Add' : 'Update'),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final wards = _wardsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    supervisorRef
                        .doc(name)
                        .set({'name': name, 'wards': wards})
                        .then((_) {
                          Navigator.of(context).pop();
                        });
                  },
                ),
              ],
            ),
          ),
        );
      }

      void _deleteSupervisor(String id) {
        supervisorRef.doc(id).delete();
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('Supervisors of ${widget.zoneId}'),
          backgroundColor: Colors.green,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: supervisorRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong.'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final name = doc['name'];
                final wards = (doc['wards'] as List).join(', ');

                return ListTile(
                  title: Text(name),
                  subtitle: Text('Wards: $wards'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteSupervisor(name),
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
}
