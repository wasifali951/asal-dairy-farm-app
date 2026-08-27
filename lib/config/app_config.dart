import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  static const String _variantFromDefine = String.fromEnvironment(
    'APP_VARIANT',
    defaultValue: '',
  );

  static bool _isOwnerApp = _variantFromDefine == 'owner';

  static bool get isOwnerApp => _isOwnerApp;

  static Future<void> initialize() async {
    if (_variantFromDefine.isNotEmpty) {
      _isOwnerApp = _variantFromDefine == 'owner';
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _isOwnerApp = packageInfo.packageName.endsWith('.owner');
    } catch (_) {
      _isOwnerApp = false;
    }
  }
}
