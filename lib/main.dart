import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
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

  // State Manajemen Kamera AR In-App
  bool _isCameraMode = false;
  CameraController? _cameraController;
  List<CameraDescription> _availableCamerasList = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false;
  bool _isFlashOn = false;
  bool _isMarkerLocked = false;

  // Animasi Laser Scanline
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
    _disposeCamera();
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isFlashOn = false;
        });
      }
    }
  }

  Future<void> _initCamera({int cameraIndex = 0}) async {
    if (_isCameraInitializing) return;
    setState(() {
      _isCameraInitializing = true;
      _isCameraMode = true;
    });

    try {
      if (_availableCamerasList.isEmpty) {
        _availableCamerasList = await availableCameras();
      }

      if (_availableCamerasList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada kamera yang ditemukan pada perangkat.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isCameraMode = false;
            _isCameraInitializing = false;
          });
        }
        return;
      }

      final targetIndex = cameraIndex % _availableCamerasList.length;
      final camera = _availableCamerasList[targetIndex];

      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _selectedCameraIndex = targetIndex;
          _isCameraInitialized = true;
          _isCameraInitializing = false;
          _isCameraMode = true;
          _isFlashOn = false;
        });
      }
    } catch (e) {
      debugPrint('Error init camera: $e');
      if (mounted) {
        setState(() {
          _isCameraMode = false;
          _isCameraInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akses kamera gagal dibuka: $e. Pastikan izin kamera telah disetujui.'),
            backgroundColor: const Color(0xFFB92B27),
          ),
        );
      }
    }
  }

  void _toggleCameraMode() async {
    if (_isCameraMode) {
      await _disposeCamera();
      if (mounted) {
        setState(() {
          _isCameraMode = false;
          _isMarkerLocked = false;
        });
      }
    } else {
      await _initCamera(cameraIndex: _selectedCameraIndex);
    }
  }

  void _switchCameraLens() async {
    if (_availableCamerasList.length > 1) {
      final nextIndex = (_selectedCameraIndex + 1) % _availableCamerasList.length;
      await _initCamera(cameraIndex: nextIndex);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya 1 lensa kamera yang terdeteksi di perangkat ini.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() => _isFlashOn = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lampu senter tidak didukung di lensa ini: $e')),
      );
    }
  }

  void _takeArSnapshot() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00C853)),
                SizedBox(width: 8),
                Text('Foto AR Berhasil Diambil', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tangkapan foto Augmented Reality berhasil disimpan di perangkat:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    image.path,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black87),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
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
                      });
                      // Menyalakan kamera langsung saat tombol Scan AR ditekan
                      _initCamera();
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
        // Sisi Kiri: Ikon Grid + 4 Thumbnail Item
        Container(
          width: 110,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.black, width: 3.5),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Ikon Grid Menu (Kembali ke Halaman 1 & Matikan Kamera)
              GestureDetector(
                onTap: () {
                  _disposeCamera();
                  setState(() {
                    _currentScreen = 0;
                    _isCameraMode = false;
                    _isMarkerLocked = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.only(bottom: 6),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 38,
                    color: Colors.black,
                  ),
                ),
              ),

              // 4 Thumbnail Vertikal
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: ArtifactData.items.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = ArtifactData.items[index];
                    final isSelected = index == _selectedArtifactIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedArtifactIndex = index;
                        });
                      },
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFECEF) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFB92B27) : Colors.black,
                            width: isSelected ? 3.5 : 2.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 26,
                              color: isSelected ? const Color(0xFFB92B27) : Colors.black,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFFB92B27) : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

        // Sisi Kanan: Area Viewport 3D / AR + Tombol "?"
        Expanded(
          child: Stack(
            children: [
              // Viewport Box 3D Model & Kamera AR
              Center(
                child: Container(
                  width: 440,
                  height: 290,
                  decoration: BoxDecoration(
                    color: _isCameraMode ? Colors.black : const Color(0xFFFBFBFB),
                    border: Border.all(color: Colors.black, width: 3.5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Live Camera Preview (jika mode kamera aktif)
                      if (_isCameraMode) ...[
                        if (_isCameraInitialized && _cameraController != null)
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!.value.previewSize?.height ?? 1280,
                                height: _cameraController!.value.previewSize?.width ?? 720,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Color(0xFFB92B27)),
                                SizedBox(height: 12),
                                Text(
                                  'Menghubungkan Kamera HP...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],

                      // 2. AR Scanner Reticle & Laser (hanya saat mode kamera aktif)
                      if (_isCameraMode)
                        _buildArScannerOverlay(activeArtifact),

                      // 3. Komponen ModelViewer 3D Interaktif
                      // Di mode kamera, latar transparan agar objek 3D melayang di atas kamera nyata
                      Positioned.fill(
                        child: ModelViewer(
                          key: ValueKey('${activeArtifact.id}_${_isCameraMode ? "cam" : "studio"}'),
                          src: activeArtifact.publicUrl,
                          alt: activeArtifact.name,
                          ar: false, // Intent eksternal dinonaktifkan agar tidak mental/crash
                          autoRotate: !_isCameraMode,
                          cameraControls: true,
                          backgroundColor: Colors.transparent,
                        ),
                      ),

                      // 4. Tombol Kontrol Kamera di Kanan Atas Viewport (Flash, Flip, Snapshot)
                      if (_isCameraMode && _isCameraInitialized)
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
                                tooltip: 'Ganti Kamera',
                                color: Colors.white,
                                onTap: _switchCameraLens,
                              ),
                              const SizedBox(width: 6),
                              _buildCircleHudButton(
                                icon: Icons.camera_alt,
                                tooltip: 'Ambil Foto AR',
                                color: Colors.white,
                                onTap: _takeArSnapshot,
                              ),
                            ],
                          ),
                        ),

                      // 5. Badge Status di Kiri Atas Viewport
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _buildStatusBadge(activeArtifact),
                      ),

                      // 6. Bar Tombol di Bagian Bawah Viewport
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol Toggle Mode (Kamera AR / 3D Studio)
                            GestureDetector(
                              onTap: _toggleCameraMode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isCameraMode ? Colors.white : const Color(0xFFF7B2BD),
                                  border: Border.all(color: Colors.black, width: 3),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isCameraMode ? Icons.view_in_ar : Icons.camera_alt,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isCameraMode ? 'Mode 3D Studio' : 'Nyalakan Kamera AR',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Tombol Kunci Marker / Pindai Ulang jika mode kamera aktif
                            if (_isCameraMode) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isMarkerLocked = !_isMarkerLocked;
                                  });
                                  if (_isMarkerLocked) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✓ Marker Terdeteksi: Objek ${activeArtifact.name} terkunci di ruang nyata!'),
                                        backgroundColor: const Color(0xFF00C853),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isMarkerLocked ? const Color(0xFF00C853) : Colors.black87,
                                    border: Border.all(color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isMarkerLocked ? Icons.check_circle : Icons.filter_center_focus,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isMarkerLocked ? 'Marker Terkunci' : 'Kunci Marker',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Tombol Info Scene Viewer jika di mode 3D
                            if (!_isCameraMode) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showSceneViewerDialog(activeArtifact),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.open_in_new, size: 16, color: Colors.black),
                                      SizedBox(width: 6),
                                      Text(
                                        'Google ARCore',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tombol Bantuan "?" di Pojok Kanan Bawah Layar
              Positioned(
                right: 24,
                bottom: 18,
                child: GestureDetector(
                  onTap: () => _showObjectInfoDialog(activeArtifact),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // WIDGET HELPER SCANNER AR & HUD
  // ==========================================================
  Widget _buildArScannerOverlay(TorajaArtifact artifact) {
    final color = _isMarkerLocked ? const Color(0xFF00C853) : const Color(0xFFFFDE59);

    return IgnorePointer(
      ignoring: true, // Input sentuhan tetap tembus ke ModelViewer untuk rotasi 3D
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

              // Garis Laser Scan yang bergerak vertikal
              if (!_isMarkerLocked)
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

  Widget _buildStatusBadge(TorajaArtifact artifact) {
    if (_isCameraMode) {
      if (_isMarkerLocked) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00C853),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                'TERKUNCI: ${artifact.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 0, 0, 0.70),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFDE59), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, size: 11, color: Colors.redAccent),
            SizedBox(width: 5),
            Text(
              'LIVE AR • MEMINDAI...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.threed_rotation, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            artifact.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  void _showSceneViewerDialog(TorajaArtifact artifact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.view_in_ar, color: Color(0xFFB92B27)),
            SizedBox(width: 8),
            Text('Google Scene Viewer', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Scene Viewer adalah penampil AR eksternal bawaan Google untuk mendeteksi permukaan lantai datar.',
              style: TextStyle(fontSize: 13.5),
            ),
            SizedBox(height: 10),
            Text(
              '⚠️ Catatan Perangkat:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB92B27)),
            ),
            SizedBox(height: 4),
            Text(
              'Fitur ini memerlukan aplikasi "Google Play Services for AR" terpasang dan model HP bersertifikasi ARCore oleh Google.\n\nJika layar sempat abu-abu lalu kembali, HP belum mendukung ARCore. Anda dapat langsung menggunakan fitur "Nyalakan Kamera AR" di aplikasi ini yang 100% berjalan aktif.',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB92B27),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (Platform.isAndroid) {
                  final intent = AndroidIntent(
                    action: 'android.intent.action.VIEW',
                    data: Uri(
                      scheme: 'https',
                      host: 'arvr.google.com',
                      path: '/scene-viewer/1.0',
                      queryParameters: {
                        'mode': 'ar_preferred',
                        'file': artifact.publicUrl,
                      },
                    ).toString(),
                    package: 'com.google.android.googlequicksearchbox',
                    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                  );
                  await intent.launch();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal membuka Scene Viewer: $e'),
                      backgroundColor: const Color(0xFFB92B27),
                    ),
                  );
                }
              }
            },
            child: const Text('Coba Buka'),
          ),
        ],
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
          const _BinderStep(number: '2', text: 'Kamera HP langsung menyala otomatis di layar. Arahkan kamera ke kartu marker atau meja kerja.'),
          const _BinderStep(number: '3', text: 'Pilih salah satu objek Toraja pada panel sebelah kiri (Sa\'pi\', Passapu, Sarong, Figur).'),
          const _BinderStep(number: '4', text: 'Usap layar untuk memutar objek 3D 360°, dan cubit untuk memperbesar / zoom.'),
          const _BinderStep(number: '5', text: 'Tekan "Kunci Marker" untuk mengunci posisi objek, dan tekan ikon Kamera di pojok kanan atas untuk mengambil foto AR.'),
          const _BinderStep(number: '6', text: 'Tekan tombol (?) untuk membaca sejarah & makna filosofi adat objek budaya.'),
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
