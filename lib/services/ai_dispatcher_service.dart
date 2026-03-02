import 'ai_service.dart';

abstract class RemoteNlpClient {
  Future<ParsedTask?> parseTask(String text);
}

class AiDispatcherService {
  static final AiDispatcherService _instance = AiDispatcherService._internal();
  factory AiDispatcherService() => _instance;
  AiDispatcherService._internal();

  final NLPService _localNlpService = NLPService();
  RemoteNlpClient? _remoteClient;

  void setRemoteClient(RemoteNlpClient? client) {
    _remoteClient = client;
  }

  Future<ParsedTask> parseTask(
    String text, {
    bool preferRemote = true,
  }) async {
    if (preferRemote && _remoteClient != null) {
      try {
        final remoteResult = await _remoteClient!.parseTask(text);
        if (remoteResult != null && remoteResult.title.trim().isNotEmpty) {
          return remoteResult;
        }
      } catch (_) {
        // 远程失败时降级到本地规则引擎。
      }
    }
    return _localNlpService.parseTask(text);
  }
}

