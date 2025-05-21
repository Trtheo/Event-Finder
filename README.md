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
