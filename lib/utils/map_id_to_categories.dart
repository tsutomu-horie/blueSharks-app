import 'package:get/get.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';

List<String> mapCategoryIdsToNames(List<int> categoryIds) {
  // Define the mapping of category IDs to category names
  Map<int, String> categoryMap = {
    1: LocaleKeys.notice_tab.tr,
    33: LocaleKeys.event_information.tr,
    34: LocaleKeys.event_tab.tr,
    38: LocaleKeys.activites.tr,
    // Add more mappings as needed
  };

  return categoryIds
      .where((id) => categoryMap.containsKey(id))
      .map((id) => categoryMap[id]!)
      .toList();

  // // Check if the list contains ID 33. If it does, return all available category names.
  // if (categoryIds.contains(33)) {
  //   // Return all category names (excluding 33 itself if you want to avoid duplication).
  //   return categoryMap.values
  //       .where((name) => name != categoryMap[33]) // Remove '33' value
  //       .toList();
  // } else {
  //   // Otherwise, map the category IDs to their corresponding names.
  //   return categoryIds
  //       .map((id) => categoryMap[id] ?? LocaleKeys.other_jp.tr)
  //       .toList();
  // }
}
