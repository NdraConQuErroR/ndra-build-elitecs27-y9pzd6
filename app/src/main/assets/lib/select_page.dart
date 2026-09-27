// ===== select_page.dart (FIXED) =====
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'home_page.dart';
import 'bug_group.dart';
import 'bug_sender.dart';
import 'device_dashboard.dart';

class SelectPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String uId;
  final String role;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;
  final VoidCallback? onBack;

  const SelectPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.uId,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
    this.onBack,
  });

  @override
  State<SelectPage> createState() => _SelectPageState();
}

class _SelectPageState extends State<SelectPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  late VideoPlayerController _bgVideoController;
  bool _bgVideoReady = false;

  // ✅ FIX: 4 CARD — SEMUA PAKE reze.png
  final List<_MenuCard> _cards = const [
    _MenuCard(
      title: 'XNOXAT BUG',
      subtitle: 'Bug tanpa custom\n( default bug )',
      description: 'Gunakan langsung tanpa custom delay dan loops',
      badge: 'RECOMMENDED',
      badgeColor: Color(0xFFE65100),
      features: ['mudah digunakan', 'function terbaru', 'all work', 'XNOXATX BUG'],
      imageAsset: 'assets/images/spam.jpg',
    ),
    _MenuCard(
      title: 'XNOXAT BUG GROUP',
      subtitle: 'Bug Group',
      description: 'Auto spam tanpa henti dengan interval yang bisa diatur',
      badge: 'EXTREME',
      badgeColor: Color(0xFF1565C0),
      features: ['auto repeat', 'high speed', 'mass target', 'XNOXATX BUG GROUP'],
      imageAsset: 'assets/images/reze.png',
    ),
    _MenuCard(
      title: 'RAT XNOXAT',
      subtitle: 'Remote Access Trojan',
      description: 'Sadap jarak jauh, malware, dan trojan',
      badge: 'RAT SYSTEM',
      badgeColor: Color(0xFF6A1B9A),
      features: ['Sadap Jarak Jauh', 'Malware', 'Trojan', 'Full Control'],
      imageAsset: 'assets/images/custom.jpg',
    ),
    _MenuCard(
      title: 'MANAGE SENDER',
      subtitle: 'Untuk Memulai Bug Terlebih Dahulu Memasang Sender',
      description: 'Pairing & Konfigurasi WhatsApp Sender',
      badge: 'SUPPORT BUG',
      badgeColor: Color(0xFF6A1B9A),
      features: ['Sender Support', 'All WhatsApp', 'SENDER BUG'],
      imageAsset: 'assets/images/reze.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0, initialPage: 0);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _bgVideoController = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        _bgVideoController.setLooping(true);
        _bgVideoController.setVolume(0);
        _bgVideoController.play();
        if (mounted) setState(() => _bgVideoReady = true);
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _bgVideoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _bgVideoReady
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _bgVideoController.value.size.width,
                      height: _bgVideoController.value.size.height,
                      child: VideoPlayer(_bgVideoController),
                    ),
                  )
                : Container(color: const Color(0xFF0A0A0A)),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.60),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        _buildBackButton(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        const Spacer(),
                        const Text(
                          'DRIV4X MENU',
                          style: TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'AROMA',
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTitle(),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih menu yang tersedia!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: 'AROMA',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60, height: 2.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        final isActive = index == _currentPage;
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: isActive ? 1.0 : 0.90, end: isActive ? 1.0 : 0.90),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, scale, _) => Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: isActive ? 1.0 : 0.65,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildMenuCard(card),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDots(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00BCD4), Color(0xFF80DEEA)],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: const Text(
        'DRIV4X MENU',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          fontFamily: 'AROMA',
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildMenuCard(_MenuCard card) {
    final allowedRoles = ['dev', 'team_project', 'founder', 'moderator', 'high_owner', 'tk', 'owner', 'vip', 'member'];
    final restricted  = !allowedRoles.contains(widget.role.toLowerCase());
    final isLocked    = restricted && card.title != 'XNOXAT BUG';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (!isLocked)
              BoxShadow(
                color: card.badgeColor.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLocked
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.18),
                width: 1.5,
              ),
            ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                card.badgeColor.withOpacity(isLocked ? 0.10 : 0.25),
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16, right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.grey.withOpacity(0.4) : card.badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isLocked ? 'LOCKED' : card.badge,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 10,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'AROMA', letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        // ✅ SEMUA PAKE reze.png
                        if (!isLocked)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              child: Image.asset(
                                card.imageAsset,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (isLocked)
                          Center(
                            child: Icon(Icons.lock_rounded, color: Colors.grey, size: 48),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: TextStyle(
                              color: isLocked ? Colors.grey : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'AROMA', letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLocked ? 'Diperlukan VIP ke atas' : card.subtitle,
                            style: TextStyle(
                              color: (isLocked ? Colors.grey : Colors.white).withOpacity(0.6),
                              fontSize: 12, fontFamily: 'AROMA', height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Divider(color: const Color(0xFF00BCD4).withOpacity(0.2), thickness: 1),
                          const SizedBox(height: 8),
                          Text(
                            isLocked ? 'Fitur ini hanya tersedia untuk role VIP, Owner, dan di atas nya.' : card.description,
                            style: TextStyle(
                              color: (isLocked ? Colors.grey : Colors.white).withOpacity(0.75),
                              fontSize: 12, fontFamily: 'AROMA', height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!isLocked)
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: card.features.map((f) => _buildFeaturePill(f)).toList(),
                            ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: _buildAnimatedButton(
                              isLocked: isLocked,
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _onSelectCard(card);
                              },
                              label: isLocked ? 'TERKUNCI' : 'PILIH MENU INI',
                              icon: isLocked ? Icons.lock_rounded : Icons.flash_on_rounded,
                              badgeColor: card.badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.black.withOpacity(0.35),
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

  Widget _buildBackButton({required VoidCallback onTap}) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onTap();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedScale(
            scale: isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(isPressed ? 0.55 : 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00BCD4).withOpacity(isPressed ? 0.6 : 0.4),
                  width: isPressed ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (isPressed)
                    BoxShadow(
                      color: const Color(0xFF00BCD4).withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF00BCD4),
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturePill(String label) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(isHovered ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(isHovered ? 0.5 : 0.3),
              ),
              boxShadow: [
                if (isHovered)
                  BoxShadow(
                    color: const Color(0xFF00BCD4).withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isHovered ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF00BCD4),
                    size: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'AROMA',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_cards.length, (i) {
        final active = i == _currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            width: active ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: active
                  ? const Color(0xFF00BCD4)
                  : Colors.white.withOpacity(0.3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedButton({
    required bool isLocked,
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color badgeColor,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            onPressed();
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedScale(
            scale: isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (!isLocked)
                    BoxShadow(
                      color: badgeColor.withOpacity(isPressed ? 0.4 : 0.2),
                      blurRadius: isPressed ? 12 : 8,
                      spreadRadius: isPressed ? 2 : 0,
                    ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLocked ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLocked
                      ? Colors.grey.withOpacity(0.3)
                      : const Color(0xFF0097A7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: isLocked ? 0 : (isPressed ? 2 : 6),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'AROMA',
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSelectCard(_MenuCard card) {
    final restricted = ['reseller', 'member', 'owner'].contains(widget.role.toLowerCase());

    if (card.title == 'XNOXAT BUG GROUP' && restricted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔒 Group Bug — Upgrade role terlebih dahulu'),
        backgroundColor: Color(0xFF333340),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (card.title == 'XNOXAT BUG') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HomePage(
          username: widget.username,
          password: widget.password,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          role: widget.role,
          expiredDate: widget.expiredDate,
        ),
      ));
      return;
    }
    
    if (card.title == 'XNOXAT BUG GROUP') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GroupBugPage(
          username: widget.username,
          password: widget.password,
          sessionKey: widget.sessionKey,
          role: widget.role,
          expiredDate: widget.expiredDate,
        ),
      ));
      return;
    }

    if (card.title == 'RAT XNOXAT') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DeviceDashboardPage(
          username: widget.username,
          role: widget.role,
          sessionKey: widget.sessionKey,
        ),
      ));
      return;
    }

    if (card.title == 'MANAGE SENDER') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BugSenderPage(
          sessionKey: widget.sessionKey,
          username: widget.username,
          role: widget.role,
        ),
      ));
      return;
    }
  }
}

// ✅ FIX: _MenuCard — tambahin field imageAsset
class _MenuCard {
  final String title;
  final String subtitle;
  final String description;
  final String badge;
  final Color badgeColor;
  final List<String> features;
  final String imageAsset; // ✅ TAMBAHIN INI

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.features,
    required this.imageAsset, // ✅ WAJIB ADA
  });
}