import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui; // Added for ImageFilter
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const _baseUrl = 'http://zyromodeapa.pteroq.biz.id:10750';

// ===== Palette: Dark Navy =====
class _C {
  static const bg        = Color(0xFF020617);
  static const surface   = Color(0xFF020B1F);
  static const card      = Color(0xFF0A1124);
  static const cardAlt   = Color(0xFF0F172A);
  static const border    = Color(0xFF1E293B);
  static const borderLit = Color(0xFF334155);
  static const borderHit = Color(0xFF3B82F6);
  static const accent    = Color(0xFF3B82F6);
  static const accentDim = Color(0xFF1D4ED8);
  static const green     = Color(0xFF22C55E);
  static const greenDim  = Color(0xFF15803D);
  static const amber     = Color(0xFFFACC15);
  static const red       = Color(0xFFEF4444);
  static const blue      = Color(0xFF60A5FA);
  static const text      = Color(0xFFE2E8F0);
  static const textSub   = Color(0xFF94A3B8);
  static const textDim   = Color(0xFF475569);

  static const LinearGradient btnGrad = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ===== CONSTANTS =====
const Color _cardBlack = Color(0xFF0A0A0A);
const Color _cardBlackDeep = Color(0xFF0D0D0D);
const Color _accentBlue = Color(0xFF0A1A3A);
const Color _accentDeep = Color(0xFF1D4ED8);
const Color _accentBlueGlow = Color(0xFF60A5FA);
const Color _greenLive = Color(0xFF22C55E);
const String _font = 'AROMA';
String _detectedDialCode = '+62';

// Added missing color getters
Color get _tealAccent => const Color(0xFF22D3EE);
Color get _greenAccent => const Color(0xFF4ADE80);
Color get _textWhite => const Color(0xFFFFFFFF);
Color get _textGrey => const Color(0xFF94A3B8);

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'owner':     return const Color(0xFFFBBF24);
    case 'admin':     return const Color(0xFFFF5555);
    case 'moderator': return const Color(0xFF4ADE80);
    case 'partner':   return const Color(0xFFD4D4D4);
    case 'vip':       return const Color(0xFFA78BFA);
    case 'reseller':  return const Color(0xFF4ADE80);
    default:          return _C.accent;
  }
}

// ===== HomePage =====
class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetCtrl = TextEditingController();
  final _payloadScrollCtrl = ScrollController();
  double _payloadScrollPos = 0;

  late AnimationController _liveDotController;

  // Fixed: Use consistent naming
  String _selectedBugId = '';
  String _senderType   = 'private';
  bool   _isSending    = false;
  String? _responseMsg;

  List<String> _globalSenders    = [];
  bool         _isLoadingSenders = false;

  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _sendBtnCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _waveCtrl;

  late Animation<double> _entrance;
  late Animation<double> _sendPulse;
  late Animation<double> _sendGlow;
  late Animation<double> _resultFade;
  late Animation<Offset>  _resultSlide;

  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _videoReady = false;

  // Added missing page controller
  late PageController _bugPageController;
  int _currentBugPage = 0;

  bool get canAccessGlobalSender {
    final r = widget.role.toLowerCase();
    return r == 'owner' || r == 'admin' || r == 'moderator' ||
           r == 'partner' || r == 'vip';
  }

  @override
  void initState() {
    super.initState();
    if (widget.listBug.isNotEmpty) {
      _selectedBugId = widget.listBug[0]['bug_id'] ?? '';
    }

    _bugPageController = PageController(initialPage: 0);

    _liveDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))..repeat();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _entrance = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);

    _sendBtnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _sendPulse = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));
    _sendGlow = Tween<double>(begin: 0.2, end: 0.5)
        .animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));

    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _resultFade  = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat();

    _entranceCtrl.forward();
    _initVideo();
    _loadGlobalSenders();

    _payloadScrollCtrl.addListener(() {
      setState(() {
        _payloadScrollPos = _payloadScrollCtrl.position.pixels;
      });
    });
  }

  @override
  void dispose() {
    _liveDotController.dispose();
    _bgCtrl.dispose();
    _entranceCtrl.dispose();
    _sendBtnCtrl.dispose();
    _resultCtrl.dispose();
    _waveCtrl.dispose();
    _payloadScrollCtrl.dispose();
    targetCtrl.dispose();
    _videoController.dispose();
    _chewieController?.dispose();
    _bugPageController.dispose();
    super.dispose();
  }

  // ===== Video =====
  void _initVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4');
    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.1);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
        );
        _videoReady = true;
      });
    }).catchError((e) {
      setState(() => _videoReady = false);
    });
  }

  // ===== Global Senders =====
  Future<void> _loadGlobalSenders() async {
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(Uri.parse(
        '$_baseUrl/getActiveSenders?key=${widget.sessionKey}',
      )).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['senders'] != null) {
        if (mounted) setState(() => _globalSenders = List<String>.from(data['senders']));
      } else {
        if (mounted) setState(() => _globalSenders = []);
      }
    } catch (_) {
      if (mounted) setState(() => _globalSenders = []);
    } finally {
      if (mounted) setState(() => _isLoadingSenders = false);
    }
  }

  // ===== Send =====
  Future<void> _sendBug() async {
    final rawInput = targetCtrl.text.trim();
    final key = widget.sessionKey;

    if (formatPhone(rawInput) == null) {
      _showAlert('Nomor Tidak Valid',
          'Gunakan format internasional.\nContoh: +62812xxxxxxxx');
      return;
    }

    if (_senderType == 'global' && !canAccessGlobalSender) {
      _showAlert('Akses Ditolak',
          'Sender Global hanya untuk Owner, Admin, Moderator, Partner & VIP!');
      return;
    }

    if (_selectedBugId.isEmpty) {
      _showAlert('Pilih Bug', 'Silakan pilih bug terlebih dahulu.');
      return;
    }

    setState(() { _isSending = true; _responseMsg = null; });
    _resultCtrl.reset();

    try {
      final encodedTarget = Uri.encodeComponent(rawInput);
      
      final url = Uri.parse(
        '$_baseUrl/sendBug'
        '?key=$key'
        '&target=$encodedTarget'
        '&bug=$_selectedBugId'
        '${_senderType == 'global' ? '&senderMode=global' : ''}',
      );
      
      final res = await http.get(url).timeout(const Duration(seconds: 30));
      final data = jsonDecode(res.body);

      if (data['valid'] == false) {
        _setResponse('error', 'Session key tidak valid. Silakan login ulang.');
      } else if (data['cooldown'] == true) {
        final wait = data['wait'] ?? 0;
        _setResponse('warning', 'Cooldown aktif! Tunggu $wait detik lagi.');
      } else if (data['sended'] == true) {
        final senderLabel = _senderType == 'global' ? 'Global Sender' : 'Private Sender';
        _setResponse('success', 'Bug berhasil dikirim ke $rawInput! [$senderLabel]');
        targetCtrl.clear();
      } else {
        _setResponse('error', 'Gagal mengirim. ${data['message'] ?? "Server maintenance."}');
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _setResponse('error', 'Request timeout. Periksa koneksi internet.');
      } else {
        _setResponse('error', 'Koneksi error. Periksa jaringan dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _setResponse(String type, String msg) {
    if (!mounted) return;
    setState(() => _responseMsg = '$type|$msg');
    _resultCtrl.forward(from: 0);
  }

  String? formatPhone(String s) {
    final c = s.replaceAll(RegExp(r'[^\d+]'), '');
    return (c.startsWith('+') && c.length >= 8) ? c : null;
  }

  void _showAlert(String title, String msg) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.amber.withOpacity(0.25), width: 1.5),
            boxShadow: [BoxShadow(color: _C.amber.withOpacity(0.08), blurRadius: 32)],
          ),
          padding: const EdgeInsets.all(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.amber.withOpacity(0.08),
                border: Border.all(color: _C.amber.withOpacity(0.25)),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: _C.amber, size: 26),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                  fontFamily: _font,
                  color: _C.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _font,
                  color: _C.textSub,
                  fontSize: 13,
                  height: 1.5,
                )),
            const SizedBox(height: 22),
            _GradBtn(label: 'OK', fullWidth: true, onTap: () => Navigator.pop(ctx)),
          ]),
        ),
      ),
    );
  }

  // ===== Build =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(children: [
        Positioned.fill(child: _AnimatedBg(controller: _bgCtrl)),
        SafeArea(
          child: FadeTransition(
            opacity: _entrance,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(children: [
                _buildProfileCard(),
                const SizedBox(height: 14),
                _buildVideoCard(),
                const SizedBox(height: 18),
                _buildTargetInput(),
                const SizedBox(height: 16),
                _buildSenderCard(),
                const SizedBox(height: 28),
                _buildSendButton(),
                const SizedBox(height: 12),
                if (_responseMsg != null) _buildResultBanner(),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ===== Glass card helper =====
  Widget _glassCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _C.card.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // ===== Profile card =====
  Widget _buildProfileCard() {
    return _glassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _tealAccent, width: 2.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/reze.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.person, color: _tealAccent, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'AROMA',
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.role.toUpperCase(),
                      style: TextStyle(
                        color: _tealAccent,
                        fontFamily: 'AROMA',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, color: _textGrey, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      widget.expiredDate,
                      style: TextStyle(
                        color: _textWhite,
                        fontFamily: 'AROMA',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                _buildStatItem(Icons.bug_report_rounded, _tealAccent,
                    '${widget.listBug.length}', 'Total Bugs'),
                _buildStatDivider(),
                _buildStatItem(Icons.bolt_rounded, _greenAccent, 'GACOR', 'Success Rate'),
                _buildStatDivider(),
                _buildStatItem(
                    Icons.check_circle_rounded, _greenAccent, 'ACTIVE', 'Status'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.18),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 7),
          Text(value,
              style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  fontFamily: 'AROMA')),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: _textGrey, fontSize: 10, fontFamily: 'AROMA')),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 52, color: Colors.white.withOpacity(0.12));
  }

  // ===== Video card =====
  Widget _buildVideoCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1A3A6A),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A6A).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _videoReady && _chewieController != null
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _chewieController!.videoPlayerController.value.size.width,
                    height: _chewieController!.videoPlayerController.value.size.height,
                    child: VideoPlayer(_chewieController!.videoPlayerController),
                  ),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6),
                  strokeWidth: 3,
                ),
              ),
      ),
    );
  }

  // ===== Target input =====
  Widget _buildTargetInput() {
    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: _tealAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'NOMOR TARGET',
                style: TextStyle(
                  color: _textWhite,
                  fontFamily: 'AROMA',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Input field
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                ),
                child: TextField(
                  controller: targetCtrl,
                  style: TextStyle(color: _textWhite, fontFamily: 'AROMA', fontSize: 15),
                  cursorColor: _tealAccent,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Contoh: +62812xxxxxxxx',
                    hintStyle: TextStyle(color: _textGrey.withOpacity(0.5), fontFamily: 'AROMA'),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.language_rounded, color: _textGrey, size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // PILIH BUG label
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'PILIH BUG',
                style: TextStyle(
                  color: _textWhite,
                  fontFamily: 'AROMA',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bug Carousel
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _bugPageController,
              itemCount: widget.listBug.length,
              onPageChanged: (i) {
                setState(() {
                  _currentBugPage = i;
                  final bug = widget.listBug[i];
                  final bugId = bug['bug_id'] as String? ?? '$i';
                  _selectedBugId = bugId;
                });
              },
              itemBuilder: (context, index) {
                final bug = widget.listBug[index];
                final bugId = bug['bug_id'] as String? ?? '$index';
                final isSelected = _selectedBugId == bugId;

                return AnimatedBuilder(
                  animation: _bugPageController,
                  builder: (context, child) {
                    double scale = 1.0;
                    if (_bugPageController.position.haveDimensions) {
                      double diff = (_bugPageController.page! - index).abs();
                      scale = (1 - diff * 0.07).clamp(0.93, 1.0);
                    }
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBugId = bugId),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? _tealAccent.withOpacity(0.18) : Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? _tealAccent : Colors.white.withOpacity(0.15),
                                width: isSelected ? 2 : 1.2,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(color: _tealAccent.withOpacity(0.35), blurRadius: 24, spreadRadius: 2)
                              ] : [],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.shield_rounded, color: isSelected ? _tealAccent : _textGrey, size: 36),
                                    if (isSelected) Icon(Icons.check_circle, color: _greenAccent, size: 24),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  (bug['bug_name'] as String? ?? 'BUG').toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? _tealAccent : _textWhite,
                                    fontFamily: 'AROMA',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    bug['bug_id']?.toString().toLowerCase() ?? 'bug',
                                    style: TextStyle(color: _textGrey, fontFamily: 'AROMA', fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.listBug.length, (i) {
              final isActive = i == _currentBugPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? _tealAccent : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===== Sender card =====
  Widget _buildSenderCard() {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
            blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                  color: _C.border.withOpacity(0.6))),
            ),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _C.borderLit),
                ),
                child: const Icon(FontAwesomeIcons.server,
                    color: _C.accent, size: 13),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih Sender', style: TextStyle(
                    fontFamily: _font,
                    color: _C.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
                  Text('Sumber nomor pengirim', style: TextStyle(
                    fontFamily: _font,
                    color: _C.textSub,
                    fontSize: 11,
                  )),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadGlobalSenders,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.border),
                  ),
                  child: _isLoadingSenders
                      ? const Padding(padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _C.accent))
                      : const Icon(Icons.refresh_rounded,
                          color: _C.textSub, size: 16),
                ),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(child: _SenderOption(
                icon: FontAwesomeIcons.globe,
                label: 'Global',
                sublabel: _isLoadingSenders
                    ? 'Loading...'
                    : '${_globalSenders.length} sender',
                selected: _senderType == 'global',
                locked: !canAccessGlobalSender,
                onTap: () {
                  if (!canAccessGlobalSender) {
                    _showAlert('Akses Ditolak',
                        'Sender Global hanya untuk Owner, Admin, Moderator, Partner & VIP!');
                    return;
                  }
                  setState(() => _senderType = 'global');
                  _loadGlobalSenders();
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: _SenderOption(
                icon: FontAwesomeIcons.userShield,
                label: 'Private',
                sublabel: 'Session lu sendiri',
                selected: _senderType == 'private',
                locked: false,
                onTap: () => setState(() => _senderType = 'private'),
              )),
            ]),
          ),

          if (_senderType == 'global' && _globalSenders.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.format_list_bulleted_rounded,
                        color: _C.textSub, size: 12),
                    const SizedBox(width: 6),
                    Text('${_globalSenders.length} sender aktif',
                        style: const TextStyle(
                          fontFamily: _font,
                          color: _C.textSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ]),
                  const SizedBox(height: 8),
                  ...(_globalSenders.take(3).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Container(width: 5, height: 5,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _C.green)),
                      const SizedBox(width: 8),
                      Text(s, style: const TextStyle(
                        fontFamily: _font,
                        color: _C.accent,
                        fontSize: 11,
                      )),
                    ]),
                  ))),
                  if (_globalSenders.length > 3)
                    Text('+ ${_globalSenders.length - 3} lainnya...',
                        style: const TextStyle(
                          fontFamily: _font,
                          color: _C.textDim,
                          fontSize: 10,
                        )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===== Send button =====
  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _sendBtnCtrl,
      builder: (_, __) => GestureDetector(
        onTap: _isSending ? null : _sendBug,
        child: Transform.scale(
          scale: _isSending ? 1.0 : _sendPulse.value,
          child: Container(
            height: 62, width: double.infinity,
            decoration: BoxDecoration(
              color: _isSending ? _C.cardAlt : _C.borderLit,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isSending
                    ? _C.border
                    : _C.accent.withOpacity(_sendGlow.value),
              ),
              boxShadow: _isSending
                  ? []
                  : [BoxShadow(
                      color: Colors.white
                          .withOpacity(_sendGlow.value * 0.08),
                      blurRadius: 24, offset: const Offset(0, 6),
                    )],
            ),
            child: Stack(children: [
              if (_isSending)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _WavePainter(_waveCtrl.value),
                      size: const Size(double.infinity, 62),
                    ),
                  ),
                ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _isSending
                      ? const Row(
                          key: ValueKey('sending'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: _C.text),
                            ),
                            SizedBox(width: 12),
                            Text('Mengirim Bug...', style: TextStyle(
                              fontFamily: _font,
                              color: _C.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            )),
                          ])
                      : const Row(
                          key: ValueKey('idle'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.rocket_launch_rounded,
                                color: _C.text, size: 20),
                            SizedBox(width: 10),
                            Text('KIRIM BUG ATTACK', style: TextStyle(
                              fontFamily: _font,
                              color: _C.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 1.2,
                            )),
                          ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ===== Result banner =====
  Widget _buildResultBanner() {
    if (_responseMsg == null) return const SizedBox();
    final parts = _responseMsg!.split('|');
    final type  = parts[0];
    final msg   = parts.length > 1 ? parts[1] : '';

    Color color;
    IconData icon;
    switch (type) {
      case 'success': color = _C.green; icon = Icons.check_circle_rounded; break;
      case 'warning': color = _C.amber; icon = Icons.warning_rounded; break;
      default:        color = _C.red;   icon = Icons.error_rounded;
    }

    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 14)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: color.withOpacity(0.1)),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type == 'success' ? 'Berhasil'
                        : type == 'warning' ? 'Peringatan' : 'Gagal',
                    style: TextStyle(
                      fontFamily: _font,
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(msg, style: const TextStyle(
                    fontFamily: _font,
                    color: _C.textSub,
                    fontSize: 12,
                    height: 1.4,
                  )),
                ],
              )),
              GestureDetector(
                onTap: () {
                  setState(() => _responseMsg = null);
                  _resultCtrl.reset();
                },
                child: const Icon(Icons.close_rounded, color: _C.textDim, size: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Widgets =====
class _InputSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _InputSection({
    required this.icon, required this.label, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _C.border.withOpacity(0.6))),
          ),
          child: Row(children: [
            Icon(icon, color: _C.textSub, size: 14),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(
              fontFamily: _font,
              color: _C.textSub,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(12), child: child),
      ]),
    );
  }
}

class _SenderOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _SenderOption({
    required this.icon, required this.label, required this.sublabel,
    required this.selected, required this.locked, required this.onTap,
  });

  @override
  State<_SenderOption> createState() => _SenderOptionState();
}

class _SenderOptionState extends State<_SenderOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? _C.accent : _C.textSub;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.selected ? _C.borderLit : _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected ? _C.borderHit : _C.border,
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(widget.icon, color: color, size: 19),
              if (widget.locked)
                Positioned(
                  right: -4, top: -4,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.amber,
                      border: Border.all(color: _C.card, width: 1.5),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 7),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(widget.label, style: TextStyle(
              fontFamily: _font,
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 3),
            Text(widget.sublabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _font,
                  color: _C.textDim,
                  fontSize: 10,
                  height: 1.3,
                )),
            if (widget.selected) ...[
              const SizedBox(height: 6),
              Container(width: 18, height: 2.5,
                  decoration: BoxDecoration(
                    color: _C.green,
                    borderRadius: BorderRadius.circular(2),
                  )),
            ],
          ]),
        ),
      ),
    );
  }
}

// ===== Background & Primitives =====
class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 4 * math.pi) + (t * math.pi * 2)) *
              size.height * 0.14;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader();

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_c.value - i / 3) % 1.0).clamp(0.0, 1.0);
          final s = math.sin(t * math.pi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: 0.4 + s * 0.6,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.accent.withOpacity(0.3 + s * 0.6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(painter: _BgPainter(controller.value)),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFF272727).withOpacity(0.28)
      ..strokeWidth = 0.4;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFFFFF)
            .withOpacity(0.025 + math.sin(t * math.pi * 2) * 0.008),
        Colors.transparent,
      ], radius: 0.85).createShader(
          Rect.fromCircle(
              center: Offset(size.width / 2, 0), radius: size.width));
    canvas.drawCircle(Offset(size.width / 2, 0), size.width, glow);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

class _GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _GradBtn({
    required this.label, required this.onTap, this.fullWidth = false,
  });

  @override
  State<_GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<_GradBtn> {
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
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: _C.cardAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.borderLit),
            boxShadow: _down
                ? []
                : [BoxShadow(color: Colors.black.withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Center(
            child: Text(widget.label,
                style: const TextStyle(
                  fontFamily: _font,
                  color: _C.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )),
          ),
        ),
      ),
    );
  }
}