import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'category.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wardsController = TextEditingController();

  String? selectedZoneId;

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showForm(String zoneId, {DocumentSnapshot? doc}) {
    if (doc != null) {
      _nameController.text = doc['name'];
      _wardsController.text = (doc['wards'] as List).join(', ');
    } else {
      _nameController.clear();
      _wardsController.clear();
    }

    final supervisorRef = FirebaseFirestore.instance
        .collection('Zones')
        .doc(zoneId)
        .collection('Supervisors');

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
              decoration: const InputDecoration(labelText: 'Supervisor Name'),
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

                supervisorRef.doc(name).set({'name': name, 'wards': wards}).then(
                      (_) => Navigator.of(context).pop(),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSupervisor(String zoneId, String id) {
    final supervisorRef = FirebaseFirestore.instance
        .collection('Zones')
        .doc(zoneId)
        .collection('Supervisors');

    supervisorRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final zonesRef = FirebaseFirestore.instance.collection('Zones');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Admin Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Manage Categories'),
              onTap: () => _navigateTo(context, const Category()),
            ),
          ],
        ),
      ),
      body: selectedZoneId == null
          ? StreamBuilder<QuerySnapshot>(
              stream: zonesRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading zones.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final zoneDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: zoneDocs.length,
                  itemBuilder: (context, index) {
                    final zoneId = zoneDocs[index].id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedZoneId = zoneId;
                          });
                        },
                        child:
                            Text(zoneId, style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  },
                );
              },
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Supervisors of $selectedZoneId',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            selectedZoneId = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Zones')
                        .doc(selectedZoneId)
                        .collection('Supervisors')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Something went wrong.'));
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
                                  onPressed: () => _showForm(selectedZoneId!, doc: doc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteSupervisor(selectedZoneId!, name),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: selectedZoneId != null
          ? FloatingActionButton(
              onPressed: () => _showForm(selectedZoneId!),
              child: const Icon(Icons.add),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
}
