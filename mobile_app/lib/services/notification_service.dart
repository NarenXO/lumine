import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart' show Color;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Scripture verses for daily notifications
  static const List<Map<String, String>> _dailyVerses = [
    {"text": "Be still, and know that I am God.", "ref": "Psalm 46:10"},
    {"text": "I can do all this through him who gives me strength.", "ref": "Philippians 4:13"},
    {"text": "The Lord is my shepherd, I lack nothing.", "ref": "Psalm 23:1"},
    {"text": "Cast all your anxiety on him because he cares for you.", "ref": "1 Peter 5:7"},
    {"text": "For I know the plans I have for you, declares the Lord.", "ref": "Jeremiah 29:11"},
    {"text": "Come to me, all you who are weary and burdened, and I will give you rest.", "ref": "Matthew 11:28"},
    {"text": "The Lord is close to the brokenhearted.", "ref": "Psalm 34:18"},
    {"text": "Peace I leave with you; my peace I give you.", "ref": "John 14:27"},
    {"text": "But those who hope in the Lord will renew their strength.", "ref": "Isaiah 40:31"},
    {"text": "Give thanks to the Lord, for he is good.", "ref": "Psalm 136:1"},
    {"text": "A gentle answer turns away wrath.", "ref": "Proverbs 15:1"},
    {"text": "He gives strength to the weary.", "ref": "Isaiah 40:29"},
    {"text": "Do not be anxious about anything.", "ref": "Philippians 4:6"},
    {"text": "This is the day the Lord has made; let us rejoice.", "ref": "Psalm 118:24"},
    {"text": "The joy of the Lord is your strength.", "ref": "Nehemiah 8:10"},
  ];

  static Future<void> initialize() async {
    if (_initialized) return;

    // ✅ Fixed: use tz_data alias to avoid conflict with tz alias
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  static Future<void> scheduleDailyScripture({
    int hour = 8,
    int minute = 0,
  }) async {
    await initialize();

    await _notifications.cancelAll();

    // Pick verse based on day of year
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final verse = _dailyVerses[dayOfYear % _dailyVerses.length];

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lumine_daily',
      'Lumíne Daily Scripture',
      channelDescription: 'Daily Scripture notification from Lumíne',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
      color: Color(0xFF6B3FA0),
      ledColor: Color(0xFFD4AF37),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      0,
      '✦ Lumíne',
      '"${verse["text"]}" — ${verse["ref"]}',
      _nextInstanceOfTime(hour, minute),
      details,
           androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // ✅ THIS was the missing required parameter causing the build error
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> sendTestNotification() async {
    await initialize();

    final verse =
        _dailyVerses[DateTime.now().millisecond % _dailyVerses.length];

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lumine_daily',
      'Lumíne Daily Scripture',
      channelDescription: 'Daily Scripture notification from Lumíne',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF6B3FA0),
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      1,
      '✦ Lumíne',
      '"${verse["text"]}" — ${verse["ref"]}',
      details,
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}