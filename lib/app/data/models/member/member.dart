import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
@HiveType(typeId: 1)
class Member with _$Member {
  factory Member({
    @HiveField(0)
    required int id,
    @HiveField(1)
    required String date,
    @HiveField(2)
    required String modified,
    @HiveField(3)
    required String slug,
    @HiveField(4)
    required String status,
    @HiveField(5)
    required String type,
    @HiveField(6)
    required String link,
    @HiveField(7)
    required Title title,
    @HiveField(12)
    String? playerNameKatakana,
    @HiveField(8)
    required int? categoryId,
    @HiveField(9)
    required String? categorySlug,
    @HiveField(10)
    required String? categoryName,
    @HiveField(11)
    required CustomField? custom_field,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}

@freezed
@HiveType(typeId: 2)
//menampung seluruh data mulai dari nama member sampai posisi
class CombineMember with _$CombineMember {
  factory CombineMember({
    @HiveField(0)
    required String playerName,
    @HiveField(1)
    required String position,   // e.g., hooker, scrumhalf, etc.
    @HiveField(2)
    required String parentPosition,  // e.g., forward, back, staff
    @HiveField(3)
    required int id, // Player ID
  }) = _CombineMember;

  factory CombineMember.fromJson(Map<String, dynamic> json) => _$CombineMemberFromJson(json);
}

class MemberGroup {
  final String title;
  final List<Member> players;

  MemberGroup({required this.title, required this.players});
}

class CategorizedPlayerGroup {
  final String categoryTitle; // "Forward", "Back", or "Staff"
  final List<MemberGroup> playerGroups; // List of groups (e.g. Prop, Hooker under Forward)

  CategorizedPlayerGroup({required this.categoryTitle, required this.playerGroups});
}