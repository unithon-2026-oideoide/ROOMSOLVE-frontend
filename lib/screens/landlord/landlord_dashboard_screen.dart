import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../services/landlord_service.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  List<Map<String, dynamic>>? _requests;
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
      final result = await LandlordService.instance.getRequests();
      setState(() {
        _requests = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '요청 목록을 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('임대인 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/landlord/auto-approval'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
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
    if (_requests == null || _requests!.isEmpty) {
      return ListView(children: const [SizedBox(height: 80), Center(child: Text('대기 중인 요청이 없습니다.'))]);
    }
    return ListView.separated(
      itemCount: _requests!.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final request = _requests![index];
        final id = request['id']?.toString() ?? '';
        return ListTile(
          title: Text(request['title']?.toString() ?? '요청 #$id'),
          subtitle: Text(request['status']?.toString() ?? ''),
          onTap: () => context.push('/landlord/requests/$id'),
        );
      },
    );
  }
}
