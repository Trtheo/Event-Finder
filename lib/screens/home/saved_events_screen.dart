import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../db/database_helper.dart';
import '../../models/local_event_model.dart';
import 'event_detail_screen.dart';

class SavedEventsScreen extends StatefulWidget {
  const SavedEventsScreen({super.key});

  @override
  State<SavedEventsScreen> createState() => _SavedEventsScreenState();
}

class _SavedEventsScreenState extends State<SavedEventsScreen> {
  final _dbHelper = DatabaseHelper();
  bool _isOnline = true;
  List<LocalEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadEvents();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _isOnline = result != ConnectivityResult.none);
  }

  Future<void> _loadEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isOnline) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('saved_events')
              // 🔁 Removed .orderBy('date') to prevent Timestamp vs String issue
              .get();

      final events =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return LocalEvent.fromMap({...data, 'id': doc.id});
          }).toList();

      setState(() => _events = events);

      for (var event in events) {
        await _dbHelper.insertOrUpdateEvent(event);
      }
    } else {
      final localData = await _dbHelper.getEvents();
      setState(() => _events = localData);
    }
  }

  Future<void> _unsaveEvent(LocalEvent event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Remove from Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_events')
        .doc(event.id)
        .delete();

    // Remove from local SQLite
    await _dbHelper.deleteEvent(event.id);

    // Update UI
    setState(() {
      _events.removeWhere((e) => e.id == event.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event removed from saved list")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Events")),
      body:
          _events.isEmpty
              ? const Center(child: Text("You haven't saved any events yet."))
              : RefreshIndicator(
                onRefresh: _loadEvents,
                child: ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            event.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                          ),
                        ),
                        title: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(event.location),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Remove from saved',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text("Unsave Event"),
                                    content: const Text(
                                      "Are you sure you want to remove this event from saved list?",
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancel"),
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                      ),
                                      ElevatedButton(
                                        child: const Text("Remove"),
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              await _unsaveEvent(event);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: event),
                            ),
                          );
                        }
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
