import 'package:flutter/foundation.dart';
import '../models/sync_data.dart';
import '../models/task.dart';
import '../models/task_group.dart';
import '../services/sync_service.dart';
import '../services/local_sync_provider.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;

  SyncStatus _status = SyncStatus.idle;
  SyncResult? _lastResult;
  DateTime? _lastSyncTime;
  ConflictStrategy _conflictStrategy = ConflictStrategy.newerWins;

  SyncProvider({SyncService? syncService})
      : _syncService = syncService ?? LocalSyncProvider();

  SyncStatus get status => _status;
  SyncResult? get lastResult => _lastResult;
  DateTime? get lastSyncTime => _lastSyncTime;
  ConflictStrategy get conflictStrategy => _conflictStrategy;
  bool get isSyncing => _status == SyncStatus.syncing;

  void setConflictStrategy(ConflictStrategy strategy) {
    _conflictStrategy = strategy;
    notifyListeners();
  }

  /// 执行同步
  Future<void> sync({
    required List<Task> tasks,
    required List<Task> deletedTasks,
    required List<TaskGroup> taskGroups,
    required List<CustomTag> tags,
  }) async {
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      // 创建同步数据
      final localData = SyncData(
        tasks: tasks,
        deletedTasks: deletedTasks,
        taskGroups: taskGroups,
        tags: tags,
        lastModified: DateTime.now(),
        deviceId: _syncService.deviceId,
      );

      // 获取远程数据
      final remoteData = await _syncService.fetchRemoteData();

      // 如果远程有数据，进行冲突解决
      SyncData finalData;
      if (remoteData != null) {
        finalData = _resolveConflict(localData, remoteData);
      } else {
        finalData = localData;
      }

      // 执行同步
      final result = await _syncService.sync(finalData);

      if (result.success) {
        _status = SyncStatus.success;
        _lastSyncTime = DateTime.now();
        _lastResult = result;
      } else {
        _status = SyncStatus.error;
        _lastResult = result;
      }
    } catch (e) {
      _status = SyncStatus.error;
      _lastResult = SyncResult.failure(e.toString());
    }

    notifyListeners();
  }

  /// 冲突解决
  SyncData _resolveConflict(SyncData local, SyncData remote) {
    switch (_conflictStrategy) {
      case ConflictStrategy.localWins:
        return local;
      case ConflictStrategy.remoteWins:
        return remote;
      case ConflictStrategy.newerWins:
        if (local.lastModified.isAfter(remote.lastModified)) {
          return local;
        } else {
          return remote;
        }
    }
  }

  /// 获取远程数据
  Future<SyncData?> fetchRemoteData() async {
    return _syncService.fetchRemoteData();
  }

  /// 检查连接状态
  Future<bool> isConnected() async {
    return _syncService.isConnected();
  }

  /// 重置状态
  void reset() {
    _status = SyncStatus.idle;
    _lastResult = null;
    notifyListeners();
  }
}
