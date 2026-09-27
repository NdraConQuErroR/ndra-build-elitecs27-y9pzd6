// splash_dashboard.dart - TAMBAH CONTAC DEVELOPER
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- TAMBAH
import 'dashboard_page.dart';

class SplashDashboardPage extends StatefulWidget {
  final Map<String, dynamic>? data;
  const SplashDashboardPage({super.key, this.data});

  @override
  State<SplashDashboardPage> createState() => _SplashDashboardPageState();
}

class _SplashDashboardPageState extends State<SplashDashboardPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'XNOXAT VERSE V10',
      'subtitle': 'WELCOME TO XNOXAT APPS',
      'desc': 'Selamat Datang Di Menu Apps Kami',
      'icon': Icons.shield_rounded,
      'color1': 0xFF0D47A1,
      'color2': 0xFF1565C0,
    },
    {
      'title': 'XNOXAT APPS BUG',
      'subtitle': 'READY TO APPS XNOXAT',
      'desc': 'MASUK KE DASHBOARD\nBERGABUNGLAH & NIKMATI SEMUA FITUR BERSAMA BRO!!',
      'icon': Icons.rocket_launch_rounded,
      'color1': 0xFF1565C0,
      'color2': 0xFF1E88E5,
    },
    {
      'title': 'TEAM XNOXAT ENGINE',
      'subtitle': 'CHAT DEV',
      'desc': 'MASUK DASHBOARD',
      'icon': Icons.telegram,
      'color1': 0xFF1E88E5,
      'color2': 0xFF42A5F5,
    },
  ];

  // ===== FUNGSI BUKA TELEGRAM =====
  Future<void> _openTelegram() async {
    final url = Uri.parse('https://t.me/BUYAPKBUY/RoomPublicKayy1'); // GANTI LINK CHANNEL LU
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Telegram')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/splashd.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.play();
        _videoController.setVolume(1.0);
        _videoController.setLooping(true);
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Background
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A1929),
                    const Color(0xFF0D47A1).withOpacity(0.3),
                    const Color(0xFF0A1929),
                  ],
                ),
              ),
            ),

          // Overlay
          Container(color: Colors.black.withOpacity(0.4)),

          // Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final data = _pages[index];
              return _buildPage(data, index);
            },
          ),

          // Bottom: dots + button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          boxShadow: _currentPage == index
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      if (_currentPage == _pages.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardPage(
                              username: widget.data!['username'] as String? ?? '',
                              password: widget.data!['password'] as String? ?? '',
                              role: widget.data!['role'] as String? ?? 'member',
                              sessionKey: widget.data!['key'] as String? ?? '',
                              expiredDate: widget.data!['expiredDate'] as String? ?? '2099-12-31',
                              listBug: List<Map<String, dynamic>>.from(widget.data!['listBug'] ?? []),
                              listDoos: List<Map<String, dynamic>>.from(widget.data!['listDoos'] ?? []),
                              news: List<Map<String, dynamic>>.from(widget.data!['news'] ?? []),
                            ),
                          ),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(_pages[_currentPage]['color1']),
                            Color(_pages[_currentPage]['color2']),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Color(_pages[_currentPage]['color1'])
                                .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'MASUK DASHBOARD'
                                : 'LANJUT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.2,
                              fontFamily: 'AROMA',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Page indicator
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_pages.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'AROMA',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> data, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(data['color1']),
                  Color(data['color2']),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(data['color1']).withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              data['icon'],
              size: 70,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 50),

          // Title
          Text(
            data['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'AROMA',
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            data['subtitle'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'AROMA',
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            data['desc'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontFamily: 'AROMA',
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),

          // ===== TAMBAH CONTAC DEVELOPER (HANYA DI HALAMAN 3) =====
          if (index == 2) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _openTelegram,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF1E88E5).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      FontAwesomeIcons.telegram,
                      color: Color(0xFF42A5F5),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'CONTAC DEVELOPER',
                      style: TextStyle(
                        color: Color(0xFF42A5F5),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'AROMA',
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF42A5F5),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}