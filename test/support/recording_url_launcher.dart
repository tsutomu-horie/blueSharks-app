import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';

export 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart'
    show PreferredLaunchMode;

/// Records the requested mode while preserving existing method-channel mocks.
class RecordingUrlLauncher extends UrlLauncherPlatform {
  RecordingUrlLauncher() : _delegate = UrlLauncherPlatform.instance {
    UrlLauncherPlatform.instance = this;
  }

  final UrlLauncherPlatform _delegate;
  final modes = <PreferredLaunchMode>[];

  @override
  LinkDelegate? get linkDelegate => _delegate.linkDelegate;

  @override
  Future<bool> canLaunch(String url) => _delegate.canLaunch(url);

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) {
    modes.add(options.mode);
    return _delegate.launchUrl(url, options);
  }

  void restore() => UrlLauncherPlatform.instance = _delegate;
}
