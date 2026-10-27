import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:koto_blue_sharks/presentation/calendar/controllers/calendar.controller.dart';
import 'package:koto_blue_sharks/presentation/menu/match/match_detail/match_member_count_header.dart';

http.Response _eventsResponse(
  List<Map<String, dynamic>> items, {
  String? nextPageToken,
}) {
  return http.Response(
    jsonEncode({
      'items': items,
      if (nextPageToken != null) 'nextPageToken': nextPageToken,
    }),
    200,
  );
}

Map<String, dynamic> _birthdayOccurrence(String date, String eventId) => {
      'id': eventId,
      'summary': 'Synthetic recurring birthday occurrence',
      'recurringEventId': 'synthetic-birthday-series',
      'originalStartTime': {'date': date},
      'start': {'date': date},
      'end': {
        'date': DateTime.parse(date)
            .add(const Duration(days: 1))
            .toIso8601String()
            .substring(0, 10),
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recurring event requests expand occurrences and follow every page',
      () async {
    final requests = <Uri>[];
    final controller = CalendarScreenController(httpGet: (uri) async {
      requests.add(uri);
      if (requests.length == 1) {
        return _eventsResponse(
          [_birthdayOccurrence('2026-10-24', 'birthday-20261024')],
          nextPageToken: 'mock-page-2',
        );
      }
      if (requests.length == 2) {
        return _eventsResponse(
            [_birthdayOccurrence('2026-10-31', 'birthday-20261031')]);
      }
      throw StateError('Unexpected additional calendar page.');
    });

    await controller.fetchPublicEvents(
      DateTime(2026, 10),
      DateTime(2026, 11),
      'mock-calendar',
    );

    expect(requests, hasLength(2));
    expect(
      requests.every((uri) =>
          uri.queryParameters['singleEvents'] == 'true' &&
          uri.queryParameters['orderBy'] == 'startTime' &&
          uri.queryParameters['maxResults'] == '250'),
      isTrue,
    );
    expect(
      requests.map((uri) => uri.queryParameters['pageToken']).toList(),
      [null, 'mock-page-2'],
    );
    expect(controller.publicEvents.map((event) => event.start.day), [24, 31]);
    expect(controller.publicEvents.last.end.day, 31);
  });

  test('all-calendar view expands and follows pages for each calendar',
      () async {
    final requests = <Uri>[];
    final pageCounts = <String, int>{};
    final controller = CalendarScreenController(httpGet: (uri) async {
      requests.add(uri);
      final calendarId = uri.pathSegments[3];
      final page = (pageCounts[calendarId] ?? 0) + 1;
      pageCounts[calendarId] = page;
      final event = _birthdayOccurrence(
        page == 1 ? '2026-10-10' : '2026-10-11',
        'synthetic-${calendarId.hashCode}-$page',
      );
      if (page == 1) {
        return _eventsResponse(
          [event],
          nextPageToken: 'next-${calendarId.hashCode}',
        );
      }
      if (page == 2) return _eventsResponse([event]);
      throw StateError('Unexpected additional calendar page.');
    });

    await controller.fetchAllCalendars(
      DateTime(2026, 10),
      DateTime(2026, 11),
    );

    final calendarIds = requests.map((uri) => uri.pathSegments[3]).toSet();
    expect(calendarIds, hasLength(3));
    expect(requests, hasLength(6));
    expect(controller.publicEvents, hasLength(6));
    expect(
      requests.every((uri) =>
          uri.queryParameters['singleEvents'] == 'true' &&
          uri.queryParameters['orderBy'] == 'startTime' &&
          uri.queryParameters['maxResults'] == '250'),
      isTrue,
    );
    for (final calendarId in calendarIds) {
      final calendarRequests =
          requests.where((uri) => uri.pathSegments[3] == calendarId).toList();
      expect(calendarRequests, hasLength(2));
      expect(calendarRequests.map((uri) => uri.queryParameters['pageToken']),
          [null, 'next-${calendarId.hashCode}']);
    }
  });

  testWidgets('先発15名の見出しを保ち、リザーブ数は別見出しで表示する', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                MatchMemberCountHeader(label: 'Starting', count: 15),
                MatchMemberCountHeader(label: 'Reserves', count: 17),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Starting 15'), findsOneWidget);
    expect(find.text('Reserves 17'), findsOneWidget);
  });
}
