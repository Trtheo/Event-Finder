import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  File? _pickedImage;
  bool _isLoading = false;

  final List<String> _categories = [
    'Tech',
    'Music',
    'Food',
    'Business',
    'Sports',
    'Art',
    'Health',
    'Party',
    'Birthday',
    'Ceremony',
    'Wedding',
    'Festival',
  ];
  String _selectedCategory = 'Tech';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/trtheo/image/upload",
    );
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = 'event_upload'
          ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(responseData);
      return json['secure_url'];
    } else {
      print('Upload failed: $responseData');
      return null;
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate() ||
        _pickedImage == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All fields including image, date & category are required.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final eventId = FirebaseFirestore.instance.collection('events').doc().id;

      // Upload to Cloudinary
      final imageUrl = await uploadImageToCloudinary(_pickedImage!);
      if (imageUrl == null) {
        throw Exception("Image upload failed.");
      }

      final eventData = {
        'id': eventId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'date': Timestamp.fromDate(_selectedDate!),
        'imageUrl': imageUrl,
        'createdBy': user.uid,
        'organizerName': user.displayName ?? 'Organizer',
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .set(eventData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event created successfully.")),
      );
      Navigator.pop(context);
    } catch (e) {
      print('🔥 Error uploading event: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _pickedImage != null ? FileImage(_pickedImage!) : null,
                  child:
                      _pickedImage == null
                          ? const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 30,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator:
                    (val) =>
                        val == null || val.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items:
                    _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _selectedDate != null
                      ? DateFormat('EEE, MMM d • h:mm a').format(_selectedDate!)
                      : 'Pick Date & Time',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Submit Event"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitEvent,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
