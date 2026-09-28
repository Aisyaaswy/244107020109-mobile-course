|  | Pemrograman Mobile |
|--|--|
| NIM |  244107020109|
| Nama |  Aisya Aswy Nur Aidha |
| Kelas | TI - 3H |

# **WEEK 5 - Local Storage & Offline First**

## **Praktikum 1 - SharedPreferences**

Persiapan project
![screenshots](screenshots/create.png)
![screenshots](screenshots/add.png)

Struktur folder

![screenshots](screenshots/structure.png)

Membuat file prefs.dart dan settings_page.dart.

## **Praktikum 2 - SQLite dan repository catatan**

Membuat file note.dart dan file db.page.dart

## **Praktikum 3 - Cache-first dan antrean sync**

Berdasarkan hasil pengujian yang telah dilakukan, mekanisme Cache-First pada aplikasi berhasil dijalankan dengan baik. Aplikasi mampu menampilkan data postingan secara instan dari penyimpanan lokal SQLite cached_posts saat pertama kali dibuka maupun dalam kondisi tanpa koneksi internet. Proses fetching data dari API JSONPlaceholder melalui Dio yang berjalan di background juga secara otomatis memperbarui cache lokal tanpa mengganggu responsivitas antarmuka pengguna (UI).

### Simulasi Offline yang Deterministik & Sinkronisasi Data

Untuk mempermudah pengujian tanpa bergantung pada kondisi koneksi internet atau Wi-Fi, aplikasi menyediakan dua mekanisme pengujian offline: menggunakan mode pesawat sungguhan dan sakelar *Simulasi Force Offline* pada provider.

---

#### 1. Langkah-Langkah Pengujian

1. **Pengujian Kondisi Offline (Force Offline / Mode Pesawat):**
   * Aktifkan sakelar *Simulasi Force Offline* melalui Halaman Pengaturan (atau matikan Wi-Fi / aktifkan Mode Pesawat pada perangkat).
   * Buka kembali Halaman Utama Catatan.
   * Tambahkan beberapa catatan baru.
   * **Observasi:** Catatan baru berhasil tersimpan ke SQLite lokal, catatan tetap tampil di daftar, dan indikator *badge* pada ikon awan secara akurat menunjukkan jumlah catatan *dirty* (misalnya angka **2**).

2. **Pengujian Sinkronisasi Data (`syncNotes`):**
   * Nonaktifkan sakelar *Simulasi Force Offline* di Pengaturan (atau nyalakan kembali koneksi Wi-Fi/data).
   * Tekan tombol ikon awan di `AppBar` untuk menjalankan proses sinkronisasi (`syncNotes`).
   * **Observasi:** Aplikasi memperbarui status `dirty` dari `2` menjadi `0` pada database SQLite. Indikator *badge* angka pada ikon awan otomatis hilang, dan SnackBar konfirmasi sinkronisasi muncul di layar.

---

#### 2. Hasil Observasi Sinkronisasi

| Parameter | Sebelum Sinkronisasi (Offline) | Sesudah Sinkronisasi (Online + `syncNotes`) |
| :--- | :--- | :--- |
| **Status Koneksi** | Force Offline / Mode Pesawat Aktif | Online / Force Offline Mati |
| **Nilai `dirty` SQLite** | `2` (Catatan Kotor) | `0` (Tersinkronisasi) |
| **Jumlah Badge Awan** | Menampilkan angka sesuai jumlah catatan baru (misal: **2**) | **0** (Badge Otomatis Hilang) |
| **Pesan Antarmuka** | Indikator `sync_problem` warna oranye pada item | SnackBar konfirmasi berhasil sinkron |

---

#### 3. Lampiran Screenshot Pengujian

Seluruh gambar hasil pengujian telah disimpan ke dalam folder `screenshots/`:

### Tabel Lampiran Bukti Pengujian Sync & Force Offline

| No | File Screenshot | Kondisi & Fitur | Keterangan Observasi |
| :---: | :--- | :--- | :--- |
| 1 | ![screenshots](screenshots/force_offline_on.jpeg) | **Force Offline Aktif** | Sakelar *Simulasi Force Offline* diaktifkan pada Halaman Pengaturan untuk memutus koneksi API. |
| 2 | ![screenshots](screenshots/dirty_notes_offline.jpeg) | **Catatan Kotor (Dirty)** | Penambahan 2 catatan baru saat offline. Terdapat indikator oranye pada item dan *badge* angka **2** pada ikon awan (`dirty = 2`). |
| 3 | ![screenshots](screenshots/force_offline_off.jpeg) | **Force Offline Mati** | Sakelar *Simulasi Force Offline* dimatikan kembali untuk mensimulasikan koneksi internet yang terhubung. |
| 4 | ![screenshots](screenshots/sync_success.jpeg) | **Hasil Sinkronisasi** | Setelah tombol awan ditekan, timbul SnackBar *"2 catatan berhasil disinkronkan"*, indikator oranye hilang, dan *badge* kembali ke **0** (`dirty = 0`). |

### Aturan Konflik

Aplikasi ini menerapkan kebijakan Last-Write-Wins (LWW) berbasis stempel waktu updated_at untuk menangani konflik data saat proses sinkronisasi dua arah. Tanpa aturan ini, data lokal dan data server berisiko saling menimpa secara diam-diam (silent overwriting) yang dapat menghilangkan perubahan terbaru. Setiap kali catatan dibuat atau diubah, kolom updated_at pada tabel SQLite otomatis menyimpan stempel waktu terkini dalam format ISO-8601 melalui model Note. Saat sinkronisasi dilakukan, sistem akan membandingkan stempel waktu antara data lokal dan server untuk ID catatan yang sama, lalu mempertahankan versi data dengan stempel waktu paling baru.

## **AI Challenge: Perbandingan dan Justifikasi Pemilihan Storage**
Peran AI pada bagian ini adalah memberikan opsi dan analisis teknis. Keputusan akhir dan justifikasi pemilihan teknologi sepenuhnya ditentukan oleh pengembang.

---

#### 1. Tabel Perbandingan Opsi Storage

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
| :--- | :--- | :--- | :--- | :--- |
| **Kompleksitas Query** | Sangat Rendah (Key-Value) | Rendah (Filter Objek Manually) | Tinggi (SQL Native) | Sangat Tinggi (Type-safe SQL/Dart) |
| **Kebutuhan Relasi** | Tidak Ada | Terbatas (Manual Linking) | Ya (Foreign Key, Join) | Ya (Relasi Terstruktur & Type-safe) |
| **Reaktivitas (Stream)** | Tidak Ada (Manual Polling) | Ya (`Watchable`) | Tidak Ada (Perlu Riverpod/StreamController) | Ya (Native Stream/Reactive Queries) |
| **Type-Safety** | Sangat Rendah (Dynamic) | Sedang (Perlu TypeAdapter) | Rendah (Manual Map Mapping) | Sangat Tinggi (Code Generation) |
| **Ukuran Boilerplate** | Sangat Kecil | Sedang | Sedang ke Tinggi | Tinggi (Perlu Code Gen / `build_runner`) |
| **Kemudahan Testing** | Sangat Mudah (Mocking) | Mudah | Sedang (Perlu SQLite Binary) | Sangat Mudah (In-memory Database) |

---

#### 2. Trade-Off Masing-Masing Pilihan

* **SharedPreferences:**
  * *Kelebihan:* Sangat ringan, mudah digunakan, tanpa *boilerplate*.
  * *Kekurangan:* Tidak dirancang untuk data terstruktur, tidak mendukung kueri kompleks atau pencarian, dan seluruh data dimuat ke memori.
* **Hive:**
  * *Kelebihan:* Performa *read/write* sangat cepat, *schemaless*, dan mendukung reaktivitas.
  * *Kekurangan:* Pengelolaan relasi antar data cukup rumit dan rawan error jika terjadi perubahan struktur objek (*breaking changes* pada adapter).
* **sqflite (SQLite):**
  * *Kelebihan:* Standar industri untuk relational database, sangat stabil, mendukung kueri SQL kompleks (`WHERE`, `JOIN`, status `dirty`).
  * *Kekurangan:* Banyak *boilerplate code*, penulisan SQL berbasis string (raw string) rawan *typo*, dan tidak ada reaktivitas bawaan.
* **Drift:**
  * *Kelebihan:* Menawarkan seluruh kekuatan SQLite dengan fitur *type-safety*, reaktivitas *stream*, dan kemudahan *testing* via *in-memory database*.
  * *Kekurangan:* Membutuhkan proses *build_runner* (code generation) yang menambah kompleksitas *setup* awal.

---

#### 3. Rekomendasi Final & Justifikasi

| Kebutuhan Aplikasi | Pilihan Storage Terbaik | Alasan & Justifikasi Utama |
| :--- | :--- | :--- |
| **Preferensi Tema (`isDarkMode`)** | **SharedPreferences** | Data bersifat *key-value* sederhana, berukuran sangat kecil, dan membutuhkan pengaksesan cepat saat *startup* tanpa memerlukan kueri database. |
| **Catatan (`CRUD + Sync Status`)** | **sqflite (SQLite)** | Membutuhkan kueri terstruktur untuk memfilter status sinkronisasi (`WHERE dirty = 1`), mendukung pembuatan indeks, serta memastikan konsistensi data lokal jangka panjang. |

---

#### 4. Skema Database & Kinerja untuk 1000+ Catatan

Untuk menangani **1000+ catatan** secara efisien di SQLite, dibuat skema tabel yang mencakup **Indeks (`INDEX`)** pada kolom `dirty` dan `updated_at` guna mempercepat kueri pencarian dan sinkronisasi.

##### A. Visualisasi Skema Kotak (Entity Diagram)

```text
+-----------------------------------------------------------------------+
|                             TABLE: notes                              |
+---------------------+-------------------+-----------------------------+
| Column Name         | Data Type         | Constraints / Attributes    |
+---------------------+-------------------+-----------------------------+
| id                  | INTEGER           | PRIMARY KEY AUTOINCREMENT   |
| title               | TEXT              | NOT NULL                    |
| body                | TEXT              | DEFAULT ''                  |
| updated_at          | TEXT              | NOT NULL (ISO-8601 String)  |
| dirty               | INTEGER           | NOT NULL DEFAULT 1 (0 or 1) |
+---------------------+-------------------+-----------------------------+
| INDEXES:                                                              |
| - idx_notes_dirty   ON notes(dirty)     --> Mempercepat count/sync    |
| - idx_notes_updated ON notes(updated_at)--> Mempercepat sort/LWW      |
+-----------------------------------------------------------------------+
```

##### B. Kode DDL Pembuatan Tabel & Indeks

```sql
-- Tabel Utama
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT DEFAULT '',
    updated_at TEXT NOT NULL,
    dirty INTEGER NOT NULL DEFAULT 1
);

-- Indeks untuk Optimasi Performance Kueri 1000+ Data
CREATE INDEX idx_notes_dirty ON notes(dirty);
CREATE INDEX idx_notes_updated ON notes(updated_at);
```

### AI Verification Checklist & Temuan Evaluasi

Sebelum merekomendasikan atau memutuskan opsi *storage*, dilakukan verifikasi teknis terhadap usulan awal AI guna memastikan kesesuaian dengan kebutuhan aplikasi.

---

#### 1. Hasil Verifikasi Temuan AI

* **Apakah AI menempatkan daftar catatan di `SharedPreferences`?**
  * **Temuan & Sikap:** Ditolak. `SharedPreferences` tidak cocok untuk menyimpan koleksi daftar catatan. Menyimpan list objek dalam bentuk JSON String pada `SharedPreferences` sangat rapuh, tidak mendukung pencarian/kueri, dan memiliki risiko kegagalan *parsing* yang tinggi saat data bertambah banyak.

* **Apakah skema AI mendukung antrean sync (`dirty` flag / `updated_at`) atau hanya CRUD polos?**
  * **Temuan & Sikap:** Diterima. Skema yang dirancang telah mencakup atribut `dirty` (INTEGER 0/1) untuk antrean sinkronisasi serta `updated_at` (TEXT ISO-8601) untuk menangani aturan konflik *Last-Write-Wins* (LWW), bukan sekadar CRUD dasar.

* **Apakah klaim "real-time" AI didukung stream (`Drift`/`watch`) atau hanya asumsi?**
  * **Temuan & Sikap:** Diverifikasi. Klaim *real-time* pada `Drift` dan `Hive` terbukti didukung oleh *native stream* (`watch()`). Namun pada `sqflite`, fungsi *real-time* tidak tersedia secara *native* dan harus dikombinasikan dengan *state management* seperti Riverpod (`ref.invalidate()`) atau `StreamController`.

* **Apakah estimasi *boilerplate* AI masuk akal setelah mencoba instalasinya?**
  * **Temuan & Sikap:** Masuk akal. Penggunaan `sqflite` membutuhkan *boilerplate* sedang (penulisan fungsi *helper* database & map *converter*). Sementara `Drift` membutuhkan proses konfigurasi awal dan *build_runner* yang cukup memakan waktu di awal, tetapi memudahkan penulisan kode di tahap selanjutnya.

---

#### 2. Keputusan Final & Argumen Justifikasi

* **Preferensi Aplikasi (Tema & Waktu Buka):** Menggunakan **`SharedPreferences`**.
  * **Argumen:** Data berukuran sangat kecil, berstruktur *key-value*, dan perlu dibaca secara instan saat aplikasi pertama kali dijalankan tanpa beban pemuatan database.

* **Penyimpanan Catatan & Cache API:** Menggunakan **`sqflite` (SQLite)**.
  * **Argumen:** Kebutuhan fitur memerlukan kueri terstruktur untuk memfilter status sinkronisasi (`WHERE dirty = 1`), perhitungan jumlah *dirty data*, serta pengurutan stempel waktu. SQLite terbukti stabil, efisien untuk skema lokal, dan tidak memerlukan pustaka *code generation* tambahan.


## **REFACTORING, TESTING dan ERROR UMUM**
### **Refactoring Challenge**

| Tantangan Refactoring | Bukti Tangkapan Layar | Deskripsi | Bukti Potongan Kode |
|---|---|---|---|
| Ekstrak Widget NoteTile | ![screenshots](screenshots/ekstrak_widget.jpeg)| Antarmuka daftar catatan yang menampilkan indikator "Belum tersinkron" | ![screenshots](screenshots/note_dirty.png)Blok kode `if (note.dirty)` pada file `lib/widgets/note_tile.dart` |
| Pemisahan logika sync.dart | ![screenshots](screenshots/sync.png) | Panel struktur direktori editor yang menampilkan file `lib/data/sync.dart` | ![screenshots](screenshots/dirty_notes.png) ![screenshots](screenshots/load.png) Fungsi `syncDirtyNotes` dan `loadPostsCacheFirst` pada file `sync.dart` |
| Halaman detail GoRouter | ![screenshots](screenshots/gorouter.jpeg) | Antarmuka halaman detail catatan saat menekan salah satu item | Definisi rute pada [router.dart](week5_offline_notes/lib/router.dart) dan `ref.watch` pada [note_detail_page.dart](week5_offline_notes/lib/pages/note_detail_page.dart) |

### **Checklist Verifikasi Mandiri**

1. **Pemisahan Logika Akses Data**: Antarmuka pengguna tidak memanggil SQLite atau SharedPreferences secara langsung, melainkan seluruh akses data dikelola sepenuhnya melalui repository dan provider.

2. **Fungsionalitas Mode Luring**: Aplikasi dapat berfungsi secara penuh dalam mode pesawat, di mana proses membaca, menambah, serta menghapus catatan berjalan lancar tanpa koneksi internet.

3. **Indikator Sinkronisasi**: Badge indikator dirty menampilkan jumlah catatan yang belum tersinkronisasi secara akurat sebelum dan sesudah proses sinkronisasi dilakukan.

4. **Penyimpanan Cache Data API**: Halaman Cached Posts berhasil menampilkan data yang bersumber dari API dan tersimpan di database lokal saat perangkat berada dalam kondisi offline.

5. **Flutter test** tanpa issue ![screenshots](screenshots/flutter_test.png)

## **Tugas, refleksi, dan referensi**

| Keterangan | Bukti Tangkapan Layar | 
|---|---|
| Light mode | ![screenshots](screenshots/force_offline_off.jpeg) |
| Dark mode | ![screenshots](screenshots/darkmode.jpeg) |
| Sebelum Sync | ![screenshots](screenshots/dirty_notes_offline.jpeg) |
| Setelah Sync | ![screenshots](screenshots/sync_success.jpeg) |
| Detail | ![screenshots](screenshots/gorouter.jpeg) |

### **Refleksi**

1. Mengapa daftar catatan tidak boleh disimpan di SharedPreferences? Apa yang rusak jika aturan ini dilanggar?
    - SharedPreferences hanya dirancang untuk menyimpan data kecil seperti status mode gelap atau preferensi aplikasi. Tempat ini tidak cocok untuk menyimpan data berstruktur seperti daftar catatan. Jika aturan ini dilanggar, aplikasi akan menjadi sangat lambat saat jumlah catatan bertambah karena seluruh data harus dibaca sekaligus ke memori. Anda juga tidak bisa melakukan pencarian atau pengurutan data secara efisien. Selain itu, catatan sangat rentan hilang atau rusak total jika aplikasi mendadak crash saat proses penyimpanan sedang berlangsung.
2. Kapan cache-first cukup, dan kapan Anda membutuhkan strategi lain (misalnya network-first untuk data harga real-time)?
    - Strategi cache-first cukup digunakan untuk data yang jarang berubah dan tetap berguna meskipun tidak up-to-date, seperti daftar catatan lokal, artikel berita lama, profil pengguna, atau riwayat transaksi. Strategi ini memprioritaskan kecepatan akses dan ketersediaan data secara offline dengan membaca data dari penyimpanan lokal terlebih dahulu sebelum memperbaruinya dari jaringan. Sebaliknya, Anda membutuhkan strategi lain seperti network-first saat menangani data sensitif yang membutuhkan tingkat akurasi tinggi dan harus selalu real-time, seperti harga saham, nilai tukar mata uang, sisa stok produk, atau status transaksi pembayaran. Jika strategi network-first gagal akibat koneksi terputus, aplikasi baru akan menampilkan data dari cache sebagai cadangan (fallback) dengan peringatan bahwa data yang ditampilkan adalah data lama.
3. Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan antrean terpisah (tabel outbox) menjadi perlu?
    - Dirty flag berubah menjadi antrean sync tanpa memblokir UI dengan menjalankan proses sinkronisasi secara asinkron (asynchronous) di latar belakang (background). Ketika Anda menambah atau mengubah catatan, aplikasi langsung menyimpan data ke SQLite lokal dengan status dirty = true dan mengembalikan respon cepat ke layar. Setelah itu, provider memanggil fungsi sinkronisasi yang berjalan di luar main thread (UI thread). Aplikasi mengirimkan catatan berstatus dirty ke API satu per satu atau secara batch. Begitu server merespon sukses, nilai dirty flag pada database lokal diubah menjadi false (atau dirty = 0) dan UI diperbarui secara otomatis tanpa pernah mengalami freeze.
4. Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?
    - Rekomendasi AI yang ditolak adalah saran untuk menguji FutureProvider secara langsung menggunakan perintah await provider.future atau expectLater saat menangani skenario error. Pendekatan ini ditolak karena pemanggilan await pada future yang melempar exception menyebabkan proses asinkron di Riverpod menggantung (hang), sehingga unit test mengalami kegagalan akibat TimeoutException selama 30 detik. Kegagalan tersebut juga berdampak pada proses pembersihan memori (container.dispose) yang memicu timbulnya StateError karena provider dipaksa tutup saat masih berada dalam status loading. Sebagai solusinya, pengujian dialihkan menggunakan pendekatan yang lebih stabil, yaitu memicu provider lewat container.listen, memberikan jeda pada event loop, lalu melakukan verifikasi status AsyncValue (state.hasError dan state.error) secara langsung tanpa menunggu future.
