import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Map<String, String> convertJapaneseDate(String japaneseDate) {
  try {
    // Regular expression to extract the date and day of the week
    final RegExp dateRegExp = RegExp(r'(\d{4})年(\d{2})月(\d{2})日（(.+)）');
    debugPrint("convertData to = $japaneseDate");

    // Extract year, month, day, and day of the week
    final match = dateRegExp.firstMatch(japaneseDate);

    if (match != null) {
      String year = match.group(1)!; // Extracted year
      String month = match.group(2)!; // Extracted month
      String day = match.group(3)!; // Extracted day
      String japaneseDayOfWeek = match.group(
          4)!; // Extracted day of the week in Japanese

      // Create a DateTime object
      DateTime parsedDate = DateTime.parse('$year-$month-$day');

      // Format the date to "yyyy/MM/dd"
      String formattedDate = DateFormat('yyyy/MM/dd').format(parsedDate);

      // Map Japanese day of the week to English
      Map<String, String> dayOfWeekMap = {
        '月': 'Mon',
        '火': 'Tue',
        '水': 'Wed',
        '木': 'Thu',
        '金': 'Fri',
        '土': 'Sat',
        '日': 'Sun',
      };

      // Convert the Japanese day of the week to English
      String englishDayOfWeek = dayOfWeekMap[japaneseDayOfWeek] ?? '';

      // Return a map with separate variables
      return {
        'formattedDate': formattedDate,
        'dayOfWeek': '$englishDayOfWeek'
      };
    } else {
      throw FormatException('Invalid Japanese date format');
    }
  } catch (e) {
    return {'formattedDate' : "", "dayOfWeek": ""};
  }
}

Future<String>  convertToJapaneseFormat(String dateString) async {
  // Parse the input string into a DateTime object
  await initializeDateFormatting('ja', null);

  // Parse the input string into a DateTime object
  DateTime dateTime = DateTime.parse(dateString);

  // Manual formatting to add 年, 月, 日 symbols
  String year = DateFormat.y('ja').format(dateTime);
  String month = DateFormat.M('ja').format(dateTime);
  String day = DateFormat.d('ja').format(dateTime);

  return '$year $month $day';
}