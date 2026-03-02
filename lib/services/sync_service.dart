import '../models/sync_data.dart';

/// 同步服务接口
abstract class SyncService {
  /// 同步数据
  Future<SyncResult> sync(SyncData data);

  /// 获取远程数据
  Future<SyncData?> fetchRemoteData();

  /// 保存本地数据
  Future<void> saveLocalData(SyncData data);

  /// 检查连接状态
  Future<bool> isConnected();

  /// 获取设备ID
  String? get deviceId;
}
