import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/main.dart';
import 'package:campus_notify/messaging/push_service.dart';

// Fake PushService agar tidak mengakses Firebase native di unit test
class FakePushService implements PushService {
  @override
  Future<void> initialize({required Function(String route) onNavigate}) async {
    // Kosongkan agar tidak mengeksekusi Firebase asli saat diuji
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MyApp renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushServiceProvider.overrideWithValue(FakePushService()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MyApp), findsOneWidget);
  });
}