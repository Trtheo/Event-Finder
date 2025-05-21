import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isSaved = false;
  bool _isAttending = false;
  GoogleMapController? _mapController;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
    _checkAttendanceStatus();
  }

  Future<void> _checkSavedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_events')
            .doc(widget.event['id'])
            .get();

    setState(() => _isSaved = doc.exists);
  }

  Future<void> _checkAttendanceStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event['id'])
            .collection('attendees')
            .doc(user.uid)
            .get();

    setState(() => _isAttending = doc.exists);
  }

  Future<void> _saveEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_events')
        .doc(widget.event['id'])
        .set(widget.event);

    setState(() => _isSaved = true);

    final date = widget.event['date']?.toDate();
    if (date != null) {
      final time = date.subtract(const Duration(minutes: 30));
      final id = widget.event['id'].hashCode;

      _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Upcoming Event',
        '${widget.event['title']} starts in 30 minutes!',
        tz.TZDateTime.from(time, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminder_channel',
            'Event Reminders',
            channelDescription: '30 minutes before event start',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event saved & reminder set.")),
    );
  }

  Future<void> _unsaveEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_events')
        .doc(widget.event['id'])
        .delete();

    setState(() => _isSaved = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Bookmark removed.")));
  }

  void _addToCalendar() {
    final date = widget.event['date']?.toDate();
    if (date == null) return;

    final calendarEvent = Event(
      title: widget.event['title'],
      description: widget.event['description'] ?? '',
      location: widget.event['location'] ?? '',
      startDate: date,
      endDate: date.add(const Duration(hours: 2)),
    );

    Add2Calendar.addEvent2Cal(calendarEvent);
  }

  Future<void> _attendEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event['id'])
        .collection('attendees')
        .doc(user.uid);

    if (_isAttending) {
      await docRef.delete();
      setState(() => _isAttending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are no longer attending.")),
      );
    } else {
      await docRef.set({
        'userId': user.uid,
        'displayName': user.displayName ?? 'User',
        'timestamp': Timestamp.now(),
      });
      setState(() => _isAttending = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're attending this event.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.event['date']?.toDate();
    final formattedDate =
        date != null
            ? DateFormat('EEE, MMM d • h:mm a').format(date)
            : 'Date TBD';

    final imageUrl = widget.event['imageUrl'];
    final imageWidget =
        imageUrl != null
            ? Image.network(
              imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            )
            : Container(
              height: 220,
              color: Colors.grey[200],
              child: const Center(child: Text("No Image")),
            );

    final isOngoing = date != null && DateTime.now().isBefore(date);

    final lat = widget.event['latitude'];
    final lng = widget.event['longitude'];
    final eventLatLng = (lat != null && lng != null) ? LatLng(lat, lng) : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.event['title'] ?? 'Event Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageWidget,
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event['title'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOngoing ? "🟢 Ongoing" : "🔴 Ended",
                    style: TextStyle(
                      color: isOngoing ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 6),
                      Text("Organized by: ${widget.event['organizerName']}"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.event['description'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // 🔘 Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(
                          _isSaved ? Icons.bookmark_remove : Icons.bookmark_add,
                        ),
                        label: Text(
                          _isSaved ? "Remove Bookmark" : "Save Event",
                        ),
                        onPressed: _isSaved ? _unsaveEvent : _saveEvent,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text("Add to Calendar"),
                        onPressed: _addToCalendar,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _isAttending ? Icons.cancel : Icons.check_circle,
                      ),
                      label: Text(
                        _isAttending ? "Cancel Attendance" : "Attend",
                      ),
                      onPressed: _attendEvent,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (eventLatLng != null) ...[
                    const Text(
                      "Location Map",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: eventLatLng,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('event_location'),
                            position: eventLatLng,
                          ),
                        },
                        onMapCreated:
                            (controller) => _mapController = controller,
                        myLocationEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
