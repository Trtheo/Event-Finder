import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final savedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_events')
        .doc(widget.event['id'] ?? widget.event['title'])
        .get();

    if (savedDoc.exists) {
      setState(() => _isSaved = true);
    }
  }

  Future<void> _saveEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final eventId = widget.event['id'] ?? widget.event['title'];

    final savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_events')
        .doc(eventId);

    await savedRef.set(widget.event);
    setState(() => _isSaved = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event saved!")),
    );
  }

  Future<void> _unsaveEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final eventId = widget.event['id'] ?? widget.event['title'];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_events')
        .doc(eventId)
        .delete();

    setState(() => _isSaved = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bookmark removed.")),
    );
  }

  void _addToCalendar() {
    final date = widget.event['date']?.toDate();
    if (date == null) return;

    final calendarEvent = Event(
      title: widget.event['title'] ?? 'Event',
      description: widget.event['description'] ?? '',
      location: widget.event['location'] ?? '',
      startDate: date,
      endDate: date.add(const Duration(hours: 2)),
    );

    Add2Calendar.addEvent2Cal(calendarEvent);
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.event['date']?.toDate();
    final formattedDate = date != null
        ? DateFormat('EEE, MMM d • h:mm a').format(date)
        : 'Date TBD';

    return Scaffold(
      appBar: AppBar(title: Text(widget.event['title'] ?? 'Event Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.event['imageUrl'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Image.network(
                  widget.event['imageUrl'],
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event['title'] ?? 'No Title',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 20),
                      const SizedBox(width: 6),
                      Text(widget.event['location'] ?? 'No location'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 20),
                      const SizedBox(width: 6),
                      Text(formattedDate),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.event['description'] ?? 'No description available.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(_isSaved
                            ? Icons.bookmark_remove
                            : Icons.bookmark_add),
                        label: Text(_isSaved
                            ? "Remove Bookmark"
                            : "Save Event"),
                        onPressed: _isSaved ? _unsaveEvent : _saveEvent,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text("Add to Calendar"),
                        onPressed: _addToCalendar,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
