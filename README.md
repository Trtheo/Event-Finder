## 📱 Event Finder App
The Event Finder App is a Flutter-based mobile application that allows users to discover, create, bookmark, RSVP, and manage local events. It features modern UI, Google Maps integration, calendar support, and real-time Firestore database interaction.

### Features
🔐 Firebase Authentication (login/register,reset-password)

🎉 Create, edit, delete,share your own events

📍 Google Maps to show event locations

🔔 Local notifications 30 minutes before events

📆 Add event to device calendar

📚 Bookmark events to "Saved" section

✅ RSVP/Attendee management (attend/cancel)

🔄 Filter your events (past/upcoming)

📡 Firestore integration for events, users, and attendance

🌗 Light/Dark mode toggle

📤 Cloudinary integration for image uploads

🌐 Firebase Hosting support (web access)

### 🛠️ Tech Stack
**Layer**	                        **Technology**
UI & State Mgmt                  	Flutter + Provider
Backend	                            Firebase Firestore & Auth
Maps	                            Google Maps Flutter SDK
Media Hosting                    	Cloudinary
Calendar Support                 	add_2_calendar
Notifications	                    flutter_local_notifications + timezone
Web Support	                        Firebase Hosting + Deep Linking

###  Dependencies

```bash
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.x.x
  firebase_auth: ^4.x.x
  cloud_firestore: ^4.x.x
  image_picker: ^1.x.x
  http: ^0.13.x
  provider: ^6.x.x
  google_maps_flutter: ^2.x.x
  add_2_calendar: ^3.x.x
  flutter_local_notifications: ^16.x.x
  timezone: ^0.9.x
  curved_navigation_bar: ^1.x.x
  shared_preferences: ^2.x.x
  share_plus: ^7.x.x
```
###  Setup Instructions
1. Clone this Repository

```bash
git clone https://github.com/Trtheo/Event-Finder.git
cd Event-Finder
```
2. Install Dependencies
```bash
flutter pub get
```
3. Configure Firebase
- Add your `google-services.json (Android) under android/app/`

- Add your `GoogleService-Info.plist (iOS) under ios/Runner/`

- Ensure `firebase_options.dart exists (via FlutterFire CLI)`

4. Enable APIs and Features

✅ Firebase Auth (Email/Password)

✅ Firebase Firestore

✅ Google Maps SDK (Android/iOS)

✅ Cloudinary (media uploads)

5. Android Setup for Google Maps Integration
Make sure you:

- Enable Maps SDK on Google Cloud Console

- Add your API key in the Android and iOS platforms

###  Screens
LoginScreen 

RegisterScreen

MainNavigation with:

   EventListScreen

   SavedEventsScreen

NotificationsScreen

ProfileScreen

CreateEventScreen (edit/create)

EventDetailScreen (map, RSVP, calendar)

### Cloudinary Integration
Images are uploaded to Cloudinary via `http.MultipartRequest.` Update your `upload_preset` and `cloud_name` in `create_event_screen.dart`.

# =============================================================

**1. Push Notifications**
Type: Local & Firebase Push Notifications (FCM)

Usage:

Local Notifications (via flutter_local_notifications):

Triggered when the user saves an event.

Notifies them 30 minutes before and 30 minutes before the event ends.

Scheduled using Dart code inside event_detail_screen.dart.

Firebase Cloud Messaging (FCM) (backend push):

Will notify:

Event creator when someone RSVPs.

All users when a new event is published.

Attendees 10 minutes before the event starts.

These are sent from Firebase Cloud Functions using backend triggers.

**2. Firebase**
Services Used: Firestore + FirebaseAuth + FCM

Usage:

Authentication:

Users log in and register using FirebaseAuth.

After login, their uid is used across the app.

Firestore Database:

Stores all events, saved events, attendees, and notifications.

Data structure:


events/{eventId}
users/{userId}/saved_events
users/{userId}/notifications
events/{eventId}/attendees
FCM Tokens:

Each logged-in user's FCM token is saved to Firestore.

This allows push messages to be sent to specific users from the backend.

 **3. State Management**
Approach: setState() and Firebase Stream-based reactive UI

Usage:

The app does not use heavy state managers like Provider or GetX.

Instead, it uses:

setState() for UI updates (e.g., when saving, attending).

StreamBuilder to listen to Firestore updates in real-time (like for NotificationsScreen).

Keeps it simple and effective for a mid-size app.

**4. Local Storage**
Purpose: Support offline access

Usage:

Events are cached locally using SQLite when online.

If there's no internet connection, the app automatically shows events from local storage.

This is managed by checking connection status using connectivity_plus.

**5. SQLite**
Tool: sqflite package
Purpose: Offline caching for event listing and saved events

Usage:

Whenever events are fetched from Firestore, they are also saved locally using DatabaseHelper.

Structure:

```bash
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  ...
)
```
This makes the app usable even without internet — a major UX benefit.

**6. Navigation**
Tool: Flutter's built-in Navigator (Navigator.push, MaterialPageRoute)

Usage:

Navigates between screens like:

Event list → Event details

Profile → Create/Edit event

Home → Saved/Notifications/Profile tabs

Clean transitions are managed with standard Flutter navigation patterns.