import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'screens/main_navigation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'theme/theme_notifier.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/events/my_created_events_screen.dart';
import 'screens/home/event_detail_screen_from_id.dart';

class EventFinderApp extends StatelessWidget {
  const EventFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            title: 'Event Finder',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.deepPurple,
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark().copyWith(useMaterial3: true),
            themeMode:
                themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            // ✅ Dynamic Deep Link Handling
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments.first == 'event') {
                final eventId = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder:
                      (context) => EventDetailScreenFromId(eventId: eventId),
                );
              }
              return null; // fallback to default routes
            },

            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/main': (context) => const MainNavigation(),
              '/reset-password': (context) => const ResetPasswordScreen(),
              '/my-events': (context) => const MyCreatedEventsScreen(),
            },

            // 👇 Default root screen with auth
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData) {
                  return const MainNavigation();
                } else {
                  return const LoginScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
