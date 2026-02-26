import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

// IMPORT SENJATA RESPONSIVE SULTAN
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.init();
  runApp(const AlWaqiahApp());
}

// ==========================================
// SERVICE: NOTIFIKASI ADZAN
// ==========================================
class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(android: android),
    );
  }

  static Future scheduleAdzan(int id, String title, DateTime time) async {
    if (time.isBefore(DateTime.now())) return;
    await _notifications.zonedSchedule(
      id,
      'Waktunya Sholat $title',
      'Mari menunaikan ibadah sholat $title tepat waktu.',
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'adzan_channel_id',
          'Notifikasi Adzan',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('adzan'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

// ==========================================
// APP CORE & THEME (PREMIUM FORCE UPDATE)
// ==========================================
class AlWaqiahApp extends StatelessWidget {
  const AlWaqiahApp({super.key});

  void executeUpdate() async {
    final Uri url = Uri.parse(
      'https://github.com/Yusuf-Ardiansyah/Yasin-Tahlil/releases/latest/download/app-arm64-v8a-release.apk',
    );

    debugPrint("Mencoba membuka link update: $url");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Gagal: canLaunchUrl mengembalikan nilai false.");
      }
    } catch (e) {
      debugPrint("Error saat membuka link: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // BUNGKUS DENGAN SCREENUTILINIT AGAR SEMUA OTOMATIS RESPONSIVE
    return ScreenUtilInit(
      designSize: const Size(360, 800), // Ukuran standar desain HP
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            useMaterial3: true,
          ),
          home: UpgradeAlert(
            dialogStyle: UpgradeDialogStyle.cupertino,
            // Gaya elegan ala iOS
            // --- BAGIAN FORCE UPDATE (WAJIB UPDATE) ---
            showIgnore: false,
            // Hilangkan tombol "Abaikan"
            showLater: false,
            // Hilangkan tombol "Nanti"
            // ------------------------------------------
            onUpdate: () {
              executeUpdate();
              return false;
            },
            upgrader: Upgrader(
              messages: _CustomUpgraderMessages(),
              // Panggil pesan custom di sini
              storeController: UpgraderStoreController(
                onAndroid:
                    () => UpgraderAppcastStore(
                      appcastURL:
                          'https://raw.githubusercontent.com/Yusuf-Ardiansyah/Yasin-Tahlil/refs/heads/main/appcast.xml',
                      osVersion: Version(1, 0, 0),
                    ),
              ),
              debugDisplayAlways: false,
            ),
            child: const MenuUtama(),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// WIDGET TAMBAHAN: CUSTOM TEKS UNTUK POP-UP UPDATE EKSKLUSIF
// ---------------------------------------------------------
class _CustomUpgraderMessages extends UpgraderMessages {
  @override
  String get title => '✨ PEMBARUAN EKSKLUSIF ✨';

  @override
  String get body =>
      'Versi terbaru Yasin & Tahlil Premium sudah tersedia.\n\nNikmati fitur terbaru, tampilan yang lebih elegan, dan perbaikan performa untuk kenyamanan ibadah Anda.\n\nMohon lakukan pembaruan sekarang untuk melanjutkan.';

  @override
  String get prompt => 'Silakan klik tombol di bawah ini:';

  @override
  String get buttonTitleUpdate => 'UNDUH SEKARANG 🚀';
}

// ==========================================
// HALAMAN: MENU UTAMA (BANNER INSPIRASI)
// ==========================================
class MenuUtama extends StatelessWidget {
  const MenuUtama({super.key});

  Future<void> _kontakYusuf() async {
    final Uri url = Uri.parse(
      "https://wa.me/6282139743432?text=Assalamualaikum%20Mas%20Yusuf",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Gagal");
    }
  }

  Map<String, String> _getRandomQuote() {
    final List<Map<String, String>> quotes = [
      {
        "text": "Maka nikmat Tuhan kamu yang manakah yang kamu dustakan?",
        "surah": "Ar-Rahman",
      },
      {
        "text": "Sesungguhnya bersama kesulitan ada kemudahan.",
        "surah": "Al-Insyirah: 6",
      },
      {
        "text":
            "Cukuplah Allah menjadi Penolong kami dan Allah adalah sebaik-baik Pelindung.",
        "surah": "Ali 'Imran: 173",
      },
      {
        "text": "Janganlah kamu bersedih, sesungguhnya Allah bersama kita.",
        "surah": "At-Taubah: 40",
      },
      {
        "text":
            "Dan barangsiapa bertawakal kepada Allah, niscaya Allah akan mencukupkan keperluannya.",
        "surah": "At-Thalaq: 3",
      },
      {
        "text":
            "Boleh jadi kamu membenci sesuatu, padahal ia amat baik bagimu.",
        "surah": "Al-Baqarah: 216",
      },
    ];
    return quotes[math.Random().nextInt(quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final quote = _getRandomQuote();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'YASIN & TAHLIL',
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00332B),
      ),
      body: ListView(
        padding: EdgeInsets.all(15.w),
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00332B), Color(0xFF001A16)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFFFFD54F).withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withOpacity(0.05),
                  blurRadius: 10.r,
                  spreadRadius: 2.r,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: const Color(0xFFFFD54F),
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "INSPIRASI HARI INI",
                      style: TextStyle(
                        color: const Color(0xFFFFD54F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  '"${quote["text"]!}"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "- QS. ${quote["surah"]!} -",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSectionTitle("BACAAN UTAMA"),
          _buildMenuItem(
            context,
            "📖",
            "Surat Yasin",
            "83 Ayat - Audio Full",
            Colors.teal,
            "yasin",
          ),
          _buildMenuItem(
            context,
            "📜",
            "Tahlil Lengkap",
            "Fokus Bacaan Platinum",
            Colors.teal,
            "tahlil",
          ),
          _buildMenuItem(
            context,
            "✨",
            "Al-Waqiah",
            "96 Ayat - Audio Full",
            Colors.teal,
            "waqiah",
          ),
          _buildSectionTitle("TOOLS & DZIKIR"),
          _buildMenuItem(
            context,
            "💍",
            "Cek Weton Jodoh",
            "Ramalan Jodoh Primbon Jawa",
            Colors.pinkAccent,
            "weton",
          ),
          _buildMenuItem(
            context,
            "📅",
            "Hitung Selamatan",
            "Kalkulator Hari Kematian",
            Colors.redAccent,
            "selamatan",
          ),
          _buildMenuItem(
            context,
            "🌟",
            "Asmaul Husna",
            "99 Nama Allah",
            Colors.purple,
            "asmaul_husna",
          ),
          _buildMenuItem(
            context,
            "🕌",
            "Jadwal Sholat",
            "Waktu Sholat & Adzan",
            Colors.green,
            "sholat",
          ),
          _buildMenuItem(
            context,
            "🧭",
            "Arah Kiblat",
            "Kompas Akurat & Getar",
            Colors.blueAccent,
            "qiblat",
          ),
          _buildMenuItem(
            context,
            "🤲",
            "Kumpulan Doa",
            "Doa Selamat, Rezeki & Ilmu",
            Colors.orange,
            "doa",
          ),
          _buildMenuItem(
            context,
            "📿",
            "Tasbih Digital",
            "Dzikir & Getar",
            Colors.amber,
            "tasbih",
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBranding(context),
    );
  }

  Widget _buildBottomBranding(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _kontakYusuf,
      child: Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: const Color(0xFF00332B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 22.r,
                backgroundImage: const AssetImage('assets/images/yusuf.png'),
              ),
            ),
            SizedBox(width: 15.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dibuat oleh",
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                Text(
                  "Yusuf Ardiansyah",
                  style: TextStyle(
                    color: const Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 5.w),
    child: Text(
      t,
      style: TextStyle(
        color: Colors.amberAccent,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildMenuItem(
    BuildContext c,
    String l,
    String t,
    String s,
    Color col,
    String type,
  ) => Card(
    color: const Color(0xFF1A1A1A),
    margin: EdgeInsets.only(bottom: 10.h),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: col.withOpacity(0.2),
        child: Text(l, style: TextStyle(fontSize: 16.sp)),
      ),
      title: Text(
        t,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
      ),
      subtitle: Text(s, style: TextStyle(fontSize: 12.sp)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 15.sp,
        color: Colors.white24,
      ),
      onTap: () async {
        if (type == "sholat" || type == "qiblat") {
          if (await Permission.location.request().isGranted) {
            if (type == "sholat") {
              Navigator.push(
                c,
                MaterialPageRoute(builder: (c) => const JadwalSholatPage()),
              );
            } else {
              Navigator.push(
                c,
                MaterialPageRoute(builder: (c) => const QiblahPage()),
              );
            }
          } else {
            ScaffoldMessenger.of(c).showSnackBar(
              const SnackBar(content: Text("Izin lokasi diperlukan")),
            );
          }
        } else if (type == "weton") {
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const WetonJodohPage()),
          );
        } else if (type == "selamatan") {
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const SelamatanPage()),
          );
        } else if (type == "asmaul_husna") {
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const AsmaulHusnaPage()),
          );
        } else if (type == "tasbih") {
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const TasbihPage()),
          );
        } else if (type == "doa") {
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const DoaListPage()),
          );
        } else {
          Navigator.push(
            c,
            MaterialPageRoute(
              builder: (c) => SurahDetailPage(fileName: type, title: t),
            ),
          );
        }
      },
    ),
  );
}

// ==========================================
// HALAMAN: CEK WETON JODOH (PREMIUM EDITION)
// ==========================================
class WetonJodohPage extends StatefulWidget {
  const WetonJodohPage({super.key});

  @override
  State<WetonJodohPage> createState() => _WetonJodohPageState();
}

class _WetonJodohPageState extends State<WetonJodohPage> {
  DateTime? tglPria;
  DateTime? tglWanita;
  Map<String, dynamic>? hasilRamalan;

  final List<String> listHari = [
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
  ];
  final List<String> listPasaran = ['Wage', 'Kliwon', 'Legi', 'Pahing', 'Pon'];

  final Map<String, int> neptuHari = {
    'Minggu': 5,
    'Senin': 4,
    'Selasa': 3,
    'Rabu': 7,
    'Kamis': 8,
    'Jumat': 6,
    'Sabtu': 9,
  };
  final Map<String, int> neptuPasaran = {
    'Legi': 5,
    'Pahing': 9,
    'Pon': 7,
    'Wage': 4,
    'Kliwon': 8,
  };

  final List<Map<String, String>> hasilJodoh = [
    {
      "title": "PESTHI (8/0) - Kedamaian Sejati",
      "desc":
          "Dalam perhitungan Primbon Jawa, jatuh pada hitungan PESTHI adalah sebuah anugerah agung dari Sang Pencipta. Rumah tangga yang dibangun di atas fondasi ini dijanjikan akan berjalan dengan sangat rukun, tenteram, dan damai sejahtera hingga masa tua memisahkan.\n\nKehidupan pernikahan kalian ibarat air sungai yang mengalir tenang. Meskipun sesekali ada kerikil masalah atau perbedaan pendapat, hal tersebut sama sekali tidak akan mampu merusak keharmonisan keluarga. Kalian memiliki ikatan batin yang sangat kuat, saling mengerti tanpa harus banyak bicara, dan memiliki cinta yang mengakar dalam.\n\nSecara ekonomi dan sosial, kehidupan kalian akan stabil. Rezeki selalu ada dan cukup untuk memenuhi kebutuhan. Kunci utama dari langgengnya hubungan ini adalah rasa syukur yang tak pernah putus atas ketenangan yang jarang didapatkan oleh pasangan lain.",
    },
    {
      "title": "PEGAT (1) - Ujian Kesabaran",
      "desc":
          "Hitungan PEGAT (berarti putus/berpisah) menandakan adanya potensi rintangan yang cukup berat dalam perjalanan bahtera rumah tangga kalian. Sering kali, badai ujian ini dipicu oleh masalah ekonomi, perbedaan prinsip yang tajam, atau bahkan campur tangan pihak luar seperti keluarga besar maupun lingkungan pertemanan.\n\nNamun, ini bukanlah vonis mutlak, melainkan sebuah peringatan kewaspadaan. Pasangan dengan hitungan ini dituntut untuk memiliki kesabaran ekstra tinggi, kompromi tingkat dewa, dan kedewasaan emosional. Jika ego masing-masing selalu dikedepankan, maka potensi perpisahan akan sangat besar.\n\nUntuk menetralisir energi ini, disarankan untuk selalu mendekatkan diri kepada Tuhan, memperbanyak sedekah, dan saling menurunkan gengsi saat terjadi pertengkaran. Komunikasi yang terbuka dan niat untuk saling mempertahankan adalah kunci penawar paling ampuh.",
    },
    {
      "title": "RATU (2) - Mahkota Kehormatan",
      "desc":
          "Pasangan yang jatuh pada hitungan RATU bagaikan raja dan permaisuri yang bertahta. Pernikahan kalian akan memancarkan aura wibawa dan karisma yang membuat kalian sangat disegani, dihormati, serta sering dijadikan teladan oleh tetangga dan lingkungan sekitar.\n\nKehidupan rumah tangga ini dijanjikan akan dikaruniai rezeki yang mengalir deras dari berbagai pintu, kebahagiaan yang melimpah, dan kemuliaan derajat. Kalian akan sangat jarang tertimpa musibah besar atau kesulitan finansial yang berarti, karena energi alam semesta sangat mendukung persatuan kalian.\n\nKalian adalah pasangan yang sangat beruntung. Namun, ingatlah bahwa mahkota Ratu juga membawa tanggung jawab. Jangan sampai kemuliaan ini membuat kalian sombong. Tetaplah dermawan dan merendah agar rezeki dan keharmonisan tersebut tetap kekal abadi.",
    },
    {
      "title": "JODOH (3) - Takdir Semesta",
      "desc":
          "Ini adalah tingkat kecocokan yang paling diidamkan. Jatuh pada hitungan JODOH berarti kalian memang ditakdirkan bersama oleh semesta, ibarat gembok yang telah menemukan kuncinya. Chemistry di antara kalian mengalir begitu natural tanpa perlu dipaksakan.\n\nKalian berdua memiliki kapasitas yang luar biasa untuk saling mentolerir, menerima kekurangan masa lalu, dan melengkapi satu sama lain. Rumah tangga ini akan diwarnai dengan romansa yang tak lekang oleh waktu, kerukunan, kedamaian, dan kasih sayang yang tulus hingga akhir hayat.\n\nKetika ada masalah, kalian selalu bisa menemukan jalan tengah dengan mudah. Komunikasi batin kalian sangat selaras. Jaga terus kemesraan dan komunikasi yang hangat ini, karena fondasi JODOH adalah anugerah terbesar dalam sebuah ikatan pernikahan.",
    },
    {
      "title": "TOPO (4) - Berakit-rakit ke Hulu",
      "desc":
          "Filosofi TOPO (bertapa) menggambarkan sebuah rumah tangga yang harus melewati kawah candradimuka di awal pernikahannya. Di tahun-tahun pertama, kalian mungkin akan dihadapkan pada berbagai kesulitan, baik dari segi finansial yang serba pas-pasan, maupun gesekan sifat karena proses penyesuaian (babat alas).\n\nMasa-masa awal ini akan penuh dengan air mata, keringat, dan perjuangan batin. Namun, jangan pernah menyerah! Ujian ini sebenarnya adalah cara alam semesta membentuk mental dan karakter kalian berdua agar menjadi sekuat baja.\n\nJika kalian berdua mampu bersabar, saling berpegangan tangan, dan tidak lari dari masalah, maka di pertengahan hingga akhir usia pernikahan, kalian akan menuai kesuksesan yang sangat luar biasa. Kalian akan membangun 'kerajaan' kalian sendiri dari nol, mencapai kekayaan, and kebahagiaan paripurna di masa tua.",
    },
    {
      "title": "TINARI (5) - Sang Penarik Rezeki",
      "desc":
          "Pasangan dengan hitungan TINARI adalah mereka yang senantiasa dinaungi oleh bintang keberuntungan abadi. Kehidupan rumah tangga kalian akan terasa jauh lebih ringan karena kalian akan sangat mudah dalam mencari jalan rezeki.\n\nKalian akan jarang sekali mengalami kekurangan finansial yang mencekik. Ke mana pun kalian melangkah atau usaha apa pun yang kalian bangun bersama, pintu kemudahan akan selalu terbuka. Hidup kalian penuh dengan anugerah, keceriaan, dan rasa syukur yang berlimpah. \n\nSelain itu, rumah tangga Tinari sering kali menjadi tempat singgah yang nyaman bagi sanak saudara, karena kehangatan dan kemurahan hati kalian. Sangat cocok bagi kalian untuk membangun bisnis atau usaha bersama, karena perpaduan energi kalian adalah magnet rezeki yang sangat kuat.",
    },
    {
      "title": "PADU (6) - Benci tapi Rindu",
      "desc":
          "Hitungan PADU (bertengkar) mengisyaratkan sebuah rumah tangga yang akan sangat bising. Tiada hari tanpa cekcok, perdebatan, dan silang pendapat. Anehnya, pertengkaran ini sering kali hanya dipicu oleh masalah-masalah sepele atau sekadar adu gengsi dan ego masing-masing.\n\nBagi orang luar yang melihat, kalian mungkin terlihat seperti musuh yang terpaksa tinggal serumah. Namun inilah letak keunikannya: sekeras apa pun piring berterbangan atau pintu dibanting, kalian memiliki ikatan batin (chemistry) yang sangat aneh dan tak bisa dipisahkan. Kalian sering bertengkar, namun sangat jauh dari kata perceraian.\n\nKalian ibarat Tom & Jerry; tidak bisa hidup damai jika bersama, tapi akan saling mencari dan merindu gila-gilaan jika dipisahkan. Saran terbaik: belajarlah mengelola emosi dan ubah energi amarah menjadi candaan, agar rumah tangga tetap seru tanpa melukai hati.",
    },
    {
      "title": "SUJANAN (7) - Badai Api Cemburu",
      "desc":
          "Jatuh pada hitungan SUJANAN (curiga/cemburu) adalah sebuah peringatan keras. Rumah tangga ini sangat rawan didera cobaan emosional yang berat, terutama yang berkaitan dengan kepercayaan. Ada potensi besar munculnya kecemburuan buta, ketidaksetiaan, atau godaan kuat dari pihak ketiga.\n\nRumah tangga ini akan sering diuji oleh kecurigaan, baik yang beralasan maupun yang hanya sekadar prasangka. Ujian kesetiaan akan datang silih berganti. Oleh karena itu, hubungan ini menuntut kejujuran absolut dan transparansi total. Jangan pernah ada rahasia, baik urusan keuangan maupun urusan komunikasi di ponsel.\n\nUntuk menghindari kehancuran, kalian membutuhkan fondasi iman yang ekstra kuat. Perbanyaklah ibadah bersama, saling menguatkan komitmen setiap hari, dan segera potong rantai pergaulan yang berpotensi merusak rumah tangga. Kesetiaan adalah harga mati untuk hitungan ini.",
    },
  ];

  Map<String, dynamic> hitungWeton(DateTime date) {
    int diff = date.difference(DateTime(1970, 1, 1)).inDays;
    String hari = listHari[(diff % 7 + 7) % 7];
    String pasaran = listPasaran[(diff % 5 + 5) % 5];
    int neptu = neptuHari[hari]! + neptuPasaran[pasaran]!;
    return {'hari': hari, 'pasaran': pasaran, 'neptu': neptu};
  }

  void _kalkulasiJodoh() {
    if (tglPria == null || tglWanita == null) return;

    var wetonPria = hitungWeton(tglPria!);
    var wetonWanita = hitungWeton(tglWanita!);

    int totalNeptu = wetonPria['neptu'] + wetonWanita['neptu'];
    int sisa = totalNeptu % 8;

    setState(() {
      hasilRamalan = {
        'pria': wetonPria,
        'wanita': wetonWanita,
        'total': totalNeptu,
        'hasil': hasilJodoh[sisa],
      };
    });
  }

  String _formatDate(DateTime? d) =>
      d == null
          ? "Pilih Tanggal Lahir"
          : DateFormat('dd MMMM yyyy', 'id_ID').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "CEK WETON JODOH",
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: IconThemeData(color: const Color(0xFFFFD54F), size: 24.sp),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                Text(
                  "Masukkan Tanggal Lahir Pasangan:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD54F),
                    fontSize: 16.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),

                // Form Pria
                _buildDateSelector(
                  "Tanggal Lahir Pria",
                  tglPria,
                  (date) => setState(() => tglPria = date),
                  Icons.male,
                ),
                SizedBox(height: 15.h),

                // Form Wanita
                _buildDateSelector(
                  "Tanggal Lahir Wanita",
                  tglWanita,
                  (date) => setState(() => tglWanita = date),
                  Icons.female,
                ),
                SizedBox(height: 30.h),

                // Tombol Hitung
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00332B),
                    foregroundColor: const Color(0xFFFFD54F),
                    side: BorderSide(
                      color: const Color(0xFFFFD54F),
                      width: 1.5.w,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  ),
                  onPressed:
                      (tglPria != null && tglWanita != null)
                          ? _kalkulasiJodoh
                          : null,
                  child: Text(
                    "CEK KECOCOKAN",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                SizedBox(height: 30.h),

                // Hasil Ramalan
                if (hasilRamalan != null) ...[
                  const Divider(color: Colors.white24),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withOpacity(0.05),
                          blurRadius: 10.r,
                          spreadRadius: 2.r,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "HASIL PERHITUNGAN NEPTU",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNeptuBox(
                              "PRIA",
                              hasilRamalan!['pria']['hari'],
                              hasilRamalan!['pria']['pasaran'],
                              hasilRamalan!['pria']['neptu'],
                            ),
                            Text(
                              "+",
                              style: TextStyle(
                                color: const Color(0xFFFFD54F),
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildNeptuBox(
                              "WANITA",
                              hasilRamalan!['wanita']['hari'],
                              hasilRamalan!['wanita']['pasaran'],
                              hasilRamalan!['wanita']['neptu'],
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "TOTAL NEPTU: ${hasilRamalan!['total']}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00332B).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  hasilRamalan!['hasil']['title'],
                                  style: TextStyle(
                                    color: const Color(0xFFFFD54F),
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 15.h),
                              Text(
                                hasilRamalan!['hasil']['desc'],
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime? current,
    Function(DateTime) onSelect,
    IconData icon,
  ) {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
        side: BorderSide(color: const Color(0xFFFFD54F).withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFFD54F), size: 24.sp),
        title: Text(
          label,
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        subtitle: Text(
          _formatDate(current),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        trailing: Icon(
          Icons.calendar_today,
          color: const Color(0xFFFFD54F),
          size: 18.sp,
        ),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: current ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFFFFD54F),
                    onPrimary: Color(0xFF00332B),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) onSelect(picked);
        },
      ),
    );
  }

  Widget _buildNeptuBox(String label, String hari, String pasaran, int neptu) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          "$hari $pasaran",
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
        Text(
          "($neptu)",
          style: TextStyle(color: Colors.white54, fontSize: 14.sp),
        ),
      ],
    );
  }
}

// ==========================================
// HALAMAN: HITUNG SELAMATAN (DENGAN PASARAN JAWA)
// ==========================================
class SelamatanPage extends StatefulWidget {
  const SelamatanPage({super.key});

  @override
  State<SelamatanPage> createState() => _SelamatanPageState();
}

class _SelamatanPageState extends State<SelamatanPage> {
  DateTime selectedDate = DateTime.now();

  String _formatDate(DateTime d) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);

  String _getPasaranJawa(DateTime date) {
    final List<String> listPasaran = [
      'Wage',
      'Kliwon',
      'Legi',
      'Pahing',
      'Pon',
    ];
    int diff = date.difference(DateTime(1970, 1, 1)).inDays;
    return listPasaran[(diff % 5 + 5) % 5];
  }

  String _formatDateJawa(DateTime d) {
    String hariNasional = DateFormat('EEEE', 'id_ID').format(d);
    String pasaran = _getPasaranJawa(d);
    String tanggal = DateFormat('d MMMM yyyy', 'id_ID').format(d);
    return "$hariNasional $pasaran, $tanggal";
  }

  Widget _buildRow(String title, int days) {
    DateTime res = selectedDate.add(Duration(days: days - 1));
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: EdgeInsets.only(bottom: 10.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
        side: BorderSide(color: const Color(0xFFFFD54F).withOpacity(0.3)),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        subtitle: Text(
          _formatDateJawa(res),
          style: TextStyle(color: Colors.white, fontSize: 13.sp),
        ),
        trailing: Icon(
          Icons.calendar_today,
          size: 18.sp,
          color: const Color(0xFFFFD54F),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "KALKULATOR SELAMATAN",
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: IconThemeData(color: const Color(0xFFFFD54F), size: 24.sp),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          Text(
            "Pilih Tanggal Meninggal (Geblag):",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: const Color(0xFFFFD54F),
            ),
          ),
          SizedBox(height: 15.h),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141414),
              foregroundColor: const Color(0xFFFFD54F),
              side: BorderSide(color: const Color(0xFFFFD54F), width: 1.5.w),
              padding: EdgeInsets.symmetric(vertical: 15.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
            ),
            icon: Icon(Icons.edit_calendar, size: 24.sp),
            label: Text(
              _formatDateJawa(selectedDate),
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFFFD54F),
                        onPrimary: Color(0xFF00332B),
                        onSurface: Colors.white,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFFD54F),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          SizedBox(height: 25.h),
          _buildRow("Geblag (Hari H)", 1),
          _buildRow("3 Hari", 3),
          _buildRow("7 Hari", 7),
          _buildRow("40 Hari", 40),
          _buildRow("100 Hari", 100),
          _buildRow("Mendak Pisan (1 Tahun Jawa)", 354),
          _buildRow("Mendak Pindo (2 Tahun Jawa)", 708),
          _buildRow("Nyewu (1000 Hari)", 1000),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN: JADWAL SHOLAT (JAM REALTIME)
// ==========================================
class JadwalSholatPage extends StatefulWidget {
  const JadwalSholatPage({super.key});

  @override
  State<JadwalSholatPage> createState() => _JadwalSholatPageState();
}

class _JadwalSholatPageState extends State<JadwalSholatPage> {
  PrayerTimes? prayerTimes;
  String alamatLengkap = "Mencari lokasi...";
  String koordinatStr = "";
  String _timeString = "";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timeString = DateFormat('HH:mm:ss').format(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
    _loadSavedLocation();
    _initJadwal();
  }

  void _updateTime() {
    setState(() => _timeString = DateFormat('HH:mm:ss').format(DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _kontakYusuf() async {
    final Uri url = Uri.parse(
      "https://wa.me/6282139743432?text=Assalamualaikum%20Mas%20Yusuf",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
      () =>
          alamatLengkap =
              prefs.getString('saved_address') ?? "Mencari lokasi...",
    );
  }

  _initJadwal() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      final myCoords = Coordinates(pos.latitude, pos.longitude);
      final params = CalculationMethod.singapore.getParameters();
      params.madhab = Madhab.shafi;
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      Placemark place = placemarks[0];
      String finalAlamat =
          "${place.subLocality}, Kec. ${place.locality}, ${place.subAdministrativeArea}";
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_address', finalAlamat);

      setState(() {
        prayerTimes = PrayerTimes.today(myCoords, params);
        alamatLengkap = finalAlamat;
        koordinatStr =
            "Lat: ${pos.latitude.toStringAsFixed(3)}, Lon: ${pos.longitude.toStringAsFixed(3)}";
      });

      NotificationService.scheduleAdzan(101, "Subuh", prayerTimes!.fajr);
      NotificationService.scheduleAdzan(102, "Dzuhur", prayerTimes!.dhuhr);
      NotificationService.scheduleAdzan(103, "Ashar", prayerTimes!.asr);
      NotificationService.scheduleAdzan(104, "Maghrib", prayerTimes!.maghrib);
      NotificationService.scheduleAdzan(105, "Isya", prayerTimes!.isha);
    } catch (e) {
      debugPrint("Gagal memuat lokasi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "JADWAL SHOLAT",
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: IconThemeData(color: const Color(0xFFFFD54F), size: 24.sp),
      ),
      body:
          prayerTimes == null
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
              )
              : Column(
                children: [
                  // BOX JAM REALTIME (EMAS & HIJAU)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(20.w),
                    padding: EdgeInsets.symmetric(vertical: 25.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004D40), // Hijau khas masjid
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10.r,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "WAKTU SAAT INI",
                          style: TextStyle(
                            color: const Color(0xFFFFD54F),
                            fontSize: 14.sp,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          _timeString, // Jam yang jalan detiknya
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 45.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace', // Gaya digital classic
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(DateTime.now()),
                          style: TextStyle(
                            color: const Color(0xFFFFD54F),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // LOKASI
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: const Color(0xFFFFD54F),
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            alamatLengkap,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  // LIST JADWAL SHOLAT
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      children: [
                        _buildTimeCard("Subuh", prayerTimes!.fajr),
                        _buildTimeCard("Terbit", prayerTimes!.sunrise),
                        _buildTimeCard("Dzuhur", prayerTimes!.dhuhr),
                        _buildTimeCard("Ashar", prayerTimes!.asr),
                        _buildTimeCard("Maghrib", prayerTimes!.maghrib),
                        _buildTimeCard("Isya", prayerTimes!.isha),
                      ],
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: _buildBottomBranding(),
    );
  }

  Widget _buildBottomBranding() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _kontakYusuf,
      child: Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: const Color(0xFF00332B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 22.r,
                backgroundImage: const AssetImage('assets/images/yusuf.png'),
              ),
            ),
            SizedBox(width: 15.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dibuat oleh",
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                Text(
                  "Yusuf Ardiansyah",
                  style: TextStyle(
                    color: const Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String label, DateTime time) => Card(
    color: const Color(0xFF1A1A1A),
    margin: EdgeInsets.only(bottom: 10.h),
    child: ListTile(
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
      ),
      trailing: Text(
        DateFormat.Hm().format(time.toLocal()),
        style: TextStyle(
          color: const Color(0xFFFFD54F),
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// ==========================================
// HALAMAN: ARAH KIBLAT (ANIMASI PULSE)
// ==========================================
class QiblahPage extends StatefulWidget {
  const QiblahPage({super.key});

  @override
  State<QiblahPage> createState() => _QiblahPageState();
}

class _QiblahPageState extends State<QiblahPage>
    with SingleTickerProviderStateMixin {
  bool _s = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _kontakYusuf() async {
    final Uri url = Uri.parse(
      "https://wa.me/6282139743432?text=Assalamualaikum%20Mas%20Yusuf",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ARAH KIBLAT",
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: IconThemeData(color: const Color(0xFFFFD54F), size: 24.sp),
      ),
      body: StreamBuilder(
        stream: FlutterQiblah.qiblahStream,
        builder: (c, AsyncSnapshot<QiblahDirection> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
            );
          }
          final q = snapshot.data!;
          double sel = (q.direction - q.qiblah).abs();
          if (sel < 2.0) {
            if (!_s) {
              HapticFeedback.vibrate();
              _s = true;
            }
          } else {
            _s = false;
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(25.r),
                    border: Border.all(
                      color:
                          sel < 2.0
                              ? Colors.greenAccent
                              : const Color(0xFFFFD54F).withOpacity(0.3),
                    ),
                  ),
                  child: CustomPaint(
                    painter: AbstractPlatinumPainter(
                      color: const Color(0xFFFFD54F).withOpacity(0.5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      child: Column(
                        children: [
                          Text(
                            "${q.direction.toStringAsFixed(0)}°",
                            style: TextStyle(
                              fontSize: 45.sp,
                              fontWeight: FontWeight.bold,
                              color:
                                  sel < 2.0
                                      ? Colors.greenAccent
                                      : const Color(0xFFFFD54F),
                            ),
                          ),
                          SizedBox(height: 15.h),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 280.w,
                                height: 280.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFD54F,
                                    ).withOpacity(0.4),
                                    width: 2.w,
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: (q.direction * (math.pi / 180) * -1),
                                child: Opacity(
                                  opacity: 0.4,
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    child: Image.asset(
                                      'assets/images/compass.png',
                                      width: 220.w,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: (q.qiblah * (math.pi / 180) * -1),
                                child: SizedBox(
                                  width: 280.w,
                                  height: 280.w,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 10.h),
                                      child: ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: Image.asset(
                                          'assets/images/kabah.png',
                                          width: 55.w,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            sel < 2.0
                                ? "POSISI KIBLAT PAS!"
                                : "PUTAR HP PERLAHAN",
                            style: TextStyle(
                              color:
                                  sel < 2.0
                                      ? Colors.greenAccent
                                      : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                _buildInfoTile("Lokasi", "Otomatis (GPS)", Icons.my_location),
                _buildInfoTile(
                  "Derajat Kiblat",
                  "${q.qiblah.toStringAsFixed(1)}°",
                  Icons.shutter_speed,
                ),
                _buildInfoTile(
                  "Status Sensor",
                  "Akurat",
                  Icons.check_circle_outline,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBranding(),
    );
  }

  Widget _buildBottomBranding() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _kontakYusuf,
      child: Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: const Color(0xFF00332B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 22.r,
                backgroundImage: const AssetImage('assets/images/yusuf.png'),
              ),
            ),
            SizedBox(width: 15.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dibuat oleh",
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                Text(
                  "Yusuf Ardiansyah",
                  style: TextStyle(
                    color: const Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String t, String v, IconData i) => Card(
    color: const Color(0xFF1A1A1A),
    margin: EdgeInsets.only(bottom: 8.h),
    child: ListTile(
      leading: Icon(i, color: const Color(0xFFFFD54F), size: 20.sp),
      title: Text(t, style: TextStyle(fontSize: 13.sp, color: Colors.white70)),
      trailing: Text(
        v,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13.sp,
        ),
      ),
    ),
  );
}

// ==========================================
// HALAMAN: DETAIL SURAH (YASIN/WAQIAH)
// ==========================================
class SurahDetailPage extends StatefulWidget {
  final String fileName, title;

  const SurahDetailPage({
    super.key,
    required this.fileName,
    required this.title,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  final AudioPlayer player = AudioPlayer();
  final ItemScrollController itemScrollController = ItemScrollController();
  List d = [];
  bool isLoading = true;
  int? currentPlayingIndex;

  @override
  void initState() {
    super.initState();
    load();
    player.onPlayerComplete.listen((e) {
      if (currentPlayingIndex != null && currentPlayingIndex! < d.length - 1) {
        putarAudio(currentPlayingIndex! + 1);
      }
    });
  }

  load() async {
    String r = await rootBundle.loadString(
      'assets/data/${widget.fileName}.json',
    );
    setState(() {
      d = json.decode(r);
      isLoading = false;
    });
  }

  String formatTeks(String t) {
    String b = t.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    if (b.isEmpty) return "";
    return b[0].toUpperCase() + b.substring(1);
  }

  Future<void> putarAudio(int i) async {
    if (currentPlayingIndex == i && player.state == PlayerState.playing) {
      await player.pause();
    } else {
      setState(() => currentPlayingIndex = i);
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
          index: i,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
      await player.stop();
      await player.play(
        AssetSource('audio/${widget.fileName}/${d[i]['nomor']}.mp3'),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTahlil = widget.title.toLowerCase().contains("tahlil");
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        iconTheme: IconThemeData(color: const Color(0xFFFFD54F), size: 24.sp),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
              )
              : ScrollablePositionedList.builder(
                itemCount: d.length,
                itemScrollController: itemScrollController,
                itemBuilder: (c, i) {
                  bool isP =
                      currentPlayingIndex == i &&
                      player.state == PlayerState.playing;
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isP
                              ? const Color(0xFF00241E)
                              : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isP ? const Color(0xFFFFD54F) : Colors.white10,
                        width: 1.5.w,
                      ),
                    ),
                    child: CustomPaint(
                      painter: AbstractPlatinumPainter(
                        color: const Color(0xFFFFD54F).withOpacity(0.8),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(35.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              d[i]['ar'],
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: (isTahlil ? 24 : 28).sp,
                                fontWeight: FontWeight.bold,
                                height: 2,
                              ),
                            ),
                            SizedBox(height: 25.h),
                            if (!isTahlil)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${d[i]['tr']}",
                                          style: TextStyle(
                                            color: const Color(0xFFFFD54F),
                                            fontStyle: FontStyle.italic,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          formatTeks(d[i]['id']),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.sp,
                                            height: 1.5,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 15.w),
                                  GestureDetector(
                                    onTap: () => putarAudio(i),
                                    child: Icon(
                                      isP
                                          ? Icons.pause_circle
                                          : Icons.play_circle,
                                      color: const Color(0xFF00BFA5),
                                      size: 48.sp,
                                    ),
                                  ),
                                ],
                              ),
                            if (isTahlil)
                              Text(
                                formatTeks(d[i]['id']),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFFFD54F),
                                  fontSize: 16.sp,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

// ==========================================
// HALAMAN: KUMPULAN DOA
// ==========================================
class DoaListPage extends StatefulWidget {
  const DoaListPage({super.key});

  @override
  State<DoaListPage> createState() => _DoaListPageState();
}

class _DoaListPageState extends State<DoaListPage> {
  List d = [];
  bool l = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  load() async {
    String r = await rootBundle.loadString('assets/data/doa.json');
    setState(() {
      d = json.decode(r);
      l = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "KUMPULAN DOA",
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: IconThemeData(color: const Color(0xFFFFD54F), size: 24.sp),
      ),
      body:
          l
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
              )
              : ListView.builder(
                itemCount: d.length,
                itemBuilder:
                    (c, i) => Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withOpacity(0.3),
                        ),
                      ),
                      child: CustomPaint(
                        painter: AbstractPlatinumPainter(
                          color: const Color(0xFFFFD54F).withOpacity(0.5),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(25.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                d[i]['judul'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                              Divider(color: Colors.white10, height: 30.h),
                              Text(
                                d[i]['ar'],
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  height: 1.8,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                d[i]['id'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFFFD54F),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
    );
  }
}

// ==========================================
// HALAMAN: TASBIH DIGITAL (RIPPLE EFFECT)
// ==========================================
class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  int _counter = 0;

  void _tambahHitungan() {
    setState(() => _counter++);
    if (_counter % 33 == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _resetHitungan() {
    setState(() => _counter = 0);
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          "TASBIH DIGITAL",
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: IconThemeData(color: const Color(0xFFFFD54F), size: 24.sp),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Subhanallah • Alhamdulillah • Allahuakbar",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 40.h),
            Container(
              width: 260.w,
              height: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF141414),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withOpacity(0.5),
                  width: 3.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withOpacity(0.05),
                    blurRadius: 30.r,
                    spreadRadius: 10.r,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$_counter",
                      style: TextStyle(
                        fontSize: 85.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),
                    Text(
                      "Hitungan",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 70.h),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _tambahHitungan,
                customBorder: const CircleBorder(),
                splashColor: const Color(0xFFFFD54F).withOpacity(0.5),
                highlightColor: const Color(0xFF00BFA5).withOpacity(0.3),
                child: Ink(
                  width: 110.w,
                  height: 110.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00332B),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFA5).withOpacity(0.2),
                        blurRadius: 20.r,
                        spreadRadius: 2.r,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 60.sp,
                    color: const Color(0xFFFFD54F),
                  ),
                ),
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              "TAP DI SINI",
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 50.h),
            IconButton(
              onPressed: _resetHitungan,
              icon: Icon(Icons.refresh, size: 32.sp),
              color: Colors.redAccent.withOpacity(0.8),
              tooltip: "Reset Hitungan",
            ),
            Text(
              "Reset",
              style: TextStyle(color: Colors.white38, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HALAMAN: ASMAUL HUSNA PREMIUM (VIA JSON)
// ==========================================
class AsmaulHusnaPage extends StatefulWidget {
  const AsmaulHusnaPage({super.key});

  @override
  State<AsmaulHusnaPage> createState() => _AsmaulHusnaPageState();
}

class _AsmaulHusnaPageState extends State<AsmaulHusnaPage> {
  List d = [];
  bool l = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  load() async {
    String r = await rootBundle.loadString('assets/data/asmaul_husna.json');
    setState(() {
      d = json.decode(r);
      l = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          "ASMAUL HUSNA",
          style: TextStyle(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: IconThemeData(color: const Color(0xFFFFD54F), size: 24.sp),
      ),
      body:
          l
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
              )
              : GridView.builder(
                padding: EdgeInsets.all(15.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15.w,
                  mainAxisSpacing: 15.h,
                  childAspectRatio: 0.85,
                ),
                itemCount: d.length,
                itemBuilder: (context, index) {
                  final item = d[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withOpacity(0.3),
                      ),
                    ),
                    child: CustomPaint(
                      painter: AbstractPlatinumPainter(
                        color: const Color(0xFFFFD54F).withOpacity(0.5),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00332B),
                                border: Border.all(
                                  color: const Color(0xFFFFD54F),
                                ),
                              ),
                              child: Text(
                                item["no"],
                                style: TextStyle(
                                  color: const Color(0xFFFFD54F),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item["arab"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              item["latin"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFFFD54F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              item["arti"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

// ==========================================
// WIDGET: PLATINUM BORDER PAINTER
// ==========================================
class AbstractPlatinumPainter extends CustomPainter {
  final Color color;

  AbstractPlatinumPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    void drawCorner(double x, double y, bool isRight, bool isBottom) {
      double dX = isRight ? -35 : 35;
      double dY = isBottom ? -35 : 35;
      double sX = isRight ? -5 : 5;
      double sY = isBottom ? -5 : 5;
      double lX = isRight ? -20 : 20;
      double lY = isBottom ? -20 : 20;
      Path p1 = Path();
      p1.moveTo(x + dX, y);
      p1.lineTo(x, y);
      p1.lineTo(x, y + dY);
      canvas.drawPath(p1, paint);
      Path p2 = Path();
      p2.moveTo(x + lX, y + sY);
      p2.lineTo(x + sX, y + sY);
      p2.lineTo(x + sX, y + lY);
      canvas.drawPath(p2, paint);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x + (sX * 2.5), y + (sY * 2.5)),
          width: 4,
          height: 4,
        ),
        paint..style = PaintingStyle.fill,
      );
      paint.style = PaintingStyle.stroke;
    }

    drawCorner(10, 10, false, false);
    drawCorner(size.width - 10, 10, true, false);
    drawCorner(10, size.height - 10, false, true);
    drawCorner(size.width - 10, size.height - 10, true, true);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
