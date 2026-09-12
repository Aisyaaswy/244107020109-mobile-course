import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:week3_todo/pages/stats_page.dart';

/// Class FakeRandom untuk mengontrol keluaran acak saat pengujian.
class FakeRandom implements Random {
  final double valueToReturn;
  FakeRandom(this.valueToReturn);

  @override
  double nextDouble() => valueToReturn;

  @override
  bool nextBool() => throw UnimplementedError();
  @override
  int nextInt(int max) => throw UnimplementedError();
}

void main() {
  group('StatsNotifier Unit Tests', () {
    test('Mengembalikan list statistik saat fetch berhasil (Random >= 0.3)', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            statsProvider.overrideWith(() => StatsNotifier(FakeRandom(0.5))),
          ],
        );
        addTearDown(container.dispose);

        // 1. Cek state awal (AsyncLoading)
        expect(
          container.read(statsProvider),
          const AsyncLoading<List<StatItem>>(),
        );

        // 2. Lompatkan waktu 2 detik instan untuk melewati Future.delayed
        async.elapse(const Duration(seconds: 2));

        // 3. Verifikasi hasil data
        final state = container.read(statsProvider);
        expect(state.hasValue, isTrue);
        expect(state.value?.length, equals(3));
        expect(state.value?[0].title, equals('Total Pengguna'));
      });
    });

    test('Melempar Exception saat fetch gagal (Random < 0.3)', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            statsProvider.overrideWith(() => StatsNotifier(FakeRandom(0.1))),
          ],
        );
        addTearDown(container.dispose);

        // 1. Cek state awal (AsyncLoading)
        expect(
          container.read(statsProvider),
          const AsyncLoading<List<StatItem>>(),
        );

        // 2. Lompatkan waktu 2 detik instan untuk melewati Future.delayed
        async.elapse(const Duration(seconds: 2));

        // 3. Verifikasi state menandakan error
        final state = container.read(statsProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<Exception>());
      });
    });
  });
}