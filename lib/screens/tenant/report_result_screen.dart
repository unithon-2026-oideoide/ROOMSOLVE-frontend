import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/report.dart';
import '../../models/vendor.dart';
import '../../services/report_service.dart';

/// AI 분석 결과의 recommended_path에 따라 다른 위젯을 보여주는 화면.
/// self_fix / manufacturer_as / vendor_match 세 갈래로 분기한다.
class ReportResultScreen extends StatelessWidget {
  final Report report;

  const ReportResultScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분석 결과')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TODO: 디자인 적용 필요
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('분류: ${report.category ?? '알 수 없음'}'),
                    Text('심각도: ${report.severity ?? '알 수 없음'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBranch(context)),
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
        return const Center(child: Text('분석 결과를 확인할 수 없습니다.'));
    }
  }
}

class _SelfFixView extends StatelessWidget {
  final Report report;
  const _SelfFixView({required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('셀프 수리 가능', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // TODO: 디자인 적용 필요 - 임시 텍스트
        Expanded(
          child: SingleChildScrollView(
            child: Text(report.selfFixGuide ?? '셀프 수리 가이드 (임시 텍스트)\n\n1. 전원/급수를 차단하세요.\n2. 관련 부품을 점검하세요.\n3. 필요 시 교체 부품을 구매하세요.'),
          ),
        ),
      ],
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('제조사 A/S 안내', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // TODO: 디자인 적용 필요 - 임시 텍스트
        Expanded(
          child: (_asInfo == null || _asInfo!.isEmpty)
              ? const Text('제조사 A/S 정보 (임시 텍스트)\n\n연결된 제조사 A/S 정보가 없습니다.')
              : ListView.builder(
                  itemCount: _asInfo!.length,
                  itemBuilder: (context, index) {
                    final item = _asInfo![index];
                    return ListTile(
                      title: Text(item['name']?.toString() ?? '제조사'),
                      subtitle: Text(item['phone']?.toString() ?? ''),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _VendorMatchView extends StatefulWidget {
  final Report report;
  const _VendorMatchView({required this.report});

  @override
  State<_VendorMatchView> createState() => _VendorMatchViewState();
}

class _VendorMatchViewState extends State<_VendorMatchView> {
  List<Vendor>? _vendors;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ReportService.instance.matchVendors(reportId: widget.report.id);
      setState(() {
        _vendors = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '업체 매칭 정보를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('업체 매칭', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // TODO: 디자인 적용 필요 - 임시 텍스트
        Expanded(
          child: (_vendors == null || _vendors!.isEmpty)
              ? const Text('업체 매칭 결과 (임시 텍스트)\n\n매칭된 업체가 없습니다.')
              : ListView.builder(
                  itemCount: _vendors!.length,
                  itemBuilder: (context, index) {
                    final vendor = _vendors![index];
                    return ListTile(
                      title: Text(vendor.name),
                      subtitle: Text('${vendor.category ?? ''} · 평점 ${vendor.rating ?? '-'}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
