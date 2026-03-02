import 'package:ai_todo/services/ai_dispatcher_service.dart';
import 'package:ai_todo/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRemoteClient implements RemoteNlpClient {
  @override
  Future<ParsedTask?> parseTask(String text) async {
    throw Exception('remote failed');
  }
}

class _FixedRemoteClient implements RemoteNlpClient {
  @override
  Future<ParsedTask?> parseTask(String text) async {
    return ParsedTask(
      title: '远程解析任务',
      suggestedCategory: null,
    );
  }
}

class _CountingRemoteClient implements RemoteNlpClient {
  int callCount = 0;

  @override
  Future<ParsedTask?> parseTask(String text) async {
    callCount++;
    return ParsedTask(
      title: '远程解析任务',
      suggestedCategory: null,
    );
  }
}

void main() {
  group('AiDispatcherService', () {
    final dispatcher = AiDispatcherService();

    tearDown(() {
      dispatcher.setRemoteClient(null);
    });

    test('should fallback to local parser when remote throws', () async {
      dispatcher.setRemoteClient(_FailingRemoteClient());
      final parsed = await dispatcher.parseTask('明天完成报告', preferRemote: true);
      expect(parsed.title, isNotEmpty);
    });

    test('should use remote result when remote succeeds', () async {
      dispatcher.setRemoteClient(_FixedRemoteClient());
      final parsed = await dispatcher.parseTask('任意文本', preferRemote: true);
      expect(parsed.title, '远程解析任务');
    });

    test('should skip remote when preferRemote is false', () async {
      final countingRemote = _CountingRemoteClient();
      dispatcher.setRemoteClient(countingRemote);

      final parsed = await dispatcher.parseTask('明天完成报告', preferRemote: false);

      expect(countingRemote.callCount, 0);
      expect(parsed.title, isNotEmpty);
    });
  });
}
