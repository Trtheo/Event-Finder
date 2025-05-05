import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme_notifier.dart';
import '../events/create_event_screen.dart'; //
import '../events/my_created_events_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = true;
  String? _photoBase64;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    _displayNameController.text = doc['displayName'] ?? '';
    _photoBase64 = doc['photoBase64'];
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    final newName = _displayNameController.text.trim();
    if (newName.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'displayName': newName,
    });

    await user!.updateDisplayName(newName);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters."),
        ),
      );
      return;
    }

    await user!.updatePassword(newPassword);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password changed successfully.")),
    );
    _newPasswordController.clear();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final base64String = base64Encode(bytes);

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'photoBase64': base64String,
    });

    setState(() => _photoBase64 = base64String);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile picture updated.")));
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.isDarkMode;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _photoBase64 != null
                        ? MemoryImage(base64Decode(_photoBase64!))
                        : const AssetImage('assets/animations/event_logo.png')
                            as ImageProvider,
              ),
            ),
            const SizedBox(height: 12),
            Text(user?.email ?? 'No email'),
            const Divider(height: 40),

            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text("Update Profile"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _changePassword,
              child: const Text("Change Password"),
            ),

            const Divider(height: 40),

            SwitchListTile(
              value: isDarkMode,
              onChanged: _toggleTheme,
              title: const Text("Dark Mode"),
              secondary: const Icon(Icons.dark_mode),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Create Event"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
              },
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.event),
              label: const Text("My Created Events"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyCreatedEventsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
