# AI Verification & Code Refinement Report

Dokumen ini berisi catatan perbaikan dan penyesuaian yang dilakukan terhadap kode hasil AI Challenge pada Praktikum Minggu 4 (Networking & REST API).

---

## 1. Perbaikan pada Provider & Riverpod Layer (`lib/data/comment_provider.dart`)

* **Sintaks Family Superclass**: 
  AI awal menghasilkan deklarasi `extends FamilyAsyncNotifier<List<Comment>, int>` yang mengalami error `classes can only extend other classes` karena adanya ketidaksesuaian tipe generic pada Riverpod versi 2.x/3.x jika tidak menggunakan *code generation*.
  * **Solusi**: Memperbaiki sintaks class notifier dan meng-instansiasikannya menggunakan `AsyncNotifierProvider.family` agar kompatibel dan aman dijalankan tanpa bantuan *code generator*.

* **Penggunaan Client Dio Terpusat**:
  AI awal membuat instansiasi Dio baru di dalam provider.
  * **Solusi**: Memastikan `commentRepositoryProvider` memanfaatkan `dioProvider` yang sudah terkonfigurasi secara terpusat di `api_client.dart` (menggunakan `createDio()`).

* **Pesan Error Ramah Pengguna**:
  Fungsi `friendlyErrorMessage` disesuaikan untuk memetakan seluruh tipe `DioExceptionType`:
  * `connectionTimeout`, `sendTimeout`, `receiveTimeout` ➔ Pesan koneksi lambat/timeout.
  * `connectionError` ➔ Pesan gagal terhubung ke server.
  * `badResponse` (HTTP 404 & 500) ➔ Pesan spesifik dalam bahasa Indonesia yang ramah pengguna.

---

## 2. Perbaikan pada Unit & Widget Testing (`test/widget_test.dart`)

* **Pencegahan Pending Timer Test Error**:
  Pengujian widget test awal mengalami crash `A Timer is still pending even after the widget tree was disposed` karena widget `PagedPostPage` secara otomatis memicu pemanggilan HTTP request sungguhan via Dio saat di-render.
  * **Solusi**: Membuat class `FakePagedPostsNotifier` untuk meng-override `pagedPostsProvider` pada lingkungan pengujian widget test, sehingga panggilan jaringan dapat di-mock dan tes tidak menggantung.

* **Penambahan Edge Case pada Unit Test**:
  AI awal hanya membuat unit test *happy path* dan field hilang (*missing fields*).
  * **Solusi**: Menambahkan pengujian *edge case* baru pada `Comment.fromJson` untuk menangani skenario **tipe data tidak sesuai (*mismatched data types*)** (misalnya saat field ID bernilai `String` atau field nama bernilai `int`) guna memastikan parser tidak *crash* dan tetap mengembalikan nilai *default*.

---

## 3. Checklist Verifikasi Mandiri

| Kriteria Verifikasi | Status | Keterangan |
| :--- | :---: | :--- |
| **UI tidak memanggil Dio langsung** | ✅ Lolos | Pemanggilan Dio diisolasi di `CommentRepository`. UI hanya mengakses provider. |
| **`fromJson` aman null** | ✅ Lolos | Menggunakan *defensive casting* dengan nilai bawaan default (`as String? ?? ''`, `as int? ?? 0`). |
| **Pemetaan error lengkap** | ✅ Lolos | Mengcover timeout, connection error, 404, dan 500 dalam bahasa Indonesia. |
| **`baseUrl` & timeout terpusat** | ✅ Lolos | Terpusat melalui `createDio()` pada `lib/data/api_client.dart`. |
| **Unit test menguji edge case** | ✅ Lolos | Menguji kasus *field* hilang dan tipe data yang tidak sesuai (*mismatched types*). |
| **`flutter analyze` & `flutter test`** | ✅ Lolos | Lolos tanpa error atau warning (**No issues found!** & **All tests passed!**). |