import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'notification_service.dart';

class CalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarReadonlyScope],
    serverClientId: '815651670494-o8d3ok0pvaaupnu57ru35e4iebf6nolb.apps.googleusercontent.com',
  );

  static GoogleSignInAccount? _currentUser;
  static bool _initialized = false;

  // ─── Sign In ──────────────────────────────────────────
  static Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      _currentUser = account;
      _initialized = true;
      return true;
    } catch (e) {
      print('Calendar sign in error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _initialized = false;
  }

  static bool get isSignedIn => _currentUser != null;

  // ─── Get upcoming events ──────────────────────────────
  static Future<List<Map<String, dynamic>>> getUpcomingEvents({
    int maxResults = 5,
  }) async {
    if (_currentUser == null) return [];

    try {
      final authHeaders = await _currentUser!.authHeaders;
      final authenticateClient = _AuthenticatedClient(
        http.Client(),
        authHeaders,
      );

      final calendarApi = calendar.CalendarApi(authenticateClient);

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(hours: 24));
      final events = await calendarApi.events.list(
        'primary',
        timeMin: now,
        timeMax: tomorrow,
        maxResults: maxResults,
        singleEvents: true,
        orderBy: 'startTime',
      );

      final result = <Map<String, dynamic>>[];

      for (final event in (events.items ?? [])) {
        final start = event.start?.dateTime ?? event.start?.date;
        if (start == null) continue;

        final startTime = start is DateTime
            ? start
            : DateTime.parse(start.toString());
        final minutesUntil = startTime.difference(now).inMinutes;

        // Skip past events
        if (minutesUntil < 0) continue;

        result.add({
          'title': event.summary ?? 'Untitled Event',
          'startTime': startTime,
          'minutesUntil': minutesUntil,
          'description': event.description ?? '',
        });
      }

      return result;
    } catch (e) {
      print('Calendar fetch error: $e');
      return [];
    }
  }

  // ─── Get next event ───────────────────────────────────
  static Future<Map<String, dynamic>?> getNextEvent() async {
    final events = await getUpcomingEvents(maxResults: 1);
    if (events.isEmpty) return null;
    return events.first;
  }

  // ─── Check for imminent events ────────────────────────
  static Future<Map<String, dynamic>?> getImminentEvent() async {
    final events = await getUpcomingEvents(maxResults: 3);
    for (final event in events) {
      final minutes = event['minutesUntil'] as int;
      if (minutes >= 0 && minutes <= 30) {
        return event;
      }
    }
    return null;
  }

  // ─── Get scripture for event context ─────────────────
  static String getEventScripture(String eventTitle) {
    final title = eventTitle.toLowerCase();

    if (title.contains('meeting') || title.contains('call') ||
        title.contains('interview')) {
      return 'The Lord will fight for you; you need only to be still. — Exodus 14:14';
    } else if (title.contains('presentation') || title.contains('review') ||
        title.contains('demo')) {
      return 'I can do all this through him who gives me strength. — Philippians 4:13';
    } else if (title.contains('doctor') || title.contains('hospital') ||
        title.contains('appointment')) {
      return 'He heals the brokenhearted and binds up their wounds. — Psalm 147:3';
    } else if (title.contains('exam') || title.contains('test') ||
        title.contains('study')) {
      return 'For God has not given us a spirit of fear, but of power and love. — 2 Timothy 1:7';
    } else if (title.contains('date') || title.contains('dinner') ||
        title.contains('lunch')) {
      return 'Let love and faithfulness never leave you. — Proverbs 3:3';
    } else {
      return 'Be strong and courageous. Do not be afraid; do not be discouraged. — Joshua 1:9';
    }
  }

  // ─── Get Lumíne message for event ────────────────────
  static String getLumineMessage(String eventTitle, int minutesUntil) {
    if (minutesUntil <= 5) {
      return "You are about to walk into this moment. You don't walk in alone.";
    } else if (minutesUntil <= 15) {
      return 'Something is approaching. Take one breath with me before you go in.';
    } else {
      return "Lumíne sees what's coming in your day. You were made for this moment.";
    }
  }

  // ─── Schedule notifications for upcoming events ────────
  static Future<void> scheduleEventNotifications() async {
    final events = await CalendarService.getUpcomingEvents();
    for (final event in events) {
      final minutes = event['minutesUntil'] as int;
      final title = event['title'] as String;

      if (minutes <= 0) continue;

      // Notify 15 minutes before
      final notifyIn15 = minutes - 15;
      if (notifyIn15 > 0) {
        final scripture = CalendarService.getEventScripture(title);
        Future.delayed(Duration(minutes: notifyIn15), () {
          NotificationService.showNotification(
            title: 'Lumíne · $title in 15 min',
            body: scripture,
          );
        });
      }

      // Notify 5 minutes before
      final notifyIn5 = minutes - 5;
      if (notifyIn5 > 0) {
        final message = CalendarService.getLumineMessage(title, 5);
        Future.delayed(Duration(minutes: notifyIn5), () {
          NotificationService.showNotification(
            title: 'Lumíne · $title is soon',
            body: message,
          );
        });
      }
    }
  }
}

// ─── HTTP Client with auth headers ───────────────────────
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  _AuthenticatedClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}