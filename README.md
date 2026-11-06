# AR Toraja - Aplikasi Augmented Reality Kebudayaan Toraja (Flutter)

Aplikasi mobile Augmented Reality (AR) edukasi budaya Tana Toraja berbasis Flutter dengan orientasi horizontal (*landscape*), dikembangkan berdasarkan rancangan antarmuka pada dokumen `AR Toraja.pdf`.

* **Repositori Resmi**: [https://github.com/virsi18/torajaAR](https://github.com/virsi18/torajaAR)
* **Kompilasi Otomatis (CI/CD)**: GitHub Actions (Android SDK 36, Java 17, Gradle 8.14.6)
* **Hasil Rilis Terakhir**: [GitHub Actions Run #42226871411](https://github.com/virsi18/torajaAR/actions/runs/42226871411)

---

## 📱 Fitur & Tampilan Antarmuka (Sesuai Wireframe PDF)

1. **Halaman 1 (Menu Utama / Home Screen)**:
   - Judul aplikasi: **"AR Toraja"**.
   - Ilustrasi vektor khas: **Rumah Adat Tongkonan** (*Banua Layuk*).
   - 4 Tombol menu utama: **Scan AR**, **Panduan**, **Tentang Peneliti**, dan **Keluar**.
2. **Halaman 2 (Layar AR & 3D Viewer)**:
   - Tombol menu grid di kiri atas untuk kembali ke Menu Utama.
   - Panel sisi kiri dengan 4 thumbnail pilihan artefak budaya Toraja asli klien:
     1. **Sa'pi'** (Mahkota hiasan dahi penari Pa'gellu)
     2. **Passapu** (Ikat kepala penutup adat pria Toraja)
     3. **Sarong** (Kain sarung tenun tradisional)
     4. **Figur Budaya Toraja** (Seni ukir dan figur adat)
   - Viewport 3D interaktif: rotasi 360°, zoom in/out (*pinch*), dan geser (*pan*).
   - Fitur **Augmented Reality (Google Scene Viewer / ARCore)** untuk menempatkan objek 3D di dunia nyata di atas meja atau lantai melalui kamera HP.
   - Tombol bantuan tanda tanya (**?**) di pojok kanan bawah.
3. **Halaman 3 (Pop-up Info Artefak Budaya)**:
   - Dialog bergaya awan bergelombang (*scalloped border*) dengan header ikon tanda tanya (**?**) dan tombol tutup (**✕**).
   - Menampilkan narasi sejarah, makna filosofis, dan nilai adat untuk setiap objek terpilih.
4. **Halaman 4 (Pop-up Panduan)**:
   - Tampilan bergaya lembaran buku catatan binder berlubang cincin (*binder notebook sheet*).
   - Langkah-langkah cara penggunaan AR.
   - Tombol aksi: **`📥 Unduh Kartu Marker (Google Drive)`** yang langsung membuka folder Google Drive klien di browser/aplikasi HP.
5. **Halaman 5 (Pop-up Tentang Peneliti)**:
   - Lembaran binder berisi identitas pengembang, fokus penelitian, dan tujuan pelestarian warisan budaya Tana Toraja.

---

## 🏛️ Aset 3D Budaya Toraja

Model 3D yang aktif dalam aplikasi adalah file `.glb` resmi dari proyek Blender klien:
* `assets/models/sapi.glb` (120 KB)
* `assets/models/passapu.glb` (133 KB)
* `assets/models/sarong.glb` (146 KB)
* `assets/models/toraja.glb` (509 KB)

File-file tersebut juga terhubung ke tautan HTTPS publik di repositori GitHub ini agar layanan kamera AR Google Scene Viewer dapat memuat objek ke dunia nyata tanpa kendala izin jaringan internal.

---

## 🚀 Cara Mengunduh File APK dari GitHub Actions

1. Buka tautan rilis build di GitHub:
   👉 **[https://github.com/virsi18/torajaAR/actions](https://github.com/virsi18/torajaAR/actions)**
2. Klik nama build terbaru yang bercentang hijau (misalnya: *Add Google Drive marker download button in Panduan dialog*).
3. Gulir ke bagian paling bawah ke tabel **Artifacts**, lalu klik **`AR-Toraja-APK`**.
4. Ekstrak file zip hasil unduhan, Anda akan mendapatkan:
   - **`app-release.apk`**: File instalasi final siap pakai di smartphone Android.
   - **`app-debug.apk`**: File instalasi versi debug untuk pengujian teknis.

---

## 🔧 Spesifikasi Teknis Konfigurasi Android

* **Framework**: Flutter 3.x (Dart SDK `>=3.0.0 <4.0.0`)
* **Target OS**: Android (Landscape Orientation)
* **Compile SDK**: `36` (Android 16 Platform)
* **Minimum SDK**: `21` (Mendukung Android 5.0 Lollipop ke atas)
* **Target SDK**: `34` (Android 14)
* **Gradle Version**: `8.14.6`
* **Android Gradle Plugin (AGP)**: `8.12.3`
* **Kotlin Version**: `2.3.20`
* **Izin Package Android 11+**: `com.google.android.googlequicksearchbox` & `com.google.ar.core`
* **Pustaka Utama**: `model_viewer_plus: ^1.7.0`, `url_launcher: ^6.3.0`

---

## 📂 Struktur Direktori Proyek

```text
d:\aplikasi ar/
├── .github/
│   └── workflows/
│       └── build-apk.yml        # CI/CD otomatis kompilasi APK di GitHub Actions
├── android/                     # Konfigurasi native Android (Landscape, Izin Kamera, & Icons)
│   ├── app/
│   │   ├── build.gradle         # compileSdk 36, minSdk 21, targetSdk 34
│   │   └── src/main/
│   │       ├── AndroidManifest.xml # Izin kamera, internet, & query Scene Viewer
│   │       └── res/
│   │           └── mipmap-*/    # Ikon aplikasi ic_launcher.png di semua densitas
│   ├── gradle/wrapper/          # Gradle Wrapper 8.14.6
│   └── settings.gradle          # AGP 8.12.3 & Kotlin 2.3.20
├── assets/
│   ├── images/                  # Aset gambar pendukung
│   └── models/                  # File 3D resmi (.glb) klien
├── lib/
│   ├── models/
│   │   └── artifact.dart        # Data teks dan URL model artefak Toraja
│   └── main.dart                # Antarmuka 5 halaman sesuai wireframe PDF
├── index.html                   # Prototipe interaktif web untuk pengujian di browser desktop
├── pubspec.yaml                 # Dependensi Flutter & registrasi aset
└── README.md                    # Dokumentasi teknis proyek
```
