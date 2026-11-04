import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_notify/ai/ai_service.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  group('AiService Unit Tests', () {
    late FakeSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorage();
    });

    test('Throw exception jika API Key belum tersedia', () async {
      final service = AiService(storage: fakeStorage);

      expect(
        () => service.ask('Halo apa kabar?'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API key tidak tersedia'),
          ),
        ),
      );
    });

    test('Privasi: Blokir pengiriman jika mengandung NIK (16 digit)', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'fake-api-key');
      final service = AiService(storage: fakeStorage);

      expect(
        () => service.ask('Data mahasiswa saya NIK 3507112233440001'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('data sensitif'),
          ),
        ),
      );
    });

    test('Privasi: Blokir kata kunci password atau rekening', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'fake-api-key');
      final service = AiService(storage: fakeStorage);

      expect(
        () => service.ask('Tolong catat password: rahasia123'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('data sensitif'),
          ),
        ),
      );
    });

    test('Sukses mendapatkan respons teks dari Gemini API saat 200 OK', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'fake-key-valid');

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], 'fake-key-valid');
        final responseBody = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Halo! Perkuliahan dimulai pukul 07.30 WIB.'}
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseBody), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = AiService(
        storage: fakeStorage,
        client: mockClient,
      );

      final reply = await service.ask('Kapan kuliah dimulai?');
      expect(reply, 'Halo! Perkuliahan dimulai pukul 07.30 WIB.');
    });

    test('Melempar exception jika API mengembalikan status error (bukan 200)', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'fake-key-invalid');

      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final service = AiService(
        storage: fakeStorage,
        client: mockClient,
      );

      expect(
        () => service.ask('Halo?'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Gagal memanggil AI API: 401'),
          ),
        ),
      );
    });

    test('Menyimpan dan membaca API Key dengan aman', () async {
      final service = AiService(storage: fakeStorage);

      await service.saveApiKey('test-key-123');
      final storedKey = await service.getApiKey();
      expect(storedKey, 'test-key-123');

      await service.clearApiKey();
      final clearedKey = await service.getApiKey();
      expect(clearedKey, isNull);
    });
  });
}
