import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  List<Report>? _reports;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await ReportService.instance.getReports();
      setState(() {
        _reports = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '요청 내역을 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('요청 내역')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
        ],
      );
    }
    // TODO: 디자인 적용 필요
    if (_reports == null || _reports!.isEmpty) {
      return ListView(children: const [SizedBox(height: 80), Center(child: Text('등록된 요청이 없습니다.'))]);
    }
    return ListView.separated(
      itemCount: _reports!.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final report = _reports![index];
        return ListTile(
          title: Text(report.category ?? '분류 대기 중'),
          subtitle: Text(report.description ?? ''),
          trailing: Text(report.status ?? ''),
          onTap: () => context.push('/tenant/reports/result', extra: report),
        );
      },
    );
  }
}
