import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart'; // your login screen
import 'category.dart'; // your category management screen
import 'supervisors.dart'; // supervisor management screen
import 'supervisors_list.dart'; // page to show supervisors by zone

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
    Navigator.pop(context); // close the drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _navigateToZone(BuildContext context, String zone) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupervisorListPage(zone: zone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> zones = ['Zone-1', 'Zone-2', 'Zone-3', 'Zone-4'];

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
              leading: const Icon(Icons.supervisor_account),
              title: const Text('Manage Supervisors'),
              onTap: () => _navigateTo(context, const Supervisor()),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Manage Categories'),
              onTap: () => _navigateTo(context, const Category()),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: zones.map((zone) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _navigateToZone(context, zone),
                child: Text(
                  zone,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
