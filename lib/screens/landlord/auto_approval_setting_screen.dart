import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../services/landlord_service.dart';

class AutoApprovalSettingScreen extends StatefulWidget {
  const AutoApprovalSettingScreen({super.key});

  @override
  State<AutoApprovalSettingScreen> createState() => _AutoApprovalSettingScreenState();
}

class _AutoApprovalSettingScreenState extends State<AutoApprovalSettingScreen> {
  final _maxAmountController = TextEditingController();
  bool _autoApproveEnabled = false;
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await LandlordService.instance.setAutoApprovalPolicy(policy: {
        'enabled': _autoApproveEnabled,
        'maxAmount': num.tryParse(_maxAmountController.text) ?? 0,
      });
      setState(() => _message = '설정이 저장되었습니다.');
    } on ApiException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = '설정 저장 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자동 승인 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TODO: 디자인 적용 필요
            SwitchListTile(
              title: const Text('일정 금액 이하 자동 승인'),
              value: _autoApproveEnabled,
              onChanged: (value) => setState(() => _autoApproveEnabled = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxAmountController,
              keyboardType: TextInputType.number,
              enabled: _autoApproveEnabled,
              decoration: const InputDecoration(labelText: '최대 자동 승인 금액', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            if (_message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_message!)),
            FilledButton(
              onPressed: _isSubmitting ? null : _save,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
