import 'package:get/get.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';

List<String> mapCategoryIdsToNames(List<int> categoryIds) {
  // Define the mapping of category IDs to category names
  Map<int, String> categoryMap = {
    33: LocaleKeys.all.tr,
    1: LocaleKeys.notice_tab.tr,
    34: LocaleKeys.event_information.tr,
    39:  LocaleKeys.event_tab.tr,
    15: LocaleKeys.activites.tr,
    // Add more mappings as needed
  };

  // Map the category IDs to their corresponding names
  return categoryIds.map((id) => categoryMap[id] ?? LocaleKeys.other_jp.tr).toList();
}
