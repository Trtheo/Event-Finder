// 📄 lib/screens/events/my_created_events_screen.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home/event_detail_screen.dart';


class MyCreatedEventsScreen extends StatelessWidget {
  const MyCreatedEventsScreen({super.key});

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
            return Center(child: Text("Error: \${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No events created yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              data['id'] = docs[index].id;

              final imageBase64 = data['imageBase64'];
              ImageProvider? imageProvider;

              if (imageBase64 != null) {
                try {
                  final bytes = base64Decode(imageBase64);
                  imageProvider = MemoryImage(bytes);
                } catch (_) {
                  imageProvider = null;
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: imageProvider != null
                      ? CircleAvatar(backgroundImage: imageProvider)
                      : const Icon(Icons.event),
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(data['location'] ?? ''),
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
