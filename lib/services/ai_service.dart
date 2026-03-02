import '../models/task.dart';

/// AI服务层 - 本地规则引擎
/// 提供自然语言解析、智能分类、任务摘要等功能

/// 自然语言解析结果
class ParsedTask {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final Priority? priority;
  final TaskCategory? suggestedCategory;

  ParsedTask({
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.suggestedCategory,
  });

  bool get hasDate => dueDate != null;
  bool get hasPriority => priority != null;
  bool get hasCategory => suggestedCategory != null;
}

/// NLP服务 - 自然语言解析
class NLPService {
  /// 解析日期
  /// 支持：今天、明天、后天、下周X、本周五、3天后、2024-01-01等
  DateTime? parseDate(String text) {
    final lowerText = text.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 尝试解析具体日期格式
    final datePatterns = [
      // 2024-01-01 或 2024/01/01 格式
      RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'),
      // 1月1日 或 1月1号 格式
      RegExp(r'(\d{1,2})月(\d{1,2})(?:日|号)?'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (match.groupCount >= 3) {
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else if (match.groupCount >= 2) {
            final month = int.parse(match.group(1)!);
            final day = int.parse(match.group(2)!);
            return DateTime(now.year, month, day);
          }
        } catch (_) {
          // 解析失败，继续其他模式
        }
      }
    }

    // 相对日期解析
    if (lowerText.contains('今天') || lowerText.contains('今日')) {
      return today;
    }
    if (lowerText.contains('明天') || lowerText.contains('明日')) {
      return today.add(const Duration(days: 1));
    }
    if (lowerText.contains('后天')) {
      return today.add(const Duration(days: 2));
    }

    // X天后
    final afterMatch = RegExp(r'(\d+)天后').firstMatch(lowerText);
    if (afterMatch != null) {
      final days = int.tryParse(afterMatch.group(1)!);
      if (days != null) {
        return today.add(Duration(days: days));
      }
    }

    // 周X 相关解析
    final weekDays = {
      '周一': 1, '星期一': 1,
      '周二': 2, '星期二': 2,
      '周三': 3, '星期三': 3,
      '周四': 4, '星期四': 4,
      '周五': 5, '星期五': 5,
      '周六': 6, '星期六': 6,
      '周日': 7, '星期天': 7, '周末': 6,
    };

    for (final entry in weekDays.entries) {
      if (lowerText.contains(entry.key)) {
        final targetWeekday = entry.value;
        final currentWeekday = now.weekday;

        int daysToAdd;
        if (lowerText.contains('下')) {
          // 下周一、下周二等
          if (targetWeekday >= currentWeekday) {
            daysToAdd = 7 - currentWeekday + targetWeekday;
          } else {
            daysToAdd = targetWeekday - currentWeekday + 7;
          }
        } else {
          // 本周一等
          if (targetWeekday >= currentWeekday) {
            daysToAdd = targetWeekday - currentWeekday;
          } else {
            daysToAdd = 7 - currentWeekday + targetWeekday;
          }
        }
        return today.add(Duration(days: daysToAdd));
      }
    }

    return null;
  }

  /// 解析优先级
  Priority? parsePriority(String text) {
    final lowerText = text.toLowerCase();

    // 先匹配低优先级，避免“不急”被“急”误判为高优先级。
    final lowPriorityKeywords = ['不急', '低优先级', '慢慢来', '有空再做', '随意'];
    for (final keyword in lowPriorityKeywords) {
      if (lowerText.contains(keyword)) {
        return Priority.low;
      }
    }

    // 高优先级关键词
    final highPriorityKeywords = ['紧急', '重要', '立即', '马上', '高优先级', '急', '十万火急'];
    for (final keyword in highPriorityKeywords) {
      if (lowerText.contains(keyword)) {
        return Priority.high;
      }
    }

    return null;
  }

  /// 解析完整任务
  ParsedTask parseTask(String text) {
    // 去除常见前缀
    var cleanText = text
        .replaceAll(RegExp(r'^(创建|添加|新建|帮我)?(一个?)?任务[：:]?'), '')
        .trim();

    // 提取截止日期
    final dueDate = parseDate(cleanText);

    // 提取优先级
    final priority = parsePriority(cleanText);

    // 智能分类建议
    final suggestedCategory = ClassificationService.suggestCategory(cleanText, null);

    // 提取标题和描述
    // 格式：标题 - 描述 或 标题：描述
    String? description;
    String title = cleanText;

    final separatorMatch = RegExp(r'^(.+?)[-：:](.+)$').firstMatch(cleanText);
    if (separatorMatch != null) {
      title = separatorMatch.group(1)!.trim();
      description = separatorMatch.group(2)!.trim();
    }

    // 去除已解析的日期和优先级关键词作为标题
    if (dueDate != null) {
      title = title
          .replaceAll(RegExp(r'(今天|明天|后天|下?周[一二三四五六日天])'), '')
          .replaceAll(RegExp(r'\d+天后'), '')
          .replaceAll(RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}'), '')
          .replaceAll(RegExp(r'\d{1,2}月\d{1,2}(?:日|号)?'), '')
          .trim();
    }

    if (priority != null) {
      title = title
          .replaceAll(RegExp(r'(紧急|重要|高优先级|急|不急|低优先级)'), '')
          .trim();
    }

    // 清理多余符号
    title = title.replaceAll(RegExp(r'^[-：:\s]+'), '').trim();
    if (title.isEmpty) {
      title = cleanText;
    }

    return ParsedTask(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      suggestedCategory: suggestedCategory,
    );
  }
}

/// 分类服务 - 智能分类建议
class ClassificationService {
  static const Map<String, TaskCategory> categoryKeywords = {
    // 工作相关
    '工作': TaskCategory.work,
    '上班': TaskCategory.work,
    '会议': TaskCategory.work,
    '项目': TaskCategory.work,
    '报告': TaskCategory.work,
    '方案': TaskCategory.work,
    'PPT': TaskCategory.work,
    '文档': TaskCategory.work,
    '邮件': TaskCategory.work,
    '客户': TaskCategory.work,
    '老板': TaskCategory.work,
    '同事': TaskCategory.work,
    '面试': TaskCategory.work,
    '辞职': TaskCategory.work,
    '加班': TaskCategory.work,

    // 学习相关
    '学习': TaskCategory.study,
    '考试': TaskCategory.study,
    '课程': TaskCategory.study,
    '作业': TaskCategory.study,
    '论文': TaskCategory.study,
    '复习': TaskCategory.study,
    '读书': TaskCategory.study,
    '培训': TaskCategory.study,
    '上课': TaskCategory.study,
    '自学': TaskCategory.study,
    '考研': TaskCategory.study,

    // 生活相关
    '生活': TaskCategory.life,
    '吃饭': TaskCategory.life,
    '做饭': TaskCategory.life,
    '购物': TaskCategory.life,
    '买': TaskCategory.life,
    '快递': TaskCategory.life,
    '家务': TaskCategory.life,
    '卫生': TaskCategory.life,
    '洗衣服': TaskCategory.life,
    '锻炼': TaskCategory.life,
    '运动': TaskCategory.life,
    '健身': TaskCategory.life,
    '跑步': TaskCategory.life,
    '看病': TaskCategory.life,
    '体检': TaskCategory.life,
    '约会': TaskCategory.life,
    '旅行': TaskCategory.life,
    '旅游': TaskCategory.life,
    '回家': TaskCategory.life,
    '看父母': TaskCategory.life,
  };

  /// 根据任务内容推荐分类
  static TaskCategory suggestCategory(String title, String? description) {
    final text = '$title ${description ?? ''}'.toLowerCase();

    int maxScore = 0;
    TaskCategory bestCategory = TaskCategory.other;

    for (final entry in categoryKeywords.entries) {
      if (text.contains(entry.key)) {
        // 首次匹配给基础分，后续匹配累加
        final score = text.split(entry.key).length - 1;
        if (score > maxScore) {
          maxScore = score;
          bestCategory = entry.value;
        }
      }
    }

    return bestCategory;
  }
}

/// 摘要服务 - 任务摘要生成
class SummaryService {
  /// 生成任务摘要
  static String generateSummary({
    required int totalTasks,
    required int completedTasks,
    required int activeTasks,
    required double completionRate,
    required Map<TaskCategory, int> tasksByCategory,
    required Map<TaskCategory, int> completedByCategory,
    required List<int> weeklyTrend,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('📊 任务周报');
    buffer.writeln('');

    // 总体概况
    buffer.writeln('📈 总体概况');
    buffer.writeln('- 总任务数：$totalTasks');
    buffer.writeln('- 已完成：$completedTasks');
    buffer.writeln('- 进行中：$activeTasks');
    buffer.writeln('- 完成率：${(completionRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('');

    // 分类统计
    buffer.writeln('📂 分类统计');
    for (final category in TaskCategory.values) {
      final total = tasksByCategory[category] ?? 0;
      final completed = completedByCategory[category] ?? 0;
      if (total > 0) {
        buffer.writeln('- ${category.label}：$completed/$total');
      }
    }
    buffer.writeln('');

    // 本周趋势
    if (weeklyTrend.isNotEmpty) {
      final thisWeek = weeklyTrend.reduce((a, b) => a + b);
      buffer.writeln('📅 本周完成');
      buffer.writeln('- 共完成 $thisWeek 项任务');
      final maxDay = weeklyTrend.reduce((a, b) => a > b ? a : b);
      if (maxDay > 0) {
        buffer.writeln('- 最多一天完成 $maxDay 项');
      }
    }
    buffer.writeln('');

    // 效率分析
    buffer.writeln('💡 ${analyzeEfficiency(completionRate)}');

    return buffer.toString();
  }

  /// 效率分析
  static String analyzeEfficiency(double completionRate) {
    if (completionRate >= 0.8) {
      return '效率超高！继续保持！';
    } else if (completionRate >= 0.6) {
      return '效率不错，继续加油！';
    } else if (completionRate >= 0.4) {
      return '效率有待提高，建议优先处理重要任务。';
    } else if (completionRate >= 0.2) {
      return '任务堆积较多，建议尽快完成。';
    } else {
      return '建议从简单任务开始，逐步建立完成习惯。';
    }
  }

  /// 生成改进建议
  static List<String> generateSuggestions({
    required int totalTasks,
    required int activeTasks,
    required double completionRate,
    required Map<TaskCategory, int> tasksByCategory,
  }) {
    final suggestions = <String>[];

    // 检查是否有太多未完成任务
    if (activeTasks > 20) {
      suggestions.add('建议清理一些长期未完成的任务');
    }

    // 检查完成率
    if (completionRate < 0.5 && totalTasks > 5) {
      suggestions.add('建议先将注意力放在完成现有任务上');
    }

    // 检查分类平衡
    final workTasks = tasksByCategory[TaskCategory.work] ?? 0;
    final lifeTasks = tasksByCategory[TaskCategory.life] ?? 0;
    if (workTasks > 0 && lifeTasks == 0) {
      suggestions.add('别忘了平衡工作与生活');
    }

    if (suggestions.isEmpty) {
      suggestions.add('保持当前节奏，任务管理得很好！');
    }

    return suggestions;
  }
}
