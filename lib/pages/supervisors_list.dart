import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting

class SupervisorListPage extends StatefulWidget {
  final String zone;
  const SupervisorListPage({super.key, required this.zone});

  @override
  State<SupervisorListPage> createState() => _SupervisorListPageState();
}

class _SupervisorListPageState extends State<SupervisorListPage> {
  static const String backendBaseUrl = 'https://adminbackend-u7ym.onrender.com';

  String? selectedSupervisor;

  // Categories state
  List<String> categories = [];
  String? selectedCategory;
  bool isLoadingCategories = false;

  // Date state
  DateTime? selectedDate;

  // Photo count state
  int? photoCount;
  bool isLoadingCount = false;

  @override
  void didUpdateWidget(covariant SupervisorListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedSupervisor != null) {
      loadCategories();
      fetchPhotoCount(
        selectedSupervisor!,
        category: selectedCategory,
        date: selectedDate,
      );
    }
  }

  Future<void> loadCategories() async {
    setState(() {
      isLoadingCategories = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Categories')
          .doc('categories')
          .get();

      if (doc.exists) {
        final types = doc.data()?['type'];
        if (types != null && types is List) {
          categories = List<String>.from(types);
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
      categories = [];
    }

    setState(() {
      isLoadingCategories = false;
    });
  }

  Future<void> fetchPhotoCount(
    String supervisor, {
    String? category,
    DateTime? date,
  }) async {
    setState(() {
      isLoadingCount = true;
      photoCount = null;
    });

    try {
      var params = {'zone': widget.zone, 'supervisor': supervisor};
      if (category != null) params['category'] = category;
      if (date != null) {
        params['date'] = DateFormat('yyyy-MM-dd').format(date);
      }

      final uri = Uri.http(
        Uri.parse(backendBaseUrl).authority,
        '/count',
        params,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        photoCount = data['count'] ?? 0;
      } else {
        photoCount = 0;
      }
    } catch (e) {
      print('Error fetching photo count: $e');
      photoCount = 0;
    }

    setState(() {
      isLoadingCount = false;
    });
  }

  void onSupervisorSelected(String supervisor) {
    setState(() {
      selectedSupervisor = supervisor;
      selectedCategory = null;
      selectedDate = null;
      photoCount = null;
    });
    loadCategories();
    fetchPhotoCount(supervisor);
  }

  void onCategorySelected(String? category) {
    setState(() {
      selectedCategory = category;
      photoCount = null;
    });
    if (selectedSupervisor != null) {
      fetchPhotoCount(
        selectedSupervisor!,
        category: category,
        date: selectedDate,
      );
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        photoCount = null;
      });
      if (selectedSupervisor != null) {
        fetchPhotoCount(
          selectedSupervisor!,
          category: selectedCategory,
          date: picked,
        );
      }
    }
  }

  void backToList() {
    setState(() {
      selectedSupervisor = null;
      selectedCategory = null;
      selectedDate = null;
      photoCount = null;
      isLoadingCount = false;
      isLoadingCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedSupervisor == null) {
      // Show list of supervisors
      final supervisorsRef = FirebaseFirestore.instance
          .collection('Zones')
          .doc(widget.zone)
          .collection('Supervisors');

      return Scaffold(
        appBar: AppBar(
          title: Text('Supervisors in ${widget.zone}'),
          backgroundColor: Colors.green,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: supervisorsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong.'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final supervisors = snapshot.data!.docs;

            final filteredSupervisors = supervisors.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data.containsKey('name') && data['name'] != null;
            }).toList();

            if (filteredSupervisors.isEmpty) {
              return const Center(child: Text('No supervisors found.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredSupervisors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = filteredSupervisors[index];
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'];

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => onSupervisorSelected(name),
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                );
              },
            );
          },
        ),
      );
    } else {
      // Show performance view for selected supervisor
      return Scaffold(
        appBar: AppBar(
          title: Text('$selectedSupervisor Performance'),
          backgroundColor: Colors.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: backToList,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedSupervisor!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              if (isLoadingCategories)
                const Center(child: CircularProgressIndicator())
              else if (categories.isEmpty)
                const Text('No categories found.')
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Category',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCategory,
                  items: categories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: onCategorySelected,
                ),

              const SizedBox(height: 24),

              // Photo count card with embedded date picker
              Card(
                elevation: 6,
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date picker row inside card
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'Select Date'
                                  : 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: pickDate,
                            child: const Text('Pick Date'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        selectedCategory == null
                            ? 'Total Photos Uploaded'
                            : 'Photos Uploaded in "$selectedCategory"',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      isLoadingCount
                          ? const CircularProgressIndicator()
                          : Text(
                              photoCount != null ? '$photoCount' : '0',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
