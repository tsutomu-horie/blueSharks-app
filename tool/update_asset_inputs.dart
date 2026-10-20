import 'dart:convert';
import 'dart:io';

// These cover the existing registered asset trees. Resolution variants remain
// automatic Flutter inputs; only base assets belong in the generated list.
const assetInputRoots = ['assets/images', 'assets/vectors', 'assets/lottie'];
const assetInputsBegin = '    # BEGIN GENERATED ASSET INPUTS';
const assetInputsEnd = '    # END GENERATED ASSET INPUTS';
final _variantDirectory = RegExp(r'/?(\d+(\.\d*)?)x$');

List<String> discoverAssetInputs(Directory projectRoot) {
  final root = projectRoot.absolute;
  final prefix = root.path.endsWith(Platform.pathSeparator)
      ? root.path
      : '${root.path}${Platform.pathSeparator}';
  final paths = <String>{};
  for (final name in assetInputRoots) {
    final directory = Directory('$prefix$name');
    if (!directory.existsSync()) throw StateError('Missing asset tree: $name');
    for (final entity
        in directory.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = entity.path
          .substring(prefix.length)
          .split(Platform.pathSeparator)
          .join('/');
      if (relative
          .split('/')
          .any((part) => part.startsWith('._') || part == '.DS_Store')) {
        continue;
      }
      final parentName = entity.parent.path.split(Platform.pathSeparator).last;
      if (_variantDirectory.hasMatch(parentName)) {
        final base = File(
            '${entity.parent.parent.path}${Platform.pathSeparator}${entity.path.split(Platform.pathSeparator).last}');
        if (!base.existsSync()) {
          throw StateError('Resolution variant needs a base asset: $relative');
        }
        continue;
      }
      paths.add(relative);
    }
  }
  if (paths.isEmpty) throw StateError('No base assets found');
  return paths.toList()..sort();
}

String renderAssetInputBlock(Directory projectRoot) => [
      assetInputsBegin,
      '    # Regenerate after adding assets: dart tool/update_asset_inputs.dart --write',
      '    # Check without edits: dart tool/update_asset_inputs.dart --check',
      '    # Keep macOS ._ and .DS_Store metadata on disk, outside the asset inputs.',
      for (final path in discoverAssetInputs(projectRoot))
        '    - ${jsonEncode(Uri.file(path).toString())}',
      assetInputsEnd,
    ].join('\n');

String updateAssetInputBlock(String pubspec, Directory projectRoot) {
  final start = pubspec.indexOf(assetInputsBegin);
  final end = pubspec.indexOf(assetInputsEnd);
  if (start < 0 ||
      end < start ||
      pubspec.indexOf(assetInputsBegin, start + 1) >= 0 ||
      pubspec.indexOf(assetInputsEnd, end + 1) >= 0) {
    throw StateError('Expected exactly one generated asset input block');
  }
  return pubspec.replaceRange(
      start, end + assetInputsEnd.length, renderAssetInputBlock(projectRoot));
}

void main(List<String> args) {
  if (args.length != 1 || !['--check', '--write'].contains(args.single)) {
    stderr.writeln(
        'Run from the project root: dart tool/update_asset_inputs.dart --check|--write');
    exitCode = 64;
    return;
  }
  final projectRoot = Directory.current;
  final file = File('pubspec.yaml');
  final before = file.readAsStringSync();
  final after = updateAssetInputBlock(before, projectRoot);
  if (args.single == '--check') {
    if (before != after) {
      stderr.writeln(
          'Asset inputs changed. Run dart tool/update_asset_inputs.dart --write');
      exitCode = 1;
    } else {
      stdout.writeln(
          'Asset inputs are current (${discoverAssetInputs(projectRoot).length} base files).');
    }
  } else if (before != after) {
    file.writeAsStringSync(after);
    stdout.writeln(
        'Updated asset inputs (${discoverAssetInputs(projectRoot).length} base files).');
  }
}
