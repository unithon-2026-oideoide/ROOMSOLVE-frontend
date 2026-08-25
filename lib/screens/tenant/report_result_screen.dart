import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/report.dart';
import '../../models/vendor.dart';
import '../../services/report_service.dart';
import '../../services/repair_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/app_bottom_nav.dart';

String? _recommendedPathToApiString(RecommendedPath path) {
  switch (path) {
    case RecommendedPath.selfFix:
      return 'self_fix';
    case RecommendedPath.manufacturerAs:
      return 'manufacturer_as';
    case RecommendedPath.vendorMatch:
      return 'vendor_match';
    case RecommendedPath.unknown:
      return null;
  }
}

/// AI 분석 결과의 recommended_path에 따라 다른 화면을 보여준다.
/// self_fix / manufacturer_as / vendor_match 세 갈래로 분기한다.
class ReportResultScreen extends StatelessWidget {
  final Report report;

  const ReportResultScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(child: _buildBranch(context)),
            const AppBottomNav(current: AppBottomNavTab.reports),
          ],
        ),
      ),
    );
  }

  Widget _buildBranch(BuildContext context) {
    switch (report.recommendedPath) {
      case RecommendedPath.selfFix:
        return _SelfFixView(report: report);
      case RecommendedPath.manufacturerAs:
        return _ManufacturerAsView(report: report);
      case RecommendedPath.vendorMatch:
        return _VendorMatchView(report: report);
      case RecommendedPath.unknown:
        return Center(
          child: Text('분석 결과를 확인할 수 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
        );
    }
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

/// "세입자 - 자가조치가이드" 화면: POST /api/reports/chat으로 실제 AI 챗봇과
/// 대화한다. context(category/severity/recommended_path/self_fix_guide)는
/// report에서 채우고, 대화 기록은 이 화면(클라이언트)이 들고 있다가 매 요청에
/// 함께 보낸다(API가 무상태이기 때문).
class _SelfFixView extends StatefulWidget {
  final Report report;
  const _SelfFixView({required this.report});

  @override
  State<_SelfFixView> createState() => _SelfFixViewState();
}

class _SelfFixViewState extends State<_SelfFixView> {
  final _inputController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final List<Map<String, String>> _apiMessages = [];
  bool _isSending = false;
  String? _errorMessage;
  Map<String, dynamic>? _context;

  @override
  void initState() {
    super.initState();
    final category = widget.report.category;
    final severity = widget.report.severity;
    if (category != null && severity != null) {
      _context = {
        'category': category,
        'severity': severity,
        if (_recommendedPathToApiString(widget.report.recommendedPath) != null)
          'recommended_path': _recommendedPathToApiString(widget.report.recommendedPath),
        if (widget.report.selfFixGuide != null) 'self_fix_guide': widget.report.selfFixGuide,
      };
      _sendToApi(); // 첫 턴: messages를 빈 배열로 보내면 챗봇이 가이드를 먼저 제시한다.
    } else {
      // AI 분석 결과(category/severity)가 없으면 챗봇을 호출할 수 없어 기존 가이드 텍스트로 대체한다.
      _messages.add(_ChatMessage(
        text: widget.report.selfFixGuide ?? '셀프 수리 가이드를 준비 중입니다. 잠시 후 다시 확인해 주세요.',
        isUser: false,
      ));
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _sendToApi() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      final result = await RepairService.instance.chat(context: _context!, messages: _apiMessages);
      _apiMessages.add({'role': 'assistant', 'content': result.reply});
      setState(() {
        _messages.add(_ChatMessage(text: result.reply, isUser: false));
        if (result.escalate) {
          final target = result.escalateTo == 'manufacturer_as' ? '제조사 A/S' : '전문 업체 매칭';
          _messages.add(_ChatMessage(text: '자가수리로 해결이 어려워 보여요. $target 단계로 안내해 드릴게요.', isUser: false));
        }
      });
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'AI 상담 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending || _context == null) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _inputController.clear();
    });
    _apiMessages.add({'role': 'user', 'content': text});
    _sendToApi();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('자가 조치 가이드', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppColors.dropShadow,
              ),
              child: ListView(
                children: [
                  for (final m in _messages) _ChatBubble(message: m),
                  if (_isSending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('AI가 답변을 준비하고 있어요...', style: AppTextStyles.captionRegular10(color: AppColors.gray6)),
                    ),
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: AppTextStyles.captionRegular10(color: AppColors.accentRed)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI는 실수할 수 있습니다.',
            textAlign: TextAlign.center,
            style: AppTextStyles.captionRegular10(color: AppColors.gray6),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppColors.gray3, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: _context != null && !_isSending,
                    onSubmitted: (_) => _send(),
                    style: AppTextStyles.captionRegular10(color: AppColors.gray8),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '채팅을 입력하세요.',
                      hintStyle: AppTextStyles.captionRegular10(color: AppColors.gray8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, size: 20, color: AppColors.brandMain),
                  onPressed: (_context != null && !_isSending) ? _send : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 220),
          decoration: BoxDecoration(color: AppColors.brandMain, borderRadius: BorderRadius.circular(20)),
          child: Text(message.text, style: AppTextStyles.captionRegular10(color: AppColors.white)),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.gray2, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI 답변', style: AppTextStyles.captionRegular10(color: AppColors.black)),
          const SizedBox(height: 8),
          Text(message.text, style: AppTextStyles.captionRegular10(color: AppColors.black)),
        ],
      ),
    );
  }
}

/// "세입자 - 제조사AS" 화면.
class _ManufacturerAsView extends StatefulWidget {
  final Report report;
  const _ManufacturerAsView({required this.report});

  @override
  State<_ManufacturerAsView> createState() => _ManufacturerAsViewState();
}

class _ManufacturerAsViewState extends State<_ManufacturerAsView> {
  List<Map<String, dynamic>>? _asInfo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ReportService.instance.getManufacturerAs(category: widget.report.category ?? '');
      setState(() {
        _asInfo = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '제조사 A/S 정보를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _showContact(Map<String, dynamic> info) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(info['name']?.toString() ?? '서비스 센터'),
        content: Text(info['phone']?.toString() ?? '연락처 정보가 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('제조사 AS', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
          const SizedBox(height: 26),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(child: Text(_errorMessage!, style: AppTextStyles.bodyRegular14(color: AppColors.accentRed)))
          else if (_asInfo == null || _asInfo!.isEmpty)
            Center(
              child: _ServiceCenterPill(
                label: '서비스 센터로 연결',
                onTap: () => _showContact({'name': '고객센터', 'phone': '연결된 제조사 정보가 없습니다.'}),
              ),
            )
          else
            Center(
              child: Column(
                children: [
                  for (final info in _asInfo!) ...[
                    _ServiceCenterPill(
                      label: info['name']?.toString() ?? '서비스 센터로 연결',
                      onTap: () => _showContact(info),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceCenterPill extends StatelessWidget {
  const _ServiceCenterPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 73,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(46),
          boxShadow: AppColors.dropShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.subtitleRegular18(color: AppColors.gray8)),
            const SizedBox(width: 8),
            Icon(Icons.north_east, size: 20, color: AppColors.gray8),
          ],
        ),
      ),
    );
  }
}

/// "세입자 - 전문 업체 매칭" 화면: 업체 매칭 진행 단계를 보여준다.
/// 매칭 자체(ReportService.matchVendors)는 기존 로직대로 백그라운드에서 호출해
/// 1단계("수리업체 배정")의 상태 문구에 반영한다.
class _VendorMatchView extends StatefulWidget {
  final Report report;
  const _VendorMatchView({required this.report});

  @override
  State<_VendorMatchView> createState() => _VendorMatchViewState();
}

class _VendorMatchViewState extends State<_VendorMatchView> {
  List<Vendor>? _vendors;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final category = widget.report.category;
    if (category == null) {
      setState(() => _errorMessage = '문제 유형을 확인할 수 없어 업체를 찾지 못했습니다.');
      return;
    }
    try {
      final result = await ReportService.instance.matchVendors(category: category);
      if (mounted) setState(() => _vendors = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '업체 매칭 정보를 불러오지 못했습니다: $e');
    }
  }

  String get _step1Subtitle {
    if (_errorMessage != null) return '업체 매칭 중 오류가 발생했습니다.';
    if (_vendors == null) return '적합한 수리업체를 찾고 있습니다.';
    if (_vendors!.isEmpty) return '조건에 맞는 업체를 찾지 못했습니다.';
    return '${_vendors!.first.name} 등 ${_vendors!.length}개 업체 매칭 완료';
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    // submitReport()가 분석 직후 바로 저장하므로, 이 화면에 도달한 시점에 신고는
    // 이미 임대인에게 전달돼 있다. 그래서 아래 버튼은 "요청 보내기" 액션이 아니라
    // report.status를 그대로 보여주는 용도다. 예전에는 로컬 bool
    // (_approvalRequested)이 화면을 열 때마다 false로 초기화돼서, 이미 승인·거절된
    // 신고를 다시 열어도 "임대인 승인 요청하기"가 활성화된 것처럼 보였다.
    final approved = report.status == 'approved';
    final rejected = report.isRejected;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('전문 업체 매칭', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
          const SizedBox(height: 8),
          Text(
            '신고하신 문제를 검토했습니다.\n아래 절차에 따라 수리가 진행됩니다.',
            style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 판단 요약', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                const SizedBox(height: 8),
                Text(
                  widget.report.description ?? '전문 수리기사 방문이 필요한 것으로 판단됩니다.',
                  style: AppTextStyles.bodyRegular12(color: AppColors.gray8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('진행 단계', style: AppTextStyles.subtitleSemiBold16(color: AppColors.gray8)),
                const SizedBox(height: 8),
                _StepRow(number: 1, title: '수리업체 배정', subtitle: _step1Subtitle),
                _StepRow(number: 2, title: '방문 일정 확정', subtitle: '확정되면 알림으로 안내드립니다.'),
                _StepRow(number: 3, title: '현장 수리 진행', subtitle: '수리업체가 방문하여 문제를 해결합니다.'),
                _StepRow(number: 4, title: '수리 완료 확인', subtitle: '완료 후 결과를 확인하고 서명합니다.', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('안내 사항', style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
                const SizedBox(height: 8),
                Text(
                  '진행 상황은 실시간으로 업데이트됩니다. 중요한 변경이 생기면 즉시 알림을 드립니다.',
                  style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              // 실제 액션이 아니라 현재 상태 표시라 항상 비활성 — 위 주석 참고.
              onPressed: null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor:
                    rejected ? AppColors.accentRed : (approved ? AppColors.accentGreen : AppColors.brandLight),
                disabledForegroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                rejected ? '임대인이 거절했습니다' : (approved ? '임대인 승인 완료' : '임대인 승인 대기 중'),
                style: AppTextStyles.bodySemiBold16(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.dropShadow,
      ),
      child: child,
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFEDEDF2), shape: BoxShape.circle),
            child: Text('$number', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.captionLight12(color: AppColors.gray5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
