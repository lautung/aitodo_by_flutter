/// 农历信息
class LunarInfo {
  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;
  final String monthName;
  final String dayName;
  final String zodiac;
  final String? solarTerm;
  final String? festival;

  const LunarInfo({
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
    required this.monthName,
    required this.dayName,
    required this.zodiac,
    this.solarTerm,
    this.festival,
  });
}

/// 黄历信息
class HuangliInfo {
  final String yi;
  final String ji;
  final String chong;
  final String sha;
  final String luck;

  const HuangliInfo({
    required this.yi,
    required this.ji,
    required this.chong,
    required this.sha,
    required this.luck,
  });
}

/// 农历服务
class LunarService {
  static const List<String> _monthNames = [
    '正月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '冬月', '腊月',
  ];

  static const List<String> _dayNames = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
  ];

  static const List<String> _zodiacs = [
    '鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪',
  ];

  // 农历各月的天数（平年）
  static const List<int> _monthDays = [
    29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30,
  ];

  // 农历闰月月份（0表示无闰月）
  static const Map<int, int> _leapMonths = {
    2001: 4, 2004: 2, 2006: 7, 2009: 5, 2012: 4, 2014: 9, 2017: 6, 2020: 4,
    2023: 2, 2025: 6, 2028: 5, 2031: 3, 2033: 11, 2036: 6, 2039: 5, 2042: 2,
    2044: 7, 2047: 5, 2050: 3, 2052: 8, 2055: 6, 2058: 4, 2061: 3, 2063: 7,
    2066: 5, 2069: 4, 2071: 8, 2074: 6, 2077: 5, 2080: 3, 2082: 8, 2085: 6,
  };

  // 传统节日
  static const Map<String, String> _festivals = {
    '01-01': '春节',
    '01-15': '元宵节',
    '02-02': '龙抬头',
    '05-05': '端午节',
    '07-07': '七夕节',
    '07-15': '中元节',
    '08-15': '中秋节',
    '09-09': '重阳节',
    '12-08': '腊八节',
    '12-23': '小年',
  };

  // 节气日期（阳历每月两个节气）
  static const Map<String, List<String>> _solarTerms = {
    '01': ['小寒', '大寒'],
    '02': ['立春', '雨水'],
    '03': ['惊蛰', '春分'],
    '04': ['清明', '谷雨'],
    '05': ['立夏', '小满'],
    '06': ['芒种', '夏至'],
    '07': ['小暑', '大暑'],
    '08': ['立秋', '处暑'],
    '09': ['白露', '秋分'],
    '10': ['寒露', '霜降'],
    '11': ['立冬', '小雪'],
    '12': ['大雪', '冬至'],
  };

  // 获取指定日期的农历信息
  LunarInfo getLunarInfo(DateTime date) {
    final lunarDate = _convertToLunar(date);
    final festival = _getFestival(lunarDate.lunarMonth, lunarDate.lunarDay);
    final solarTerm = _getSolarTerm(date);

    return LunarInfo(
      lunarYear: lunarDate.lunarYear,
      lunarMonth: lunarDate.lunarMonth,
      lunarDay: lunarDate.lunarDay,
      isLeapMonth: lunarDate.isLeapMonth,
      monthName: _monthNames[lunarDate.lunarMonth - 1],
      dayName: _dayNames[lunarDate.lunarDay - 1],
      zodiac: _zodiacs[(lunarDate.lunarYear - 4) % 12],
      solarTerm: solarTerm,
      festival: festival,
    );
  }

  /// 获取黄历信息
  HuangliInfo getHuangliInfo(DateTime date) {
    return _calculateHuangli(date);
  }

  /// 获取农历年的开始日期（春节）
  DateTime getLunarNewYear(int lunarYear) {
    // 春节一般在1月21日到2月20日之间
    // 这里使用简化的算法
    final baseDate = DateTime(lunarYear, 1, 22);
    var days = 0;
    for (var y = 1900; y < lunarYear; y++) {
      days += 354;
      if (_leapMonths[y] != null) days += 30;
    }
    return baseDate.add(Duration(days: days % 30));
  }

  // 内部方法：将阳历转换为农历
  _LunarDate _convertToLunar(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    // 计算从1900年1月31日（庚子年正月初一）开始的天数
    var totalDays = 0;
    for (var y = 1900; y < year; y++) {
      totalDays += 365;
      if (_isLeapYear(y)) totalDays++;
    }

    // 加上本年的天数
    for (var m = 1; m < month; m++) {
      totalDays += _getMonthDays(year, m);
    }
    totalDays += day - 1;

    // 减去1900年的天数（到庚子年正月初一）
    const baseDays = 30; // 1900年1月31日
    totalDays -= baseDays;

    // 计算农历年
    var lunarYear = 1900;
    var daysInYear = _getLunarYearDays(lunarYear);
    while (totalDays >= daysInYear) {
      totalDays -= daysInYear;
      lunarYear++;
      daysInYear = _getLunarYearDays(lunarYear);
    }

    // 计算农历月和日
    var lunarMonth = 1;
    var isLeapMonth = false;
    final leapMonth = _leapMonths[lunarYear] ?? 0;
    var monthDays = _getMonthDays(lunarYear, lunarMonth);

    // 特殊处理闰月
    if (leapMonth > 0 && lunarMonth == leapMonth) {
      // 这个月是闰月，需要特殊处理
      if (totalDays >= monthDays) {
        totalDays -= monthDays;
        isLeapMonth = true;
        lunarMonth = leapMonth;
        monthDays = _getMonthDays(lunarYear, lunarMonth, true);
      }
    }

    while (totalDays >= monthDays) {
      totalDays -= monthDays;
      lunarMonth++;
      if (lunarMonth == leapMonth && leapMonth > 0) {
        // 闰月
        isLeapMonth = true;
        monthDays = _getMonthDays(lunarYear, lunarMonth, true);
      } else {
        isLeapMonth = false;
        monthDays = _getMonthDays(lunarYear, lunarMonth);
      }
    }

    final lunarDay = totalDays + 1;

    return _LunarDate(
      lunarYear: lunarYear,
      lunarMonth: lunarMonth,
      lunarDay: lunarDay,
      isLeapMonth: isLeapMonth,
    );
  }

  int _getLunarYearDays(int year) {
    var days = 0;
    for (var m = 1; m <= 12; m++) {
      days += _getMonthDays(year, m);
    }
    // 如果有闰月，加30天
    if (_leapMonths[year] != null) {
      days += 30;
    }
    return days;
  }

  int _getMonthDays(int year, int month, [bool isLeap = false]) {
    if (isLeap) return 30;
    if (_leapMonths[year] == month) {
      // 闰月后的下一个月
      return _monthDays[month % 12];
    }
    return _monthDays[month - 1];
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  String? _getFestival(int month, int day) {
    final key = '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    return _festivals[key];
  }

  String? _getSolarTerm(DateTime date) {
    final monthKey = date.month.toString().padLeft(2, '0');
    final day = date.day;

    final terms = _solarTerms[monthKey] ?? [];
    if (terms.isEmpty) return null;

    // 节气大约在固定的日期附近
    final firstTermDay = _getSolarTermDay(date.year, date.month, 0);
    final secondTermDay = _getSolarTermDay(date.year, date.month, 1);

    if (day == firstTermDay) return terms[0];
    if (day == secondTermDay) return terms[1];

    return null;
  }

  int _getSolarTermDay(int year, int month, int index) {
    // 节气日期的简化算法
    const Map<String, List<int>> termBaseDays = {
      '01': [6, 20],
      '02': [4, 19],
      '03': [6, 21],
      '04': [5, 21],
      '05': [6, 21],
      '06': [6, 21],
      '07': [7, 23],
      '08': [8, 23],
      '09': [8, 23],
      '10': [8, 23],
      '11': [7, 22],
      '12': [7, 22],
    };

    final days = termBaseDays[month.toString().padLeft(2, '0')] ?? [1, 1];
    return days[index];
  }

  // 计算黄历信息
  HuangliInfo _calculateHuangli(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    // 使用简单的算法生成黄历信息
    // 实际上应该使用专业的黄历数据
    final base = (year * 10000 + month * 100 + day) % 60;
    final branchIndex = base % 12;

    final branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

    // 冲煞计算
    final chongIndex = (branchIndex + 6) % 12;
    final chong = branches[chongIndex];

    // 煞方（简化）
    final shaDirections = ['东', '南', '西', '北', '东南', '西南', '东北', '西北'];
    final sha = shaDirections[base % 8];

    // 吉凶（基于天干地支）
    final luckValues = ['吉', '平', '凶', '平', '吉', '平', '凶', '平', '吉', '平', '凶', '平'];
    final luck = luckValues[branchIndex];

    // 宜忌（基于日期）
    final yiList = [
      ['祭祀', '祈福', '开光', '塑绘'],
      ['出行', '移徙', '入宅', '搬家'],
      ['沐浴', '理发', '整手足甲'],
      ['订盟', '订婚', '纳采', '会亲友'],
      ['拆卸', '起基', '定磉', '造屋'],
      ['立券', '交易', '立档', '登记'],
      ['纳财', '开仓', '出货财', '酝酿'],
      ['栽种', '纳畜', '牧养', '竖柱'],
      ['解除', '扫舍', '求医', '治病'],
      ['修造', '动土', '竖柱', '上梁'],
    ];

    final jiList = [
      ['动土', '破土', '开市', '交易'],
      ['开光', '塑绘', '出货财', '栽种'],
      ['移徙', '入宅', '开市', '交易'],
      ['祈福', '求嗣', '上梁', '竖柱'],
      ['开市', '交易', '立券', '出货财'],
      ['动土', '破土', '安葬', '修造'],
      ['祈福', '求嗣', '订盟', '纳采'],
      ['入宅', '移徙', '出行', '移徙'],
      ['开市', '交易', '立券', '出货财'],
      ['祈福', '求嗣', '订盟', '纳采'],
    ];

    final yi = yiList[day % 10].join(' ');
    final ji = jiList[day % 10].join(' ');

    return HuangliInfo(
      yi: yi,
      ji: ji,
      chong: '冲$chong',
      sha: '煞$sha',
      luck: luck,
    );
  }
}

class _LunarDate {
  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;

  const _LunarDate({
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
  });
}
