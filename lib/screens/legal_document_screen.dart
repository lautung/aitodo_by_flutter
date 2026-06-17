import 'package:flutter/material.dart';

import '../widgets/ui/ui.dart';

enum LegalDocumentType { privacyPolicy, userAgreement, permissions, aiNotice }

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({super.key, required this.type});

  String get _title {
    switch (type) {
      case LegalDocumentType.privacyPolicy:
        return '隐私政策';
      case LegalDocumentType.userAgreement:
        return '用户协议';
      case LegalDocumentType.permissions:
        return '权限说明';
      case LegalDocumentType.aiNotice:
        return 'AI能力说明';
    }
  }

  List<String> get _paragraphs {
    switch (type) {
      case LegalDocumentType.privacyPolicy:
        return const [
          'AiTODO 当前版本采用本地优先设计，任务、标签、回收站、番茄钟历史、聊天记录和偏好设置主要保存在本机。',
          '导入、导出和分享备份文件由用户主动触发。请妥善保管导出的 JSON 文件，避免泄露个人任务内容。',
          '当前版本未接入账号系统、真实云同步或第三方远程 AI 服务。后续接入外部服务前，应更新本政策并重新提示用户确认。',
          '用户可以在设置中清除本地数据。清除后，任务、回收站、标签、聊天记录、番茄钟历史和本地偏好将被移除。',
        ];
      case LegalDocumentType.userAgreement:
        return const [
          '使用 AiTODO 表示你理解本应用是个人效率工具，任务提醒和智能解析结果仅供辅助参考。',
          '用户应自行确认任务内容、截止时间、提醒时间和导入数据的准确性。',
          '请勿使用本应用保存违法、侵权或高度敏感的信息。导出文件由用户自行管理。',
          '当前版本不提供账号体系和云端协作服务；相关能力仅作为未来规划。',
        ];
      case LegalDocumentType.permissions:
        return const [
          '通知权限：用于发送任务提醒和每日任务总结。拒绝该权限不影响创建和管理任务，但系统不会推送提醒。',
          '文件选择与分享：用于用户主动导入、导出和分享任务备份文件。',
          '本地存储：用于保存任务、标签、回收站、聊天记录、番茄钟历史和应用偏好。',
          '当前版本不使用麦克风权限。若未来加入语音输入，应在使用前单独说明并请求授权。',
        ];
      case LegalDocumentType.aiNotice:
        return const [
          '当前版本的智能解析基于本地规则引擎，支持识别部分中文日期、优先级关键词和任务分类关键词。',
          'AI助手用于创建任务、查询任务数量、查看简要列表和生成简单统计建议，不是通用聊天机器人。',
          '远程大模型、BYOK、本地大模型和跨端云同步尚未接入，相关能力不作为当前版本承诺。',
          '智能解析可能出错，保存前请检查标题、日期、优先级、分类和提醒设置。',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: _title,
      subtitle: '本地优先、清晰授权、按需开启',
      leadingIcon: _icon,
      maxWidth: 680,
      child: AppSurface(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ListView.separated(
          itemCount: _paragraphs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _paragraphs[index],
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.65),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData get _icon {
    switch (type) {
      case LegalDocumentType.privacyPolicy:
        return Icons.privacy_tip_outlined;
      case LegalDocumentType.userAgreement:
        return Icons.description_outlined;
      case LegalDocumentType.permissions:
        return Icons.security_outlined;
      case LegalDocumentType.aiNotice:
        return Icons.auto_awesome_outlined;
    }
  }
}
