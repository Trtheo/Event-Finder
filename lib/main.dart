import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'app.dart';
import 'theme/theme_notifier.dart';
import 'services/notification_service.dart'; // ✅ Import your service

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService.showLocalNotification(message); // ✅ Use service
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize timezone and local notification setup
  tz.initializeTimeZones();
  await NotificationService.initialize(); // ✅ Setup plugin + channel

  // ✅ Background FCM handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Request notification permission
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // ✅ Print device token (for manual test)
  final token = await messaging.getToken();
  print("📲 FCM Token: $token");

  // ✅ Foreground FCM listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📥 [Foreground] Notification Received:");
    print("🔔 Title: ${message.notification?.title}");
    print("📄 Body: ${message.notification?.body}");
    NotificationService.showLocalNotification(message); // ✅ Show popup
  });

  // ✅ Run app
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const EventFinderApp(),
    ),
  );
}
