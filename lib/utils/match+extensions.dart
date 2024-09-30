/*
  * This Function will return isHome, opponentLogo, opponentName
  * */
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

Map<String, dynamic> getStatusMatch(CustomField customField) {
  final team1 = customField.team_1 ?? [];
  final team2 = customField.team_2 ?? [];
  final team2Logo = customField.team_logo_2 ?? [];
  final team1Logo = customField.team_logo_1 ?? [];

  try {
    final isHome = team1.first.contains(Constants.teamName);
    print("get status ${isHome} ${team1.first}");
    if (isHome) {
      return {
        'isHome': true,
        'opponentLogo': team2Logo.first,
        'opponentName': team2.first,
        'teamName': team1.first,
        'teamLogo': team1Logo.first,

      };
    } else {
      return {
        'isHome': false,
        'opponentLogo': customField.team_logo_1?.first,
        'opponentName': team1.first,
        'teamName': team2.first,
        'teamLogo': team2Logo.first,
      };
    }
  } catch (e) {
    return {
      'isHome': false,
      'opponentLogo': customField.team_logo_1?.first,
      'opponentName': "",
    };
  }
}