import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _apiUrl;

  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String? apiUrl,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _apiUrl = apiUrl ??
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static const String systemInstruction =
      'Kamu adalah asisten kampus ramah dan cerdas untuk mahasiswa. '
      'Jawab dalam Bahasa Indonesia yang santun, jelas, dan informatif maksimal 3 kalimat. '
      'Jangan pernah meminta atau memberikan data pribadi sensitif seperti NIK, password, atau nomor telepon.';

  /// Mengirim pertanyaan ke Gemini AI API
  Future<String> ask(String question) async {
    // 1. Privasi: Validasi dan cegah pengiriman data sensitif pengguna
    if (_containsSensitiveData(question)) {
      throw Exception(
        'Permintaan dibatalkan: Terdeteksi potensi data sensitif (NIK/Password/Data Pribadi). Privasi Anda terjaga.',
      );
    }

    // 2. Ambil API Key dari flutter_secure_storage
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    // 3. Request ke API Gemini
    final url = Uri.parse('$_apiUrl?key=$apiKey');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    '$systemInstruction\n\nPertanyaan Mahasiswa: $question',
              }
            ],
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return text.trim();
          }
        }
      }
      return 'Maaf, asisten AI tidak memberikan respons yang dapat dibaca.';
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  /// Menyimpan API key ke flutter_secure_storage
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }

  /// Membaca API key dari flutter_secure_storage
  Future<String?> getApiKey() async {
    return await _storage.read(key: 'ai_api_key');
  }

  /// Menghapus API key dari storage
  Future<void> clearApiKey() async {
    await _storage.delete(key: 'ai_api_key');
  }

  /// Deteksi privasi: Cegah NIK atau kata kunci sensitif
  bool _containsSensitiveData(String input) {
    // Regex 16 digit angka (standar NIK di Indonesia)
    final nikRegex = RegExp(r'\b\d{16}\b');
    if (nikRegex.hasMatch(input)) return true;

    final lower = input.toLowerCase();
    final sensitiveKeywords = [
      'nik:',
      'password:',
      'pin atm',
      'nomor rekening',
      'kata sandi',
    ];
    for (final kw in sensitiveKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }
}

