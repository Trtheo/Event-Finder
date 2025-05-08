import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateEventScreen extends StatefulWidget {
  final Map<String, dynamic>? eventToEdit;

  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  DateTime? _selectedDate;
  File? _pickedImage;
  bool _isLoading = false;
  String? _imageUrl;

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

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final data = widget.eventToEdit!;
      _titleController.text = data['title'] ?? '';
      _descController.text = data['description'] ?? '';
      _locationController.text = data['location'] ?? '';
      _latitudeController.text = data['latitude']?.toString() ?? '';
      _longitudeController.text = data['longitude']?.toString() ?? '';
      _selectedCategory = data['category'] ?? 'Tech';
      _imageUrl = data['imageUrl'];
      _selectedDate = data['date']?.toDate();
    }
  }

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
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
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

  Future<String?> _uploadToCloudinary(File imageFile) async {
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
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(body)['secure_url'];
    } else {
      print("Cloudinary upload failed: $body");
      return null;
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final isEditing = widget.eventToEdit != null;
      final docId =
          isEditing
              ? widget.eventToEdit!['id']
              : FirebaseFirestore.instance.collection('events').doc().id;

      String? imageUrl = _imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadToCloudinary(_pickedImage!);
        if (imageUrl == null) throw Exception("Image upload failed");
      }

      final double? latitude = double.tryParse(_latitudeController.text.trim());
      final double? longitude = double.tryParse(
        _longitudeController.text.trim(),
      );

      final eventData = {
        'id': docId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'category': _selectedCategory,
        'date': Timestamp.fromDate(_selectedDate!),
        'imageUrl': imageUrl,
        'createdBy': user.uid,
        'organizerName': user.displayName ?? 'Organizer',
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('events')
          .doc(docId)
          .set(eventData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? "Event updated." : "Event created."),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print("🔥 Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit != null ? "Edit Event" : "Create Event"),
      ),
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
                      _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_imageUrl != null
                                  ? NetworkImage(_imageUrl!)
                                  : null)
                              as ImageProvider?,
                  child:
                      _pickedImage == null && _imageUrl == null
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
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
                    label: Text(
                      widget.eventToEdit != null
                          ? "Update Event"
                          : "Submit Event",
                    ),
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
