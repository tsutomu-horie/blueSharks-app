import 'dart:convert';
import 'package:get/get.dart';
import 'package:googleapis/driveactivity/v2.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarScreenController extends GetxController {
  final String publicCalendarAllSchedulue = 'bluesharksrugby.official@gmail.com'; // Replace with your public calendar ID
  final String publicCalendarIdGameSchedulue = '49d1fb0089629f5d035c69511fcd066cca299e022b41cc6ba43ed818090d6631@group.calendar.google.com'; // Replace with your public calendar ID
  final String publicCalendarIdOpenPractice = '49d1fb0089629f5d035c69511fcd066cca299e022b41cc6ba43ed818090d6631@group.calendar.google.com'; // Replace with your public calendar ID
  final String publicCalendarIdEvent = '49d1fb0089629f5d035c69511fcd066cca299e022b41cc6ba43ed818090d6631@group.calendar.google.com'; // Replace with your public calendar ID
  final String publicCalendarIdPlayerBirthday = '49d1fb0089629f5d035c69511fcd066cca299e022b41cc6ba43ed818090d6631@group.calendar.google.com'; // Replace with your public calendar ID
  final String apiKey = 'AIzaSyAJMnARaJbvTrp5s9opMyyjFbZVVj0d0xY'; // Replace with your Google API Key
  RxList<CalendarEvent> publicEvents = <CalendarEvent>[].obs;
  final selectedYear = LocaleKeys.all.tr.obs;

  final Rx<DateTime> minDate = DateTime.now().obs;
  final Rx<DateTime> maxDate = DateTime.now().obs;

  final List<String> filterEvent = [LocaleKeys.all.tr, LocaleKeys.game_schedule.tr, LocaleKeys.open_practice_match.tr, LocaleKeys.event.tr, LocaleKeys.player_birthday.tr];

  var calendarView = CalendarView.month.obs;

  @override
  void onInit() {

    super.onInit();
    AnalyticsService.logPageView(Routes.CALENDAR);

  }

  List<String> parseCategories(String title, String description) {
    List<String> categories = [];

    if (title.contains('Meeting') || description.contains('Meeting')) {
      categories.add('Meeting');
    }
    if (title.contains('Workshop') || description.contains('Workshop')) {
      categories.add('Workshop');
    }
    if (title.contains('Conference') || description.contains('Conference')) {
      categories.add('Conference');
    } 

    // Add more conditions as needed

    print("parse catrgot ${selectedYear.value} ${LocaleKeys.all.tr.toUpperCase()}");

    // Filter categories based on selectedYear
    if (selectedYear.value.toLowerCase() != LocaleKeys.all.tr.toLowerCase()) {
      categories = categories.where((category) => category == selectedYear.value).toList();
      print("masuk $categories");
    } else {
      categories = filterEvent.where((value) => value != LocaleKeys.all.tr).toList();
    }

    return categories;
  }

  void onChangeCalendar(CalendarView value) {
    calendarView.value = value;
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
      // If in month view, add 1 month to the max date and subtract 1 day from the min date
      maxDate = DateTime(maxDate.year, maxDate.month + 1, maxDate.day);
      minDate = DateTime(minDate.year, minDate.month - 1, maxDate.day);
    } else if (calendarView.value == CalendarView.week) {
      maxDate = maxDate.add(const Duration(days: 1));
      minDate = minDate.add(const Duration(days: -1));
    }

    print("onCHange ${selectedYear.value}");
    if (selectedYear.value == LocaleKeys.all.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarAllSchedulue);
    } else if (selectedYear.value == LocaleKeys.game_schedule.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarIdGameSchedulue);
    } else if (selectedYear.value == LocaleKeys.open_practice_match.tr) {
      fetchPublicEvents(minDate, maxDate, publicCalendarIdOpenPractice);
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
          return CalendarEvent(
            title: eventData['summary'] ?? 'No Title',
            start: DateTime.parse(eventData['start']['dateTime'] ?? eventData['start']['date']),
            end: DateTime.parse(eventData['end']['dateTime'] ?? eventData['end']['date']),
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