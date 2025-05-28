import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../db/database_helper.dart';
import '../../models/local_event_model.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _dbHelper = DatabaseHelper();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showUpcoming = true;
  bool _isOnline = true;
  List<LocalEvent> _events = [];

  final List<String> categories = [
    'All',
    'Tech',
    'Music',
    'Food',
    'Business',
    'Sports',
    'Art',
    'Health',
    'Party',
    'Birthday',
    'Ceremony',
    'Wedding',
    'Festival',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final result = await Connectivity().checkConnectivity();
    final online = result != ConnectivityResult.none;
    setState(() => _isOnline = online);

    if (online) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .orderBy('date')
              .get();

      final events =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            final event = LocalEvent.fromMap(data);
            _dbHelper.insertOrUpdateEvent(event);
            return event;
          }).toList();

      setState(() => _events = events);
    } else {
      final local = await _dbHelper.getEvents();
      setState(() => _events = local);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final filtered =
        _events.where((e) {
          final matchCategory =
              _selectedCategory == 'All' || e.category == _selectedCategory;

          final lowerQuery = _searchQuery.toLowerCase();
          final matchSearch =
              e.title.toLowerCase().contains(lowerQuery) ||
              e.description.toLowerCase().contains(lowerQuery) ||
              e.location.toLowerCase().contains(lowerQuery) ||
              e.date.toIso8601String().toLowerCase().contains(lowerQuery);

          final matchTime =
              _showUpcoming ? e.date.isAfter(now) : e.date.isBefore(now);

          return matchCategory && matchSearch && matchTime;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Events"),
        actions: [
          IconButton(
            icon: Icon(_showUpcoming ? Icons.arrow_forward : Icons.history),
            tooltip: _showUpcoming ? "Showing Upcoming" : "Showing Past",
            onPressed: () => setState(() => _showUpcoming = !_showUpcoming),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.red.withOpacity(0.1),
              child: const Text(
                "No internet connection. Showing cached events.",
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by title, description, date, or location...",
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
              onChanged:
                  (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          SizedBox(
            height: 46,
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
                  onSelected:
                      (_) => setState(() => _selectedCategory = category),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: Colors.grey.shade200,
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadEvents,
              child:
                  filtered.isEmpty
                      ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No ${_showUpcoming ? 'upcoming' : 'past'} events found.'
                                  : 'No results found.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      )
                      : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final event = filtered[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading:
                                  event.imageUrl.isNotEmpty
                                      ? Image.network(
                                        event.imageUrl,
                                        width: 60,
                                        fit: BoxFit.cover,
                                      )
                                      : const Icon(Icons.image_not_supported),
                              title: Text(event.title),
                              subtitle: Text(event.location),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EventDetailScreen(event: event),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
