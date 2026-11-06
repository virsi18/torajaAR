class TorajaArtifact {
  final String id;
  final String name;
  final String modalTitle;
  final String description;
  final String localAssetPath;
  final String publicUrl;

  const TorajaArtifact({
    required this.id,
    required this.name,
    required this.modalTitle,
    required this.description,
    required this.localAssetPath,
    required this.publicUrl,
  });
}

// Data 4 objek kebudayaan Toraja sesuai aset 3D asli dari klien dan wireframe PDF
class ArtifactData {
  static const List<TorajaArtifact> items = [
    TorajaArtifact(
      id: 'sapi',
      name: "Sa'pi' (Hiasan Kepala)",
      modalTitle: "Informasi tentang hiasan kepala (Sa'pi')",
      description: 
        "Sa'pi' (Hiasan Kepala Toraja):\n\n"
        "Merupakan mahkota hiasan dahi tradisional khas Tana Toraja yang dikenakan penari perempuan dalam tarian adat Pa'gellu dan upacara adat Rambu Tuka' (syukuran).\n\n"
        "Dihiasi dengan motif ukiran tanduk kerbau berlapis emas, untaian manik-manik kuno (kandaure), serta bulu cenderawasih atau ayam jantan yang melambangkan keanggunan, martabat, dan kehormatan luhur masyarakat Toraja.",
      localAssetPath: 'assets/models/sapi.glb',
      publicUrl: 'https://cdn.jsdelivr.net/gh/virsi18/torajaAR@main/assets/models/sapi.glb',
    ),
    TorajaArtifact(
      id: 'passapu',
      name: "Passapu (Ikat Kepala)",
      modalTitle: "Informasi tentang Passapu",
      description: 
        "Passapu (Ikat Kepala Adat Toraja):\n\n"
        "Passapu adalah penutup kepala tradisional khas kaum pria Toraja yang terbuat dari lipatan kain tenun bermotif khusus.\n\n"
        "Bentuk lipatan dan sudut passapu mencerminkan status adat, kewibawaan, keberanian, serta kesiapan seorang pria Toraja dalam memimpin upacara adat atau upacara pemakaman Rambu Solo'.",
      localAssetPath: 'assets/models/passapu.glb',
      publicUrl: 'https://cdn.jsdelivr.net/gh/virsi18/torajaAR@main/assets/models/passapu.glb',
    ),
    TorajaArtifact(
      id: 'sarong',
      name: "Sarong Adat",
      modalTitle: "Informasi tentang Sarong Adat Toraja",
      description: 
        "Sarong / Busana Adat Toraja:\n\n"
        "Kain sarung tenun tradisional khas suku Toraja yang ditenun dengan benang kapas dan dihiasi motif ukiran Pa'ssura khas Toraja (seperti motif Pa'teddong dan Pa'sekong Kandaure).\n\n"
        "Sarong dikenakan oleh masyarakat Toraja baik pria maupun wanita dalam berbagai perhelatan adat akbar sebagai simbol identitas leluhur dan kesopanan budi pekerti.",
      localAssetPath: 'assets/models/sarong.glb',
      publicUrl: 'https://cdn.jsdelivr.net/gh/virsi18/torajaAR@main/assets/models/sarong.glb',
    ),
    TorajaArtifact(
      id: 'toraja',
      name: "Figur Budaya Toraja",
      modalTitle: "Informasi tentang Figur Budaya Toraja",
      description: 
        "Figur dan Ornamen Adat Toraja:\n\n"
        "Representasi seni ukir dan figur khas Tana Toraja yang menggambarkan keharmonisan antara manusia, alam (tombak dan kerbau), serta nilai-nilai spiritual Aluk Todolo.\n\n"
        "Menjadi warisan budaya takbenda nusantara yang kaya akan filosofi kehidupan, kebersamaan gotong royong, dan penghormatan kepada para leluhur.",
      localAssetPath: 'assets/models/toraja.glb',
      publicUrl: 'https://cdn.jsdelivr.net/gh/virsi18/torajaAR@main/assets/models/toraja.glb',
    ),
  ];
}
