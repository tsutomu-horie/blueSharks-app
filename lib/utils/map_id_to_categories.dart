List<String> mapCategoryIdsToNames(List<int> categoryIds) {
  // Define the mapping of category IDs to category names
  Map<int, String> categoryMap = {
    33: 'Match Information',
    1: 'Notice',
    34: 'Event Information',
    39: 'Activities',
    15: 'Interview',
    // Add more mappings as needed
  };

  // Map the category IDs to their corresponding names
  return categoryIds.map((id) => categoryMap[id] ?? 'Unknown').toList();
}
