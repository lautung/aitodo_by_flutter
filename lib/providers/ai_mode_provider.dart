import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiParseMode {
  remoteFirst,
  localFirst,
}

class AiModeProvider extends ChangeNotifier {
  static const String _modeKey = 'ai_parse_mode';

  AiParseMode _mode = AiParseMode.remoteFirst;

  AiParseMode get mode => _mode;
  bool get preferRemote => _mode == AiParseMode.remoteFirst;

  AiModeProvider() {
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_modeKey);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < AiParseMode.values.length) {
      _mode = AiParseMode.values[modeIndex];
      notifyListeners();
    }
  }

  Future<void> setMode(AiParseMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, mode.index);
  }
}
