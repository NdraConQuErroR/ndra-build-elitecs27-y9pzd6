// splash_page.dart - FULL SPLASH DENGAN VIDEO
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'splash_dashboard.dart'; // <-- TAMBAH

class SplashPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const SplashPage({super.key, required this.data});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _colorController;
  bool _isInitialized = false;
  bool _textVisible = false;

  static const Color _primaryBlue    = Color(0xFF1565C0);
  static const Color _brightBlue     = Color(0xFF42A5F5);
  static const Color _deepBlue       = Color(0xFF0D47A1);
  static const Color _midBlue        = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();

    _colorController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });

        _videoController.play();
        _videoController.setVolume(1.0);

        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _textVisible = true;
            });
          }
        });
      });

    _videoController.addListener(() {
      if (_videoController.value.isInitialized &&
          _videoController.value.position >= _videoController.value.duration) {
        _navigateToOnboarding();
      }
    });
  }

  // ===== GANTI INI =====
  void _navigateToOnboarding() {
    _videoController.pause();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SplashDashboardPage(
            data: widget.data,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
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
              const Center(
                child: CircularProgressIndicator(color: _brightBlue),
              ),

            Container(color: Colors.black.withOpacity(0.3)),

            AnimatedOpacity(
              opacity: _textVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeIn,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _colorController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment(-1.0 + (_colorController.value * 2), -1.0),
                              end: Alignment(1.0 + (_colorController.value * 2), 1.0),
                              colors: const [
                                _deepBlue,
                                _brightBlue,
                                _midBlue,
                                _primaryBlue,
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ).createShader(bounds);
                          },
                          child: const Text(
                            "XNOXAT X CRASH",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'AROMA',
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(
                                  blurRadius: 22.0,
                                  color: _brightBlue,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Meninggi Tanpa Menyenggol Siapapun",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 15,
              right: 20,
              child: GestureDetector(
                onTap: _navigateToOnboarding, // <-- GANTI
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _primaryBlue.withOpacity(0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Lewati",
                        style: TextStyle(
                          color: _brightBlue,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'AROMA',
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, color: _brightBlue, size: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}