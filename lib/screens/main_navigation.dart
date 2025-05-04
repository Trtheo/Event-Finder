import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home/event_list_screen.dart';
import 'home/saved_events_screen.dart';
import 'home/notifications_screen.dart';
import 'home/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with AutomaticKeepAliveClientMixin {
  int _index = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  bool get wantKeepAlive => true;

  final List<Widget> _screens = const [
    EventListScreen(),
    SavedEventsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  void _handleTabChange(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (index == 2 && user != null) {
      // When notifications tab is tapped → mark all as read
      final unread = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unread.docs) {
        doc.reference.update({'read': true});
      }
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final unreadStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: unreadStream,
      builder: (context, snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return CurvedNavigationBar(
          index: _index,
          height: 60,
          backgroundColor: Colors.transparent,
          color: Theme.of(context).primaryColor,
          buttonBackgroundColor: Colors.white,
          animationDuration: const Duration(milliseconds: 300),
          onTap: _handleTabChange,
          items: [
            const Icon(Icons.home, size: 30, color: Colors.black),
            const Icon(Icons.bookmark, size: 30, color: Colors.black),
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications, size: 30, color: Colors.black),
                if (unreadCount > 0)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Container(
                        key: ValueKey(unreadCount),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Icon(Icons.person, size: 30, color: Colors.black),
          ],
        );
      },
    );
  }
}
