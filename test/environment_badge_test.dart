import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/views/views/environment_badge.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';

void main() {
  testWidgets('selected environment is visible above navigation and dialogs',
      (tester) async {
    AppEnvironment.validate();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => EnvironmentBadge(child: child!),
      home: Builder(builder: (context) {
        return Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(content: Text('Dialog')),
            ),
            child: const Text('Open'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsOneWidget);
    if (AppEnvironment.usesProductionServices) {
      expect(find.byType(Banner), findsNothing);
    } else {
      final banner = tester.widget<Banner>(find.byType(Banner));
      expect(banner.message, 'DEBUG');
      expect(banner.color, const Color(0xA0B71C1C));
      expect(banner.location, BannerLocation.topEnd);
      expect(
          find.ancestor(of: find.text('Dialog'), matching: find.byType(Banner)),
          findsOneWidget);
    }
    expect(find.byType(CheckedModeBanner), findsNothing);
  });
}
