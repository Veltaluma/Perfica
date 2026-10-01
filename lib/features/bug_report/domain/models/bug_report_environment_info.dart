class BugReportEnvironmentInfo {
  const BugReportEnvironmentInfo({
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
  });

  final String appVersion;
  final String platform;
  final String osVersion;
  final String deviceModel;
}
