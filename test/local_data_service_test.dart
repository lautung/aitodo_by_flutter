import 'package:ai_todo/services/compliance_service.dart';
import 'package:ai_todo/services/local_data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalDataService', () {
    test(
      'clearUserData removes user data and keeps agreement by default',
      () async {
        SharedPreferences.setMockInitialValues({
          'tasks': '[]',
          'deleted_tasks': '[]',
          'custom_tags': '[]',
          'custom_priorities': '[]',
          'chat_messages': '[]',
          'pomodoro_history': '[]',
          'ai_parse_mode': 1,
          'daily_summary_enabled': true,
          'theme_mode': 1,
          ComplianceService.agreementAcceptedKey: true,
        });

        await LocalDataService().clearUserData();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tasks'), isNull);
        expect(prefs.getString('deleted_tasks'), isNull);
        expect(prefs.getString('custom_tags'), isNull);
        expect(prefs.getString('chat_messages'), isNull);
        expect(prefs.getString('pomodoro_history'), isNull);
        expect(prefs.getInt('ai_parse_mode'), isNull);
        expect(prefs.getBool('daily_summary_enabled'), isNull);
        expect(prefs.getInt('theme_mode'), isNull);
        expect(prefs.getBool(ComplianceService.agreementAcceptedKey), isTrue);
      },
    );
  });
}
