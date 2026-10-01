import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/models/bug_report_environment_info.dart';

class BugReportEnvironmentService {
  Future<BugReportEnvironmentInfo> load() async {
    var appVersion = 'Unknown';
    var platform = platformName(defaultTargetPlatform);
    var osVersion = 'Unknown';
    var deviceModel = 'Unknown';

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();

      if (version.isNotEmpty) {
        appVersion = buildNumber.isEmpty
            ? version
            : '$version (build $buildNumber)';
      }
    } catch (_) {
      // Environment information is best-effort.
    }

    try {
      final deviceInfo = DeviceInfoPlugin();

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await deviceInfo.androidInfo;

          platform = 'Android';

          final release = info.version.release.trim();

          osVersion = release.isEmpty
              ? 'Android (API ${info.version.sdkInt})'
              : 'Android $release (API ${info.version.sdkInt})';

          final manufacturer = info.manufacturer.trim();
          final model = info.model.trim();

          final deviceParts = <String>[
            if (manufacturer.isNotEmpty) manufacturer,
            if (model.isNotEmpty) model,
          ];

          deviceModel = deviceParts.isEmpty
              ? 'Android device'
              : deviceParts.join(' ');

          if (!info.isPhysicalDevice) {
            deviceModel = '$deviceModel (emulator)';
          }

        case TargetPlatform.iOS:
          final info = await deviceInfo.iosInfo;

          platform = 'iOS';

          final systemName = info.systemName.trim();
          final systemVersion = info.systemVersion.trim();

          osVersion = [
            if (systemName.isNotEmpty) systemName,
            if (systemVersion.isNotEmpty) systemVersion,
          ].join(' ');

          if (osVersion.isEmpty) {
            osVersion = 'iOS';
          }

          final model = info.model.trim();
          final machine = info.utsname.machine.trim();

          final deviceParts = <String>[
            if (model.isNotEmpty) model,
            if (machine.isNotEmpty) '($machine)',
          ];

          deviceModel = deviceParts.isEmpty
              ? 'iOS device'
              : deviceParts.join(' ');

          if (!info.isPhysicalDevice) {
            deviceModel = '$deviceModel (simulator)';
          }

        case TargetPlatform.macOS:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          break;
      }
    } catch (_) {
      // Device details must never prevent a bug report.
    }

    return BugReportEnvironmentInfo(
      appVersion: appVersion,
      platform: platform,
      osVersion: osVersion,
      deviceModel: deviceModel,
    );
  }

  static String platformName(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}
