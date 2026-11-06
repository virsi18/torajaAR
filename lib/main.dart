import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 0: Menu Utama (Halaman 1), 1: Layar AR & 3D Viewer (Halaman 2)
  int _currentScreen = 0;
  int _selectedArtifactIndex = 0;

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
              // Ikon Grid Menu (Kembali ke Halaman 1)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentScreen = 0;
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
              // Viewport Box 3D Model
              Center(
                child: Container(
                  width: 440,
                  height: 290,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    border: Border.all(color: Colors.black, width: 3.5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Komponen ModelViewer 3D & AR
                      ModelViewer(
                        key: ValueKey(activeArtifact.id),
                        src: activeArtifact.publicUrl,
                        alt: activeArtifact.name,
                        ar: true, // Fitur Augmented Reality via Google ARCore / Scene Viewer
                        arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                        autoRotate: true,
                        cameraControls: true,
                        backgroundColor: Colors.transparent,
                      ),

                      // Tombol "3D / Buka Kamera AR" di bagian bawah kotak wireframe
                      Positioned(
                        bottom: 12,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ketuk ikon kubus AR di sudut kanan bawah kotak 3D untuk menyalakan kamera HP!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Color(0xFFB92B27),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7B2BD),
                              border: Border.all(color: Colors.black, width: 3),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.view_in_ar, size: 20, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  '3D • Sentuh AR untuk Kamera',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      title: 'Panduan',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BinderStep(number: '1', text: 'Buka Menu Scan AR untuk masuk ke penampil 3D.'),
          const _BinderStep(number: '2', text: 'Pilih salah satu objek Toraja dari daftar panel kiri layar.'),
          const _BinderStep(number: '3', text: 'Putar objek 3D 360° dengan usapan jari, dan cubit untuk memperbesar / zoom.'),
          const _BinderStep(number: '4', text: 'Ketuk tombol AR untuk menaruh objek budaya di atas meja/lantai nyata melalui kamera HP.'),
          const _BinderStep(number: '5', text: 'Tekan tombol tanda tanya (?) untuk membaca nilai sejarah & filosofi budayanya.'),
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

