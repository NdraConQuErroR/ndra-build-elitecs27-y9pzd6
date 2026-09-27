import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

const String _baseUrl = 'http://zyromodeapa.pteroq.biz.id:10750';

// ─── LANDING PAGE ─────────────────────────────────────────────────────────────
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  // ─── COLORS ONBOARDING (HITAM) ──────────────────────────────────────────────
  final Color _onboardBg = Colors.black;
  final Color _onboardText = Colors.white;
  final Color _onboardMuted = Colors.white70;
  final Color _onboardCard = const Color(0xFF1A1A1A);
  final Color _onboardLine = Colors.white24;
  final Color _primary = const Color(0xFF3B82F6);
  final Color _primarySoft = const Color(0xFF60A5FA);
  final Color _primaryGlow = const Color(0xFF1D4ED8);

  // ─── COLORS LANDING (BIRU) ──────────────────────────────────────────────────
  final Color _landingBg = const Color(0xFF020617);
  final Color _landingText = const Color(0xFFF0F8FF);
  final Color _landingMuted = const Color(0xFF94A3B8);
  final Color _landingCard = const Color(0xFF0A1628);
  final Color _landingLine = const Color(0xFF1E293B);

  // ─── ANIMATION ───────────────────────────────────────────────────────────────
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  // ─── STATE ───────────────────────────────────────────────────────────────────
  bool _isCheckingAuth = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _checkAutoLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── AUTO LOGIN ──────────────────────────────────────────────────────────────
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser == null || savedPass == null || savedKey == null) {
      setState(() => _isCheckingAuth = false);
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final androidId = android.id ?? "unknown_device";

      final uri = Uri.parse("$_baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data['valid'] == true && data['expired'] == false) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SplashPage(
              data: {
                'username': savedUser,
                'password': savedPass,
                'role': data['role'] ?? 'member',
                'key': data['key'] ?? savedKey,
                'expiredDate': data['expiredDate'] ?? '2099-12-31',
                'listBug': (data['listBug'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
                'listDoos': (data['listDDoS'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
                'news': (data['news'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
              },
            ),
          ),
        );
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isCheckingAuth = false);
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) { _showSnack('Link tidak valid.'); return; }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showSnack('Tidak dapat membuka link.');
      }
    } catch (_) {
      _showSnack('Terjadi kesalahan.');
    }
  }

  // ─── GLOW ────────────────────────────────────────────────────────────────────
  Widget _glow(double size, Color color) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 45, sigmaY: 45),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  // ─── GLASS CARD (Hitam) ─────────────────────────────────────────────────────
  Widget _glassCardBlack({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _onboardCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _onboardLine, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  // ─── GLASS CARD (Biru) ──────────────────────────────────────────────────────
  Widget _glassCardBlue({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _landingCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _landingLine, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  // ─── OUTLINE BUTTON ──────────────────────────────────────────────────────────
  Widget _outlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool glow = false,
  }) {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: glow
            ? LinearGradient(
                colors: [_primary, _primaryGlow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: glow ? null : Border.all(color: _landingLine, width: 1.5),
        boxShadow: glow
            ? [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 20, spreadRadius: 2)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: glow ? Colors.white.withOpacity(0.1) : _primary.withOpacity(0.1),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, color: glow ? Colors.white : _primarySoft, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'AROMA',
                    color: glow ? Colors.white : _landingText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 2.5),
              ),
              const SizedBox(height: 20),
              Text(
                'Connecting...',
                style: TextStyle(color: Colors.white70, fontFamily: 'AROMA', fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return _buildOnboardingPage();
  }

  // ─── ONBOARDING (HITAM) + LANDING (BIRU) ────────────────────────────────────
  Widget _buildOnboardingPage() {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _onboardBg,
      body: Stack(
        children: [
          // ─── GLOW BACKGROUND ──────────────────────────────────────────────────
          Positioned(
            top: -60,
            left: size.width * 0.15,
            child: _glow(size.width * 0.55, _primary.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 0,
            left: -40,
            child: _glow(size.width * 0.28, _primary.withOpacity(0.05)),
          ),

          // ─── PAGE VIEW ──────────────────────────────────────────────────────
          PageView(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            children: [
              _buildWelcomePage(),
              _buildDisclaimerPage(),
              _buildLandingPage(),
            ],
          ),

          // ─── INDICATOR ──────────────────────────────────────────────────────
          Positioned(
            right: 16,
            top: size.height * 0.5 - 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  width: 3,
                  height: active ? 24 : 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: active ? _primarySoft : _onboardMuted.withOpacity(0.3),
                    boxShadow: active
                        ? [BoxShadow(color: _primarySoft.withOpacity(0.4), blurRadius: 8)]
                        : null,
                  ),
                );
              }),
            ),
          ),

          // ─── SWIPE INDICATOR ──────────────────────────────────────────────────
          if (_currentPage < 2)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1 * _glowAnim.value),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _primary.withOpacity(0.2 * _glowAnim.value)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swipe_up_rounded, color: _primarySoft, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _currentPage == 0 ? 'GESER KE ATAS' : 'GESER LAGI',
                          style: TextStyle(
                            fontFamily: 'AROMA',
                            color: _primarySoft,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── PAGE 1: WELCOME (HITAM) ──────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primary.withOpacity(0.15 * _glowAnim.value),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_primary, _primaryGlow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.2 + _glowAnim.value * 0.2),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'XNOXAT X CRASH',
              style: TextStyle(
                fontFamily: 'AROMA',
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'GACOR  ·  PERFORMANCE  ·  STABIL',
              style: TextStyle(
                fontFamily: 'AROMA',
                color: Colors.white60,
                letterSpacing: 4,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PAGE 2: WAHYU X CRASH V10 (HITAM) ──────────────────────────────────────────
  Widget _buildDisclaimerPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF60A5FA), size: 28),
          ),
          const SizedBox(height: 20),
          const Text(
            'WAHYU X CRASH V10',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'AROMA',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _glassCardBlack(
            padding: const EdgeInsets.all(18),
            child: const Text(
              'XNOXAT VERSE Apps adalah platform komunitas digital yang dibangun untuk memberikan kebebasan dalam berinovasi. Kami menyediakan berbagai tools canggih, mulai dari sistem manajemen server hingga asisten AI pintar.\n\nDengan bergabung bersama kami, Anda menjadi bagian dari ekosistem yang terus berkembang, mengedepankan keamanan dan kenyamanan pengguna.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.7,
                fontFamily: 'AROMA',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAGE 3: LANDING (BIRU) ──────────────────────────────────────────────
  Widget _buildLandingPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _landingBg,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      // Logo
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [_primary.withOpacity(0.25), Colors.transparent],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/images/reze.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: LinearGradient(
                                      colors: [
                                        _primary.withOpacity(0.3),
                                        _primarySoft.withOpacity(0.1),
                                      ],
                                    ),
                                    border: Border.all(color: _primary.withOpacity(0.4)),
                                  ),
                                  child: Icon(Icons.flash_on, color: _primarySoft, size: 54),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.white, _primarySoft, Colors.white],
                        ).createShader(bounds),
                        child: const Text(
                          'WAHYU X CRASH',
                          style: TextStyle(
                            fontFamily: 'AROMA',
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'GACOR  ·  PERFORMANCE  ·  STABIL',
                        style: TextStyle(
                          fontFamily: 'AROMA',
                          color: _primarySoft.withOpacity(0.7),
                          letterSpacing: 3,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Info Card (Biru)
                      _glassCardBlue(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _primary.withOpacity(0.2)),
                              ),
                              child: Icon(Icons.shield_outlined, color: _primarySoft, size: 32),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'XNOXAT X CRASH',
                              style: TextStyle(
                                fontFamily: 'AROMA',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aplikasi dengan desain elegan dan fitur terbaru.\nAccess restricted to authorized users.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'AROMA',
                                color: _landingMuted,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Login Button
                      _outlineButton(
                        icon: FontAwesomeIcons.bolt,
                        label: 'LOGIN TO APPS',
                        glow: true,
                        onTap: () => Navigator.pushNamed(context, '/login'),
                      ),
                      const SizedBox(height: 12),

                      // Support Button
                      _outlineButton(
                        icon: FontAwesomeIcons.headset,
                        label: 'CONTACT SUPPORT',
                        glow: false,
                        onTap: () => _openUrl('https://t.me/BUYAPKBUY/KayzzScarry'),
                      ),
                      const SizedBox(height: 24),

                      // Footer (Biru)
                      _glassCardBlue(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: _landingMuted, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'HUBUNGI KAMI',
                              style: TextStyle(
                                fontFamily: 'AROMA',
                                color: _landingMuted,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ FOOTER TEKS BAWAH (UDAH SAYA PERBAIKI & GANTI TRANSPARAN)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2230).withOpacity(0.5), // ✅ TRANSPARAN 50%
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "BY: TEAM XNOXAT VERSE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'AROMA',
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "© 2026 XNOXAT V10 — Thanks All Buyer",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                                fontFamily: 'AROMA',
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}