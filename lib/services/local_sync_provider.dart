import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sync_data.dart';
import 'sync_service.dart';

/// 本地同步提供者（模拟云同步到本地文件）
class LocalSyncProvider implements SyncService {
  static const String _deviceIdKey = 'device_id';
  static const String _syncFileName = 'aitodo_sync_backup.json';

  String? _deviceId;

  @override
  String? get deviceId => _deviceId;

  LocalSyncProvider() {
    _initDeviceId();
  }

  Future<void> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
  }

  Future<File> get _syncFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_syncFileName');
  }

  @override
  Future<bool> isConnected() async {
    // 本地同步始终可用
    return true;
  }

  @override
  Future<SyncResult> sync(SyncData data) async {
    try {
      // 保存到本地文件
      await saveLocalData(data);
      return SyncResult.success(data: data);
    } catch (e) {
      return SyncResult.failure('同步失败: $e');
    }
  }

  @override
  Future<SyncData?> fetchRemoteData() async {
    try {
      final file = await _syncFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return SyncData.fromJsonString(contents);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveLocalData(SyncData data) async {
    final file = await _syncFile;
    await file.writeAsString(data.toJsonString());
  }
}
