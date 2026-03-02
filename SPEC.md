# AiTODO 应用规格说明

## 1. 项目概述

- **项目名称**: AiTODO
- **类型**: Flutter Android 待办事项应用
- **核心功能**: AI赋能的待办应用，支持自然语言创建任务、智能分类、数据统计与分析

## 2. 技术栈

- **框架**: Flutter 3.x (Dart SDK ^3.11.0)
- **状态管理**: Provider
- **本地存储**: shared_preferences
- **图表**: fl_chart
- **工具库**: uuid (唯一ID生成), intl (日期格式化)
- **UI**: Material Design 3

## 3. 功能列表

### 3.1 任务管理
- 创建新任务（标题、描述、截止日期、优先级、分类）
- 编辑现有任务
- 删除任务（滑动删除）
- 标记任务完成/未完成
- 任务分类（工作、生活、学习、其他）
- 优先级设置（高、中、低）

### 3.2 任务列表
- 显示所有任务
- 按状态筛选（全部/进行中/已完成）
- 按分类筛选
- 按优先级排序
- 搜索任务

### 3.3 统计与分析
- 任务完成率统计
- 分类统计（饼图）
- 每周完成趋势（折线图）
- 完成率趋势

### 3.4 数据持久化
- 本地存储任务数据
- 应用重启后数据保持

## 4. UI/UX 设计方向

- **视觉风格**: Material Design 3，现代简洁风格
- **主色调**: 蓝色系 (#2196F3)
- **布局**: 底部导航栏（任务列表 / 统计）
- **任务卡片**: 圆角卡片，带优先级颜色指示
- **交互**: 下拉刷新、滑动删除、长按编辑

## 5. 数据模型

### Task
- id: String (UUID)
- title: String
- description: String?
- dueDate: DateTime?
- priority: Priority (high/medium/low)
- category: Category (work/life/study/other)
- isCompleted: bool
- createdAt: DateTime
- completedAt: DateTime?

### Priority 枚举
- high: 红色
- medium: 橙色
- low: 绿色

### Category 枚举
- work: 工作
- life: 生活
- study: 学习
- other: 其他
