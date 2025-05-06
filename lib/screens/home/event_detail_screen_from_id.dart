import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_detail_screen.dart';

class EventDetailScreenFromId extends StatelessWidget {
  final String eventId;

  const EventDetailScreenFromId({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final eventDoc = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: eventDoc.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("❌ Event not found or failed to load."),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          data['id'] = eventId;

          return EventDetailScreen(event: data);
        },
      ),
    );
  }
}
