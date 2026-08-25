import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

/// 수리기사용 화면. 시간 남으면 채울 자리 - 지금은 스켈레톤만.
class TechnicianJobListScreen extends StatelessWidget {
  const TechnicianJobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('작업 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: const Center(
        // TODO: 디자인 적용 필요 / 기능 구현 필요
        child: Text('수리기사 기능은 준비 중입니다.'),
      ),
    );
  }
}
