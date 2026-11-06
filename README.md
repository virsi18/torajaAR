# AR Toraja - Aplikasi Augmented Reality Kebudayaan Toraja (Flutter)

Aplikasi mobile Augmented Reality (AR) edukasi budaya Tana Toraja berbasis Flutter dengan orientasi *landscape*, dikembangkan berdasarkan rancangan antarmuka pada dokumen `AR Toraja.pdf`.

---

## 📱 Fitur Utama Aplikasi

1. **Halaman 1 (Menu Utama)**:
   - Judul aplikasi "AR Toraja".
   - Ilustrasi vektor rumah adat khas Toraja (*Tongkonan*).
   - Tombol menu: **Scan AR**, **Panduan**, **Tentang Peneliti**, dan **Keluar**.
2. **Halaman 2 (Layar AR & 3D Viewer)**:
   - Panel sisi kiri dengan tombol grid (kembali ke menu utama) dan 4 daftar pilihan artefak:
     1. Hiasan Kepala (*Sa'pi'*)
     2. Rumah Adat Tongkonan
     3. Patung Adat Tau-tau
     4. Tedong Bonga (Kerbau Belang)
   - Viewport interaktif 3D (rotasi 360°, zoom in/out, pan).
   - Fitur **Augmented Reality (AR)** bawaan (didukung Google Play Services for AR / ARCore) untuk menaruh objek di dunia nyata melalui kamera HP.
   - Tombol bantuan tanda tanya (**?**) di pojok kanan bawah.
3. **Halaman 3 (Pop-up Info Artefak)**:
   - Dialog bergaya awan/bergelombang (*scalloped border*) dengan header ikon tanda tanya (**?**) dan tombol tutup (**✕**).
4. **Halaman 4 (Pop-up Panduan)**:
   - Tampilan bergaya lembaran buku binder berlubang cincin (*binder notebook sheet*).
5. **Halaman 5 (Pop-up Tentang Peneliti)**:
   - Lembaran binder berisi informasi profil dan tujuan penelitian.

---

## 🚀 Cara Build APK Otomatis Menggunakan GitHub Actions

Aplikasi ini sudah dilengkapi alur kerja CI/CD otomatis di `.github/workflows/build-apk.yml`. Anda tidak perlu menginstall Android Studio atau Flutter di laptop Anda untuk menghasilkan file APK.

### Langkah 1: Buat Repositori Baru di GitHub
1. Buka browser dan login ke akun [GitHub](https://github.com).
2. Buat repositori baru (beri nama misalnya `ar-toraja`).
3. Pilih opsi **Public** atau **Private**, lalu klik **Create repository**.

### Langkah 2: Push Kode dari Komputer Anda ke GitHub
Buka terminal (PowerShell atau Command Prompt) di folder `d:\aplikasi ar`, lalu jalankan perintah berikut:

```bash
git init
git add .
git commit -m "Inisialisasi aplikasi AR Toraja dan workflow GitHub Actions"
git branch -M main
git remote add origin https://github.com/USERNAME-ANDA/ar-toraja.git
git push -u origin main
```
*(Ganti `USERNAME-ANDA/ar-toraja.git` dengan tautan repositori GitHub Anda)*.

### Langkah 3: Unduh File APK dari GitHub
1. Buka repositori Anda di GitHub.
2. Klik tab **Actions** di menu atas.
3. Anda akan melihat proses build **"Build Android APK (AR Toraja)"** sedang berjalan secara otomatis (memakan waktu ~3 menit).
4. Setelah selesai (bercentang hijau), klik nama workflow tersebut.
5. Di bagian bawah (*Artifacts*), klik **AR-Toraja-APK** untuk mengunduh file APK langsung ke laptop atau HP Android Anda!

---

## 🎨 Cara Memasukkan Aset 3D dari Klien

Saat ini aplikasi sudah dilengkapi dengan model 3D cadangan (*fallback sample*) agar dapat langsung di-build dan dicoba di HP tanpa error.

Ketika klien Anda sudah menyerahkan file 3D:

### 1. Jika File Sudah Berformat `.glb` atau `.gltf`
1. Letakkan file-file tersebut ke dalam folder:
   ```text
   assets/models/
   ├── hiasan_kepala.glb
   ├── tongkonan.glb
   ├── tau_tau.glb
   └── tedong_bonga.glb
   ```
2. Buka file `lib/models/artifact.dart`, dan ubah properti `src` di `lib/main.dart` ke path aset lokal tersebut.

### 2. Jika File Masih Berformat `.obj`, `.fbx`, atau `.blend`
- Format tersebut dapat dikonversi ke `.glb` dalam waktu 1 menit menggunakan aplikasi gratis **Blender** (`File` -> `Export` -> `glTF 2.0 (.glb)`), atau melalui situs konverter online seperti [https://imagetostl.com/convert/file/fbx/to/glb](https://imagetostl.com/convert/file/fbx/to/glb).

---

## 📂 Struktur Direktori Proyek

```text
d:\aplikasi ar/
├── .github/
│   └── workflows/
│       └── build-apk.yml        # Script build otomatis GitHub Actions
├── android/                     # Konfigurasi native Android (Landscape & Izin Kamera AR)
├── assets/
│   ├── images/                  # Aset gambar
│   └── models/                  # Tempat file 3D .glb dari klien
├── lib/
│   ├── models/
│   │   └── artifact.dart        # Data teks dan konfigurasi objek Toraja
│   └── main.dart                # Antarmuka 5 halaman sesuai wireframe PDF
├── pubspec.yaml                 # Dependensi Flutter & pustaka model_viewer_plus
└── README.md
```

