# AiTODO 应用规格说明

## 1. 项目概述

- 项目名称：AiTODO
- 类型：Flutter Android 待办事项应用
- 当前定位：本地优先的个人任务管理工具
- 核心功能：任务管理、本地规则智能解析、提醒、统计、日历、番茄钟、本地备份恢复

## 2. 技术栈

- 框架：Flutter 3.x / Dart
- 状态管理：Provider
- 本地存储：SharedPreferences
- 图表：fl_chart
- 通知：flutter_local_notifications
- 文件能力：file_picker、share_plus

## 3. 当前功能

### 3.1 任务管理

- 创建、编辑、删除和恢复任务
- 标记完成/未完成
- 截止日期、提醒时间、优先级、分类、标签
- 子任务、重复任务和回收站

### 3.2 列表与筛选

- 显示任务列表
- 按状态、分类、标签筛选
- 搜索任务
- 首页命令输入框支持本地规则解析并快速创建任务
- 按创建时间、截止日期和优先级排序
- 批量完成和批量删除

### 3.3 智能解析与助手

- 本地规则解析中文日期、优先级关键词和分类关键词
- AI 助手支持创建任务、查询数量、查看简要列表和生成简单统计建议
- 当前版本不接入远程大模型、BYOK 或本地大模型

### 3.4 日历、统计与番茄钟

- 日历视图和完成热力图
- 完成率、分类统计、周趋势
- 番茄钟支持工作/休息计时、后台真实时间恢复、阶段结束提醒和本地专注历史
- Android 端在计时运行时使用常驻前台服务通知；阶段结束提醒优先使用精确调度，权限不可用时降级为非精确提醒并在回前台时校正状态

### 3.5 数据与合规

- 本地保存任务数据
- 支持 JSON 导出/导入备份
- 首次启动展示协议确认
- 设置页提供隐私政策、用户协议、权限说明、AI 能力说明和清除本地数据

## 4. 非当前版本范围

- 真实云同步
- 跨端同步
- 账号体系和账号注销
- 远程 AI 模型
- BYOK API Key
- 本地大模型
- 多人协作

## 5. 数据模型

### Task

- id: String
- title: String
- description: String?
- dueDate: DateTime?
- priority: Priority
- category: TaskCategory
- isCompleted: bool
- createdAt: DateTime
- completedAt: DateTime?
- repeatType: RepeatType
- parentId: String?
- subtasks: List<SubTask>
- reminderTime: DateTime?
- customTagIds: List<String>
- groupId: String?
- prerequisiteIds: List<String>
- customRepeat: CustomRepeat?
- sortOrder: int

## 6. 验证命令

```bash
flutter analyze
flutter test
flutter build apk --debug
```
