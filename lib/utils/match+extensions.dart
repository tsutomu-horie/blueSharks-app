/*
  * This Function will return isHome, opponentLogo, opponentName
  * */
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/providers/match/match_provider.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
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

Future<Map<String, String>> getAdditionalInfo(MediaProvider mediaProvider, MatchProvider matchProvider, String mediaId, String gameSerialId) async {

  try {
    final imageData = await mediaProvider.fetchMedia(mediaId);
    final image = imageData.media_details.sizes.thumbnail.source_url;
    print("there is error2 ${image}");
    final matchStatus = gameSerialId != "" ? await matchProvider.getMatchStatus(gameSerialId) : Rendered(rendered: "");
    print("there is error1 ${matchStatus}");
    return {
      'image': image,
      'matchStatus': matchStatus.rendered
    };
  } catch (e) {
    print("there is error ${e}");
    return {
      'image': "",
      'matchStatus': ""
    };
  }
}

Future<String> getImage(MediaProvider mediaProvider, String mediaId, {int retries = 5}) async {
  print("getAdditional2 ${mediaId}");

  for (int attempt = 0; attempt < retries; attempt++) {
    try {
      final imageData = await mediaProvider.fetchMedia(mediaId);
      print("getAdditional1 ${imageData}");

      // Assuming imageData is not null and has the expected structure
      final image = imageData.media_details.sizes.full.source_url;

      if (mediaId == "20160") {
        print("getImagexx ${image}");
      }

      return image; // Return the fetched image URL
    } catch (e) {
      print("Attempt ${attempt + 1} failed: $e");
      if (attempt == retries - 1) {
        // If this was the last attempt, return an empty string or a placeholder
        return ""; // You can also return a placeholder image URL here
      }
      // Optionally, wait before retrying
      await Future.delayed(Duration(seconds: 1)); // Wait 1 second before retrying
    }
  }

  return ""; // Fallback in case of failure
}