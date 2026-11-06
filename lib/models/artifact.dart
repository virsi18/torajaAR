class TorajaArtifact {
  final String id;
  final String name;
  final String modalTitle;
  final String description;
  final String localAssetPath;
  final String publicUrl;
  final String thumbnailPath;
  final String markerAssetPath;

  const TorajaArtifact({
    required this.id,
    required this.name,
    required this.modalTitle,
    required this.description,
    required this.localAssetPath,
    required this.publicUrl,
    required this.thumbnailPath,
    required this.markerAssetPath,
  });
}

// Data 4 objek kebudayaan Toraja sesuai aset 3D asli dari klien dan wireframe PDF
class ArtifactData {
  static const List<TorajaArtifact> items = [
    TorajaArtifact(
      id: 'sapi',
      name: "Sa'pi'",
      modalTitle: "Informasi tentang Sa'pi' (Hiasan Kepala)",
      description: 
        "Sa'pi' (Hiasan Kepala Toraja):\n\n"
        "Merupakan mahkota hiasan dahi tradisional khas Tana Toraja yang dikenakan penari perempuan dalam tarian adat Pa'gellu dan upacara adat Rambu Tuka' (syukuran).\n\n"
        "Dihiasi dengan motif ukiran tanduk kerbau berlapis emas, untaian manik-manik kuno (kandaure), serta bulu cenderawasih atau ayam jantan yang melambangkan keanggunan, martabat, dan kehormatan luhur masyarakat Toraja.",
      localAssetPath: 'assets/models/sapi.glb',
      publicUrl: 'https://cdn.jsdelivr.net/gh/virsi18/torajaAR@main/assets/models/sapi.glb',
      thumbnailPath: 'assets/images/sapi_thumb.png',
      markerAssetPath: 'assets/markers/marker_sapi.png',
    ),
    TorajaArtifact(
      id: 'passapu',
      name: "Passapu",
      modalTitle: "Informasi tentang Passapu (Ikat Kepala)",
      description: 
        "Passapu (Ikat Kepala Adat Toraja):\n\n"
        "Passapu adalah penutup kepala tradisional khas kaum pria Toraja yang terbuat dari lipatan kain tenun bermotif khusus.\n\n"
        "Bentuk lipatan dan sudut passapu mencerminkan status adat, kewibawaan, keberanian, serta kesiapan seorang pria Toraja dalam memimpin upacara adat atau upacara pemakaman Rambu Solo'.",
      localAssetPath: 'assets/models/passapu.glb',
      publicUrl: 'https://cdn.jsdelivr.net/gh/virsi18/torajaAR@main/assets/models/passapu.glb',
      thumbnailPath: 'assets/images/passapu_thumb.png',
      markerAssetPath: 'assets/markers/marker_passapu.png',
    ),
    TorajaArtifact(
      id: 'sarong',
      name: "Sarong",
      modalTitle: "Informasi tentang Sarong Adat Toraja",
      description: 
        "Sarong / Busana Adat Toraja:\n\n"
        "Kain sarung tenun tradisional khas suku Toraja yang ditenun dengan benang kapas dan dihiasi motif ukiran Pa'ssura khas Toraja (seperti motif Pa'teddong dan Pa'sekong Kandaure).\n\n"
        "Sarong dikenakan oleh masyarakat Toraja baik pria maupun wanita dalam berbagai perhelatan adat akbar sebagai simbol identitas leluhur dan kesopanan budi pekerti.",
      localAssetPath: 'assets/models/sarong.glb',
      publicUrl: 'https://cdn.jsdelivr.net/gh/virsi18/torajaAR@main/assets/models/sarong.glb',
      thumbnailPath: 'assets/images/sarong_thumb.png',
      markerAssetPath: 'assets/markers/marker_sarong.png',
    ),
    TorajaArtifact(
      id: 'toraja',
      name: "Figur Toraja",
      modalTitle: "Informasi tentang Figur Budaya Toraja",
      description: 
        "Figur dan Ornamen Adat Toraja:\n\n"
        "Representasi seni ukir dan figur khas Tana Toraja yang menggambarkan keharmonisan antara manusia, alam (tombak dan kerbau), serta nilai-nilai spiritual Aluk Todolo.\n\n"
        "Menjadi warisan budaya takbenda nusantara yang kaya akan filosofi kehidupan, kebersamaan gotong royong, dan penghormatan kepada para leluhur.",
      localAssetPath: 'assets/models/toraja.glb',
      publicUrl: 'https://cdn.jsdelivr.net/gh/virsi18/torajaAR@main/assets/models/toraja.glb',
      thumbnailPath: 'assets/images/toraja_thumb.png',
      markerAssetPath: 'assets/markers/marker_toraja.png',
    ),
  ];
}
