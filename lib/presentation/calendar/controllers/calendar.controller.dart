import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

typedef CalendarHttpGet = Future<http.Response> Function(Uri uri);

class CalendarScreenController extends GetxController {
  CalendarScreenController({CalendarHttpGet? httpGet})
      : _httpGet = httpGet ?? http.get;

  final CalendarHttpGet _httpGet;
  // final String publicCalendarAllSchedulue = 'bluesharksrugby.official@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdGameSchedulue =
      'bluesharksrugby.official@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdAll =
      'bluesharksrugby.official2@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdEvent =
      'bluesharksrugby.official3@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdPlayerBirthday =
      'bluesharksrugby.official4@gmail.com'; // Replace with your public calendar ID
  final String apiKey =
      'AIzaSyAJMnARaJbvTrp5s9opMyyjFbZVVj0d0xY'; // Replace with your Google API Key
  RxList<CalendarEvent> publicEvents = <CalendarEvent>[].obs;
  final selectedYear = LocaleKeys.all.tr.obs;

  final Rx<DateTime> minDate = DateTime.now().obs;
  final Rx<DateTime> maxDate = DateTime.now().obs;

  final List<String> filterEvent = [
    LocaleKeys.all.tr,
    LocaleKeys.game_schedule.tr,
    LocaleKeys.event.tr,
    LocaleKeys.player_birthday.tr
  ];

  var calendarView = CalendarView.month.obs;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.logPageView(Routes.CALENDAR);
  }

  Future<void> fetchAllCalendars(DateTime minDate, DateTime maxDate) async {
    // Clear existing events before fetching
    publicEvents.clear();

    // Create a list to hold all fetched events
    List<CalendarEvent> allEvents = [];

    // Fetch events from all calendars concurrently
    await Future.wait([
      fetchCalendarEvents(minDate, maxDate, publicCalendarIdGameSchedulue),
      fetchCalendarEvents(minDate, maxDate, publicCalendarIdEvent),
      fetchCalendarEvents(minDate, maxDate, publicCalendarIdPlayerBirthday)
    ]).then((List<List<CalendarEvent>> results) {
      // Combine all events
      for (var events in results) {
        allEvents.addAll(events);
      }

      // Update the publicEvents with combined results
      publicEvents.assignAll(allEvents);
    });
  }

// Modified fetch method that returns List<CalendarEvent>
  Future<List<CalendarEvent>> fetchCalendarEvents(
      DateTime minDate, DateTime maxDate, String selectedId) async {
    try {
      final items = await _fetchCalendarItems(minDate, maxDate, selectedId);
      return _mapCalendarEvents(items);
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      return [];
    }
  }

  List<String> parseCategories(String title, String description) {
    debugPrint("parseCategory ${title}");
    List<String> categories = [];

    return categories;
  }

  void onChangeCalendar(CalendarView value) {
    calendarView.value = value;
    debugPrint("onChange ${minDate.value} - ${maxDate.value}");

    onChangeFilter(minDate.value, maxDate.value);
  }

  void changeDisplay(DateTime _minDate, DateTime _maxDate) {
    minDate.value = _minDate;
    maxDate.value = _maxDate;

    onChangeFilter(_minDate, _maxDate);
  }

  void onSelectFilter(String selectedKey) {
    selectedYear.value = selectedKey;
    onChangeFilter(minDate.value, maxDate.value);
  }

  void onChangeFilter(DateTime minDate, DateTime maxDate) {
    if (calendarView.value == CalendarView.day) {
      maxDate = maxDate.add(const Duration(days: 1));
      minDate = minDate.add(const Duration(days: -1));
    } else if (calendarView.value == CalendarView.month) {
      maxDate = DateTime(maxDate.year, maxDate.month + 1, maxDate.day);
      minDate = DateTime(minDate.year, minDate.month - 1, maxDate.day);
    } else if (calendarView.value == CalendarView.week) {
      maxDate = maxDate.add(const Duration(days: 1));
      minDate = minDate.add(const Duration(days: -1));
    }

    if (selectedYear.value == LocaleKeys.all.tr) {
      debugPrint("fetch all ${minDate} - ${maxDate}");
      fetchAllCalendars(minDate, maxDate);
    } else if (selectedYear.value == LocaleKeys.game_schedule.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarIdGameSchedulue);
    } else if (selectedYear.value == LocaleKeys.event.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarIdEvent);
    } else if (selectedYear.value == LocaleKeys.player_birthday.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarIdPlayerBirthday);
    }
  }

  Future<void> fetchPublicEvents(
      DateTime minDate, DateTime maxDate, String selectedId) async {
    try {
      final items = await _fetchCalendarItems(minDate, maxDate, selectedId);
      publicEvents.assignAll(_mapCalendarEvents(items));
    } catch (e) {
      debugPrint('Error fetching public calendar events: $e');
    }
  }

  Future<List<dynamic>> _fetchCalendarItems(
      DateTime minDate, DateTime maxDate, String selectedId) async {
    final endpoint = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/$selectedId/events');
    final baseQuery = <String, String>{
      'key': apiKey,
      'timeMin': minDate.toUtc().toIso8601String(),
      'timeMax': maxDate.toUtc().toIso8601String(),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'maxResults': '250',
    };
    final seenPageTokens = <String>{};
    final allItems = <dynamic>[];
    String? pageToken;

    while (true) {
      final query = <String, String>{
        ...baseQuery,
        if (pageToken != null) 'pageToken': pageToken,
      };
      final response = await _httpGet(endpoint.replace(queryParameters: query));
      if (response.statusCode != 200) {
        throw FormatException(
            'Calendar API returned HTTP ${response.statusCode}.');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid calendar response.');
      }
      final items = decoded['items'];
      if (items != null && items is! List) {
        throw const FormatException('Invalid calendar items.');
      }
      if (items is List) allItems.addAll(items);

      final nextPageToken = decoded['nextPageToken'];
      if (nextPageToken == null || nextPageToken == '') break;
      if (nextPageToken is! String || !seenPageTokens.add(nextPageToken)) {
        throw const FormatException('Invalid or repeated calendar page token.');
      }
      pageToken = nextPageToken;
    }

    return allItems;
  }

  List<CalendarEvent> _mapCalendarEvents(List<dynamic> eventItems) {
    return eventItems.map((eventData) {
      if (eventData is! Map<String, dynamic>) {
        throw const FormatException('Invalid calendar event.');
      }
      final start = eventData['start'];
      final end = eventData['end'];
      if (start is! Map<String, dynamic> || end is! Map<String, dynamic>) {
        throw const FormatException('Missing calendar event dates.');
      }

      final isAllDayEvent = start['date'] != null;
      final rawStart = start['dateTime'] ?? start['date'];
      final rawEnd = end['dateTime'] ?? end['date'];
      if (rawStart is! String || rawEnd is! String) {
        throw const FormatException('Invalid calendar event dates.');
      }
      final startDate = DateTime.parse(rawStart);
      var endDate = DateTime.parse(rawEnd);

      if (isAllDayEvent) {
        endDate = endDate.subtract(const Duration(days: 1));
      }
      if (startDate.isAtSameMomentAs(endDate)) {
        endDate = startDate.add(const Duration(hours: 23, minutes: 58));
      }

      return CalendarEvent(
        title: eventData['summary'] as String? ?? 'No Title',
        start: startDate,
        end: endDate,
        description: eventData['description'] as String? ?? '',
      );
    }).toList();
  }
}

class CalendarEvent {
  final String title;
  final DateTime start;
  final DateTime end;
  final String description;

  CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.description,
  });
}
