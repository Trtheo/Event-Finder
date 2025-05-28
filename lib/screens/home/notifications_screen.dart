import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/local_event_model.dart';
import 'event_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see notifications.")),
      );
    }

    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Mark all as read',
            onPressed: () async {
              final unread =
                  await notificationsRef.where('read', isEqualTo: false).get();

              for (var doc in unread.docs) {
                doc.reference.update({'read': true});
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All notifications marked as read"),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('❌ Firestore Error: ${snapshot.error}');
            return const Center(child: Text("Something went wrong."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp']?.toDate();
              final formattedTime =
                  timestamp != null
                      ? DateFormat('MMM d, h:mm a').format(timestamp)
                      : 'Time unknown';

              return Dismissible(
                key: Key(doc.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await doc.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notification deleted")),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: Icon(
                      _getIconForType(data['type']),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(data['title'] ?? 'No title'),
                    subtitle: Text("${data['message'] ?? ''}\n$formattedTime"),
                    isThreeLine: true,
                    trailing:
                        data['read'] == true
                            ? null
                            : const Icon(
                              Icons.circle,
                              color: Colors.red,
                              size: 12,
                            ),
                    onTap: () async {
                      doc.reference.update({'read': true});

                      final eventId = data['event_id'];
                      if (eventId != null) {
                        try {
                          final eventSnap =
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(eventId)
                                  .get();

                          if (eventSnap.exists) {
                            final eventData = eventSnap.data()!;
                            eventData['id'] = eventId;

                            final event = LocalEvent.fromMap(eventData);

                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(event: event),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Event not found.")),
                            );
                          }
                        } catch (e) {
                          debugPrint("❌ Error loading event: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not load event."),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'reminder':
        return Icons.event_available;
      case 'announcement':
        return Icons.campaign;
      case 'new_event':
        return Icons.new_releases;
      default:
        return Icons.notifications;
    }
  }
}
