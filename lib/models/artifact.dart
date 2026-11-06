class TorajaArtifact {
  final String id;
  final String name;
  final String modalTitle;
  final String description;
  final String localAssetPath;
  final String fallbackUrl;

  const TorajaArtifact({
    required this.id,
    required this.name,
    required this.modalTitle,
    required this.description,
    required this.localAssetPath,
    required this.fallbackUrl,
  });
}

// Data daftar objek kebudayaan Toraja sesuai wireframe PDF
class ArtifactData {
  /// Ubah nilai ini menjadi `true` jika Anda sudah memasukkan file .glb asli dari klien
  /// ke dalam folder 'assets/models/'.
  /// Jika masih bernilai `false`, aplikasi akan menggunakan model 3D sample online aman.
  static const bool useLocalAssets = false;

  static const List<TorajaArtifact> items = [
    TorajaArtifact(
      id: 'headdress',
      name: "Hiasan Kepala",
      modalTitle: "Informasi tentang hiasan kepala",
      description: 
        "Sa'pi' (Hiasan Kepala Toraja):\n\n"
        "Merupakan mahkota hiasan dahi tradisional khas Tana Toraja yang dikenakan dalam tarian adat Pa'gellu dan upacara kebesaran adat Rambu Tuka' (syukuran).\n\n"
        "Dihiasi dengan motif ukiran tanduk kerbau berlapis emas, manik-manik kuno (kandaure), serta bulu cenderawasih/ayam jantan yang melambangkan keanggunan, martabat, dan kehormatan luhur masyarakat Toraja.",
      localAssetPath: 'assets/models/hiasan_kepala.glb',
      fallbackUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    ),
    TorajaArtifact(
      id: 'tongkonan',
      name: "Tongkonan",
      modalTitle: "Informasi tentang Rumah Tongkonan",
      description: 
        "Rumah Adat Tongkonan:\n\n"
        "Tongkonan adalah rumah adat masyarakat Toraja dengan ciri khas atap melengkung menyerupai perahu terbalik atau tanduk kerbau (Banua Layuk).\n\n"
        "Di bagian depan terdapat tiang utama (Tulak Somba) yang dihiasi deretan tanduk kerbau sebagai penanda status sosial dan kekayaan adat suatu keluarga bangsawan Toraja.",
      localAssetPath: 'assets/models/tongkonan.glb',
      fallbackUrl: 'https://modelviewer.dev/shared-assets/models/reflective-sphere.gltf',
    ),
    TorajaArtifact(
      id: 'tautau',
      name: "Tau-tau",
      modalTitle: "Informasi tentang Patung Tau-tau",
      description: 
        "Patung Adat Tau-tau:\n\n"
        "Patung kayu nangka pahatan yang menyerupai fisik orang yang telah meninggal dunia dalam strata bangsawan Toraja.\n\n"
        "Patung ini diberi pakaian adat lengkap dan diletakkan di ceruk tebing batu makam (seperti di Lemo dan Londa) untuk menjaga keturunan yang masih hidup serta melambangkan kehadiran abadi para leluhur.",
      localAssetPath: 'assets/models/tau_tau.glb',
      fallbackUrl: 'https://modelviewer.dev/shared-assets/models/NeilArmstrong.glb',
    ),
    TorajaArtifact(
      id: 'tedong',
      name: "Tedong Bonga",
      modalTitle: "Informasi tentang Tedong Bonga",
      description: 
        "Tedong Bonga (Kerbau Belang Toraja):\n\n"
        "Hewan kerbau endemik paling prestisius dan bernilai sangat tinggi (dapat mencapai ratusan juta hingga miliaran rupiah).\n\n"
        "Tedong Bonga memiliki belang putih dan hitam khas serta mata berwarna putih/beling. Merupakan hewan kurban sakral utama dalam upacara pemakaman adat Rambu Solo' untuk mengantar arwah menuju alam baka (Puya).",
      localAssetPath: 'assets/models/tedong_bonga.glb',
      fallbackUrl: 'https://modelviewer.dev/shared-assets/models/Horse.glb',
    ),
  ];
}

