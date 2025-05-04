import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to see notifications."));
    }

    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             print('❌ Firestore Error: ${snapshot.error}');
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
              final data = docs[index].data() as Map<String, dynamic>;
              final timestamp = data['timestamp']?.toDate();
              final formattedTime = timestamp != null
                  ? DateFormat('MMM d, h:mm a').format(timestamp)
                  : 'Time unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    _getIconForType(data['type']),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(data['title'] ?? 'No title'),
                  subtitle: Text("${data['message'] ?? ''}\n$formattedTime"),
                  isThreeLine: true,
                  trailing: data['read'] == true
                      ? null
                      : const Icon(Icons.circle, color: Colors.red, size: 12),
                  onTap: () {
                    // Mark as read on tap
                    docs[index].reference.update({'read': true});
                  },
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
