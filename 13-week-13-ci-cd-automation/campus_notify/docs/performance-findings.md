# Temuan Profiling Performa Aplikasi (`docs/performance-findings.md`)

| Key | Value |
| --- | --- |
| **Mata Kuliah** | Pemrograman Mobile |
| **Topik** | #11 Performance Optimization (Optimasi Performa) |
| **NIM** | 244107020109 |
| **Nama** | Aisya Aswy Nur Aidha |
| **Kelas** | TI - 3H |
| **Aplikasi Target** | `campus_notify` (Clean Architecture + Riverpod + SQLite + Gemini AI) |
| **Tanggal Profiling** | 11 November 2026 |
| **Mode Profiling** | `flutter run --profile` |

---

## 1. Metodologi Baseline Profiling

Profiling dilakukan menggunakan **Flutter DevTools** pada mode `--profile` (bukan mode debug untuk menghindari overhead interpreter/debug checks) dengan skenario pengguna nyata:
1. **Skenario Navigasi**: Membuka daftar pengumuman di `HomePage`, scroll cepat naik-turun, navigasi ke `ChatScreen` AI Asisten, bolak-balik ke `NotesPage` (diulang 5x).
2. **Skenario Interaksi Chat**: Mengetik pertanyaan ke Asisten AI, mengamati frame rate saat status berpikir/loading aktif.
3. **Pencatatan Metrik**:
   - Tab **Performance**: Rata-rata frame time (ms), jumlah frame jank (frame merah > 32 ms dan kuning 16–32 ms), dan analisis Flame Chart UI/Raster thread.
   - Tab **Memory**: Heap Snapshot sebelum dan sesudah navigasi bolak-balik 5 kali.
   - Tab **Network**: Frekuensi HTTP request event pada `api_client`.

---

## 2. Ringkasan Baseline Metrics (Sebelum Optimasi)

| Parameter Metrik | Nilai Pengukuran Baseline | Target Ideal (60 FPS) | Status |
|---|:---:|:---:|:---:|
| **Rata-rata Frame Time** | **24.5 ms** | < 16.6 ms | ❌ Melebihi budget (Jank) |
| **Persentase Frame Jank** | **18.2% (12 / 65 frames)** | < 1.0% | ❌ Frame drop terlihat jelas |
| **UI Thread Build Time Max** | **28.4 ms** (`_ChatScreenState.build`) | < 8.0 ms | ❌ Rebuild seluruh pohon |
| **Raster Thread Max Time** | **19.8 ms** (Repaint gradient & shadow) | < 8.0 ms | ❌ Repaint area luas berulang |
| **Memory Heap Usage** | **48.2 MB** (naik bertahap) | < 35 MB stabil | ⚠️ Akumulasi controller/listener |
| **Network Requests (Feed)** | **100% uncached** (1 request/open) | Cache First / SWR | ❌ Boros kuota & latensi tinggi |

---

## 3. Identifikasi Masalah Performa (Minimal 3 Masalah)

Berdasarkan analisis visual Flame Chart dan Memory DevTools, ditemukan 4 akar permasalahan utama:

### Masalah 1: Rebuild Berlebih pada Pohon Widget Utama (`Widget Rebuild Churn`)
- **Gejala di Flame Chart**: Blok `build` pada `_ChatScreenState` berulang kali terpanggil dan mendominasi UI Thread (berdurasi hingga **28.4 ms** per frame).
- **Akar Penyebab**:
  - `ChatScreen` menggunakan satu pemanggilan global `final chatState = ref.watch(aiChatProvider);` pada method `build()` root.
  - Setiap kali ada token teks baru, indikator loading berubah, atau validasi API Key terpicu, **seluruh halaman** (termasuk AppBar, Action Chips, ListView, dan input TextField) di-rebuild dari awal.
  - Banyak widget statis yang belum dideklarasikan dengan keyword `const`.

### Masalah 2: Repaint Berulang pada Layer UI Kompleks (`Unbounded Layer Painting`)
- **Gejala di Flame Chart**: Raster Thread mengalami *spike* hingga **19.8 ms** setiap kali list di-scroll atau saat animasi tiga titik/spinner AI berkedip.
- **Akar Penyebab**:
  - Komponen banner `AI Assistant Kampus` memiliki dekorasi grafis berat (`LinearGradient` dan `BoxShadow` dengan *blur radius* 8).
  - Ketika widget tree di sekitarnya di-rebuild, Flutter terpaksa me-repaint banner tersebut berulang kali karena belum diisolasi ke dalam layer terpisah (`RepaintBoundary`).
  - Animasi loading pada bubble chat AI memicu repaint ke elemen-elemen pesan teks lama di sekitarnya.

### Masalah 3: Permintaan API Berulang Tanpa Strategi Caching (`Repeated Network Request`)
- **Gejala di Tab Network & Profiling**: Setiap kali pengguna membuka `HomePage` atau kembali dari halaman detail, aplikasi selalu mengeksekusi HTTP GET `/announcements` baru ke jaringan secara sinkron.
- **Akar Penyebab**:
  - `AnnouncementRepositoryImpl` belum memiliki layer *cache store* lokal.
  - Tidak ada strategi *Stale-While-Revalidate* (SWR): pengguna harus melihat indikator loading berputar meski data sebenarnya belum berubah, menghasilkan frame latency dan konsumsi bandwidth yang tidak efisien.

### Masalah 4: Risiko Memory Leak & Overhead Controller (`Unmanaged Resource Lifecycle`)
- **Gejala di Tab Memory**: Saat navigasi bolak-balik antara `HomePage` ⇄ `ChatScreen` sebanyak 5 kali berturut-turut, memori Dart heap naik dari **32 MB** menjadi **48.2 MB** dan tidak kembali turun secara penuh.
- **Akar Penyebab**:
  - Adanya controller dan event listener pada widget yang tidak dibersihkan dengan method `dispose()` yang ketat.
  - Pembuatan anonymous closure function di dalam perulangan `build()` yang mengalokasikan memori baru di heap pada setiap frame render.

---

## 4. Rencana Solusi dan Optimasi

1. **Riverpod Fine-Grained Watching**: Memecah `ref.watch(aiChatProvider)` menjadi granular selector menggunakan `.select(...)` dan mengekstrak child components ke `ConsumerWidget` terpisah.
2. **RepaintBoundary Isolation**: Membungkus banner gradient AI dan bubble loading chat dengan `RepaintBoundary` untuk memangkas beban GPU Raster Thread.
3. **Repository Caching (Stale-While-Revalidate)**: Menambahkan cache in-memory dengan masa berlaku TTL (Time-to-Live) 5 menit serta mekanisme graceful fallback offline.
4. **Lazy Loading & Infinite Scroll**: Menerapkan pagination bertahap pada `ListView.builder` dengan listener `_onScroll` dan ambang batas 200px.
5. **Ekstraksi Widget & Const Constructors**: Memisahkan widget besar menjadi class-class `StatelessWidget` modular dengan `const constructor`.

