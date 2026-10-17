import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/diagnostic_log.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// A log ready to hand over: what it came from, then the log itself.
class DiagnosticReport {
  DiagnosticReport._();

  /// [watchLog] is the paired watch's log when it was fetched; this device's
  /// own is read here.
  static Future<String> build({String? watchLog}) async {
    final out = StringBuffer()
      ..writeln('Pantry diagnostic log')
      ..writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}');
    try {
      final info = await PackageInfo.fromPlatform();
      out.writeln(
        'App: ${info.version} (${info.buildNumber}), '
        'installer: ${info.installerStore ?? 'unknown'}',
      );
    } catch (_) {}
    if (!kIsWeb) {
      out.writeln(
        'Platform: ${Platform.operatingSystem} '
        '${Platform.operatingSystemVersion}',
      );
    }
    out.writeln('Locale: ${LocaleService.instance.effectiveLocale}');
    final creds = AuthService.instance.credentials;
    final server = creds == null ? null : Uri.tryParse(creds.serverUrl);
    if (server != null) {
      // The shape of the address without the address: a scheme, port or
      // subpath that differs between devices is a common cause of trouble.
      out.writeln(
        'Server: ${server.scheme}, '
        'port ${server.hasPort ? server.port : 'default'}, '
        'path ${server.path.isEmpty ? '/' : server.path}',
      );
    }
    final versions = ServerVersionService.instance;
    out.writeln(
      'Nextcloud: ${versions.serverVersion ?? 'unknown'}, '
      'Pantry: ${versions.pantryVersion ?? 'unknown'}',
    );
    final sync = SyncManager.instance;
    out.writeln(
      'Sync: ${sync.status.value.name}, ${sync.pendingCount.value} queued',
    );
    final log = DiagnosticLog.instance;
    final report = StringBuffer(log.mask(out.toString()))
      ..writeln()
      ..writeln('--- This device ---')
      ..write(await log.read());
    if (watchLog != null) {
      report
        ..writeln()
        ..writeln('--- Watch ---')
        ..write(watchLog);
    }
    return report.toString();
  }
}
