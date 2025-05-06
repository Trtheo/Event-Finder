import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../home/event_detail_screen.dart';
import 'create_event_screen.dart';

class MyCreatedEventsScreen extends StatelessWidget {
  const MyCreatedEventsScreen({super.key});

  Future<void> _deleteEvent(BuildContext context, String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event deleted.")));
    }
  }

  void _shareEvent(String eventId) {
    final shareLink = 'https://example.com/event/$eventId'; // Customize this link if needed
    Share.share('Check out this event I created: $shareLink');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view your events."));
    }

    final eventsRef = FirebaseFirestore.instance
        .collection('events')
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("My Created Events")),
      body: StreamBuilder<QuerySnapshot>(
        stream: eventsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("You haven’t created any events yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              data['id'] = docs[index].id;

              final imageUrl = data['imageUrl'];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.event, size: 40),
                  title: Text(data['title'] ?? 'No title', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(data['location'] ?? 'No location'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateEventScreen(), // Replace with Edit screen if needed
                          ),
                        );
                      } else if (value == 'delete') {
                        _deleteEvent(context, data['id']);
                      } else if (value == 'share') {
                        _shareEvent(data['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'share', child: Text('Share')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventDetailScreen(event: data)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
