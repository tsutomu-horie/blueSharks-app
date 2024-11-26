// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// class WallpaperPreferences {
//   final _storage = const FlutterSecureStorage();
//
//   Future<void> saveWallpaper(String wallpaper) async {
//     print("userWallpaper is ${wallpaper}");
//     await _storage.write(key: 'userWallpaper', value: wallpaper);
//   }
//
//   Future<String?> getWallpaper() async {
//     String? wallpaper = await _storage.read(key: 'userWallpaper');
//
//     if (wallpaper != null){
//       return wallpaper;
//     }
//
//     return null;
//   }
//
//   Future<void> deleteWallpaper() async {
//     return await _storage.delete(key: 'userWallpaper');
//   }
// }
