import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/features/announcements/presentation/pages/home_page.dart';
import 'package:campus_notify/messaging/push_service.dart';

class FakePushService implements PushService {
  @override
  Future<void> initialize({required Function(String route) onNavigate}) async {}

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('HomePage merender banner AI terisolasi dan daftar pengumuman lazy loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushServiceProvider.overrideWithValue(FakePushService()),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verifikasi AppBar
    expect(find.text('Kampus Notify'), findsOneWidget);

    // Verifikasi Banner AI Asisten yang dibungkus RepaintBoundary
    expect(find.text('AI Assistant Kampus'), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);

    // Verifikasi batch awal lazy loaded items
    expect(find.text('Pengumuman'), findsOneWidget);
    expect(find.text('Jadwal Kuliah Semester Ganjil 2026/2027'), findsOneWidget);
    expect(find.byType(AnnouncementItemTile), findsWidgets);

    // Verifikasi FAB
    expect(find.text('Tanya AI'), findsOneWidget);
  });
}
