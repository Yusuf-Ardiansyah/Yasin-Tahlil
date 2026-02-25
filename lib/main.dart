import 'dart:convert';
import 'dart:io';
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
import 'package:intl/date_symbol_data_local.dart'; // <-- IMPORT BAHASA INDONESIA
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(
    'id_ID',
    null,
  ); // <-- INISIALISASI LOKAL INDONESIA
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
// APP CORE & THEME + AUTO UPDATE CHROME
// ==========================================
class AlWaqiahApp extends StatelessWidget {
  const AlWaqiahApp({super.key});

  void executeUpdate() async {
    final Uri url = Uri.parse(
      'https://github.com/Yusuf-Ardiansyah/Yasin-Tahlil/releases/latest/download/app-arm64-v8a-release.apk',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        useMaterial3: true,
      ),
      home: UpgradeAlert(
        dialogStyle: UpgradeDialogStyle.material,
        showIgnore: false,
        showLater: true,
        onUpdate: () {
          executeUpdate();
          return false;
        },
        upgrader: Upgrader(
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
  }
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
    if (!await launchUrl(url, mode: LaunchMode.externalApplication))
      debugPrint("Gagal");
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
        title: const Text(
          'YASIN & TAHLIL',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00332B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00332B), Color(0xFF001A16)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD54F).withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Color(0xFFFFD54F),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "INSPIRASI HARI INI",
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"${quote["text"]!}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "- QS. ${quote["surah"]!} -",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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
        height: 85,
        decoration: const BoxDecoration(
          color: Color(0xFF00332B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/images/yusuf.png'),
              ),
            ),
            const SizedBox(width: 15),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dibuat oleh",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "Yusuf Ardiansyah",
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.amberAccent,
        fontSize: 12,
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
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: col.withOpacity(0.2),
        child: Text(l),
      ),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(s, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 15,
        color: Colors.white24,
      ),
      onTap: () async {
        if (type == "sholat" || type == "qiblat") {
          if (await Permission.location.request().isGranted) {
            if (type == "sholat")
              Navigator.push(
                c,
                MaterialPageRoute(builder: (c) => const JadwalSholatPage()),
              );
            else
              Navigator.push(
                c,
                MaterialPageRoute(builder: (c) => const QiblahPage()),
              );
          } else {
            ScaffoldMessenger.of(c).showSnackBar(
              const SnackBar(content: Text("Izin lokasi diperlukan")),
            );
          }
        } else if (type == "selamatan")
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const SelamatanPage()),
          );
        else if (type == "asmaul_husna")
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const AsmaulHusnaPage()),
          );
        else if (type == "tasbih")
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const TasbihPage()),
          );
        else if (type == "doa")
          Navigator.push(
            c,
            MaterialPageRoute(builder: (c) => const DoaListPage()),
          );
        else
          Navigator.push(
            c,
            MaterialPageRoute(
              builder: (c) => SurahDetailPage(fileName: type, title: t),
            ),
          );
      },
    ),
  );
}

// ==========================================
// HALAMAN: HITUNG SELAMATAN
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

  Widget _buildRow(String title, int days) {
    DateTime res = selectedDate.add(Duration(days: days - 1));
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _formatDate(res),
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.calendar_today,
          size: 16,
          color: Colors.white24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KALKULATOR SELAMATAN"),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Pilih Tanggal Meninggal (Geblag):",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_calendar),
            label: Text(_formatDate(selectedDate)),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          const SizedBox(height: 25),
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
// HALAMAN: JADWAL SHOLAT
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

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _initJadwal();
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
        title: const Text(
          "JADWAL SHOLAT",
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
      ),
      body:
          prayerTimes == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildInfoBox(),
                  const SizedBox(height: 20),
                  _buildTimeCard("Subuh", prayerTimes!.fajr),
                  _buildTimeCard("Terbit", prayerTimes!.sunrise),
                  _buildTimeCard("Dzuhur", prayerTimes!.dhuhr),
                  _buildTimeCard("Ashar", prayerTimes!.asr),
                  _buildTimeCard("Maghrib", prayerTimes!.maghrib),
                  _buildTimeCard("Isya", prayerTimes!.isha),
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
        height: 85,
        decoration: const BoxDecoration(
          color: Color(0xFF00332B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/images/yusuf.png'),
              ),
            ),
            const SizedBox(width: 15),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dibuat oleh",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "Yusuf Ardiansyah",
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.5)),
    ),
    child: Column(
      children: [
        const Icon(Icons.location_on, color: Color(0xFFFFD54F)),
        const SizedBox(height: 10),
        Text(
          alamatLengkap,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          koordinatStr,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
        const Divider(color: Colors.white10, height: 20),
        // MANTRA FORMAT TANGGAL BAHASA INDONESIA DI BAWAH INI:
        Text(
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
          style: const TextStyle(fontSize: 14, color: Color(0xFFFFD54F)),
        ),
      ],
    ),
  );

  Widget _buildTimeCard(String label, DateTime time) => Card(
    color: const Color(0xFF1A1A1A),
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(
        DateFormat.Hm().format(time.toLocal()),
        style: const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 20,
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
        title: const Text(
          "ARAH KIBLAT",
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FlutterQiblah.qiblahStream,
        builder: (c, AsyncSnapshot<QiblahDirection> snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(25),
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
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Text(
                            "${q.direction.toStringAsFixed(0)}°",
                            style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              color:
                                  sel < 2.0
                                      ? Colors.greenAccent
                                      : const Color(0xFFFFD54F),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFD54F,
                                    ).withOpacity(0.4),
                                    width: 2,
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
                                      width: 220,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: (q.qiblah * (math.pi / 180) * -1),
                                child: SizedBox(
                                  width: 280,
                                  height: 280,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: Image.asset(
                                          'assets/images/kabah.png',
                                          width: 55,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
        height: 85,
        decoration: const BoxDecoration(
          color: Color(0xFF00332B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/images/yusuf.png'),
              ),
            ),
            const SizedBox(width: 15),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dibuat oleh",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "Yusuf Ardiansyah",
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(i, color: const Color(0xFFFFD54F), size: 20),
      title: Text(
        t,
        style: const TextStyle(fontSize: 13, color: Colors.white70),
      ),
      trailing: Text(
        v,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13,
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
      if (currentPlayingIndex != null && currentPlayingIndex! < d.length - 1)
        putarAudio(currentPlayingIndex! + 1);
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
    if (currentPlayingIndex == i && player.state == PlayerState.playing)
      await player.pause();
    else {
      setState(() => currentPlayingIndex = i);
      if (itemScrollController.isAttached)
        itemScrollController.scrollTo(
          index: i,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
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
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ScrollablePositionedList.builder(
                itemCount: d.length,
                itemScrollController: itemScrollController,
                itemBuilder: (c, i) {
                  bool isP =
                      currentPlayingIndex == i &&
                      player.state == PlayerState.playing;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isP
                              ? const Color(0xFF00241E)
                              : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isP ? const Color(0xFFFFD54F) : Colors.white10,
                        width: 1.5,
                      ),
                    ),
                    child: CustomPaint(
                      painter: AbstractPlatinumPainter(
                        color: const Color(0xFFFFD54F).withOpacity(0.8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              d[i]['ar'],
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: isTahlil ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                height: 2,
                              ),
                            ),
                            const SizedBox(height: 25),
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
                                          style: const TextStyle(
                                            color: Color(0xFFFFD54F),
                                            fontStyle: FontStyle.italic,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          formatTeks(d[i]['id']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            height: 1.5,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  GestureDetector(
                                    onTap: () => putarAudio(i),
                                    child: Icon(
                                      isP
                                          ? Icons.pause_circle
                                          : Icons.play_circle,
                                      color: const Color(0xFF00BFA5),
                                      size: 48,
                                    ),
                                  ),
                                ],
                              ),
                            if (isTahlil)
                              Text(
                                formatTeks(d[i]['id']),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 16,
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
        title: const Text(
          "KUMPULAN DOA",
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
      ),
      body:
          l
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: d.length,
                itemBuilder:
                    (c, i) => Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withOpacity(0.3),
                        ),
                      ),
                      child: CustomPaint(
                        painter: AbstractPlatinumPainter(
                          color: const Color(0xFFFFD54F).withOpacity(0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                d[i]['judul'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(color: Colors.white10, height: 30),
                              Text(
                                d[i]['ar'],
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.8,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                d[i]['id'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 14,
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
    if (_counter % 33 == 0)
      HapticFeedback.heavyImpact();
    else
      HapticFeedback.lightImpact();
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
        title: const Text(
          "TASBIH DIGITAL",
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFD54F)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Subhanallah • Alhamdulillah • Allahuakbar",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF141414),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withOpacity(0.05),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$_counter",
                      style: const TextStyle(
                        fontSize: 85,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    Text(
                      "Hitungan",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 70),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _tambahHitungan,
                customBorder: const CircleBorder(),
                splashColor: const Color(0xFFFFD54F).withOpacity(0.5),
                highlightColor: const Color(0xFF00BFA5).withOpacity(0.3),
                child: Ink(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00332B),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFA5).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    size: 60,
                    color: Color(0xFFFFD54F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "TAP DI SINI",
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 50),
            IconButton(
              onPressed: _resetHitungan,
              icon: const Icon(Icons.refresh),
              iconSize: 32,
              color: Colors.redAccent.withOpacity(0.8),
              tooltip: "Reset Hitungan",
            ),
            const Text(
              "Reset",
              style: TextStyle(color: Colors.white38, fontSize: 12),
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
        title: const Text(
          "ASMAUL HUSNA",
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF00332B),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFD54F)),
      ),
      body:
          l
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: d.length,
                itemBuilder: (context, index) {
                  final item = d[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withOpacity(0.3),
                      ),
                    ),
                    child: CustomPaint(
                      painter: AbstractPlatinumPainter(
                        color: const Color(0xFFFFD54F).withOpacity(0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00332B),
                                border: Border.all(
                                  color: const Color(0xFFFFD54F),
                                ),
                              ),
                              child: Text(
                                item["no"],
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item["arab"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item["latin"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item["arti"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
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
