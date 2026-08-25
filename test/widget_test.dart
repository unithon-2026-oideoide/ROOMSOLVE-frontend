import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:frontend/main.dart';

void main() {
  // flutter_secure_storage는 실제 Keychain/Keystore를 호출하려고 시도하는데,
  // flutter test 환경에는 해당 플랫폼 구현체가 없어 응답 없이 멈춰버린다.
  // 테스트에서는 채널을 모킹해 항상 빈 값을 반환하도록 한다.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (call) async => null,
  );

  testWidgets('앱 시작 시 로그인 화면이 보인다', (WidgetTester tester) async {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000');

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsWidgets);
  });
}
