import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'pages/home.dart';
import 'pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LD Admin App',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _showScreen = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 3)); // Wait for splash
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('users') // 👈 must be lowercase 'users' if your collection is like that
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          // ✅ User exists
          setState(() {
            _showScreen = true;
            _isLoggedIn = true;
          });
        } else {
          // ❌ Email not found in 'users'
          await FirebaseAuth.instance.signOut();
          setState(() {
            _showScreen = true;
            _isLoggedIn = false;
          });
          _showAccessDeniedDialog();
        }
      } catch (e) {
        print('❌ Error checking user: $e');
        await FirebaseAuth.instance.signOut();
        setState(() {
          _showScreen = true;
          _isLoggedIn = false;
        });
        _showAccessDeniedDialog();
      }
    } else {
      setState(() {
        _showScreen = true;
        _isLoggedIn = false;
      });
    }
  }

  void _showAccessDeniedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Access Denied"),
          content: const Text("This account is not allowed to access this app."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showScreen) {
      return _isLoggedIn ? const HomePage() : const LoginPage();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo.jpg', width: 120),
              const SizedBox(height: 20),
              const Text(
                '"Track the Work, Lead the Change"',
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
