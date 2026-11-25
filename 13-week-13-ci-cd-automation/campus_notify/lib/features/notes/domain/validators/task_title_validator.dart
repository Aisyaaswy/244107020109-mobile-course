/// Validator aturan bisnis judul tugas / catatan kampus
/// Mencakup validasi teks normal, kasus tepi (edge cases), dan batas panjang teks
class TaskTitleValidator {
  static const int minLength = 3;
  static const int maxLength = 100;

  /// Memeriksa apakah judul valid sesuai aturan bisnis
  static bool isValid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < minLength || trimmed.length > maxLength) return false;
    return true;
  }

  /// Mengembalikan pesan error jika tidak valid, atau null jika valid
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul tugas tidak boleh kosong';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return 'Judul minimal harus berisi $minLength karakter';
    }
    if (trimmed.length > maxLength) {
      return 'Judul maksimal berisi $maxLength karakter';
    }
    return null;
  }
}
