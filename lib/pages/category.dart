import 'package:flutter/material.dart';

class Category extends StatelessWidget {
  const Category({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Category Management Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
