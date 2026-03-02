import 'package:ai_todo/providers/ai_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AiModeProvider', () {
    test('should default to remoteFirst when no saved value', () async {
      SharedPreferences.setMockInitialValues({});

      final provider = AiModeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.mode, AiParseMode.remoteFirst);
      expect(provider.preferRemote, isTrue);
    });

    test('should load localFirst from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'ai_parse_mode': AiParseMode.localFirst.index,
      });

      final provider = AiModeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.mode, AiParseMode.localFirst);
      expect(provider.preferRemote, isFalse);
    });

    test('setMode should persist value', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AiModeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await provider.setMode(AiParseMode.localFirst);
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getInt('ai_parse_mode'), AiParseMode.localFirst.index);
    });
  });
}
