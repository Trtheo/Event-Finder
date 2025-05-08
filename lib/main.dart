import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_options.dart';
import 'app.dart';
import 'package:provider/provider.dart';
import 'theme/theme_notifier.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Timezone
  tz.initializeTimeZones();

  // Initialize local notifications
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const EventFinderRoot(),
    ),
  );
}

class EventFinderRoot extends StatelessWidget {
  const EventFinderRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Event Finder',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.deepPurple,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
          themeMode:
              themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const EventFinderApp(),
        );
      },
    );
  }
}
