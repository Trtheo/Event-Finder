import 'package:cloud_firestore/cloud_firestore.dart';

class LocalEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime date; // Store as DateTime for easier logic
  final String imageUrl;
  final String organizerName;

  LocalEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.date,
    required this.imageUrl,
    required this.organizerName,
  });

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'date': date.toIso8601String(), // Store as ISO string for SQLite
      'imageUrl': imageUrl,
      'organizerName': organizerName,
    };
  }

  /// Create from Map (Firestore or SQLite)
  factory LocalEvent.fromMap(Map<String, dynamic> map) {
    return LocalEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      category: map['category'] ?? '',
      date:
          map['date'] is Timestamp
              ? (map['date'] as Timestamp).toDate()
              : DateTime.parse(map['date']),
      imageUrl: map['imageUrl'] ?? '',
      organizerName: map['organizerName'] ?? '',
    );
  }

  /// Convert to Firestore-compatible map (optional)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'date': date, // Firestore accepts DateTime directly
      'imageUrl': imageUrl,
      'organizerName': organizerName,
    };
  }
}
