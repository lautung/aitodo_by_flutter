# AiTODO 下次续做清单

更新时间：2026-03-01 17:12:32

## 1. 当前状态（可直接继续）
- 代码质量：
  - `flutter analyze`：通过（No issues found）
  - `flutter test`：通过（21/21）
- 覆盖率：
  - 已生成 `coverage/lcov.info`
  - 行覆盖率：`21.04%`（`619 / 2942`）
- 最新进度总览见：`docs/EXECUTION_LOG.md`

## 2. 下次优先执行项（按顺序）
1. 覆盖率门禁落地（CI）
   - 在 `.github/workflows/flutter_ci.yml` 增加：
     - `flutter test --coverage`
     - 覆盖率阈值校验步骤（建议先设为当前基线，例如 20%，后续逐步提升到 70% 目标）
2. Widget/Golden 基线补齐（阶段3收尾）
   - 优先补任务列表、任务表单、设置页关键流程的 Widget 测试
   - 评估 Golden 测试在 CI 环境的稳定性后再启用门禁
3. release 分支策略（阶段1预备）
   - 为 `main/master` 或 `release/*` 分支增加 release 构建策略
   - 结合签名配置（`android/key.properties`）决定是否启用强制 release 构建

## 3. 建议执行命令
```bash
flutter analyze
flutter test
flutter test --coverage
```

## 4. 已确认可复用结论
- 在当前会话中，受限沙箱会影响 `flutter` 子进程（`dart -> git`）与部分写入权限；
  需要提权执行 Flutter 命令才能稳定完成验证。
- `NLPService.parsePriority` 已修复“不急”误判高优先级问题。
- `test/widget_test.dart` 已改为短时 `pump`，避免 `pumpAndSettle` 超时。
