# AiTODO 应用文档

## 目录

1. [项目概述](#项目概述)
2. [功能特性](#功能特性)
3. [技术架构](#技术架构)
4. [目录结构](#目录结构)
5. [数据模型](#数据模型)
6. [核心模块说明](#核心模块说明)
7. [页面说明](#页面说明)
8. [依赖项](#依赖项)
9. [构建与运行](#构建与运行)

---

## 项目概述

**AiTODO** 是一款 AI 赋能的智能待办事项管理应用，支持自然语言创建任务、智能分类、任务提醒、重复任务、数据统计等功能。

- **应用名称**: AiTODO
- **版本**: 1.0.0
- **目标平台**: Android
- **框架**: Flutter 3.11.0+

---

## 功能特性

### 核心功能
- **任务管理**: 创建、编辑、删除任务
- **AI智能解析**: 输入"下周三完成报告"自动识别日期、优先级、分类
- **分类管理**: 工作、生活、学习、其他四类
- **优先级**: 高/中/低 + 自定义优先级
- **自定义标签**: 用户可添加自定义标签
- **重复任务**: 每日、每周、每月、每年重复
- **任务提醒**: 截止前15分钟推送通知
- **回收站**: 误删可恢复
- **数据备份**: 支持导出/导入JSON文件

### 高级功能
- **多维度筛选**: 按状态、分类筛选
- **智能排序**: 按创建时间、截止日期、优先级排序
- **批量操作**: 批量标记完成、批量删除
- **数据统计**: 完成率、分类统计、周趋势图表
- **AI助手**: 智能问答、任务建议

### 主题支持
- 浅色主题
- 深色主题
- 跟随系统

---

## 技术架构

### 架构模式
采用 **MVVM** (Model-View-ViewModel) 架构，结合 Flutter 的 **Provider** 状态管理。

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── task.dart            # 任务模型
│   └── subtask.dart         # 子任务模型
├── repositories/            # 数据仓储抽象与本地实现
│   ├── task_repository.dart
│   └── local_task_repository.dart
├── usecases/                # 业务用例层（数据编排）
│   └── task_data_usecase.dart
├── providers/               # 状态管理
│   ├── task_provider.dart   # 任务状态
│   ├── tag_provider.dart    # 标签状态
│   ├── priority_provider.dart # 优先级状态
│   ├── theme_provider.dart  # 主题状态
│   └── ai_mode_provider.dart # AI解析模式状态
├── services/                # 业务服务
│   ├── storage_service.dart # 本地存储
│   ├── notification_service.dart # 通知服务
│   ├── ai_service.dart      # AI解析服务
│   ├── ai_dispatcher_service.dart # AI分发与降级
│   └── chat_storage_service.dart # 聊天存储
├── screens/                 # 页面
│   ├── home_screen.dart    # 主页
│   ├── task_list_screen.dart # 任务列表
│   ├── task_form_screen.dart # 任务表单
│   ├── task_detail_screen.dart # 任务详情
│   ├── settings_screen.dart # 设置页
│   ├── statistics_screen.dart # 统计页
│   ├── recycle_bin_screen.dart # 回收站
│   └── ai_chat_screen.dart # AI聊天
└── widgets/                 # 组件
    └── task_card.dart      # 任务卡片
```

---

## 数据模型

### Task (任务)
```dart
class Task {
  String id;                    // 唯一标识
  String title;                // 标题
  String? description;         // 描述
  DateTime? dueDate;           // 截止日期
  Priority priority;           // 优先级 (high/medium/low)
  TaskCategory category;       // 分类 (work/life/study/other)
  bool isCompleted;            // 是否完成
  DateTime createdAt;          // 创建时间
  DateTime? completedAt;       // 完成时间
  RepeatType repeatType;       // 重复类型 (none/daily/weekly/monthly/yearly)
  String? parentId;            // 父任务ID（用于重复任务链）
  List<SubTask> subtasks;     // 子任务列表
  DateTime? reminderTime;      // 提醒时间
  List<String> customTagIds;   // 自定义标签ID列表
}
```

### 枚举类型

**Priority (优先级)**
- `high` - 高 (红色)
- `medium` - 中 (橙色)
- `low` - 低 (绿色)

**TaskCategory (分类)**
- `work` - 工作 (蓝色图标)
- `life` - 生活 (绿色图标)
- `study` - 学习 (紫色图标)
- `other` - 其他 (灰色图标)

**RepeatType (重复类型)**
- `none` - 不重复
- `daily` - 每日
- `weekly` - 每周
- `monthly` - 每月
- `yearly` - 每年

---

## 核心模块说明

### 1. TaskProvider (任务状态管理)
负责所有任务相关的业务逻辑：
- `addTask()` - 添加任务
- `updateTask()` - 更新任务
- `deleteTask()` - 删除任务（移入回收站）
- `toggleTaskCompletion()` - 切换完成状态
- `_createNextRepeatTask()` - 创建下一个重复任务
- 筛选、排序逻辑

### 2. StorageService (本地存储)
- 使用 `SharedPreferences` 存储任务数据
- 支持导出/导入JSON文件
- 回收站持久化

### 3. AI Service (智能解析)
包含四个核心服务：
- **AiDispatcherService**: 远程优先/本地优先分发，远程失败自动降级到本地规则引擎
- **NLPService**: 自然语言解析
  - 日期解析（今天、明天、下周三、3天后等）
  - 优先级解析（紧急、重要等关键词）
- **ClassificationService**: 智能分类建议
- **SummaryService**: 任务摘要生成

### 4. NotificationService (通知服务)
- 使用 `flutter_local_notifications` 实现本地通知
- 支持定时提醒（截止前15分钟）
- Android需要配置通知权限

---

## 页面说明

### 1. HomeScreen (主页)
底部导航包含4个Tab：
- 任务列表
- 统计
- AI助手
- 设置

### 2. TaskListScreen (任务列表)
- 搜索栏
- 状态筛选（全部/进行中/已完成）
- 分类筛选（工作/生活/学习/其他）
- 排序按钮（AppBar右上角）
- 批量选择模式

### 3. TaskFormScreen (任务表单)
- AI智能解析按钮
- 截止日期选择
- 提醒开关
- 优先级选择（支持自定义优先级）
- 分类选择
- 重复类型
- 自定义标签

### 4. TaskDetailScreen (任务详情)
- 显示完整任务信息
- 子任务清单
- 进度条
- 编辑/删除操作

### 5. SettingsScreen (设置)
- 主题切换
- AI 解析模式切换（远程优先/本地优先）
- 导出/导入任务
- 回收站入口
- 标签管理
- 优先级管理

### 6. StatisticsScreen (统计)
- 完成率圆环图
- 分类统计柱状图
- 周趋势折线图

### 7. AIChatScreen (AI助手)
- 智能问答
- 任务建议
- 数据分析

---

## 依赖项

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2           # 状态管理
  shared_preferences: ^2.2.3  # 本地存储
  intl: ^0.19.0              # 日期格式化
  uuid: ^4.4.0               # UUID生成
  fl_chart: ^0.68.0          # 图表
  flutter_local_notifications: ^17.2.2  # 本地通知
  timezone: ^0.9.4           # 时区
  path_provider: ^2.1.2      # 文件路径
  file_picker: ^8.0.0+1      # 文件选择
  share_plus: ^9.0.0          # 分享
```

---

## 构建与运行

### 开发环境
- Flutter SDK: ^3.11.0
- Dart SDK: ^3.11.0
- Android SDK

### 运行命令
```bash
# 安装依赖
flutter pub get

# 运行调试版
flutter run

# 构建调试APK
flutter build apk --debug

# 构建发布APK
flutter build apk --release

# 代码分析
flutter analyze

# 全量测试
flutter test
```

### CI
- 已配置 GitHub Actions: `.github/workflows/flutter_ci.yml`
- 默认执行：依赖安装、静态检查、测试、Debug APK 构建

### Android 配置
- 最低SDK版本: 21 (Android 5.0)
- 目标SDK版本: 34 (Android 14)
- 已声明通知权限并在运行时请求（Android 13+）
- 发布构建需提供 `android/key.properties` 与 keystore

---

## 版本历史

### v1.0.0
- 初始版本
- 任务管理核心功能
- AI智能解析
- 主题支持
- 数据统计
- 任务提醒
- 重复任务
- 自定义标签和优先级

---

## 常见问题

### Q: 如何创建重复任务？
A: 在创建任务时，选择重复类型（每日/每周/每月/每年），设置截止日期后，完成任务会自动创建下一个重复任务。

### Q: 自定义标签在哪里管理？
A: 进入「设置」页面，找到「标签管理」部分，可以添加或删除自定义标签。

### Q: 数据如何备份？
A: 进入「设置」页面，点击「导出任务」，可以选择分享或保存备份文件。导入时点击「导入任务」选择备份文件。

### Q: 误删的任务如何恢复？
A: 进入「设置」页面，点击「回收站」，可以恢复误删的任务。
