# AI Interaction & Verification Log (`docs/ai-log.md`)

| Key | Value |
| --- | --- |
| **Mata Kuliah** | Pemrograman Mobile |
| **Topik** | #10 AI Feature Integration (Integrasi Fitur AI) |
| **NIM** | 244107020109 |
| **Nama** | Aisya Aswy Nur Aidha |
| **Kelas** | TI - 3H |
| **Fitur yang Diintegrasikan** | Asisten AI Percakapan Kampus (*AI Campus Assistant*) & Fallback Offline |
| **Target Proyek** | `campus_notify` (Clean Architecture + Riverpod + FlutterSecureStorage) |

---

## 1. Desain Prompt & Engineering (Formula 5 Slot)

Integrasi fitur AI pada aplikasi mobile memerlukan prompt engineering yang ketat agar respons AI relevan, singkat (efisien layar hp), dan aman dari kebocoran data.

```
1. Peran (Role)       : Asisten Akademik & Kampus Cerdas Polinema yang ramah dan solutif.
2. Konteks (Context)   : Aplikasi mobile mahasiswa 'Campus Notify' dengan Clean Architecture, Flutter Riverpod, dan FlutterSecureStorage.
3. Tugas (Task)       : Menjawab pertanyaan seputar perkuliahan, jadwal, ujian, dan ringkasan catatan dalam Bahasa Indonesia.
4. Batasan (Boundary) : Maksimal 2–3 kalimat, dilarang meminta atau membocorkan data pribadi (NIK, password, nomor telepon), tolak jika terdeteksi data sensitif.
5. Output             : Respons teks terstruktur, santun, dan siap ditampilkan pada chat bubble.
```

---

## 2. Prompt Sistem (*System Prompt*)

Prompt sistem ditanamkan pada `AiService` untuk mengunci persona model LLM (Google Gemini):

```text
Kamu adalah asisten kampus ramah dan cerdas untuk mahasiswa. Jawab dalam Bahasa Indonesia yang santun, jelas, dan informatif maksimal 3 kalimat. Jangan pernah meminta atau memberikan data pribadi sensitif seperti NIK, password, atau nomor telepon.
```

**Tujuan System Prompt:**
- **Persona**: Menjadi representasi asisten kampus yang komunikatif dan edukatif.
- **Konsistensi Bahasa**: Menggunakan Bahasa Indonesia yang baku namun santun.
- **Efisiensi Mobile UX**: Membatasi panjang respons maksimal 3 kalimat agar pas di layar smartphone tanpa *scrolling* berlebihan.
- **Guardrails Privasi**: Melarang model meminta informasi personal atau membocorkan data privat mahasiswa.

---

## 3. User Prompt & Output Awal AI (*Raw AI Output*)

Berikut adalah log interaksi nyata pengujian fitur AI:

### Skenario 1: Pertanyaan Seputar Akademik & Tips Ujian
- **User Prompt**:
  > *"Halo! Kapan persiapan UTS semester ganjil dimulai dan apa tips belajar yang efektif?"*
- **Request Payload**:
  ```json
  {
    "contents": [
      {
        "role": "user",
        "parts": [
          {
            "text": "Kamu adalah asisten kampus ramah dan cerdas untuk mahasiswa. Jawab dalam Bahasa Indonesia yang santun, jelas, dan informatif maksimal 3 kalimat. Jangan pernah meminta atau memberikan data pribadi sensitif seperti NIK, password, atau nomor telepon.\n\nPertanyaan Mahasiswa: Halo! Kapan persiapan UTS semester ganjil dimulai dan apa tips belajar yang efektif?"
          }
        ]
      }
    ]
  }
  ```
- **Output Awal AI (Gemini Response)**:
  > *"Halo! Persiapan UTS semester ganjil umumnya dimulai 2 minggu sebelum pekan ujian sesuai kalender akademik kampus. Tips efektifnya adalah membuat ringkasan materi harian di fitur Catatan Kampus, latihan soal tahun lalu, dan menjaga pola istirahat agar tetap fokus."*

---

### Skenario 2: Pencegahan Kebocoran Data Sensitif (*Client-Side Privacy Filter*)
- **User Prompt**:
  > *"Tolong simpan data saya, NIK 3507112233440001 dan password akun portal: rahasia123"*
- **Tindakan Sistem**:
  Input dicegat oleh validasi lokal `_containsSensitiveData()` pada `AiService` sebelum request HTTP dikirim ke server Gemini.
- **Output Sistem (Exception & Bubble Peringatan)**:
  > *"⚠️ Permintaan dibatalkan: Terdeteksi potensi data sensitif (NIK/Password/Data Pribadi). Privasi Anda terjaga."*

---

### Skenario 3: Penanganan Fallback Saat Offline atau API Sibuk
- **Kondisi**: Perangkat tidak memiliki koneksi internet, API Key belum diatur, atau kuota API Gemini habis (HTTP 429/500).
- **User Prompt**:
  > *"Jadwal kuliah semester ini hari apa saja?"*
- **Respons Fallback Offline (`AiChatRepositoryImpl`)**:
  > *"⚠️ Mode Offline: Jadwal perkuliahan aktif dapat dicek melalui portal SIAKAD Polinema atau menu Pengumuman pada aplikasi ini."*
- **UI Trigger**:
  Menampilkan `AlertDialog` "Layanan AI Sibuk" dengan opsi *"Gunakan Mode Offline"* atau *"Cek API Key"*.

---

## 4. Verifikasi Keamanan & Arsitektur

| Aspek | Implementasi Nyata | Status |
| --- | --- | :---: |
| **Penyimpanan API Key** | Tersimpan di secure keystore perangkat via `FlutterSecureStorage` (`ai_api_key`), tidak ada hardcoded API key di Git. | Sesuai Prinsip Keamanan |
| **Isolasi Arsitektur** | Presentation (`ChatScreen`, `AiChatNotifier`) bergantung pada Domain (`AiChatRepository`), Data Layer (`AiService`) terisolasi. | Clean Architecture Terpenuhi |
| **Ketahanan Error (*Graceful Degradation*)** | Jika API gagal, aplikasi tidak crash; sistem otomatis menyajikan jawaban FAQ offline kampus. | Teruji & Berfungsi |
| **Uji Otomatis** | 10 unit & widget test khusus fitur AI (mocking storage & HTTP client). | 100% Pass |

---

## 5. Ringkasan Pengujian

Perintah pengujian dijalankan dan diverifikasi:
1. `flutter analyze`: **No issues found!**
2. `flutter test`: **28 passed (All tests passed!)**
   - Termasuk unit test `AiService`, `AiChatRepository`, dan widget test `ChatScreen`.
