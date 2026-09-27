import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui' as ui;

import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'select_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'anime_home.dart';
import 'music_page.dart';

const String _nFont = "AROMA";

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0B0F1A);
  static const surface   = Color(0xFF0E1320);
  static const card      = Color(0xFF131C2E);
  static const cardAlt   = Color(0xFF192236);
  static const border    = Color(0xFF1E2D4A);
  static const borderLit = Color(0xFF253560);
  static const teal      = Color(0xFF4ECDC4);
  static const green     = Color(0xFF22C55E);
  static const blue      = Color(0xFF3B82F6);
  static const amber     = Color(0xFFF59E0B);
  static const red       = Color(0xFFEF4444);
  static const orange    = Color(0xFFFF6B35);
  static const pink      = Color(0xFFEC4899);
  static const indigo    = Color(0xFF4169E1);
  static const text      = Color(0xFFEEEEEE);
  static const textSub   = Color(0xFF7B8DB3);
  static const textDim   = Color(0xFF2D3A5A);
}

// ─── CONSTANTS ──────────────────────────────────────────────────────────────────
const Color kCard = Color(0xFF1A1A3E);
const Color kBorder = Color(0xFF2A2A5E);
const Color kWhite = Color(0xFFFFFFFF);
const Color kWhite54 = Color(0x8AFFFFFF);
const Color kCyan = Color(0xFF00E5FF);
const Color kGreen = Color(0xFF4CAF50);
const Color kBlue = Color(0xFF2196F3);
const Color kOrange = Color(0xFFFF9800);
const Color kRed = Color(0xFFE91E63);
const Color kYellow = Color(0xFFFFEB3B);
const Color _nCard = Color(0xFF1C2230);

// ─── Color Extensions ──────────────────────────────────────────────────────────
extension ColorExt on Color {
  Color withOpacity(double opacity) {
    return withAlpha((opacity * 255).round());
  }
}

// ─── Quick Action Data ──────────────────────────────────────────────────────────
class _QuickActionData {
  final IconData icon;
  final IconData bgIcon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _QuickActionData({
    required this.icon,
    required this.bgIcon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

// ─── Dashboard Page ────────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  final List<Map<String, dynamic>> listBug, listDoos;
  final List<dynamic> news;
  const DashboardPage({
    super.key, required this.username, required this.password,
    required this.role, required this.expiredDate, required this.listBug,
    required this.listDoos, required this.sessionKey, required this.news,
  });
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {

  late String sessionKey, username, password, role, expiredDate;
  late List<Map<String, dynamic>> listBug, listDoos;
  late List<dynamic> newsList;

  late WebSocketChannel channel;
  String androidId = 'unknown';
  File? _profileImage;
  VideoPlayerController? _menuVideoCtrl;

  int _navIndex = 0;
  Widget _body  = const SizedBox();
  int onlineUsers = 0, activeConns = 0;

  // ✅ STATS DARI API
  int totalUsers = 0;
  int totalSender = 0;
  bool _statsLoading = true;
  
  // Quick Actions carousel
  late PageController _qaPageCtrl;
  double _currentQaPage = 0.0;
  
  // News Page Controller
  late PageController _newsPageCtrl;
  int _newsPageViewKey = 0;
  double _currentNewsPage = 0.0;

  late AnimationController _bgCtrl, _pageCtrl, _pulseCtrl;
  late Animation<double> _pageFade, _pulse;
  late Animation<Offset> _pageSlide;

  final PageController _bannerCtrl = PageController();
  int _bannerPage = 0;

  // ── Prayer times ──
  bool _detectingLocation = false;
  String _prayerCity = 'Jakarta';
  Map<String, String> _prayerTimes = {};
  String _nextPrayerLabel = '';
  String _nextPrayerTime = '';
  bool _prayerLoading = true;

  Color get primaryColor => const Color(0xFF6C5CE7);
  Color get accentColor => const Color(0xFFCE93D8);
  Color get cardColor => const Color(0xFF1A1A3E);
  Color get backgroundColor => const Color(0xFF0B0F1A);

  @override
  void initState() {
    super.initState();
    sessionKey  = widget.sessionKey; username = widget.username;
    password    = widget.password;   role     = widget.role;
    expiredDate = widget.expiredDate;
    listBug     = widget.listBug; listDoos = widget.listDoos;
    newsList    = widget.news;

    _qaPageCtrl = PageController();
    _newsPageCtrl = PageController();

    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _pageCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _body = _homeDashboard();
    _pageCtrl.forward();
    _initAndroidId();
    _loadProfileImage();
    _initMenuVideo();
    _fetchPrayerTimes();
    _fetchStats();
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _bgCtrl.dispose(); 
    _pageCtrl.dispose(); 
    _pulseCtrl.dispose();
    _qaPageCtrl.dispose();
    _newsPageCtrl.dispose();
    _menuVideoCtrl?.dispose(); 
    _bannerCtrl.dispose();
    super.dispose();
  }

  Animation<double> get _pulseAnim => _pulse;

  // ✅ FUNGSI FETCH STATS DARI API
  Future<void> _fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('http://zyromodeapa.pteroq.biz.id:10750/api/stats?key=$sessionKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            totalUsers = data['totalUsers'] ?? 0;
            totalSender = data['totalSender'] ?? 0;
            _statsLoading = false;
          });
        }
      } else {
        setState(() {
          totalUsers = listBug.length;
          totalSender = listDoos.length;
          _statsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        totalUsers = listBug.length;
        totalSender = listDoos.length;
        _statsLoading = false;
      });
    }
  }

 void _initMenuVideo() {
  _menuVideoCtrl = VideoPlayerController.asset('assets/videos/banner1.mp4')
    ..initialize().then((_) {
      if (mounted) setState(() {});
      _menuVideoCtrl?.setLooping(true);
      _menuVideoCtrl?.setVolume(1.0); // ✅ UBAH INI DARI 0 JADI 1.0 (SUARA NYALA)
      _menuVideoCtrl?.play();
    });
}

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path  = prefs.getString('profile_image_$username');
    if (path != null && path.isNotEmpty && mounted)
      setState(() => _profileImage = File(path));
  }
  
  Future<void> _fetchPrayerTimes() async {
    if (!mounted) return;
    setState(() => _prayerLoading = true);
    final data = await PrayerTimeService.fetchPrayerTimes(_prayerCity);
    if (!mounted) return;
    if (data.isNotEmpty && data['data'] != null) {
      final timings = data['data']['timings'] ?? {};
      final Map<String, String> times = {
        'Subuh': timings['Fajr'] ?? '--:--',
        'Dzuhur': timings['Dhuhr'] ?? '--:--',
        'Ashar': timings['Asr'] ?? '--:--',
        'Maghrib': timings['Maghrib'] ?? '--:--',
        'Isya': timings['Isha'] ?? '--:--',
      };
      final now = TimeOfDay.now();
      String nextLabel = 'Isya';
      String nextTime = times['Isya'] ?? '--:--';
      for (final entry in times.entries) {
        final parts = entry.value.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          if (h > now.hour || (h == now.hour && m > now.minute)) {
            nextLabel = entry.key;
            nextTime = entry.value;
            break;
          }
        }
      }
      setState(() {
        _prayerTimes = times;
        _nextPrayerLabel = nextLabel;
        _nextPrayerTime = nextTime;
        _prayerLoading = false;
      });
    } else {
      setState(() => _prayerLoading = false);
    }
  }

  Future<void> _autoDetectLocationAndFetchPrayer() async {
    if (_detectingLocation) return;
    setState(() => _detectingLocation = true);
    try {
      final city = await PrayerTimeService.detectLocationByGPS();
      if (mounted) {
        setState(() {
          _prayerCity = city;
          _detectingLocation = false;
        });
        await _fetchPrayerTimes();
      }
    } catch (e) {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  void _showChangeCityDialog() {
    final ctrl = TextEditingController(text: _prayerCity);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18), 
          side: BorderSide(color: accentColor.withOpacity(0.3))
        ),
        title: const Text('Ganti Lokasi', style: TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nama kota (misal: Jakarta, Surabaya, Bandung)',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true, fillColor: backgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFFCE93D8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _prayerCity = ctrl.text.trim();
                });
                _fetchPrayerTimes();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _initAndroidId() async {
    final info = await DeviceInfoPlugin().androidInfo;
    androidId = info.id;
    _connectWS();
  }

  void _connectWS() {
    channel = WebSocketChannel.connect(
        Uri.parse('http://zyromodeapa.pteroq.biz.id:10750'));
    channel.sink.add(jsonEncode({'type': 'validate', 'key': sessionKey, 'androidId': androidId}));
    channel.sink.add(jsonEncode({'type': 'stats'}));
    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo' && data['valid'] == false) {
        _handleInvalidSession(data['reason'] == 'androidIdMismatch'
            ? 'Akun ini login di perangkat lain.'
            : 'Sesi tidak valid. Silakan login ulang.');
      }
      if (data['type'] == 'stats' && mounted) {
        setState(() {
          onlineUsers = data['onlineUsers'] ?? 0;
          activeConns = data['activeConnections'] ?? 0;
        });
      }
    });
  }

  Future<void> _openUrl(String url) async =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  void _handleInvalidSession(String msg) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    _showSystemDialog(title: 'Sesi Berakhir', message: msg,
        icon: Icons.lock_outline_rounded, color: _C.red,
        onOk: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false));
  }

  Future<void> _doLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  void _navigate(Widget page) {
    setState(() => _body = page);
    _pageCtrl.forward(from: 0);
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: _navigate(_homeDashboard()); break;
      case 1: _navigate(InfoPage(sessionKey: sessionKey)); break;
      case 2: _navigate(SelectPage(
          username: username,
          password: password,
          listBug: listBug,
          uId: androidId,
          role: role,
          listPayload: listBug,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
          listDDoS: listDoos,
        )); break;
      case 3: _navigate(ToolsPage(
          sessionKey: sessionKey,
          userRole: role,
          listDoos: listDoos,
        )); break;
      case 4: Navigator.push(context, _slideRoute(MusicPage())); break;
    }
  }

  void _onDrawerNav(int index) {
    Navigator.pop(context);
    switch (index) {
      case 1: _navigate(SellerPage(keyToken: sessionKey)); break;
      case 2: _navigate(AdminPage(sessionKey: sessionKey, role: role)); break;
    }
  }

  void _showSystemDialog({required String title, required String message,
      required IconData icon, required Color color, VoidCallback? onOk}) {
    showGeneralDialog(
      context: context, barrierDismissible: false, barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child)),
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(color: _C.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 40)]),
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(color: color.withOpacity(0.3))),
                child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textSub, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            _MxBtn(label: 'OK', fullWidth: true, color: color, onTap: () {
              Navigator.pop(ctx); onOk?.call();
            }),
          ]),
        ),
      ),
    );
  }
  
  Widget _buildQuickActionsSection() {
    final actions = [
      _QuickActionData(
        icon: FontAwesomeIcons.whatsapp,
        bgIcon: FontAwesomeIcons.whatsapp,
        title: 'Manage Sender',
        subtitle: 'Manage your active sender',
        gradient: [const Color(0xFFE91E8C), const Color(0xFFAD1457)],
        onTap: () => Navigator.push(
          context,
          _slideRoute(BugSenderPage(sessionKey: sessionKey, username: username, role: role)),
        ).then((_) {
          if (mounted && _newsPageCtrl.hasClients) {
            setState(() { _currentNewsPage = 0.0; _newsPageViewKey++; });
            _newsPageCtrl.jumpToPage(0);
          }
        }),
      ),
      _QuickActionData(
        icon: FontAwesomeIcons.telegram,
        bgIcon: FontAwesomeIcons.telegram,
        title: 'PV DEVELOPER',
        subtitle: 'MAU UP ROLL',
        gradient: [const Color(0xFF00B4D8), const Color(0xFF0077B6)],
        onTap: () => _openUrl('https://t.me/BUYAPKBUY/RoomPublicKayy1'),
      ),
      _QuickActionData(
        icon: FontAwesomeIcons.bookQuran,
        bgIcon: FontAwesomeIcons.bookQuran,
        title: 'Ganti Password Account',
        subtitle: 'Account And Info',
        gradient: [const Color(0xFF7C4DFF), const Color(0xFF4A148C)],
        onTap: () => Navigator.push(context, _slideRoute(ChangePasswordPage(username: username, sessionKey: sessionKey))),
      ),
      _QuickActionData(
        icon: FontAwesomeIcons.tv,
        bgIcon: FontAwesomeIcons.tv,
        title: 'Anime',
        subtitle: 'Discover & Watch Anime',
        gradient: [const Color(0xFFFF6D00), const Color(0xFFE65100)],
        onTap: () => Navigator.push(context, _slideRoute(HomeAnimePage())),
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: kYellow.withOpacity(0.18),
                  border: Border.all(color: kYellow.withOpacity(0.3)),
                ),
                child: const Icon(Icons.bolt_rounded, color: kYellow, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUICK ACTIONS',
                      style: TextStyle(
                        color: kWhite, fontWeight: FontWeight.bold, fontSize: 15,
                        fontFamily: 'AROMA', letterSpacing: 1)),
                  Text('Beberapa Menu Tambahan',
                      style: TextStyle(color: kWhite54, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: kYellow.withOpacity(0.15),
                  border: Border.all(color: kYellow.withOpacity(0.4)),
                ),
                child: Row(children: [
                  Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: kYellow)),
                  const SizedBox(width: 5),
                  const Text('XNOXAT',
    style: TextStyle(color: kYellow, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _qaPageCtrl,
            itemCount: actions.length,
            onPageChanged: (index) {
              if (mounted) setState(() => _currentQaPage = index.toDouble());
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildQuickActionCard(actions[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(actions.length, (index) {
            final bool isActive = _currentQaPage.round() == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive ? kYellow : Colors.white24,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickActionData action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
              colors: action.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: action.gradient.first.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12, bottom: -12,
              child: Icon(action.bgIcon, color: Colors.white.withOpacity(0.08), size: 110),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white.withOpacity(0.22)),
                    child: Icon(action.icon, color: kWhite, size: 24),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.22)),
                      child: const Text('Tap →',
                          style: TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(action.title,
                      style: const TextStyle(
                        color: kWhite, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'AROMA')),
                  const SizedBox(height: 4),
                  Text(action.subtitle,
                      style: TextStyle(color: kWhite.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeDashboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildBannerVideo(),
        const SizedBox(height: 14),
        _userCard(),
        const SizedBox(height: 14),
        _buildWhatsAppBugCard(),
        const SizedBox(height: 14),
        _buildPrayerSection(),
        const SizedBox(height: 14),
        _buildQuickActionsSection(),
        const SizedBox(height: 80),
        Padding(
           padding: const EdgeInsets.symmetric(horizontal: 20),
           child: _buildFooter(),
         ),
         const SizedBox(height: 10),
      ]),
    );
  }
  
  Widget _buildBannerVideo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 190,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 40,
              spreadRadius: 10,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 60,
              spreadRadius: 15,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 190,
            width: double.infinity,
            color: const Color(0xFF080C12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_menuVideoCtrl != null && _menuVideoCtrl!.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _menuVideoCtrl!.value.size.width,
                      height: _menuVideoCtrl!.value.size.height,
                      child: VideoPlayer(_menuVideoCtrl!),
                    ),
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0A0F1E), Color(0xFF1A1A2E)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                  ),
                ),
                // 3D edge highlight (matching the reference banner style)
                Positioned(
                  top: 0, left: 20, right: 20,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 16, bottom: 14,
                  child: Text('WAHYU X CRASH',
                    style: TextStyle(
                      color: kWhite, fontSize: 22, fontWeight: FontWeight.bold,
                      fontFamily: 'AROMA', letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: _nCard.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12)],
      ),
      child: Column(
        children: [
          const Text(
            'BY : TEAM XNOXAT',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                fontFamily: _nFont,
                letterSpacing: 2.5),
          ),
          const SizedBox(height: 5),
          Text(
            'Thank You Semua Buyer WAHYU XD',
            style: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 11, fontFamily: _nFont),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 258,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            if (newsList.isNotEmpty)
              PageView.builder(
                controller: _bannerCtrl,
                onPageChanged: (i) => setState(() => _bannerPage = i),
                itemCount: newsList.length,
                itemBuilder: (_, i) => newsList[i]['image'] != null &&
                    newsList[i]['image'].toString().isNotEmpty
                    ? NewsMedia(url: newsList[i]['image'])
                    : const _PlaceholderBanner(),
              )
            else
              const _PlaceholderBanner(),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xE00B0F1A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18, bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBannerLogo(),
                ],
              ),
            ),
            if (newsList.length > 1)
              Positioned(
                top: 12, right: 14,
                child: Row(
                  children: List.generate(newsList.length, (i) {
                    final active = i == _bannerPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: active ? 16 : 5, height: 5,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBannerLogo() {
    return Text(
      'XNOXAT X CRASH',
      style: TextStyle(
        fontFamily: 'AROMA',
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.white,
      ),
    );
  }

  Widget _userCard() {
  return Container(
    margin: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/custom.jpg',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.75),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 1.5,
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/spam.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'AROMA',
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.45),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'AROMA',
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.white38,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Expired: ",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11,
                                  fontFamily: 'AROMA',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                expiredDate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'AROMA',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _statsLoading ? "..." : "$totalUsers",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'AROMA',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Total Users",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 9,
                                fontFamily: 'AROMA',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1.2,
                        height: 34,
                        color: Colors.white.withOpacity(0.12),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.send_outlined,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _statsLoading ? "..." : "$totalSender",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'AROMA',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Total Sender",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 9,
                                fontFamily: 'AROMA',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildWhatsAppBugCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B8C3F), Color(0xFF25D366), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -12,
            bottom: -10,
            child: Icon(
              FontAwesomeIcons.whatsapp,
              size: 110,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 60,
            child: _bubble(8, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            top: 10,
            right: 100,
            child: _bubble(5, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            top: 30,
            right: 30,
            child: _bubble(12, Colors.white.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "BUG X RAT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AROMA',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Fast Bug Excution & flexsibel system",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                    fontFamily: 'AROMA',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "AKTIF",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AROMA',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNavItem5(int index, IconData icon, String label) {
  final active = _navIndex == index;
  
  const LinearGradient shinyGreen = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF25D366), Color(0xFF128C7E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  return Expanded(
    child: GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ─── INDICATOR LINE ──────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: active ? 28 : 0,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              gradient: active ? shinyGreen : null,
              color: active ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: active ? [
                BoxShadow(
                  color: const Color(0xFF25D366).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
          ),
          
          // ─── ICON ─────────────────────────────────────────────────────────
          Icon(
            icon,
            size: 22,
            color: active ? const Color(0xFF25D366) : _C.textSub,
          ),
          
          const SizedBox(height: 3),
          
          // ─── LABEL ────────────────────────────────────────────────────────
          Text(
            label,
            style: TextStyle(
              fontFamily: 'AROMA',
              color: active ? const Color(0xFF25D366) : _C.textSub,
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── BUBBLE ──────────────────────────────────────────────────────────────────
Widget _bubble(double r, Color color) => Container(
  width: r * 2,
  height: r * 2,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: color,
  ),
);
  
  
  Widget _buildPrayerSection() {
    final prayerColors = [
      const Color(0xFF0D47A1),   // Biru sangat tua
      const Color(0xFF1565C0),   // Biru tua
      const Color(0xFF1E88E5),   // Biru medium
      const Color(0xFF42A5F5),   // Biru terang
      const Color(0xFF64B5F6),   // Biru lebih terang
    ];
    final prayerIcons = [
      Icons.nights_stay_rounded,
      Icons.wb_sunny_rounded,
      Icons.cloud_rounded,
      Icons.wb_twilight_rounded,
      Icons.nightlight_round,
    ];
    final prayerKeys = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

    // GANTI LANGSUNG PAKE WARNA BIRU
    const Color _primaryBlue = Color(0xFF0D47A1);
    const Color _accentBlue = Color(0xFF1565C0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _primaryBlue.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _accentBlue.withOpacity(0.15),
                          border: Border.all(
                            color: _accentBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.mosque_rounded,
                            color: Color(0xFF42A5F5),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'JADWAL SHOLAT',
                              style: TextStyle(
                                fontFamily: 'AROMA',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: _accentBlue,
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _prayerCity,
                                  style: const TextStyle(
                                    fontFamily: 'AROMA',
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _autoDetectLocationAndFetchPrayer,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accentBlue.withOpacity(0.12),
                            border: Border.all(
                              color: _accentBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: _detectingLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF42A5F5),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.gps_fixed_rounded,
                                  color: _accentBlue,
                                  size: 14,
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showChangeCityDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [_primaryBlue, _accentBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryBlue.withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit_location_alt_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'GANTI',
                                style: TextStyle(
                                  fontFamily: 'AROMA',
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_nextPrayerLabel.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _accentBlue.withOpacity(0.3),
                          width: 1,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            _primaryBlue.withOpacity(0.2),
                            _primaryBlue.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: _accentBlue.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Menuju $_nextPrayerLabel : $_nextPrayerTime',
                            style: const TextStyle(
                              fontFamily: 'AROMA',
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _accentBlue.withOpacity(0.12),
                              border: Border.all(
                                color: _accentBlue.withOpacity(0.2),
                              ),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                fontFamily: 'AROMA',
                                color: Color(0xFF42A5F5),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (_prayerLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF42A5F5),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: prayerKeys.length,
                        itemBuilder: (ctx, i) {
                          final key = prayerKeys[i];
                          final time = _prayerTimes[key] ?? '--:--';
                          final color = prayerColors[i];
                          final icon = prayerIcons[i];
                          final isNext = key == _nextPrayerLabel;

                          return Container(
                            width: 72,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.15),
                                  color.withOpacity(0.04),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isNext ? _accentBlue : color.withOpacity(0.2),
                                width: isNext ? 2 : 1,
                              ),
                              boxShadow: isNext ? [
                                BoxShadow(
                                  color: _accentBlue.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ] : [],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icon,
                                    color: isNext ? _accentBlue : Colors.white54,
                                    size: 14,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    key.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'AROMA',
                                      color: isNext ? _accentBlue : Colors.white54,
                                      fontSize: 7,
                                      fontWeight: isNext ? FontWeight.bold : FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      fontFamily: 'AROMA',
                                      color: isNext ? _accentBlue : Colors.white,
                                      fontSize: 12,
                                      fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                  if (isNext)
                                    Container(
                                      margin: const EdgeInsets.only(top: 1),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primaryBlue, _accentBlue],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'NEXT',
                                        style: TextStyle(
                                          fontFamily: 'AROMA',
                                          color: Colors.white,
                                          fontSize: 5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildCircleStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.18),
              border: Border.all(color: color.withOpacity(0.6), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)],
            ),
            child: Center(child: Icon(icon, color: color, size: 28)),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: kWhite, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'AROMA')),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: kWhite54, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStatDivider() =>
      Container(width: 1, height: 60, color: kBorder.withOpacity(0.5));

  Widget _buildQuickActionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
              blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3A2D00),
              border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.35)),
              boxShadow: [BoxShadow(
                  color: const Color(0xFFFBBF24).withOpacity(0.2), blurRadius: 10)],
            ),
            child: const Icon(Icons.bolt_rounded,
                color: Color(0xFFFBBF24), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('QUICK\nACTIONS',
                style: TextStyle(
                  fontFamily: 'AROMA',
                  color: _C.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 3),
            Text('Beberapa Menu Tambahan',
                style: TextStyle(
                  fontFamily: 'AROMA',
                  color: _C.textSub,
                  fontSize: 11,
                )),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.teal.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _C.teal,
                  boxShadow: [BoxShadow(
                      color: _C.teal.withOpacity(0.6), blurRadius: 5)],
                ),
              ),
              const SizedBox(width: 5),
              Text('CRASH',
                  style: TextStyle(
                    fontFamily: 'AROMA',
                    color: _C.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  )),
            ]),
          ),
        ]),
      ),
    );
  }

List<_FC> _buildFeatureCards() => [
    _FC(
      icon: FontAwesomeIcons.whatsapp,
      title: 'Manage Sender',
      subtitle: 'Pairing & Configuration',
      gradient: [const Color(0xFFFF1744), const Color(0xFFFF6B9D)],
      onTap: () => Navigator.push(context, _slideRoute(BugSenderPage(
          sessionKey: sessionKey, username: username, role: role))),
    ),
    _FC(
      icon: FontAwesomeIcons.telegram,
      title: 'Info Channel',
      subtitle: 'Gabung update channel',
      gradient: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      onTap: () => _openUrl('https://t.me/BUYAPKBUY/+TESTI_YUSI'),
    ),
    _FC(
      icon: Icons.headset_mic_outlined,
      title: 'Kontak Kami',
      subtitle: 'Hubungi tim support',
      gradient: [const Color(0xFF16A34A), const Color(0xFF4ADE80)],
      onTap: () => Navigator.push(context, _slideRoute(const ContactPage())),
    ),
    _FC(
      icon: Icons.history_rounded,
      title: 'Riwayat Akun',
      subtitle: 'Log aktivitas akun kamu',
      gradient: [const Color(0xFF6D28D9), const Color(0xFFA78BFA)],
      onTap: () => Navigator.push(context,
          _slideRoute(RiwayatPage(sessionKey: sessionKey, role: role))),
    ),
    _FC(
      icon: Icons.lock_outline_rounded,
      title: 'Ganti Password',
      subtitle: 'Perbarui keamanan akun',
      gradient: [const Color(0xFFDC2626), const Color(0xFFF87171)],
      onTap: () => Navigator.push(context, _slideRoute(
          ChangePasswordPage(username: username, sessionKey: sessionKey))),
    ),
  ];

Widget _buildFeatureCardsSection() {
  final fcs = _buildFeatureCards();
  return SizedBox(
    height: 210,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: fcs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            right: index == fcs.length - 1 ? 0 : 12,
          ),
          child: _FeatureCard(fc: fcs[index]),
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Stack(children: [
        Positioned.fill(child: _AnimatedBg(controller: _bgCtrl)),
        SafeArea(
          child: FadeTransition(opacity: _pageFade,
              child: SlideTransition(position: _pageSlide, child: _body)),
        ),
      ]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.surface,
      elevation: 0, centerTitle: true, titleSpacing: 0,
      leading: Builder(builder: (ctx) =>
          _MenuBtn(onTap: () => Scaffold.of(ctx).openDrawer())),
      title: _buildAppBarLogo(),
      actions: [
        _AppBarIconBtn(icon: Icons.headphones_outlined, onTap: () {}),
        _AppBarIconBtn(icon: Icons.notifications_outlined, onTap: () {}),
        _AppBarIconBtn(icon: Icons.logout_rounded, onTap: _doLogout),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  Widget _buildAppBarLogo() {
    return Text(
      'WAHYUXCRASH',
      style: TextStyle(
        fontFamily: 'ARABOLIC',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBottomNav() {
  return Container(
    color: Colors.transparent,
    padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
    child: Container(
      height: 70,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItemFlat(0, Icons.home_rounded, 'Home'),
          _buildNavItemFlat(1, Icons.chat_bubble_outline_rounded, 'Info'),
          _buildNavItemFlat(2, FontAwesomeIcons.whatsapp, 'Bug Whatsapp'),
          _buildNavItemFlat(3, Icons.build_outlined, 'Tools'),
          _buildNavItemFlat(4, Icons.music_note_rounded, 'Music'),
        ],
      ),
    ),
  );
}

// Fungsi helper untuk membuat icon sejajar tanpa efek melayang
Widget _buildNavItemFlat(int index, IconData icon, String label) {
  bool isSelected = _navIndex == index;
  
  return GestureDetector(
    onTap: () => _onNavTap(index),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: isSelected
          ? BoxDecoration(
              color: _C.surface.withOpacity(0.8), // Background abu gelap saat aktif (seperti gambar)
              borderRadius: BorderRadius.circular(20),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF25D366) : _C.textSub, // WA tetap warna hijau jika aktif
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'AROMA',
              color: isSelected ? const Color(0xFF25D366) : _C.textSub,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

  // ─── DRAWER ────────────────────────────────────────────────────────────────
Widget _buildDrawer() {
  return Drawer(
    backgroundColor: Colors.transparent,
    width: MediaQuery.of(context).size.width * 0.82,
    child: Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: const Color(0xFF1E2D4A), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 40,
            offset: const Offset(10, 0),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/xcv.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.82),
                  Colors.black.withOpacity(0.75),
                  Colors.black.withOpacity(0.88),
                ],
              ),
            ),
          ),
          Column(
        children: [
          _DrawerHeader(
            username: username,
            role: role,
            expiredDate: expiredDate,
            profileImage: _profileImage,
            videoCtrl: _menuVideoCtrl,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF253560).withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF3B82F6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'NAVIGASI',
                  style: TextStyle(
                    color: Color(0xFF7B8DB3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'AROMA',
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              children: [
                if (role == 'reseller' || role == 'vip' || role == 'pt' || role == 'member')
                  _PremiumDrawerItem(
                    icon: Icons.storefront_rounded,
                    label: 'Seller Page',
                    subtitle: 'Kelola produk & reseller',
                    accentColor: const Color(0xFF4ADE80),
                    onTap: () => _onDrawerNav(1),
                  ),
                if (role == 'owner' || role == 'admin' || role == 'moderator' ||
                    role == 'developer' || role == 'tk' || role == 'pt' || role == 'founder')
                  _PremiumDrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Admin Page',
                    subtitle: 'Panel manajemen system',
                    accentColor: const Color(0xFFFBBF24),
                    onTap: () => _onDrawerNav(2),
                  ),
                _PremiumDrawerItem(
                  icon: Icons.headset_mic_rounded,
                  label: 'Contact Support',
                  subtitle: 'Hubungi tim Drive',
                  accentColor: const Color(0xFF60A5FA),
                  onTap: () {
                    Navigator.pop(context);
                    _openUrl('https://t.me/BUYAPKBUY/KayzzScarry');
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF253560).withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: const Color(0xFFEF4444).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SISTEM',
                        style: TextStyle(
                          color: Color(0xFF7B8DB3),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'AROMA',
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131C2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2D4A), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E2D4A), Color(0xFF253560)],
                          ),
                        ),
                        child: const Icon(Icons.info_outline_rounded,
                            color: Color(0xFF7B8DB3), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WAHYU X CRASH',
                            style: TextStyle(
                              color: Color(0xFFEEEEEE),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'AROMA',
                            ),
                          ),
                          Text(
                            'V10— By XNOXAT V10',
                            style: TextStyle(
                              color: const Color(0xFF7B8DB3).withOpacity(0.8),
                              fontSize: 9,
                              fontFamily: 'AROMA',
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'AROMA',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFEF4444).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await _doLogout();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Color(0xFFEF4444), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keluar',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'AROMA',
                          ),
                        ),
                        Text(
                          'Logout dari akun ini',
                          style: TextStyle(
                            color: const Color(0xFFEF4444).withOpacity(0.5),
                            fontSize: 9,
                            fontFamily: 'AROMA',
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: const Color(0xFFEF4444).withOpacity(0.4), size: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    ),
  );
}
} // _DashboardPageState

//Class Button

class _PremiumDrawerItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _PremiumDrawerItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_PremiumDrawerItem> createState() => _PremiumDrawerItemState();
}

class _PremiumDrawerItemState extends State<_PremiumDrawerItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.accentColor.withOpacity(0.08)
              : const Color(0xFF131C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed
                ? widget.accentColor.withOpacity(0.35)
                : const Color(0xFF1E2D4A),
            width: 1,
          ),
          boxShadow: _pressed
              ? [BoxShadow(color: widget.accentColor.withOpacity(0.1), blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: widget.accentColor.withOpacity(0.12),
                border: Border.all(color: widget.accentColor.withOpacity(0.2), width: 1),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Color(0xFFEEEEEE),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'AROMA',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF7B8DB3),
                      fontSize: 10,
                      fontFamily: 'AROMA',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF2D3A5A), size: 11),
          ],
        ),
      ),
    );
  }
}


// ─── Feature Card Model ────────────────────────────────────────────────────────
class _FC {
  final IconData icon;
  final String title, subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _FC({required this.icon, required this.title, required this.subtitle,
      required this.gradient, required this.onTap});
}

// ─── Prayer Time Service ──────────────────────────────────────────────────────
class PrayerTimeService {
  static Future<Map<String, dynamic>> fetchPrayerTimes(String city) async {
    final now = DateTime.now();
    final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
      'city': city, 'country': 'ID', 'method': '11',
      'day': '${now.day}', 'month': '${now.month}', 'year': '${now.year}',
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {};
  }

  static Future<String> detectLocationByGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await detectLocationByIP();
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await detectLocationByIP();
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return await detectLocationByIP();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 15));
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = (place.subAdministrativeArea?.isNotEmpty == true)
            ? place.subAdministrativeArea!
            : (place.administrativeArea?.isNotEmpty == true)
                ? place.administrativeArea!
                : 'Jakarta';
        return city;
      }
    } catch (e) {}
    return await detectLocationByIP();
  }

  static Future<String> detectLocationByIP() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          String city = data['city'] ?? '';
          if (city.isNotEmpty) return city;
        }
      }
    } catch (e) {}
    try {
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String city = data['city'] ?? '';
        if (city.isNotEmpty) return city;
      }
    } catch (e) {}
    return 'Jakarta';
  }
}

// ─── Color Helper ─────────────────────────────────────────────────────────────
Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'owner':    return const Color(0xFFFBBF24);
    case 'admin':    return const Color(0xFFFF5555);
    case 'reseller': return const Color(0xFF4ADE80);
    case 'vip':      return const Color(0xFFA78BFA);
    default:         return _C.pink;
  }
}

IconData _roleIcon(String role) {
  switch (role.toLowerCase()) {
    case 'owner':    return Icons.workspace_premium_rounded;
    case 'admin':    return Icons.admin_panel_settings_rounded;
    case 'reseller': return Icons.storefront_rounded;
    case 'vip':      return Icons.star_rounded;
    default:         return Icons.shield_rounded;
  }
}

String _roleShort(String role) {
  if (role.isEmpty) return '??';
  return role.substring(0, math.min(2, role.length)).toUpperCase();
}

// ─── Placeholder Banner ────────────────────────────────────────────────────────
class _PlaceholderBanner extends StatelessWidget {
  const _PlaceholderBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E2D4A), Color(0xFF0B0F1A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF2D3A5A), size: 48),
      ),
    );
  }
}

// ─── Hexagon Pattern Painter ──────────────────────────────────────────────────
class _HexagonPatternPainter extends CustomPainter {
  const _HexagonPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double hexSize = 30;
    final double hexWidth = hexSize * 1.732;
    final double hexHeight = hexSize * 2;

    for (double y = -hexSize; y < size.height + hexSize; y += hexHeight * 0.75) {
      for (double x = -hexSize; x < size.width + hexSize; x += hexWidth) {
        final bool offset = (y / (hexHeight * 0.75)).floor() % 2 == 1;
        final double cx = x + (offset ? hexWidth * 0.5 : 0);
        final double cy = y;

        final hexPath = Path()
          ..moveTo(cx + hexSize * 0.5, cy - hexSize * 0.3)
          ..lineTo(cx + hexSize, cy)
          ..lineTo(cx + hexSize * 0.5, cy + hexSize * 0.3)
          ..lineTo(cx - hexSize * 0.5, cy + hexSize * 0.3)
          ..lineTo(cx - hexSize, cy)
          ..lineTo(cx - hexSize * 0.5, cy - hexSize * 0.3)
          ..close();
        canvas.drawPath(hexPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Feature Card Widget ───────────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final _FC fc;
  const _FeatureCard({required this.fc});
  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fc = widget.fc;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); fc.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 260,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: fc.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: fc.gradient[0].withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(children: [
            Positioned(
              right: -10, bottom: -10,
              child: Icon(fc.icon, size: 90,
                  color: Colors.white.withOpacity(0.12)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Icon(fc.icon, color: Colors.white, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Tap →',
                            style: TextStyle(
                                color: Colors.white, 
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'AROMA')),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(fc.title,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 20,
                        fontWeight: FontWeight.w900, 
                        height: 1.1,
                        fontFamily: 'AROMA',
                      )),
                  const SizedBox(height: 3),
                  Text(fc.subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                          fontFamily: 'AROMA')),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Drawer Header ─────────────────────────────────────────────────────────────
class _DrawerHeader extends StatefulWidget {
  final String username, role, expiredDate;
  final File? profileImage;
  final VideoPlayerController? videoCtrl;
  const _DrawerHeader({required this.username, required this.role,
      required this.expiredDate, required this.profileImage, required this.videoCtrl});
  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fade  = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rColor = _roleColor(widget.role);
    return Container(
      height: 230, clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: _C.card,
          border: Border(bottom: BorderSide(color: _C.border))),
      child: Stack(children: [
        if (widget.videoCtrl != null && widget.videoCtrl!.value.isInitialized)
          Positioned.fill(child: FittedBox(fit: BoxFit.cover,
              child: SizedBox(width: widget.videoCtrl!.value.size.width,
                  height: widget.videoCtrl!.value.size.height,
                  child: VideoPlayer(widget.videoCtrl!)))),
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x440B0F1A), Color(0xF20B0F1A)],
          )),
        )),
        Positioned.fill(child: SafeArea(
          child: FadeTransition(opacity: _fade, child: SlideTransition(
            position: _slide,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Stack(children: [
                Container(
                  width: 74, height: 74,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: rColor,
                      border: Border.all(color: rColor.withOpacity(0.6), width: 2),
                      boxShadow: [BoxShadow(color: rColor.withOpacity(0.3), blurRadius: 16)]),
                  child: ClipOval(child: widget.profileImage != null
                      ? Image.file(widget.profileImage!, fit: BoxFit.cover)
                      : Icon(_roleIcon(widget.role), size: 32, color: Colors.white)),
                ),
                Positioned(right: 0, bottom: 0, child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: rColor, shape: BoxShape.circle,
                      border: Border.all(color: _C.card, width: 2)),
                  child: Icon(_roleIcon(widget.role), size: 9, color: Colors.white),
                )),
              ]),
              const SizedBox(height: 12),
              Text(widget.username, style: const TextStyle(
                  color: _C.text, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: rColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rColor.withOpacity(0.3))),
                child: Text(widget.role.toUpperCase(), style: TextStyle(
                    color: rColor, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
              const SizedBox(height: 5),
              Text('Exp: ${widget.expiredDate}',
                  style: const TextStyle(color: _C.textSub, fontSize: 10)),
            ]),
          )),
        )),
      ]),
    );
  }
}

// ─── Drawer Item ───────────────────────────────────────────────────────────────
class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _DrawerItem({required this.icon, required this.label,
      required this.onTap, this.isDestructive = false});
  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? _C.red : _C.textSub;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _pressed ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _pressed ? color.withOpacity(0.25) : _C.border),
        ),
        child: Row(children: [
          Icon(widget.icon, color: color, size: 17),
          const SizedBox(width: 14),
          Text(widget.label, style: TextStyle(
              color: widget.isDestructive ? _C.red : _C.text,
              fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, color: _C.textDim, size: 11),
        ]),
      ),
    );
  }
}

// ─── Menu Button ───────────────────────────────────────────────────────────────
class _MenuBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _MenuBtn({required this.onTap});
  @override
  State<_MenuBtn> createState() => _MenuBtnState();
}

class _MenuBtnState extends State<_MenuBtn> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          decoration: BoxDecoration(
            color: _down ? _C.borderLit : _C.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _C.border),
          ),
          child: const Icon(Icons.menu_rounded, color: _C.textSub, size: 19),
        ),
      ),
    );
  }
}

// ─── AppBar Icon Button ────────────────────────────────────────────────────────
class _AppBarIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarIconBtn({required this.icon, required this.onTap});
  @override
  State<_AppBarIconBtn> createState() => _AppBarIconBtnState();
}

class _AppBarIconBtnState extends State<_AppBarIconBtn> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _down ? _C.borderLit : _C.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _C.border),
          ),
          child: Icon(widget.icon, color: _C.textSub, size: 17),
        ),
      ),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
          painter: _BgPainter(controller.value), size: Size.infinite),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0B0F1A));

    final gridPaint = Paint()
      ..color = const Color(0xFF1E2D4A).withOpacity(0.3)
      ..strokeWidth = 0.5 ..style = PaintingStyle.stroke;
    const hexSize = 36.0;
    final hexW = hexSize * math.sqrt(3);
    final hexH = hexSize * 2;
    final rows = (size.height / (hexH * 0.75)).ceil() + 2;
    final cols = (size.width / hexW).ceil() + 2;
    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final dx = col * hexW + (row.isOdd ? hexW / 2 : 0);
        final dy = row * hexH * 0.75;
        _drawHex(canvas, Offset(dx, dy), hexSize, gridPaint);
      }
    }

    canvas.drawCircle(
      Offset(size.width / 2, -size.height * 0.1), size.width * 0.8,
      Paint()..shader = RadialGradient(colors: [
        const Color(0xFF4ECDC4)
            .withOpacity(0.05 + math.sin(t * math.pi * 2) * 0.02),
        Colors.transparent,
      ], radius: 0.6).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, -size.height * 0.1),
          radius: size.width * 0.8)),
    );

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height), size.width * 0.5,
      Paint()..shader = RadialGradient(colors: [
        const Color(0xFFEF4444)
            .withOpacity(0.04 + math.sin(t * math.pi * 2 + 1) * 0.01),
        Colors.transparent,
      ], radius: 0.5).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height),
          radius: size.width * 0.5)),
    );
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

// ─── Mx Button ─────────────────────────────────────────────────────────────────
class _MxBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  final Color color;
  const _MxBtn({required this.label, required this.onTap,
      this.fullWidth = false, this.color = const Color(0xFF4ECDC4)});
  @override
  State<_MxBtn> createState() => _MxBtnState();
}

class _MxBtnState extends State<_MxBtn> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 46,
          width: widget.fullWidth ? double.infinity : null,
          padding: widget.fullWidth
              ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withOpacity(0.35)),
            boxShadow: _down ? [] : [BoxShadow(color: widget.color.withOpacity(0.12),
                blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Center(child: Text(widget.label, style: TextStyle(
              color: widget.color, fontWeight: FontWeight.w800,
              fontSize: 14, letterSpacing: 0.5))),
        ),
      ),
    );
  }
}

// ─── Animated Dot ──────────────────────────────────────────────────────────────
class _AnimatedDot extends StatefulWidget {
  final Color color;
  const _AnimatedDot({required this.color});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_animation.value),
          ),
        );
      },
    );
  }
}

// ─── NewsMedia ─────────────────────────────────────────────────────────────────
class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});
  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _ctrl;
  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _ctrl?.setLooping(true); _ctrl?.setVolume(0); _ctrl?.play();
        });
    }
  }
  bool _isVideo(String url) => url.endsWith('.mp4') || url.endsWith('.webm')
      || url.endsWith('.mov') || url.endsWith('.mkv');
  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_ctrl?.value.isInitialized == true) {
        return AspectRatio(aspectRatio: _ctrl!.value.aspectRatio,
            child: VideoPlayer(_ctrl!));
      }
      return Container(color: _C.card, child: const Center(child: SizedBox(
          width: 18, height: 18, child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Color(0xFF4ECDC4)))));
    }
    return Image.network(widget.url, fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null ? child
          : Container(color: _C.card, child: Center(child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
              strokeWidth: 1.5, color: const Color(0xFF4ECDC4)))),
      errorBuilder: (_, __, ___) => Container(color: _C.card,
          child: const Icon(Icons.broken_image_outlined,
              color: _C.textSub, size: 28)),
    );
  }
}

// ─── Shared ────────────────────────────────────────────────────────────────────
PageRoute _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionDuration: const Duration(milliseconds: 320),
  transitionsBuilder: (_, anim, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
    child: FadeTransition(opacity: anim, child: child)),
);