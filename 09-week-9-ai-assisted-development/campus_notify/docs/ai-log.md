# AI Interaction & Verification Log (`docs/ai-log.md`)

| Key | Value |
| --- | --- |
| **Mata Kuliah** | Pemrograman Mobile |
| **Topik** | #09 AI-Assisted Development / Vibe Coding |
| **NIM** | 244107020109 |
| **Nama** | Aisya Aswy Nur Aidha |
| **Kelas** | TI - 3H |
| **Fitur yang Dikerjakan** | Pencarian Judul Catatan (*Search Notes by Title*) & Empty State |
| **Target Proyek** | `campus_notify` (Refactor Feature-First Clean Architecture) |

---

## 1. Praktikum 1: Prompt & Context Engineering

### A. Formula 5 Slot
Dalam codelab ini, prompt disusun secara terstruktur menggunakan formula 5 slot:
1. **Peran (*Role*)**: Senior Flutter Developer dengan spesialisasi Clean Architecture & Riverpod.
2. **Konteks (*Context*)**:
   - Struktur proyek: *Feature-First Clean Architecture* pada Flutter.
   - Pustaka: `flutter_riverpod: ^3.4.3`, `sqflite`, `dio`.
   - Kontrak entitas domain:
     ```dart
     class Note {
       final int? id;
       final String title;
       final String body;
       final DateTime updatedAt;
       final bool dirty;
     }
     ```
   - Aturan arsitektur: `Presentation -> Domain <- Data`. Domain harus steril dari pustaka pihak ketiga/framework.
3. **Tugas (*Task*)**:
   - Menambahkan fitur pencarian (search) judul catatan secara *in-memory* pada daftar catatan yang telah di-fetch.
   - Menyediakan tampilan *empty state* yang informatif saat catatan tidak ditemukan.
4. **Batas (*Constraints*)**:
   - Jangan merusak struktur Clean Architecture yang ada.
   - Jangan memanggil database (SQLite) langsung dari widget UI.
   - Setiap fungsi/method di UI dibatasi maksimal 40 baris.
   - Hindari *over-engineering*.
5. **Output**:
   - Kode Dart lengkap (Use Case, Provider Riverpod, Widget UI).
   - Minimal 3 unit/widget test cases pembukti keberhasilan fitur.
   - Panduan cara verifikasi dan pengujian.

### B. Prompt Mentah yang Diberikan (Raw Prompt)
```text
Bertindaklah sebagai Senior Flutter Developer.
Proyek kita adalah 'campus_notify' dengan arsitektur Feature-First Clean Architecture.
Stack yang dipakai: flutter_riverpod (versi 3.x), sqflite, dio.
Model domain entitas:
class Note {
  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}

Tugas:
Buat fitur pencarian judul catatan (notes) secara in-memory lengkap dengan empty state jika hasil tidak ditemukan.

Batasan:
1. Ikuti prinsip Clean Architecture: UI (Widget) -> State (Notifier) -> Use Case (Domain) -> Repository.
2. Jangan memanggil SQLite langsung dari widget.
3. Layer domain harus steril dari package Flutter/Dio/SQLite.
4. Pecah fungsi widget agar tidak melebihi 40 baris.
5. Berikan 3 test case (sukses, query kosong, dan query tak cocok).
```

---

## 2. Praktikum 2: Output Awal AI & Verifikasi 6 Langkah

### A. Output Awal AI Mentah (Raw AI Proposal)
```dart
// domain/usecases/search_notes.dart
import 'package:flutter/foundation.dart'; // Pelanggaran: import framework di domain!
import '../entities/note.dart';

class SearchNotes {
  List<Note> call(List<Note> notes, String query) {
    if (query.isEmpty) return notes;
    // Logika Bug: Menggunakan contains case-sensitive tanpa toLowerCase() dan tanpa trim
    return notes.where((note) => note.title.contains(query)).toList();
  }
}

// presentation/providers/notes_providers.dart
// Pelanggaran Package Kadaluarsa: StateProvider tidak ada di Riverpod 3.x!
final noteSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).value ?? [];
  final query = ref.watch(noteSearchQueryProvider);
  return SearchNotes().call(notes, query);
});
```

### B. Log Verifikasi 6 Langkah

| Langkah | Item Pemeriksaan | Hasil Temuan | Status |
| --- | --- | --- | :---: |
| **1. Baca Tiap Baris** | Menelaah setiap baris kode yang diusulkan AI | Ditemukan import framework di layer domain, penggunaan `contains` case-sensitive, dan penggunaan API usang `StateProvider`. | **DITANDAI** |
| **2. Cek Import** | Memastikan `domain/` bebas dari Flutter/Dio/SQLite | Ditemukan `import 'package:flutter/foundation.dart';` pada usulan usecase AI. Wajib dibersihkan menjadi pure Dart. | **GAGAL (Lalu Diperbaiki)** |
| **3. Cek API Nyata** | Cek ketersediaan class/method pada package versi aktif | AI sempat mengusulkan `noteRepository.searchFuzzy(query)` dan `StateProvider<String>`. Tidak ada di kontrak repositori lokal dan tidak ada di Riverpod 3.x. | **GAGAL (Lalu Disesuaikan)** |
| **4. Flutter Analyze** | Menjalankan analisis statis (`flutter analyze`) | Muncul error fatal: `Error: Method not found: 'StateProvider'` saat menggunakan kode bawaan AI. | **GAGAL (Lalu Diperbaiki)** |
| **5. Tulis Test Bukti** | Menulis unit test pembukti bug (Test Merah) | Test case-insensitive `expect(searchNotes(list, 'belanja'), hasLength(2))` gagal karena kode AI menghasilkan `[]` (length 0). | **BUKTI BUG DITEMUKAN** |
| **6. Uji Manual** | Menguji query kosong, cocok, dan tak cocok | Query kosong menampilkan 4 data; query 'belanja' berhasil memfilter 2 data; query 'zzz tak ada' menampilkan empty state yang rapi. | **LOLOS** |

---

## 3. Temuan Bug & Halusinasi AI (Bukti Wajib)

Sesuai ketentuan codelab, berikut adalah 3 bukti halusinasi dan bug dari usulan AI:

### 1. Bug Logika: Pencarian Bersifat Case-Sensitive (*Logika Yakin Tapi Salah*)
* **Deskripsi**: AI menggunakan ekspresi `note.title.contains(query)`. Jika pengguna mengetikkan kata kunci `"belanja"`, catatan berjudul `"Belanja Mingguan"` atau `"Daftar BELANJA Elektronik"` tidak akan ditemukan.
* **Cara Membuktikan (Test Merah)**:
  Dibuat berkas pengujian `test/search_notes_test.dart` dengan kode pengujian:
  ```dart
  test('filter abaikan huruf besar/kecil', () {
    final result = searchNotes(list, 'belanja');
    expect(result, hasLength(2));
  });
  ```
* **Hasil Eksekusi Test Merah**:
  ```text
  00:00 +1 -1: SearchNotes Use Case Tests filter abaikan huruf besar/kecil [E]
    Expected: an object with length of <2>
      Actual: []
       Which: has length of <0>
    
    package:matcher expect
    test\search_notes_test.dart 46:7 main.<fn>.<fn>
  ```
  Test tersebut membuktikan secara valid bahwa logika AI memiliki cacat logika (*silent logic bug*).

### 2. Halusinasi Package Kadaluarsa: `StateProvider` pada Riverpod 3.x
* **Deskripsi**: AI mengusulkan `final noteSearchQueryProvider = StateProvider<String>((ref) => '');`.
* **Kenyataan**: Pada `pubspec.yaml`, proyek menggunakan `flutter_riverpod: ^3.4.3`. Pada Riverpod 3.x, `StateProvider` telah dihilangkan dan diganti dengan arsitektur `NotifierProvider` + `Notifier<T>`.
* **Bukti Error Terminal**:
  ```text
  lib/features/notes/presentation/providers/notes_providers.dart:32:33: Error: Method not found: 'StateProvider'.
  final noteSearchQueryProvider = StateProvider<String>((ref) => '');
                                  ^^^^^^^^^^^^^
  ```

### 3. Pelanggaran Batas Arsitektur (*Architectural Boundary Violation*)
* **Deskripsi**: AI memasukkan `import 'package:flutter/foundation.dart';` pada file domain `search_notes.dart` dan menyarankan penyaringan langsung pada method `build` di widget.
* **Bukti Grep/Pemeriksaan**:
  Pemeriksaan direktori `domain/` menemukan ketergantungan terhadap framework Flutter yang melanggar *Dependency Rule*.

---

## 4. Praktikum 3: Debug & Refactoring ke Clean Architecture

### A. Alur Debugging dengan Test Merah (Red-to-Green Workflow)
1. **Reproduksi**: Menguji filter judul catatan dengan input huruf kecil `"belanja"` terhadap judul catatan yang mengandung huruf besar.
2. **Isolasi**: Memindahkan seluruh logika filter ke use case murni `SearchNotes` di layer `features/notes/domain/usecases/search_notes.dart` tanpa dependensi UI.
3. **Test Merah**: Mengonfirmasi kegagalan pengujian unit dengan kode status exit 1.
4. **Perbaikan Kecil**:
   - Menambahkan `.trim().toLowerCase()` pada query dan judul catatan:
     ```dart
     final trimmedQuery = query.trim().toLowerCase();
     if (trimmedQuery.isEmpty) return notes;
     return notes.where((note) => note.title.toLowerCase().contains(trimmedQuery)).toList();
     ```
   - Mengubah penyedia state Riverpod menjadi `NotifierProvider<NoteSearchQueryNotifier, String>`.
5. **Test Hijau**: Menjalankan ulang `flutter test test/search_notes_test.dart` -> **All tests passed!**

### B. Refactor ke Layer yang Benar

```
[UI Widget (NotesPage, NoteSearchBar, NotesEmptyView)]
           |  (hanya membaca state & mengirim event)
           v
[State Notifier (notes_providers.dart)]
           |  (menggabungkan data async & string query)
           v
[Domain Use Case (SearchNotes)]
           |  (aturan murni pemfilteran in-memory)
           v
[Domain Repository Interface (NoteRepository)]
           |  (kontrak sumber data)
           v
[Data Repository Implementation (NoteRepositoryImpl)]
```

### C. Pemecahan Fungsi Maksimal 40 Baris
Seluruh komponen UI pada `notes_page.dart` dipecah menjadi *reusable private/public widgets*:
- `NotesPage.build()`: 35 baris (hanya mengorkestrasi Scaffold, SearchBar, dan body state).
- `_NoteSearchBarState.build()`: 34 baris (hanya mengelola TextField dan tombol clear).
- `NotesEmptyView.build()`: 24 baris (menampilkan ilustrasi ikon dan teks kondisi kosong).
- `NotesList.build()`: 15 baris (menampilkan ListView catatan).
- `ErrorView.build()`: 22 baris (menampilkan pesan error dan tombol coba lagi).

Tidak ada satupun fungsi di atas 40 baris dan tidak ada pemanggilan database langsung dari widget.

---

## 5. Keputusan Terima, Tolak, dan Modifikasi (Decision Log)

| Usulan Kode AI | Keputusan | Alasan Teknis |
| --- | :---: | --- |
| Pembuatan use case `SearchNotes` untuk pemfilteran judul | **DITERIMA** | Memisahkan aturan bisnis pencarian dari UI widget, memudahkan pengujian unit murni tanpa mock widget. |
| Penggunaan `contains()` langsung tanpa normalisasi string | **DITOLAK** | Menimbulkan bug case-sensitivity (gagal menemukan teks bila kapitalisasinya berbeda). Diganti dengan `.trim().toLowerCase()`. |
| Penggunaan `StateProvider<String>` | **DITOLAK** | Tidak kompatibel dengan `flutter_riverpod: ^3.4.3`. Diganti dengan `NotifierProvider` turunan `Notifier<String>`. |
| Import `package:flutter/foundation.dart` di layer domain | **DITOLAK** | Melanggar *Clean Architecture Dependency Rule* (Domain harus murni Dart tanpa framework). |
| Penambahan `NotesEmptyView` dengan deteksi status pencarian | **DIMODIFIKASI** | Ditambahkan visual pembeda antara kondisi "database kosong" vs "hasil pencarian tidak ditemukan". |
| Pemisahan widget menjadi `NoteSearchBar` terisolasi | **DITERIMA** | Menjaga ukuran fungsi di bawah 40 baris dan mempermudah pengujian widget secara modular. |

---

## 6. Verifikasi Akhir Mesin

Hasil eksekusi tiga perintah verifikasi mesin:

1. **`flutter test`**:
   - `test/auth_push_test.dart` (4 tests) -> Lolos
   - `test/get_notes_test.dart` (2 tests) -> Lolos
   - `test/search_notes_test.dart` (4 tests) -> Lolos
   - `test/notes_page_search_widget_test.dart` (4 widget tests) -> Lolos
   - `test/widget_test.dart` (1 test) -> Lolos
   - **Total**: 15 tests passed!

2. **`flutter analyze`**:
   - `No issues found!` (0 error, 0 warning).

3. **`dart format --set-exit-if-changed .`**:
   - `Formatted 34 files (0 changed) in 0.24 seconds.` (Kode 100% rapi dan standar).
