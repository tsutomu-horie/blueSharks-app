import 'dart:convert';
import 'package:get/get.dart';
import 'package:googleapis/driveactivity/v2.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarScreenController extends GetxController {
  // final String publicCalendarAllSchedulue = 'bluesharksrugby.official@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdGameSchedulue = 'bluesharksrugby.official@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdAll = 'bluesharksrugby.official2@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdEvent = 'bluesharksrugby.official3@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdPlayerBirthday = 'bluesharksrugby.official4@gmail.com'; // Replace with your public calendar ID
  final String apiKey = 'AIzaSyAJMnARaJbvTrp5s9opMyyjFbZVVj0d0xY'; // Replace with your Google API Key
  RxList<CalendarEvent> publicEvents = <CalendarEvent>[].obs;
  final selectedYear = LocaleKeys.all.tr.obs;

  final Rx<DateTime> minDate = DateTime.now().obs;
  final Rx<DateTime> maxDate = DateTime.now().obs;

  final List<String> filterEvent = [ LocaleKeys.all.tr, LocaleKeys.game_schedule.tr, LocaleKeys.event.tr, LocaleKeys.player_birthday.tr];

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
  Future<List<CalendarEvent>> fetchCalendarEvents(DateTime minDate, DateTime maxDate, String selectedId) async {
    List<CalendarEvent> events = [];

    try {
      final url = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/$selectedId/events?key=$apiKey'
            '&timeMin=${minDate.toUtc().toIso8601String()}&timeMax=${maxDate.toUtc().toIso8601String()}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> eventItems = data['items'];

        events = eventItems.map((eventData) {
          final isAllDayEvent = eventData['start']['date'] != null;

          // Parse start & end time
          DateTime startDate = DateTime.parse(eventData['start']['dateTime'] ?? eventData['start']['date']);
          DateTime endDate = DateTime.parse(eventData['end']['dateTime'] ?? eventData['end']['date']);

          if (isAllDayEvent) {
            endDate = endDate.subtract(const Duration(days: 1));
          }

          // 🛠 Fix: Ensure a minimum duration of 30 minutes if the event has no duration
          if (startDate.isAtSameMomentAs(endDate)) {
            endDate = startDate.add(const Duration(hours: 23, minutes: 58)); // Set default duration
          }

          return CalendarEvent(
            title: eventData['summary'] ?? 'No Title',
            start: startDate,
            end: endDate,
            description: eventData['description'] ?? '',
          );
        }).toList();
      }
    } catch (e) {
      print("Error fetching calendar events: $e");
    }

    return events;
  }

  List<String> parseCategories(String title, String description) {
    print("parseCategory ${title}");
    List<String> categories = [];

    return categories;
  }

  void onChangeCalendar(CalendarView value) {
    calendarView.value = value;
    print("onChange ${minDate.value} - ${maxDate.value}");

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
      print("fetch all ${minDate} - ${maxDate}");
      fetchAllCalendars(minDate, maxDate);
    } else if (selectedYear.value == LocaleKeys.game_schedule.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarIdGameSchedulue);
    } else if (selectedYear.value == LocaleKeys.event.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarIdEvent);
    } else if (selectedYear.value == LocaleKeys.player_birthday.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarIdPlayerBirthday);
    }
  }


  Future<void> fetchPublicEvents(DateTime minDate, DateTime maxDate, String selectedId) async {
    print("finish fetch with data ${minDate} - ${maxDate}");

    try {
      final url = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/$selectedId/events?key=$apiKey'
            '&timeMin=${minDate.toUtc().toIso8601String()}&timeMax=${maxDate.toUtc().toIso8601String()}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> events = data['items'];

        print("get data\n ${data}");
        // Map the event data to your CalendarEvent model
        final fetchedEvents = events.map((eventData) {
          final isAllDayEvent = eventData['start']['date'] != null;

          DateTime startDate = DateTime.parse(eventData['start']['dateTime'] ?? eventData['start']['date']);
          DateTime endDate = DateTime.parse(eventData['end']['dateTime'] ?? eventData['end']['date']);

          if (isAllDayEvent) {
            endDate = endDate.subtract(const Duration(days: 1));
          }

          print("summary ${eventData['summary']}");
          return CalendarEvent(
            title: eventData['summary'] ?? 'No Title',
            start: startDate,
            end: endDate,
            description: eventData['description'] ?? '',
          );
        }).toList();

        print("finish fetch with data ${fetchedEvents}");
        publicEvents.assignAll(fetchedEvents);
      } else {
        print('Failed to fetch events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching public calendar events: $e");
    }
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