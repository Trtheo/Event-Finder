import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> scheduleNotification({
  required String id,
  required String title,
  required String body,
  required DateTime eventTime,
}) async {
  final scheduledTime = eventTime.subtract(const Duration(minutes: 30));
  final tz.TZDateTime tzScheduled =
      tz.TZDateTime.from(scheduledTime, tz.local);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id.hashCode,
    title,
    body,
    tzScheduled,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'event_channel_id',
        'Event Reminders',
        channelDescription: 'Reminder for upcoming events',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}
