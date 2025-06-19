import 'package:flutter/material.dart';

class Supervisor extends StatelessWidget {
  const Supervisor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Supervisor Management Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
