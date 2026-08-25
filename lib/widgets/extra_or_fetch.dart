import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_top_bar.dart';

/// go_router 라우트가 `extra`로 넘겨받은 객체가 있으면 그대로 쓰고, 없으면
/// (웹에서 새로고침했거나 링크로 직접 들어온 경우 — go_router는 `extra`를
/// 앱 상태로만 들고 있어 페이지가 다시 로드되면 항상 null이다) [loader]로
/// 같은 데이터를 다시 불러와 같은 화면을 구성한다.
///
/// 예전에는 각 라우트가 `state.extra as Report`처럼 강제 캐스팅해서, extra가
/// 없는 상황(웹 새로고침 등)에 타입 캐스팅 예외로 화면이 그대로 죽었다.
class ExtraOrFetch<T> extends StatefulWidget {
  const ExtraOrFetch({
    super.key,
    required this.initial,
    required this.loader,
    required this.builder,
    this.notFoundMessage = '정보를 찾을 수 없습니다.',
    this.fallbackRoute,
    this.fallbackLabel = '돌아가기',
  });

  /// 라우트의 `state.extra`에서 온 값(타입이 맞을 때만). 없으면 null.
  final T? initial;

  /// initial이 없을 때 다시 불러오는 함수. 데이터가 없으면(예: 삭제됨) null을
  /// 돌려주고, 조회 자체가 실패하면 예외를 던지면 된다 — 둘 다 아래 화면에서
  /// 알아서 안내한다.
  final Future<T?> Function() loader;

  final Widget Function(BuildContext context, T value) builder;

  final String notFoundMessage;

  /// "돌아가기" 버튼을 누르면 이동할 경로. null이면 버튼을 보여주지 않는다.
  final String? fallbackRoute;
  final String fallbackLabel;

  @override
  State<ExtraOrFetch<T>> createState() => _ExtraOrFetchState<T>();
}

class _ExtraOrFetchState<T> extends State<ExtraOrFetch<T>> {
  late final Future<T?> _future = widget.initial != null ? Future.value(widget.initial) : widget.loader();

  @override
  Widget build(BuildContext context) {
    if (widget.initial != null) return widget.builder(context, widget.initial as T);

    return FutureBuilder<T?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StatusScaffold(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          final err = snapshot.error;
          final message = err is ApiException ? err.message : '정보를 불러오지 못했습니다: $err';
          return _StatusScaffold(child: _Message(message, fallback: _fallbackButton(context)));
        }
        final value = snapshot.data;
        if (value == null) {
          return _StatusScaffold(child: _Message(widget.notFoundMessage, fallback: _fallbackButton(context)));
        }
        return widget.builder(context, value);
      },
    );
  }

  Widget? _fallbackButton(BuildContext context) {
    final route = widget.fallbackRoute;
    if (route == null) return null;
    return TextButton(
      onPressed: () => context.go(route),
      child: Text(widget.fallbackLabel, style: AppTextStyles.bodySemiBold14(color: AppColors.brandMain)),
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.fallback});
  final String text;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
            if (fallback != null) ...[const SizedBox(height: 12), fallback!],
          ],
        ),
      ),
    );
  }
}
