import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/views/views/member_card_view.dart';

void main() {
  test('profile decoding accepts old API responses without qualification', () {
    final profile = UserData.fromJson({
      'account_id': 'SYNTHETIC-OLD',
      'created_at': '2026-10-28T00:00:00Z',
      'email': 'old@example.test',
      'id': 1,
      'is_verified': true,
    });

    expect(profile.qualification, isNull);
  });

  test('profile decoding reads the added qualification object', () {
    final profile = UserData.fromJson({
      'account_id': 'SYNTHETIC-NEW',
      'created_at': '2026-10-28T00:00:00Z',
      'email': 'new@example.test',
      'id': 2,
      'is_verified': true,
      'qualification': {
        'status': 'active',
        'valid_from': '2026-10-01',
        'valid_to': '2026-10-28',
      },
    });

    expect(profile.qualification?.status, 'active');
    expect(profile.qualification?.validFrom, '2026-10-01');
    expect(profile.qualification?.validTo, '2026-10-28');
  });

  testWidgets('summary displays missing, current, expired and future dates',
      (tester) async {
    const scenarios = [
      (
        qualification: MemberQualification(
          status: 'active',
          validFrom: null,
          validTo: null,
        ),
        status: '有効',
        dates: '開始日：未登録 / 有効期限：未登録',
      ),
      (
        qualification: MemberQualification(
          status: 'active',
          validFrom: '2026-10-01',
          validTo: '2026-10-28',
        ),
        status: '有効',
        dates: '開始日：2026/10/01 / 有効期限：2026/10/28',
      ),
      (
        qualification: MemberQualification(
          status: 'expired',
          validFrom: null,
          validTo: '2026-10-27',
        ),
        status: '期限切れ',
        dates: '開始日：未登録 / 有効期限：2026/10/27',
      ),
      (
        qualification: MemberQualification(
          status: 'pending',
          validFrom: '2026-10-29',
          validTo: null,
        ),
        status: '開始前',
        dates: '開始日：2026/10/29 / 有効期限：未登録',
      ),
    ];

    for (final scenario in scenarios) {
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: MemberQualificationSummary(
              qualification: scenario.qualification,
            ),
          ),
        ),
      ));

      expect(find.text('資格状態：${scenario.status}'), findsOneWidget);
      expect(find.text(scenario.dates), findsOneWidget);
    }
  });
}
