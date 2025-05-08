import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../home/event_detail_screen.dart';
import 'create_event_screen.dart';

class MyCreatedEventsScreen extends StatelessWidget {
  const MyCreatedEventsScreen({super.key});

  Future<void> _deleteEvent(BuildContext context, String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // allow tap outside to cancel
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Event"),
          content: const Text("Are you sure you want to delete this event?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .delete();

        // show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event deleted successfully.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(" Failed to delete event: $e")));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(" Deletion canceled.")));
    }
  }

  void _showShareModal(BuildContext context, String eventId) {
    final link = 'https://event-finder-fabd7.firebaseapp.com/event/$eventId';

    showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: AlertDialog(
            title: const Text("Share Event"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(link),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy Link"),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Copied")));
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text("Share"),
                  onPressed: () {
                    Share.share("Check out my event: $link");
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text("You haven’t created any events yet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              data['id'] = docs[index].id;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  leading:
                      data['imageUrl'] != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['imageUrl'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Icon(Icons.event, size: 40),
                  title: Text(
                    data['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['location'] ?? ''),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => CreateEventScreen(eventToEdit: data),
                          ),
                        );
                      } else if (value == 'delete') {
                        _deleteEvent(context, data['id']);
                      } else if (value == 'share') {
                        _showShareModal(context, data['id']);
                      }
                    },
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'share',
                            child: Text('Share / Copy'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
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
    );
  }
}
