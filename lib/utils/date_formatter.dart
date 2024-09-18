import 'package:intl/intl.dart';

Map<String, String> convertJapaneseDate(String japaneseDate) {
  // Regular expression to extract the date and day of the week
  final RegExp dateRegExp = RegExp(r'(\d{4})年(\d{2})月(\d{2})日（(.+)）');

  // Extract year, month, day, and day of the week
  final match = dateRegExp.firstMatch(japaneseDate);

  if (match != null) {
    String year = match.group(1)!; // Extracted year
    String month = match.group(2)!; // Extracted month
    String day = match.group(3)!; // Extracted day
    String japaneseDayOfWeek = match.group(4)!; // Extracted day of the week in Japanese

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
      'dayOfWeek': '($englishDayOfWeek)'
    };
  } else {
    throw FormatException('Invalid Japanese date format');
  }
}