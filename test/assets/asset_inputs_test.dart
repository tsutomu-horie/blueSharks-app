import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/update_asset_inputs.dart' as inputs;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new subfolders are detected while metadata and variants stay implicit',
      () {
    final root = Directory.systemTemp.createTempSync('af90-asset-inputs-');
    addTearDown(() => root.deleteSync(recursive: true));
    for (final path in inputs.assetInputRoots) {
      Directory('${root.path}/$path').createSync(recursive: true);
    }
    void write(String path) {
      final file = File('${root.path}/$path');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync([1, 2, 3]);
    }

    write('assets/images/pose.png');
    write('assets/images/2.0x/pose.png');
    write('assets/images/._pose.png');
    write('assets/images/2.0x/._pose.png');
    write('assets/images/.DS_Store');
    write('assets/images/._folder/unused.png');
    expect(inputs.discoverAssetInputs(root), ['assets/images/pose.png']);
    const before = 'name: fixture\nflutter:\n  assets:\n'
        '${inputs.assetInputsBegin}\n${inputs.assetInputsEnd}\n'
        '# APP_ENV stays outside the managed block\n';
    final initial = inputs.updateAssetInputBlock(before, root);
    expect(initial, startsWith('name: fixture\nflutter:\n  assets:\n'));
    expect(initial, endsWith('# APP_ENV stays outside the managed block\n'));
    expect(inputs.updateAssetInputBlock(initial, root), initial);
    write('assets/images/new folder/icon #1.png');
    final changed = inputs.updateAssetInputBlock(initial, root);
    expect(changed, isNot(initial));
    expect(changed, contains('assets/images/new%20folder/icon%20%231.png'));
    expect(inputs.discoverAssetInputs(root).toSet().length, 2);
    write('assets/images/3.0x/orphan.png');
    expect(() => inputs.discoverAssetInputs(root), throwsStateError);
  });

  test('missing or repeated managed block markers are rejected', () {
    final root = Directory.current;
    expect(() => inputs.updateAssetInputBlock('flutter:\n', root),
        throwsStateError);
    expect(
        () => inputs.updateAssetInputBlock(
            '${inputs.assetInputsBegin}\n${inputs.assetInputsBegin}\n'
            '${inputs.assetInputsEnd}',
            root),
        throwsStateError);
  });

  test('asset additions require regenerating the explicit input list', () {
    final file = File('pubspec.yaml');
    expect(
        inputs.updateAssetInputBlock(
            file.readAsStringSync(), Directory.current),
        file.readAsStringSync(),
        reason:
            'Run dart tool/update_asset_inputs.dart --write after adding assets.');
  });

  test(
      'the real bundle has every base asset, variants, and no AppleDouble inputs',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest.listAssets();
    expect(
        all.where((key) => key.split('/').any((part) => part.startsWith('._'))),
        isEmpty);
    final managed = all
        .where((key) =>
            inputs.assetInputRoots.any((root) => key.startsWith('$root/')))
        .toSet();
    final expected = inputs.discoverAssetInputs(Directory.current).toSet();
    expect(managed, expected);
    final bundled = <String>{};
    for (final key in managed) {
      bundled.add(key);
      for (final variant
          in manifest.getAssetVariants(key) ?? <AssetMetadata>[]) {
        bundled.add(variant.key);
      }
    }
    final expectedFiles = <String>{};
    for (final tree in inputs.assetInputRoots) {
      for (final entity
          in Directory(tree).listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final path = entity.path.split(Platform.pathSeparator).join('/');
        if (path
            .split('/')
            .any((part) => part.startsWith('._') || part == '.DS_Store')) {
          continue;
        }
        expectedFiles.add(path);
      }
    }
    expect(bundled, expectedFiles,
        reason: 'Base assets and resolution variants must all remain bundled.');
    for (final key in bundled) {
      expect(key.split('/').any((part) => part.startsWith('._')), isFalse);
      final data = await rootBundle.load(key);
      expect(
          listEquals(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              File(key).readAsBytesSync()),
          isTrue,
          reason: 'Bundled bytes changed: $key');
    }
  });
}
