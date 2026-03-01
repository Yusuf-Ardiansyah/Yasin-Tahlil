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

// IMPORT PENERJEMAH BAHASA INDONESIA UNTUK KALENDER
import 'package:flutter_localizations/flutter_localizations.dart';

// ==========================================
// IMPORT FIREBASE, CLOUD FIRESTORE & GOOGLE LOGIN
// ==========================================
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Pastikan Flutter Binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase (Wajib nyala duluan sebelum aplikasi jalan)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Inisialisasi pengaturan format tanggal Indonesia & Notifikasi Adzan
  await initializeDateFormatting('id_ID', null);
  await NotificationService.init();

  // 4. Jalankan Aplikasi
  runApp(const AlWaqiahApp());
}

// ==========================================
// SERVICE: DATABASE FIREBASE (HADLOROH CLOUD)
// ==========================================
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // Fungsi simpan nama Almarhum
  Future<void> addAlmarhum(String nama, String binBinti) async {
    if (uid != null) {
      await _db.collection('users').doc(uid).collection('hadloroh').add({
        'nama': nama,
        'bin_binti': binBinti,
        'timestamp': FieldValue.serverTimestamp(),
        'order': DateTime.now().millisecondsSinceEpoch, // BIAR BISA DIURUTKAN
      });
    }
  }
}

// ==========================================
// SERVICE: NOTIFIKASI ADZAN (UPDATED VERSI 20+)
// ==========================================
class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      settings: const InitializationSettings(android: android),
    );
  }

  static Future scheduleAdzan(int id, String title, DateTime time) async {
    if (time.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id: id,
      title: 'Waktunya Sholat $title',
      body: 'Mari menunaikan ibadah sholat $title tepat waktu.',
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'adzan_channel_id',
          'Notifikasi Adzan',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(
            'adzan',
          ), // Pastikan file adzan.mp3 ada di res/raw
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('id', 'ID')],
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            useMaterial3: true,
          ),
          home: UpgradeAlert(
            dialogStyle: UpgradeDialogStyle.cupertino,
            showIgnore: false,
            showLater: false,
            onUpdate: () {
              executeUpdate();
              return false;
            },
            upgrader: Upgrader(
              messages: _CustomUpgraderMessages(),
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
// HALAMAN: MENU UTAMA (DENGAN LOGIN GOOGLE)
// ==========================================
class MenuUtama extends StatefulWidget {
  const MenuUtama({super.key});

  @override
  State<MenuUtama> createState() => _MenuUtamaState();
}

class _MenuUtamaState extends State<MenuUtama> {
  User? _currentUser;
  bool _isGoogleInit = false;

  @override
  void initState() {
    super.initState();
    // Cek otomatis apakah user sudah login sebelumnya
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  // --- FUNGSI LOGIN GOOGLE SULTAN (STANDAR TERBARU v7.2.0+) ---
  Future<void> _signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId:
        '46216843544-8mvgrmgbmcogehsno469bgj3ovugh7bq.apps.googleusercontent.com',
      );
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final String? idToken = googleUser.authentication.idToken;

      final authClient = googleUser.authorizationClient;
      var authorization = await authClient.authorizationForScopes([
        'email',
        'profile',
      ]);
      authorization ??= await authClient.authorizeScopes(['email', 'profile']);

      final String? accessToken = authorization?.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      setState(() {
        _currentUser = userCredential.user;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Alhamdulillah, selamat datang ${_currentUser?.displayName}!",
          ),
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
    } catch (e) {
      debugPrint("Error Login: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal login, periksa koneksi atau SHA-1."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> _signOut() async {
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
    setState(() {
      _currentUser = null;
    });
  }

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
        actions: [
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: _signOut,
              tooltip: "Keluar Akun",
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(15.w),
        children: [
          // --- WIDGET PROFIL PENGGUNA ---
          _buildGoogleLoginCard(),

          // --- WIDGET TOTAL DOA (FITUR BARU) ---
          if (_currentUser != null)
            StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser!.uid)
                  .collection('hadloroh')
                  .snapshots(),
              builder: (context, snapshot) {
                int total = snapshot.hasData ? snapshot.data!.docs.length : 0;

                return Container(
                  margin: EdgeInsets.only(top: 15.h, bottom: 5.h),
                  padding: EdgeInsets.all(15.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00332B).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(
                      color: const Color(0xFF00BFA5).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: const Color(0xFFFFD54F),
                        size: 24.sp,
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Text(
                          "Alhamdulillah, kamu sudah mengirim doa untuk $total almarhum keluarga.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          SizedBox(height: 15.h),

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
            "👥",
            "Daftar Hadloroh",
            "Kirim Doa (Tersimpan di Cloud)",
            Colors.blueGrey,
            "hadloroh",
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
      bottomNavigationBar: _buildBottomBranding(),
    );
  }

  Widget _buildGoogleLoginCard() {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.3)),
      ),
      child:
      _currentUser == null
          ? Row(
        children: [
          CircleAvatar(
            radius: 25.r,
            backgroundColor: Colors.white10,
            child: Icon(
              Icons.person_outline,
              color: Colors.white54,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Simpan Ibadah ke Cloud",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  "Login untuk simpan Hadloroh & Tasbih",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 15.w,
                vertical: 8.h,
              ),
            ),
            onPressed: _signInWithGoogle,
            child: Row(
              children: [
                Icon(
                  Icons.g_mobiledata,
                  color: Colors.red,
                  size: 24.sp,
                ),
                Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Row(
        children: [
          CircleAvatar(
            radius: 25.r,
            backgroundImage: NetworkImage(_currentUser!.photoURL ?? ''),
            backgroundColor: Colors.white10,
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.displayName ?? "Hamba Allah",
                  style: TextStyle(
                    color: const Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Status: Terhubung ke Cloud ☁️",
                  style: TextStyle(
                    color: const Color(0xFF00BFA5),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        } else if (type == "hadloroh") {
          if (FirebaseAuth.instance.currentUser == null) {
            ScaffoldMessenger.of(c).showSnackBar(
              const SnackBar(
                content: Text(
                  "Silakan login Google dulu ya untuk akses fitur ini!",
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else {
            Navigator.push(
              c,
              MaterialPageRoute(builder: (c) => const HadlorohPage()),
            );
          }
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
}

// ==========================================
// HALAMAN: DAFTAR HADLOROH (DENGAN DRAG AND DROP)
// ==========================================
class HadlorohPage extends StatefulWidget {
  const HadlorohPage({super.key});

  @override
  State<HadlorohPage> createState() => _HadlorohPageState();
}

class _HadlorohPageState extends State<HadlorohPage> {
  void _showAddNamaSheet(BuildContext context) {
    final TextEditingController _namaController = TextEditingController();
    final TextEditingController _binController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool _isSaving = false;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Tambah Nama Almarhum/ah",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD54F),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  TextField(
                    controller: _namaController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Nama Lengkap",
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: const Color(0xFFFFD54F),
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _binController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Bin / Binti (Opsional)",
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: Icon(
                        Icons.family_restroom,
                        color: const Color(0xFFFFD54F),
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00332B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: const BorderSide(color: Color(0xFFFFD54F)),
                        ),
                      ),
                      onPressed:
                      _isSaving
                          ? null
                          : () async {
                        setModalState(
                              () => _isSaving = true,
                        );

                        if (_namaController.text.isNotEmpty) {
                          await DatabaseService().addAlmarhum(
                            _namaController.text,
                            _binController.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Data berhasil disimpan di Cloud! ☁️",
                                ),
                                backgroundColor: Color(0xFF00BFA5),
                              ),
                            );
                          }
                        } else {
                          setModalState(() => _isSaving = false);
                        }
                      },
                      child:
                      _isSaving
                          ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          color: Color(0xFFFFD54F),
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        "Simpan ke Cloud ☁️",
                        style: TextStyle(
                          color: const Color(0xFFFFD54F),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DAFTAR HADLOROH",
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
      uid == null
          ? Center(
        child: Text(
          "Silakan login terlebih dahulu.",
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream:
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('hadloroh')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD54F),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Belum ada daftar nama.\nKlik tombol + di bawah untuk menambahkan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
            );
          }

          List<DocumentSnapshot> docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            int orderA =
            dataA.containsKey('order')
                ? dataA['order']
                : 999999999999;
            int orderB =
            dataB.containsKey('order')
                ? dataB['order']
                : 999999999999;
            return orderA.compareTo(orderB);
          });

          return ReorderableListView.builder(
            padding: EdgeInsets.all(15.w),
            itemCount: docs.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = docs.removeAt(oldIndex);
              docs.insert(newIndex, item);

              WriteBatch batch = FirebaseFirestore.instance.batch();
              for (int i = 0; i < docs.length; i++) {
                batch.update(docs[i].reference, {'order': i});
              }
              await batch.commit();
            },
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                key: ValueKey(docs[index].id),
                color: const Color(0xFF1A1A1A),
                margin: EdgeInsets.only(bottom: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  side: BorderSide(
                    color: const Color(0xFFFFD54F).withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 5.h,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00332B),
                    child: Icon(
                      Icons.person,
                      color: const Color(0xFFFFD54F),
                      size: 20.sp,
                    ),
                  ),
                  title: Text(
                    data['nama'] ?? "",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  subtitle: Text(
                    "Bin/Binti: ${data['bin_binti'] ?? '-'}",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20.sp,
                        ),
                        onPressed: () => docs[index].reference.delete(),
                        tooltip: "Hapus",
                      ),
                      Icon(
                        Icons.drag_indicator,
                        color: Colors.white54,
                        size: 24.sp,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFD54F),
        onPressed: () => _showAddNamaSheet(context),
        child: const Icon(Icons.add, color: Color(0xFF00332B)),
      ),
    );
  }
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
      "Dalam perhitungan Primbon Jawa, jatuh pada hitungan PESTHI adalah sebuah anugerah agung dari Sang Pencipta. Rumah tangga yang dibangun di atas fondasi ini dijanjikan akan berjalan dengan sangat rukun, tenteram, dan damai sejahtera hingga masa tua memisahkan.\n\nKehidupan pernikahan kalian ibarat air sungai yang mengalir tenang. Meskipun sesekali ada kerikil masalah atau perbedaan pendapat, hal tersebut sama sekali tidak akan mampu merusak keharmonisan keluarga. Kalian memiliki ikatan batin yang sangat kuat, saling mengerti tanpa harus banyak bicara, and memiliki cinta yang mengakar dalam.\n\nSecara ekonomi dan sosial, kehidupan kalian akan stabil. Rezeki selalu ada dan cukup untuk memenuhi kebutuhan. Kunci utama dari langgengnya hubungan ini adalah rasa syukur yang tak pernah putus atas ketenangan yang jarang didapatkan oleh pasangan lain.",
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
      "Filosofi TOPO (bertapa) menggambarkan sebuah rumah tangga yang harus melewati kawah candradimuka di awal pernikahannya. Di tahun-fallback-pertama, kalian mungkin akan dihadapkan pada berbagai kesulitan, baik dari segi finansial yang serba pas-pasan, maupun gesekan sifat karena proses penyesuaian (babat alas).\n\nMasa-masa awal ini akan penuh dengan air mata, keringat, dan perjuangan batin. Namun, jangan pernah menyerah! Ujian ini sebenarnya adalah cara alam semesta membentuk mental dan karakter kalian berdua agar menjadi sekuat baja.\n\nJika kalian berdua mampu bersabar, saling berpegangan tangan, dan tidak lari dari masalah, maka di pertengahan hingga akhir usia pernikahan, kalian akan menuai kesuksesan yang sangat luar biasa. Kalian akan membangun 'kerajaan' kalian sendiri dari nol, mencapai kekayaan, and kebahagiaan paripurna di masa tua.",
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
// HALAMAN: ARAH KIBLAT (ANIMASI PULSE & PREMIUM HAPTIC)
// ==========================================
class QiblahPage extends StatefulWidget {
  const QiblahPage({super.key});

  @override
  State<QiblahPage> createState() => _QiblahPageState();
}

class _QiblahPageState extends State<QiblahPage>
    with SingleTickerProviderStateMixin {
  bool _isAligned = false;
  double _lastVibratedDirection = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ), // Dipercepat dikit biar lebih responsif
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
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

          // Kalkulasi selisih derajat yang lebih akurat (handling 360 to 0)
          double diff = (q.direction - q.qiblah).abs();
          if (diff > 180) diff = 360 - diff;

          bool isCurrentlyAligned = diff < 2.0; // Toleransi 2 derajat

          // LOGIC HAPTIC SULTAN
          if (isCurrentlyAligned) {
            if (!_isAligned) {
              // Getaran berat beruntun saat pertama kali pas menghadap Kiblat
              HapticFeedback.heavyImpact();
              Future.delayed(
                const Duration(milliseconds: 150),
                    () => HapticFeedback.heavyImpact(),
              );
              Future.delayed(
                const Duration(milliseconds: 300),
                    () => HapticFeedback.heavyImpact(),
              );
              _isAligned = true;
            }
          } else {
            _isAligned = false;
            // Getaran halus 'tick' setiap diputar 3 derajat
            if ((q.direction - _lastVibratedDirection).abs() > 3.0) {
              HapticFeedback.selectionClick();
              _lastVibratedDirection = q.direction;
            }
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
                      isCurrentlyAligned
                          ? Colors.greenAccent
                          : const Color(0xFFFFD54F).withOpacity(0.3),
                      width:
                      isCurrentlyAligned
                          ? 3.w
                          : 1.w, // Border menebal pas sejajar
                    ),
                    boxShadow:
                    isCurrentlyAligned
                        ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.2),
                        blurRadius: 20.r,
                        spreadRadius: 5.r,
                      ),
                    ]
                        : [],
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
                              isCurrentlyAligned
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
                                        scale:
                                        isCurrentlyAligned
                                            ? _pulseAnimation
                                            : const AlwaysStoppedAnimation(
                                          1.0,
                                        ),
                                        child: Image.asset(
                                          'assets/images/kabah.png',
                                          width:
                                          isCurrentlyAligned ? 65.w : 55.w,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color:
                              isCurrentlyAligned
                                  ? Colors.green[900]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Text(
                              isCurrentlyAligned
                                  ? "✨ KIBLAT TERKUNCI ✨"
                                  : "PUTAR HP PERLAHAN",
                              style: TextStyle(
                                color:
                                isCurrentlyAligned
                                    ? Colors.greenAccent
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                letterSpacing: 1.5,
                              ),
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
// HALAMAN: DETAIL SURAH & TAHLIL (DENGAN INJEKSI HADLOROH CLOUD GLOWING)
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

class _SurahDetailPageState extends State<SurahDetailPage> with SingleTickerProviderStateMixin {
  final AudioPlayer player = AudioPlayer();
  final ItemScrollController itemScrollController = ItemScrollController();
  List d = [];
  bool isLoading = true;
  int? currentPlayingIndex;

  // Variabel untuk Hadloroh
  List<String> listNamaHadloroh = [];
  bool isFetchingHadloroh = false;

  // Controller untuk Glow Animasi
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    load();

    // Inisialisasi animasi GLOW SULTAN
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Kalau ini halaman Tahlil, tarik data nama dari Cloud!
    if (widget.title.toLowerCase().contains("tahlil")) {
      _tarikDataHadloroh();
    }

    player.onPlayerComplete.listen((e) {
      if (currentPlayingIndex != null && currentPlayingIndex! < d.length - 1) {
        putarAudio(currentPlayingIndex! + 1);
      }
    });
  }

  // --- FUNGSI TARIK NAMA HADLOROH DARI CLOUD ---
  Future<void> _tarikDataHadloroh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => isFetchingHadloroh = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('hadloroh')
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Ambil dan urutkan datanya
        var docs = snapshot.docs.toList();
        docs.sort((a, b) {
          int orderA = a.data().containsKey('order') ? a['order'] : 999999;
          int orderB = b.data().containsKey('order') ? b['order'] : 999999;
          return orderA.compareTo(orderB);
        });

        List<String> namaFormat = [];
        for (var doc in docs) {
          String nama = doc['nama'] ?? '';
          String bin = doc['bin_binti'] ?? '';
          if (bin.isNotEmpty) {
            namaFormat.add("$nama Bin/Binti $bin");
          } else {
            namaFormat.add(nama);
          }
        }
        setState(() => listNamaHadloroh = namaFormat);
      }
    } catch (e) {
      debugPrint("Gagal narik nama Hadloroh: $e");
    } finally {
      setState(() => isFetchingHadloroh = false);
    }
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
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTahlil = widget.title.toLowerCase().contains("tahlil");

    // Total item di list ditambah 1 kalau ada daftar Hadloroh
    int totalItem = d.length;
    bool hasHadloroh = isTahlil && listNamaHadloroh.isNotEmpty;
    if (hasHadloroh) totalItem += 1;

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
      body: isLoading || isFetchingHadloroh
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
      )
          : ScrollablePositionedList.builder(
        itemCount: totalItem,
        itemScrollController: itemScrollController,
        itemBuilder: (c, index) {
          // --- KARTU EKSKLUSIF HADLOROH GLOWING SULTAN ---
          if (hasHadloroh && index == 0) {
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF004D40), Color(0xFF00241E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25.r),
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withOpacity(0.8),
                      width: 1.5.w,
                    ),
                    // EFEK GLOW MENYALA (Emas Transparan)
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withOpacity(0.2 * _pulseAnimation.value),
                        blurRadius: 20.r * _pulseAnimation.value,
                        spreadRadius: 5.r * _pulseAnimation.value,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 5),
                        blurRadius: 10.r,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: AbstractPlatinumPainter(
                      color: const Color(0xFFFFD54F).withOpacity(0.4),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(25.w),
                      child: Column(
                        children: [
                          // Icon Berpijar
                          Icon(
                            Icons.auto_awesome,
                            color: const Color(0xFFFFD54F),
                            size: 30.sp * (0.8 + (_pulseAnimation.value * 0.2)), // Icon ikut berdenyut halus
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "KHUSUSON ILA RUHI :",
                            style: TextStyle(
                                color: const Color(0xFFFFD54F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 5.r, offset: const Offset(1, 1))
                                ]
                            ),
                          ),
                          Divider(
                              color: const Color(0xFFFFD54F).withOpacity(0.2),
                              thickness: 1,
                              height: 30.h
                          ),
                          // Daftar Nama Keluarga
                          ...listNamaHadloroh.map((nama) => Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Text(
                              "• $nama",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )),
                          SizedBox(height: 15.h),
                          // Footer Doa dengan Glow Hijau
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              "Laha / Lahumul Fatihah...",
                              style: TextStyle(
                                  color: const Color(0xFF00BFA5),
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          // Penyesuaian index untuk ayat (karena index 0 dipakai Hadloroh jika ada)
          int dataIndex = hasHadloroh ? index - 1 : index;
          bool isP =
              currentPlayingIndex == dataIndex &&
                  player.state == PlayerState.playing;

          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              color: isP
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
                      d[dataIndex]['ar'],
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
                                  "${d[dataIndex]['tr']}",
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
                                  formatTeks(d[dataIndex]['id']),
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
                            onTap: () => putarAudio(dataIndex),
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
                        formatTeks(d[dataIndex]['id']),
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
      body: l
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
      )
          : ListView.builder(
        itemCount: d.length,
        itemBuilder: (c, i) => Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
      body: l
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
    final paint = Paint()
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