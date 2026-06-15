import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataService {
  static const Set<String> _userDataKeys = {
    'tasks',
    'deleted_tasks',
    'custom_tags',
    'custom_priorities',
    'chat_messages',
    'pomodoro_history',
    'ai_parse_mode',
    'daily_summary_enabled',
    'daily_summary_hour',
    'daily_summary_minute',
    'theme_mode',
    'theme_color',
    'device_id',
  };

  Future<void> clearUserData({bool keepComplianceConsent = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final keepAgreement = keepComplianceConsent
        ? prefs.getBool('agreement_accepted_v1')
        : null;

    for (final key in _userDataKeys) {
      await prefs.remove(key);
    }

    if (keepAgreement != null) {
      await prefs.setBool('agreement_accepted_v1', keepAgreement);
    } else if (!keepComplianceConsent) {
      await prefs.remove('agreement_accepted_v1');
    }

    await _deleteLocalSyncBackup();
  }

  Future<void> _deleteLocalSyncBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/aitodo_sync_backup.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Clearing SharedPreferences is the critical path; backup cleanup is best effort.
    }
  }
}
