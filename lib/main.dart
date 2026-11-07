import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/artifact.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Mengunci orientasi layar ke Landscape (Horizontal) sesuai wireframe PDF
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const ArTorajaApp());
  });
}

class ArTorajaApp extends StatelessWidget {
  const ArTorajaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Toraja',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'sans-serif',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  // 0: Menu Utama (Halaman 1), 1: Layar AR & 3D Viewer (Halaman 2)
  int _currentScreen = 0;
  int _selectedArtifactIndex = 0;

  // State Manajemen Scanner Kamera AR Optik (Metode B)
  bool _isCameraMode = true; // Default aktif saat klik Scan AR
  MobileScannerController? _scannerController;
  bool _isFlashOn = false;

  // STATE SCAN MARKER: Objek 3D HANYA muncul bila marker optik telah dideteksi kamera!
  bool _isMarkerScanned = false;

  // Animasi Laser Scanline
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _initScanner() {
    _scannerController ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: _isFlashOn,
    );
  }

  void _disposeScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    _isFlashOn = false;
  }

  void _toggleCameraMode() {
    setState(() {
      _isCameraMode = !_isCameraMode;
      if (_isCameraMode) {
        _initScanner();
      } else {
        _disposeScanner();
      }
    });
  }

  void _switchCameraLens() {
    _scannerController?.switchCamera();
  }

  void _toggleFlash() {
    _scannerController?.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  // PEMROSESAN PENGENALAN MARKER OPTIK (METODE B) REAL-TIME
  // HANYA MARKER YANG SESUAI DENGAN PILIHAN DI SIDEBAR YANG AKAN DITERIMA!
  DateTime? _lastWrongMarkerWarning;

  void _handleDetectedMarker(String rawCode) {
    final upper = rawCode.toUpperCase().trim();
    int? detectedIndex;

    // Pencocokan kode marker Toraja unik
    if (upper.contains('SAPI') || upper.contains('01')) {
      detectedIndex = 0;
    } else if (upper.contains('PASSAPU') || upper.contains('02')) {
      detectedIndex = 1;
    } else if (upper.contains('SARONG') || upper.contains('03')) {
      detectedIndex = 2;
    } else if (upper.contains('FIGUR') || upper.contains('TORAJA') || upper.contains('04')) {
      detectedIndex = 3;
    }

    if (detectedIndex == null) return;

    // HANYA AKTIFKAN JIKA MARKER SESUAI DENGAN PILIHAN OBJEK SAAT INI DI SIDEBAR!
    if (detectedIndex == _selectedArtifactIndex) {
      if (!_isMarkerScanned) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isMarkerScanned = true;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✓ MARKER OPTIK TERDETEKSI: ${ArtifactData.items[_selectedArtifactIndex].name}!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00C853),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Jika kamera membaca marker lain yang tidak sesuai dengan pilihan di sidebar
      final now = DateTime.now();
      if (_lastWrongMarkerWarning == null || now.difference(_lastWrongMarkerWarning!).inSeconds >= 3) {
        _lastWrongMarkerWarning = now;
        HapticFeedback.lightImpact();
        final detectedName = ArtifactData.items[detectedIndex].name;
        final selectedName = ArtifactData.items[_selectedArtifactIndex].name;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Marker "$detectedName" terdeteksi. Silakan arahkan kamera ke marker "$selectedName" sesuai pilihan di menu kiri.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Reset Pemindaian Marker: Menyembunyikan model 3D kembali ke mode scan
  void _resetMarkerScan() {
    setState(() {
      _isMarkerScanned = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Model 3D disembunyikan. Silakan arahkan kamera ke kartu marker kembali.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _currentScreen == 0
            ? _buildHomeScreen()
            : _buildArViewerScreen(),
      ),
    );
  }

  // ==========================================================
  // HALAMAN 1: MENU UTAMA (HOME)
  // ==========================================================
  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        children: [
          // Sisi Kiri: Judul & Ilustrasi Vektor Tongkonan
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'AR Toraja',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 250,
                  height: 180,
                  child: CustomPaint(
                    painter: TongkonanWireframePainter(),
                  ),
                ),
              ],
            ),
          ),

          // Sisi Kanan: 4 Tombol Menu berbentuk Pill
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMenuButton(
                    label: 'Scan AR',
                    onPressed: () {
                      setState(() {
                        _currentScreen = 1;
                        _isCameraMode = true;
                        _isMarkerScanned = false; // Reset: Objek 3D TIDAK MUNCUL sebelum discan
                      });
                      _initScanner();
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildMenuButton(
                    label: 'Panduan',
                    onPressed: () => _showPanduanDialog(),
                  ),
                  const SizedBox(height: 14),
                  _buildMenuButton(
                    label: 'Tentang peneliti',
                    onPressed: () => _showPenelitiDialog(),
                  ),
                  const SizedBox(height: 14),
                  _buildMenuButton(
                    label: 'Keluar',
                    onPressed: () => _showExitConfirmation(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.black, width: 3.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HALAMAN 2: LAYAR AR & 3D VIEWER
  // ==========================================================
  Widget _buildArViewerScreen() {
    final activeArtifact = ArtifactData.items[_selectedArtifactIndex];

    return Row(
      children: [
        // SISI KIRI: PANEL 4 KOTAK PILIHAN OBJEK (HANYA MENAMPILKAN NAMA OBJEK)
        Container(
          width: 120, // Lebar proporsional untuk nama objek
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.black, width: 3.5),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 6),
              // Ikon Menu / Kembali ke Halaman 1
              GestureDetector(
                onTap: () {
                  _disposeScanner();
                  setState(() {
                    _currentScreen = 0;
                    _isCameraMode = false;
                    _isMarkerScanned = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
                      SizedBox(width: 4),
                      Icon(Icons.grid_view_rounded, size: 28, color: Colors.black),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.black26, height: 10),

              // 4 Kotak Pilihan Objek Budaya Toraja (Hanya Menampilkan Nama Objek Saja)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: ArtifactData.items.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = ArtifactData.items[index];
                    final isSelected = index == _selectedArtifactIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedArtifactIndex = index;
                          // Reset scan saat berganti objek, agar harus scan marker objek baru!
                          _isMarkerScanned = false;
                        });
                      },
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFECEF) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFB92B27) : Colors.black,
                            width: isSelected ? 3.0 : 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x33B92B27),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: isSelected ? const Color(0xFFB92B27) : Colors.black87,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),

        // SISI KANAN: KOTAK SCAN AR & KONTROL DI LUAR KOTAK
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 20, top: 10, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. KOTAK SCAN AR UTAMA (BERSIH & LAPANG)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isCameraMode ? Colors.black : const Color(0xFFFBFBFB),
                      border: Border.all(color: Colors.black, width: 3.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Live Optical Scanner Camera (Metode B)
                        if (_isCameraMode) ...[
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (BarcodeCapture capture) {
                              for (final barcode in capture.barcodes) {
                                final code = barcode.rawValue;
                                if (code != null && code.isNotEmpty) {
                                  _handleDetectedMarker(code);
                                  break;
                                }
                              }
                            },
                            errorBuilder: (context, error) {
                              return const Center(
                                child: Text(
                                  'Akses Kamera Diperlukan untuk Scan AR',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ],

                        // AR Scanner Reticle & Laser (Hanya saat memindai & belum discan)
                        if (_isCameraMode && !_isMarkerScanned)
                          _buildArScannerOverlay(activeArtifact),

                        // MODEL 3D INTERAKTIF (HANYA MUNCUL SETELAH MARKER DISCAN / MODE 3D)
                        if (!_isCameraMode || _isMarkerScanned)
                          Positioned.fill(
                            child: ModelViewer(
                              key: ValueKey('${activeArtifact.id}_${_isCameraMode ? "cam" : "studio"}_$_isMarkerScanned'),
                              src: activeArtifact.publicUrl,
                              alt: activeArtifact.name,
                              ar: false,
                              autoRotate: !_isCameraMode,
                              cameraControls: true,
                              backgroundColor: Colors.transparent,
                            ),
                          ),

                        // Tombol Kontrol Kamera di Kanan Atas Viewport (Flash, Flip)
                        if (_isCameraMode)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Row(
                              children: [
                                _buildCircleHudButton(
                                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                  tooltip: 'Lampu Senter',
                                  color: _isFlashOn ? const Color(0xFFFFDE59) : Colors.white,
                                  onTap: _toggleFlash,
                                ),
                                const SizedBox(width: 6),
                                _buildCircleHudButton(
                                  icon: Icons.flip_camera_android,
                                  tooltip: 'Ganti Kamera Depan/Belakang',
                                  color: Colors.white,
                                  onTap: _switchCameraLens,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 2. AREA DI LUAR KOTAK SCAN: TEKS STATUS POLOS, TOMBOL 3D STUDIO, & TOMBOL "?"
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      // BAGIAN KIRI: TEKS SEDANG MEMINDAI (POLOS TANPA PEMBUNGKUS) / TOMBOL PINDAI ULANG
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildOuterStatusArea(activeArtifact),
                        ),
                      ),

                      // TOMBOL MODE 3D STUDIO (DIPINDAHKAN KE LUAR KOTAK SCAN)
                      OutlinedButton.icon(
                        icon: Icon(
                          _isCameraMode ? Icons.view_in_ar : Icons.camera_alt,
                          size: 18,
                          color: Colors.black,
                        ),
                        label: Text(
                          _isCameraMode ? 'Mode 3D Studio' : 'Nyalakan Kamera AR',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black, width: 2.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: _toggleCameraMode,
                      ),

                      const SizedBox(width: 10),

                      // TOMBOL BANTUAN "?" DI LUAR KOTAK SCAN
                      GestureDetector(
                        onTap: () => _showObjectInfoDialog(activeArtifact),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // WIDGET HELPER SCANNER AR & RETICLE
  // ==========================================================
  Widget _buildArScannerOverlay(TorajaArtifact artifact) {
    final color = _isMarkerScanned ? const Color(0xFF00C853) : const Color(0xFFFFDE59);

    return IgnorePointer(
      ignoring: true, // Input sentuhan tetap tembus ke ModelViewer jika sudah muncul
      child: AnimatedBuilder(
        animation: _scanAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // 4 Sudut Bidik Target AR (Corner Brackets)
              Center(
                child: SizedBox(
                  width: 260,
                  height: 180,
                  child: CustomPaint(
                    painter: _ArReticlePainter(
                      color: color,
                      strokeWidth: 3.5,
                      cornerLength: 26,
                    ),
                  ),
                ),
              ),

              // Garis Laser Scan yang bergerak vertikal (Hanya saat memindai / belum discan)
              if (!_isMarkerScanned)
                Positioned(
                  left: 90,
                  right: 90,
                  top: 55 + (_scanAnimation.value * 180),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color.fromRGBO(185, 43, 39, 0.9),
                          const Color(0xFFFFDE59),
                          const Color.fromRGBO(185, 43, 39, 0.9),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(185, 43, 39, 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Area status di luar kotak scan: Teks polos tanpa pembungkus, otomatis hilang saat marker terdeteksi
  Widget _buildOuterStatusArea(TorajaArtifact artifact) {
    if (_isCameraMode) {
      if (!_isMarkerScanned) {
        // Teks polos tanpa border / tanpa background pembungkus
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFFB92B27),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Sedang memindai marker ${artifact.name}...',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        );
      } else {
        // Ketika berhasil memindai: TEKS SEDANG MEMINDAI HILANG!
        // Digantikan tombol "Pindai Ulang" jika ingin memindai marker kembali
        return OutlinedButton.icon(
          icon: const Icon(Icons.refresh, size: 16, color: Colors.black),
          label: const Text(
            'Pindai Ulang',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: _resetMarkerScan,
        );
      }
    }

    return Text(
      'Studio 3D • ${artifact.name}',
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCircleHudButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 1.5),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // ==========================================================
  // HALAMAN 3: POP-UP INFORMASI OBJEK (CLOUDY / SCALLOPED MODAL)
  // ==========================================================
  void _showObjectInfoDialog(TorajaArtifact artifact) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Kontainer Modal Bertepi Gelombang / Rounded
              Container(
                width: 480,
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 3.5),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artifact.modalTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          artifact.description,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Header Badge "?" Kuning di Atas Modal
              Positioned(
                top: -24,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDE59),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3.5),
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              // Tombol Tutup "X" di Pojok Kanan Atas
              Positioned(
                top: 8,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.5),
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // HALAMAN 4: POP-UP PANDUAN (BINDER NOTEBOOK SHEET)
  // ==========================================================
  void _showPanduanDialog() {
    _showBinderNotebookDialog(
      title: 'Panduan Scan AR',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BinderStep(number: '1', text: 'Tekan tombol "Scan AR" di Menu Utama untuk membuka penampil AR.'),
          const _BinderStep(number: '2', text: 'Kamera HP langsung aktif memindai pola optik marker secara otomatis.'),
          const _BinderStep(number: '3', text: 'Arahkan kamera HP ke kartu marker Toraja yang telah dicetak atau ditampilkan di layar monitor.'),
          const _BinderStep(number: '4', text: 'Saat kartu marker terbaca, kamera otomatis memunculkan model 3D yang sesuai di atas kartu!'),
          const _BinderStep(number: '5', text: 'Usap layar untuk memutar objek 360°, dan cubit untuk memperbesar / zoom.'),
          const _BinderStep(number: '6', text: 'Tekan tombol "🔄 Pindai Marker Lain" untuk menyembunyikan model dan berganti marker.'),
          const _BinderStep(number: '7', text: 'Tekan tombol (?) untuk membaca sejarah & makna filosofi adat objek budaya.'),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB92B27),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text(
                'Unduh Kartu Marker (Google Drive)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                final Uri url = Uri.parse('https://drive.google.com/drive/folders/1t1M_GMO6DiAKDI37YLO62ZTx6qjQP-lt');
                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Error launching url: $e');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HALAMAN 5: POP-UP TENTANG PENELITI (BINDER NOTEBOOK SHEET)
  // ==========================================================
  void _showPenelitiDialog() {
    _showBinderNotebookDialog(
      title: 'Tentang Peneliti',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ResearcherRow(label: 'Aplikasi', value: 'AR Toraja (Augmented Reality)'),
          SizedBox(height: 8),
          _ResearcherRow(label: 'Tujuan', value: 'Media Edukasi & Pengenalan Warisan Budaya Suku Toraja berbasis Mobile AR'),
          SizedBox(height: 8),
          _ResearcherRow(label: 'Pengembang', value: 'Tim Peneliti Budaya Toraja'),
          SizedBox(height: 8),
          _ResearcherRow(label: 'Spesifikasi', value: 'Berdasarkan Dokumen Wireframe AR Toraja.pdf'),
        ],
      ),
    );
  }

  // Helper Template Modal Buku Binder
  void _showBinderNotebookDialog({required String title, required Widget content}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
          child: Stack(
            children: [
              Container(
                width: 520,
                padding: const EdgeInsets.fromLTRB(60, 24, 28, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF9),
                  border: Border.all(color: Colors.black, width: 3.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(color: Colors.black26, thickness: 2, height: 18),
                    Flexible(
                      child: SingleChildScrollView(child: content),
                    ),
                  ],
                ),
              ),

              // 5 Lubang Cincin Binder di Sisi Kiri
              Positioned(
                left: 14,
                top: 24,
                bottom: 24,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    5,
                    (index) => Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                    ),
                  ),
                ),
              ),

              // Tombol Tutup "X" di Kanan Atas
              Positioned(
                top: 10,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.5),
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi AR Toraja?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// CUSTOM PAINTER RETICLE SUDUT BIDIK AR (CORNER BRACKETS)
// ==========================================================
class _ArReticlePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _ArReticlePainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final l = cornerLength;

    // Siku Kiri Atas
    canvas.drawLine(const Offset(0, 0), Offset(l, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, l), paint);

    // Siku Kanan Atas
    canvas.drawLine(Offset(w, 0), Offset(w - l, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, l), paint);

    // Siku Kiri Bawah
    canvas.drawLine(Offset(0, h), Offset(l, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - l), paint);

    // Siku Kanan Bawah
    canvas.drawLine(Offset(w, h), Offset(w - l, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - l), paint);
  }

  @override
  bool shouldRepaint(covariant _ArReticlePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ==========================================================
// WIDGET HELPER PANDUAN & PENELITI
// ==========================================================
class _BinderStep extends StatelessWidget {
  final String number;
  final String text;
  const _BinderStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResearcherRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResearcherRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13.5)),
        ),
      ],
    );
  }
}

// ==========================================================
// CUSTOM PAINTER TONGKONAN SESUAI WIREFRAME PDF HALAMAN 1
// ==========================================================
class TongkonanWireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Atap Melengkung Khas Tongkonan
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.1, size.height * 0.35);
    roofPath.cubicTo(
      size.width * 0.25, size.height * 0.72,
      size.width * 0.75, size.height * 0.72,
      size.width * 0.9, size.height * 0.35,
    );
    roofPath.lineTo(size.width * 0.8, size.height * 0.68);
    roofPath.lineTo(size.width * 0.2, size.height * 0.68);
    roofPath.close();

    canvas.drawPath(roofPath, fillPaint);
    canvas.drawPath(roofPath, paint);

    // Garis Dobel Atap Bawah
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.72),
      Offset(size.width * 0.8, size.height * 0.72),
      paint,
    );

    // Badan Rumah
    final bodyRect = Rect.fromLTWH(
      size.width * 0.22,
      size.height * 0.72,
      size.width * 0.56,
      size.height * 0.16,
    );
    canvas.drawRect(bodyRect, fillPaint);
    canvas.drawRect(bodyRect, paint);

    // Jendela-jendela Persegi
    final windowPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final winWidth = size.width * 0.08;
    final winHeight = size.height * 0.09;
    final winY = size.height * 0.75;

    canvas.drawRect(Rect.fromLTWH(size.width * 0.27, winY, winWidth, winHeight), windowPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.39, winY, winWidth, winHeight), windowPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.53, winY, winWidth, winHeight), windowPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.65, winY, winWidth, winHeight), windowPaint);

    // Tiang-tiang Penyangga Bawah
    final pillarYTop = size.height * 0.88;
    final pillarYBottom = size.height * 1.0;

    void drawPillar(double x) {
      canvas.drawLine(Offset(x, pillarYTop), Offset(x, pillarYBottom), paint);
      canvas.drawLine(Offset(x + 5, pillarYTop), Offset(x + 5, pillarYBottom), paint);
    }

    drawPillar(size.width * 0.30);
    drawPillar(size.width * 0.50);
    drawPillar(size.width * 0.70);

    // Garis Tanah
    canvas.drawLine(
      Offset(size.width * 0.20, pillarYBottom),
      Offset(size.width * 0.80, pillarYBottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
