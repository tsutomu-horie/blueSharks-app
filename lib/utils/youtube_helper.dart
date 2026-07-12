String? getYouTubeThumbnailUrl(String? youtubeUrl) {
  if (youtubeUrl == null) return null;

  // Extract video ID from different YouTube URL formats
  String? videoId;

  // Format: https://youtube.com/embed/VIDEO_ID
  if (youtubeUrl.contains('/embed/')) {
    videoId = youtubeUrl.split('/embed/')[1];
    // Remove any additional parameters
    videoId = videoId.split('?').first;
  }
  // Format: https://www.youtube.com/watch?v=VIDEO_ID
  else if (youtubeUrl.contains('watch?v=')) {
    videoId = Uri.parse(youtubeUrl).queryParameters['v'];
  }
  // Format: https://youtu.be/VIDEO_ID
  else if (youtubeUrl.contains('youtu.be/')) {
    videoId = youtubeUrl.split('youtu.be/')[1];
    videoId = videoId.split('?').first;
  }

  print("retrun https://img.youtube.com/vi/$videoId/hqdefault.jpg");
  if (videoId == null) return null;

  // Return high quality thumbnail URL
  return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}