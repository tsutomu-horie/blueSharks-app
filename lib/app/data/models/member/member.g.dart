// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberAdapter extends TypeAdapter<Member> {
  @override
  final int typeId = 1;

  @override
  Member read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Member(
      id: fields[0] as int,
      date: fields[1] as String,
      modified: fields[2] as String,
      slug: fields[3] as String,
      status: fields[4] as String,
      type: fields[5] as String,
      link: fields[6] as String,
      title: fields[7] as Title,
      playerNameKatakana: fields[12] as String?,
      categoryId: fields[8] as int?,
      categorySlug: fields[9] as String?,
      categoryName: fields[10] as String?,
      custom_field: fields[11] as CustomField?,
    );
  }

  @override
  void write(BinaryWriter writer, Member obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.modified)
      ..writeByte(3)
      ..write(obj.slug)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.link)
      ..writeByte(7)
      ..write(obj.title)
      ..writeByte(12)
      ..write(obj.playerNameKatakana)
      ..writeByte(8)
      ..write(obj.categoryId)
      ..writeByte(9)
      ..write(obj.categorySlug)
      ..writeByte(10)
      ..write(obj.categoryName)
      ..writeByte(11)
      ..write(obj.custom_field);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CombineMemberAdapter extends TypeAdapter<CombineMember> {
  @override
  final int typeId = 2;

  @override
  CombineMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CombineMember(
      playerName: fields[0] as String,
      position: fields[1] as String,
      parentPosition: fields[2] as String,
      id: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CombineMember obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.playerName)
      ..writeByte(1)
      ..write(obj.position)
      ..writeByte(2)
      ..write(obj.parentPosition)
      ..writeByte(3)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombineMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MemberImpl _$$MemberImplFromJson(Map<String, dynamic> json) => _$MemberImpl(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      modified: json['modified'] as String,
      slug: json['slug'] as String,
      status: json['status'] as String,
      type: json['type'] as String,
      link: json['link'] as String,
      title: Title.fromJson(json['title'] as Map<String, dynamic>),
      playerNameKatakana: json['playerNameKatakana'] as String?,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categorySlug: json['categorySlug'] as String?,
      categoryName: json['categoryName'] as String?,
      custom_field: json['custom_field'] == null
          ? null
          : CustomField.fromJson(json['custom_field'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MemberImplToJson(_$MemberImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'modified': instance.modified,
      'slug': instance.slug,
      'status': instance.status,
      'type': instance.type,
      'link': instance.link,
      'title': instance.title,
      'playerNameKatakana': instance.playerNameKatakana,
      'categoryId': instance.categoryId,
      'categorySlug': instance.categorySlug,
      'categoryName': instance.categoryName,
      'custom_field': instance.custom_field,
    };

_$CombineMemberImpl _$$CombineMemberImplFromJson(Map<String, dynamic> json) =>
    _$CombineMemberImpl(
      playerName: json['playerName'] as String,
      position: json['position'] as String,
      parentPosition: json['parentPosition'] as String,
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$$CombineMemberImplToJson(_$CombineMemberImpl instance) =>
    <String, dynamic>{
      'playerName': instance.playerName,
      'position': instance.position,
      'parentPosition': instance.parentPosition,
      'id': instance.id,
    };
