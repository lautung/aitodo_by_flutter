import 'package:flutter/material.dart';

import '../screens/legal_document_screen.dart';
import '../services/compliance_service.dart';
import 'ui/ui.dart';

class ComplianceGate extends StatefulWidget {
  final Widget child;
  final ComplianceService complianceService;

  const ComplianceGate({
    super.key,
    required this.child,
    this.complianceService = const _DefaultComplianceService(),
  });

  @override
  State<ComplianceGate> createState() => _ComplianceGateState();
}

class _DefaultComplianceService extends ComplianceService {
  const _DefaultComplianceService();
}

class _ComplianceGateState extends State<ComplianceGate> {
  bool _checkingAgreement = true;

  @override
  void initState() {
    super.initState();
    _checkAgreement();
  }

  Future<void> _checkAgreement() async {
    final accepted = await widget.complianceService.hasAcceptedAgreement();
    if (!mounted) return;
    setState(() {
      _checkingAgreement = false;
    });
    if (!accepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAgreementDialog();
        }
      });
    }
  }

  Future<void> _showAgreementDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.verified_user_outlined),
        title: const Text('使用前须知'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: const Text('AiTODO 当前版本为本地优先的任务管理工具。请先阅读并同意《隐私政策》和《用户协议》。'),
        ),
        actions: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              TextButton(
                onPressed: () => _openDocument(
                  dialogContext,
                  LegalDocumentType.privacyPolicy,
                ),
                child: const Text('隐私政策'),
              ),
              TextButton(
                onPressed: () => _openDocument(
                  dialogContext,
                  LegalDocumentType.userAgreement,
                ),
                child: const Text('用户协议'),
              ),
            ],
          ),
          FilledButton(
            onPressed: () async {
              await widget.complianceService.acceptAgreement();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
  }

  void _openDocument(BuildContext dialogContext, LegalDocumentType type) {
    Navigator.of(
      dialogContext,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => LegalDocumentScreen(type: type)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_checkingAgreement)
          const ColoredBox(
            color: Colors.white,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
