|  | Pemrograman Mobile |
|--|--|
| NIM | 244107020109 |
| Nama | Aisya Aswy Nur Aidha |
| Kelas | TI - 3H |

# **WEEK 11 — Performance Optimization (Optimasi Performa)**

> **Referensi Codelab**: [#11 Minggu 11 – Optimasi Performa](https://jti-polinema.github.io/flutter-codelab/11-minggu-11-performance-optimization/index.html#0)

---

## 1. Tujuan Pembelajaran

Setelah menyelesaikan praktikum Minggu 11 ini, mahasiswa mampu:
- Menggunakan **Flutter DevTools** untuk melakukan profiling CPU, GPU rendering, dan alokasi memori Dart heap pada mode `--profile`.
- Mengidentifikasi dan mengeliminasi proses *widget rebuild* yang tidak perlu menggunakan Riverpod `select`, ekstraksi widget, dan `const constructor`.
- Menerapkan isolasi render painting menggunakan `RepaintBoundary` untuk widget dengan efek grafis berat (gradient, shadow, animasi loading).
- Menerapkan *lazy loading* dan *pagination (infinite scroll)* pada daftar panjang dengan `ListView.builder`.
- Mengoptimalkan interaksi jaringan dengan strategi *caching* **Stale-While-Revalidate (SWR)** dan mekanisme *offline graceful fallback*.
- Mengaudit siklus hidup sumber daya (*resource lifecycle*) untuk mencegah *memory leaks*.
- Mendokumentasikan temuan profiling di `docs/performance-findings.md` dan laporan komprehensif di `docs/performance-report.md`.

---

## 2. Konsep Pipeline Rendering & Frame Budget Flutter

Flutter menggunakan dua thread utama dalam proses rendering antarmuka pengguna:
```
       UI Thread (Dart)                        Raster Thread (GPU)
  ┌─────────────────────────┐               ┌─────────────────────────┐
  │  • Build Widget Tree    │               │  • Composite Layers     │
  │  • Layout Calculation   ├──────────────►│  • Rasterize Pixels     │
  │  • Paint Commands       │               │  • Draw to Screen Buffer│
  └─────────────────────────┘               └─────────────────────────┘
               │                                         │
               ▼                                         ▼
   Budget per Frame: 16.67 ms (untuk 60 FPS) / 8.33 ms (untuk 120 FPS)
```
- **UI Thread**: Mengeksekusi kode Dart logika, memproses state management, menyusun widget tree, dan menghasilkan *paint commands*.
- **Raster Thread**: Mengubah instruksi layer dari UI thread menjadi piksel nyata pada GPU.
- **Jank / Frame Drop**: Terjadi saat durasi pemrosesan frame melebihi budget **16.67 ms**, mengakibatkan animasi terasa tersendat atau patah-patah bagi pengguna.

---

## 3. Rangkuman 5 Teknik Optimasi yang Diterapkan

Pada proyek **`campus_notify`**, dilakukan 5 teknik optimasi nyata sesuai materi Codelab:

| No | Teknik Optimasi | Lokasi File Implementasi | Deskripsi Manfaat & Mekanisme |
|:---:|---|---|---|
| **1** | **Riverpod `select` Granular Listening** | `lib/features/chat_screen.dart` | Mengganti `ref.watch(aiChatProvider)` dengan `ref.watch(aiChatProvider.select((s) => s.hasApiKey))` dan selector spesifik untuk messages dan loading. Hanya komponen yang datanya berubah yang di-rebuild. |
| **2** | **Ekstraksi Widget & `const` Constructor** | `lib/features/announcements/presentation/pages/home_page.dart`<br>`lib/features/chat_screen.dart`<br>`lib/features/notes/presentation/pages/notes_page.dart` | Memecah widget besar menjadi class `StatelessWidget` terpisah (`ChatMessageBubble`, `ChatLoadingBubble`, `AnnouncementItemTile`, `AiAssistantBanner`, `NoteTileItem`). Menghilangkan anonymous closure baru tiap frame build. |
| **3** | **`RepaintBoundary` untuk Isolasi Layer** | `lib/features/announcements/presentation/pages/home_page.dart`<br>`lib/features/chat_screen.dart` | Membungkus `AiAssistantBanner` (kompleks gradient + box shadow) dan animasi berkedip `ChatLoadingBubble` dengan `RepaintBoundary` agar tidak memicu repaint pass berulang pada seluruh layar. |
| **4** | **Repository Caching (Stale-While-Revalidate)** | `lib/features/announcements/data/repositories/announcement_repository_impl.dart` | Mengimplementasikan cache memory dengan masa aktif TTL 5 menit. Data langsung disajikan instan (0 ms latency), background refresh dilakukan otomatis, dan menyediakan graceful fallback saat offline. |
| **5** | **Lazy Loading & Infinite Scroll Pagination** | `lib/features/announcements/presentation/pages/home_page.dart` | Menggunakan `ListView.builder` dengan listener `ScrollController` (ambang batas 200px dari dasar layar) dan indikator progress loading untuk merender item secara bertahap saat pengguna menggulir. |

---

## 4. Evaluasi Kuantitatif: Baseline vs Optimized Metrics

| Metrik DevTools Profiling | Baseline (Sebelum) | Optimized (Sesudah) | Efisiensi & Dampak |
|---|:---:|:---:|:---:|
| **Rata-rata Frame Time** | **24.5 ms** | **7.8 ms** | **Peningkatan performa 68.2% (Bebas Jank)** |
| **Persentase Jank Frames** | **18.2%** | **0.4%** | **Turun 97.8% (Smooth 60 FPS stabil)** |
| **Max UI Thread Build Time** | **28.4 ms** | **2.1 ms** | **Hemat 92.6% waktu CPU Dart** |
| **Max Raster Thread Time** | **19.8 ms** | **2.3 ms** | **Hemat 88.4% beban rendering GPU** |
| **Konsumsi Memori (RAM)** | **48.2 MB** | **31.4 MB** | **Pengurangan memori sebesar 34.8%** |
| **Network Requests (Feed)** | Uncached (setiap buka) | SWR Memory Hit | **Hemat data 75% & Instant Render 0ms** |

---

## 5. Bukti Visual Profiling Flutter DevTools

### A. Flame Chart Sebelum Optimasi (`screenshots/before-profile.png`)
Frame timeline menunjukkan banyaknya frame merah/kuning (jank) akibat rebuild menyeluruh pada `ChatScreen` dan repaint grafis berat.

![Flame Chart Before](screenshots/before-profile.png)

---

### B. Flame Chart Sesudah Optimasi (`screenshots/after-profile.png`)
Frame timeline seragam hijau di bawah 10 ms (60 FPS stabil), beban build terisolasi rapi, dan data cache langsung tersaji.

![Flame Chart After](screenshots/after-profile.png)

---

## 6. Bukti Verifikasi Hijau (*Green Pipeline Verification*)

Seluruh analisis statis Dart dan rangkaian pengujian unit serta widget otomatis berhasil dijalankan dengan status **HIJAU (100% Pass, 0 Issues)**.

### A. Hasil `flutter analyze`

![Bukti Flutter Analyze](screenshots/flutter_analyze.png)

---

### B. Hasil `flutter test`

![Bukti Flutter Test](screenshots/flutter_test.png)

---

## 7. Jawaban Refleksi (Sesuai Bab 8 Codelab)

### 1. Optimasi mana yang memberikan dampak terbesar dan mengapa?
> **Jawaban**:
> Optimasi yang memberikan dampak terbesar adalah **kombinasi Riverpod `.select(...)` bersama `RepaintBoundary`**.
> Pada fitur asisten AI (`ChatScreen`), pesan dan indikator berpikir diperbarui sangat intensif. Sebelum optimasi, `ref.watch(aiChatProvider)` di level root memaksa seluruh pohon widget (termasuk TextField input dan tombol AppBar) dibangun ulang dari awal setiap frame, menimbulkan *build time* hingga **28.4 ms** yang memicu jank. Setelah dipecah dengan selector `.select()` dan animasi loading diisolasi dengan `RepaintBoundary`, waktu build terpangkas drastis menjadi **2.1 ms** dan beban repaint GPU turun ke **2.3 ms**, menjadikan UI terasa sangat halus dan responsif.

### 2. Bagaimana Anda memverifikasi bahwa optimasi benar-benar bekerja (bukan placebo)?
> **Jawaban**:
> Verifikasi dilakukan secara **objektif dan terukur** melalui tiga metode:
> 1. **Data Metrik Profiling**: Melakukan perekaman pada mode `flutter run --profile` di DevTools Performance Timeline, membuktikan penurunan rata-rata *frame time* dari **24.5 ms** ke **7.8 ms** serta penurunan jank frame rate dari **18.2%** ke **0.4%**.
> 2. **Analisis Event Jaringan**: Mengamati tab Network pada DevTools di mana panggilan HTTP berkurang signifikan pada kunjungan berulang karena dilayani langsung oleh memory cache SWR (latensi 0 ms).
> 3. **Automated Test Suite**: Menjalankan 31 pengujian otomatis (`flutter test`) yang membuktikan bahwa seluruh fungsionalitas aplikasi tetap utuh tanpa ada regresi fitur.

### 3. Trade-off apa yang Anda hadapi (misalnya kompleksitas kode vs performa)?
> **Jawaban**:
> Trade-off utama adalah **peningkatan kompleksitas struktural kode (*Code Boilerplate vs Runtime Speed*)**:
> - Widget tree harus dipecah menjadi beberapa sub-widget dengan `ConsumerWidget` dan passing callback secara eksplisit daripada menulis kode monolitik dalam satu file.
> - Pengelolaan cache repository memerlukan logika tambahan untuk masa berlaku TTL, sinkronisasi pembaruan background, dan penanganan fallback saat error.
> Namun, trade-off ini menghasilkan arsitektur kode yang jauh lebih modular, mudah diuji secara terisolasi (*testable*), dan memberikan pengalaman pengguna yang unggul (*zero-lag*).

### 4. Kapan sebaiknya optimasi premature dihindari?
> **Jawaban**:
> Optimasi prematur sebaiknya dihindari **pada tahap eksplorasi awal produk (*prototyping*), saat kebutuhan bisnis masih berubah-ubah, atau pada bagian kode yang tidak berada di jalur kritis (*non-critical rendering path*)**.
> Sebagai contoh, membungkus semua widget sederhana dengan `RepaintBoundary` justru memboroskan memori grafis GPU karena setiap boundary membuat alokasi framebuffer baru. Optimasi harus selalu dipandu oleh data empiris (**Profiling-Driven Optimization**): jalankan Flutter DevTools, amati frame merah yang melanggar budget 16.6 ms, lalu terapkan perbaikan pada bottleneck yang tepat.

---

## 8. Struktur Direktori Proyek

```
11-week-11-performance-optimization/
├── campus_notify/
│   ├── lib/
│   │   ├── features/
│   │   │   ├── announcements/
│   │   │   │   ├── data/repositories/
│   │   │   │   │   └── announcement_repository_impl.dart  ← SWR Cache Implementation
│   │   │   │   ├── domain/repositories/
│   │   │   │   │   └── announcement_repository.dart       ← Cache policy contract
│   │   │   │   └── presentation/pages/
│   │   │   │       └── home_page.dart                     ← Lazy Loading, Pagination & RepaintBoundary
│   │   │   ├── chat_screen.dart                           ← Riverpod .select() & Isolated Widgets
│   │   │   └── notes/presentation/pages/
│   │   │       └── notes_page.dart                        ← Const Tiles & Extracted Widgets
│   │   ├── core/network/api_client.dart                   ← Connection & Receive Timeouts
│   │   └── main.dart
│   ├── test/
│   │   ├── performance_swr_cache_test.dart                ← Unit test verifikasi SWR Caching
│   │   ├── home_page_performance_widget_test.dart         ← Widget test lazy loading & boundary
│   │   ├── chat_screen_widget_test.dart
│   │   └── ... (Total 31 Unit & Widget Tests)
│   └── pubspec.yaml
├── docs/
│   ├── performance-findings.md                            ← Analisis baseline profiling & 4 masalah
│   └── performance-report.md                              ← Laporan komprehensif before/after & refleksi
├── screenshots/
│   ├── before-profile.png                                 ← Flame Chart sebelum optimasi (Jank terdeteksi)
│   ├── after-profile.png                                  ← Flame Chart sesudah optimasi (60 FPS stabil)
│   ├── flutter_analyze.png                                ← Bukti 'No issues found!'
│   └── flutter_test.png                                   ← Bukti 'All tests passed! (31/31)'
├── lib/                                                   ← Struktur kode pustaka utama
└── README.md
```

