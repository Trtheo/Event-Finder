import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  List<String> categories = [
    'All',
    'Tech',
    'Music',
    'Food',
    'Business',
    'Sports',
    'Art',
    'Health',
    'Party',
    'BirthDay',
    'Ceremony',
    'Wedding',
    'Festival',
  ];

  @override
  Widget build(BuildContext context) {
    Query eventsQuery = FirebaseFirestore.instance.collection('events');

    if (_selectedCategory != 'All') {
      eventsQuery = eventsQuery.where('category', isEqualTo: _selectedCategory);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Find Events")),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),

          // Category Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),

          // Event List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: eventsQuery.orderBy('date').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final filtered =
                    docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title =
                          (data['title'] ?? '').toString().toLowerCase();
                      return title.contains(_searchQuery);
                    }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty && _selectedCategory == 'All'
                          ? 'No events available.'
                          : 'No matching events found.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index].data() as Map<String, dynamic>;
                    data['id'] = filtered[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),

                      child: ListTile(
                        leading: Image.network(
                          data['imageUrl'] ?? '',
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                        ),
                        title: Text(data['title'] ?? ''),
                        subtitle: Text(data['location'] ?? ''),

                        trailing: FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('saved_events')
                                  .doc(data['id'])
                                  .get(),
                          builder: (context, snapshot) {
                            final isSaved = snapshot.data?.exists ?? false;
                            return IconButton(
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isSaved ? Colors.deepPurple : null,
                              ),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                final docRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user!.uid)
                                    .collection('saved_events')
                                    .doc(data['id']);

                                if (isSaved) {
                                  await docRef.delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Removed from bookmarks."),
                                    ),
                                  );
                                } else {
                                  await docRef.set(data);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Added to bookmarks."),
                                    ),
                                  );
                                }

                                setState(() {}); // Refresh the icon state
                              },
                            );
                          },
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: data),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
