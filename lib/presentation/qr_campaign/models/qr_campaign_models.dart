enum QrCampaignStatus { draft, scheduled, active, adjustment, needsReview }

extension QrCampaignStatusLabel on QrCampaignStatus {
  String get label {
    switch (this) {
      case QrCampaignStatus.draft:
        return '下書き';
      case QrCampaignStatus.scheduled:
        return '公開予定';
      case QrCampaignStatus.active:
        return '公開中';
      case QrCampaignStatus.adjustment:
        return '調整値';
      case QrCampaignStatus.needsReview:
        return '要確認';
    }
  }
}

class QrCampaign {
  const QrCampaign({
    required this.id,
    required this.name,
    required this.points,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.maxPerMember,
    required this.offlineReception,
    required this.readMode,
  });

  final String id;
  final String name;
  final String points;
  final String startAt;
  final String endAt;
  final QrCampaignStatus status;
  final String maxPerMember;
  final String offlineReception;
  final String readMode;

  String get period => '$startAt〜$endAt';

  QrCampaign copyWith({
    String? id,
    String? name,
    String? points,
    String? startAt,
    String? endAt,
    QrCampaignStatus? status,
    String? maxPerMember,
    String? offlineReception,
    String? readMode,
  }) {
    return QrCampaign(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      maxPerMember: maxPerMember ?? this.maxPerMember,
      offlineReception: offlineReception ?? this.offlineReception,
      readMode: readMode ?? this.readMode,
    );
  }
}
